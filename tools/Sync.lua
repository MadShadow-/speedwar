--[[
		Sync Version 3.0
		
		-- Sync.CallNoSync("Message","Hello")
		-- Sync.Call("Logic.CreateEntity", Entities.PU_Hero3, 15000,15000,0,1)
		-- MPMenu.Screen_ToT1()
]]
Sync = {
	PrepareChar = string.char(2),
	AcknowledgeChar = string.char(3),
	NoSyncChar = string.char(4)
}
Sync.CNetworkCalls = {
	["SW.Bastille.TrackGroup"] = function( _sender, _bId, ...) 
		local bPId = Logic.EntityGetPlayer( _bId)
		if not CNetwork.isAllowedToManipulatePlayer( _sender, bPId) then
			return
		end
		for i = 1, arg.n do
			if Logic.EntityGetPlayer(arg[i]) ~= bPId then return end
		end
		-- all checks were successful? go!
		arg.n = nil
		SW.Bastille.TrackGroup( arg, _bId)
	end,
	["SW.Bastille.SyncedReleaseAllUnits"] = function( _sender, _bId)
		if CNetwork.isAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _bId)) then
			SW.Bastille.SyncedReleaseAllUnits( _bId)
		end
	end,
	["SW.Bastille.ReleaseOneUnitSynced"] = function( _sender, _bId, _slotId)
		if CNetwork.isAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _bId)) then
			SW.Bastille.ReleaseOneUnitSynced( _bId, _slotId)
		end
	end,
	["SW.Walls2.SellWall"] = function( _sender, _eId) 
		if CNetwork.isAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _eId)) then
			SW.Walls2.SellWall( _eId)
		end
	end,
	["SW.Walls2.ToggleGate"] = function( _sender, _eId) 
		if CNetwork.isAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _eId)) then
			SW.Walls2.ToggleGate( _eId)
		end
	end,
	["SW.WallGUI.AddWallInConstructionToQueue"] = function( _sender, _eId, _wall, _isNewWall)
		if CNetwork.isAllowedToManipulatePlayer( _sender, Logic.EntityGetPlayer( _eId)) then
			SW.WallGUI.AddWallInConstructionToQueue( _eId, _wall, _isNewWall)
		end
	end
}

function Sync.Init()
	if CNetwork then
		Sync.CNetworkInit()
		return
	end

	-- allow use of tributes
	GameCallback_FulfillTribute = function() return 1 end
	
	Sync.UseWhitelist = true
	Sync.Whitelist = {
		["SW.Activate"] = true,
		["SW.Bastille.TrackGroup"] = true,
		["SW.Bastille.SyncedReleaseAllUnits"] = true,
		["SW.Bastille.ReleaseOneUnitSynced"] = true,
		["SW.Walls2.SellWall"] = true,
		["SW.Walls2.ToggleGate"] = true,
		["SW.WallGUI.PayCosts"] = true,
		["SW.WallGUI.AddWallInConstructionToQueue"] = true,
		["SW.ResumeGame"] = true,
		--["Message"] = true
	};
	
	-- numOfTributes determines actions at the same time
	local numberOfTributes = 150;
	Sync.Tributes = {}
	for playerId = 1,8 do
		for i = 1, numberOfTributes do
			Sync.CreateNewTribut(playerId)
		end
	end
	
	-- this overwrite should be the last one, to overwrite this method
	-- so no one can accidentely filter out sync messages
	Sync.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage;
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _alliedOnly, _senderID )
		if string.find(_msg, Sync.PrepareChar) == 1 then
			Sync.OnPrepareMessageArrived(string.sub(_msg, 2))
			return
		elseif string.find(_msg, Sync.AcknowledgeChar) == 1 then
			Sync.OnAcknowledgeMessageArrived(string.sub(_msg, 2), _senderID)
			return
		elseif string.find(_msg, Sync.NoSyncChar) == 1 then
			Sync.ExecuteFunctionByString(string.sub(_msg,2))
			return
		end
		Sync.MPGame_ApplicationCallback_ReceivedChatMessage(_msg, _alliedOnly, _senderID);
	end
	-- change some stuff if CNetwork is present
	if CNetwork then
		-- change chars for reasons unknown
		Sync.PrepareChar = "SyncPrep"
		Sync.AcknowledgeChar = "SyncAck"
		Sync.NoSyncChar = "SyncNSyn"
		MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _alliedOnly, _senderID )
			local n1 = string.find(_msg, Sync.PrepareChar)
			local n2 = string.find(_msg, Sync.AcknowledgeChar)
			local n3 = string.find(_msg, Sync.NoSyncChar)
			if n1 then
				Sync.OnPrepareMessageArrived( Sync.RemoveColor( string.sub(_msg, n1+8)))
				return
			elseif n2 then
				Sync.OnAcknowledgeMessageArrived( Sync.RemoveColor( string.sub(_msg, n2+7)), _senderID)
				return
			elseif n3 then
				Sync.ExecuteFunctionByString( Sync.RemoveColor( string.sub(_msg,n3+8)))
				return
			end
			Sync.MPGame_ApplicationCallback_ReceivedChatMessage(_msg, _alliedOnly, _senderID);
		end
	end
	
	
	Sync.Call = function(_func, ...)
		local player = GUI.GetPlayerID()
		local id = Sync.GetFreeTributeId(player)
		if not id then
			Message("Sync Failed: No Tribute Id's left")
			return
		end
		Sync.Tributes[id].Used = true
		Sync.Tributes[id].AckData = {}
		for i = 1, 8 do
			Sync.Tributes[id].AckData[i] = ((XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) ~= 1) or GUI.GetPlayerID() == i or (XNetwork.GameInformation_IsHumanPlayerThatLeftAttachedToPlayerID(i) == 1))
		end
		local fs = Sync.CreateFunctionString( _func, unpack(arg))
		Sync.OverwriteTributeCallback(id, fs)
		Sync.Send(Sync.PrepareChar..id..fs);
	end
	Sync.CallNoSync = function(_func, ...)
		Sync.Send(Sync.NoSyncChar .. Sync.CreateFunctionString(_func, unpack(arg)))
	end
end
function Sync.CNetworkInit()
	for k,v in pairs(Sync.CNetworkCalls) do
		CNetwork.SetNetworkHandler( k, v)
	end
	Sync.Call = function( _s, ...)
		if _s == "SW.Bastille.TrackGroup" then
			CNetwork.send_command( _s, arg[2], unpack(arg[1]))
			return
		end
		if Sync.CNetworkCalls[_s] then
			arg.n = nil
			CNetwork.send_command( _s, unpack(arg))
		else
			Message("Unknown command send to sync: ".._s)
		end
	end
end

function Sync.RemoveColor( _str)
	local n = string.find( _str, "@color")
	if n then
		return string.sub( _str, 1, n-1)
	end
	return _str
end
function Sync.AddCall(_f)
	Sync.Whitelist[_f] = true;
end
function Sync.OverwriteTributeCallback(_id, _fs)
	Sync.Tributes[_id].Callback = function()
		Sync.ExecuteFunctionByString(_fs)
		Sync.CreateNewTribut(Sync.Tributes[_id].Player)
		Sync.Tributes[_id] = nil
	end
end
function Sync.OnPrepareMessageArrived(_msg)
	local start, finish = string.find( _msg, "%d+")
	local tributeId = tonumber(string.sub(_msg, start, finish))
	local fs = string.sub( _msg, finish+1)
	Sync.OverwriteTributeCallback(tributeId, fs)
	Sync.Send(Sync.AcknowledgeChar..tributeId)
end
function Sync.OnAcknowledgeMessageArrived(_msg, _pId)
	local tributeId = tonumber(_msg)
	-- Is tributeId for this player?
	if GUI.GetPlayerID() ~= Sync.Tributes[tributeId].Player then
		return
	end
	Sync.Tributes[tributeId].AckData[_pId] = true;
	for i = 1, 8 do
		if not Sync.Tributes[tributeId].AckData[i] then
			return
		end
	end
	if CNetwork then
		GUI.PayTribute(Sync.Tributes[tributeId].Player, tributeId)
	else
		GUI.PayTribute(8, tributeId)
	end
end

function Sync.Send(_str)
	if SW.IsMultiplayer() then
		XNetwork.Chat_SendMessageToAll(_str)
	else
		MPGame_ApplicationCallback_ReceivedChatMessage(_str, 0, GUI.GetPlayerID())
	end
end

function Sync.CreateNewTribut(_playerId)
	local tributePlayerId = 8
	if CNetwork then
		tributePlayerId = _playerId
	end
	local tributeData = {
		text = "",
		cost = {},
		pId = tributePlayerId,
		Callback = function()	--TO BE OVERRIDEN ONCE FUNCTION IS READY TO CALL
		end				
	}
	local tributeId = AddTribute(tributeData)
	Sync.Tributes[tributeId] = tributeData
	Sync.Tributes[tributeId].Player = _playerId
	Sync.Tributes[tributeId].Used = false
end

function Sync.GetFreeTributeId(_pId)
	for k,v in pairs(Sync.Tributes) do
		if (not v.Used) and (v.Player == _pId) then
			return k
		end
	end
end

-- type mapping: 1=string, 2=number, 3=table, 4=boolean, 5=true, 6=false
-- structure: key, valuetype, value

function Sync.CreateFunctionString(_func, ...)
	return _func .. string.char(4) .. Sync.TableToString(arg)
end

function Sync.ExecuteFunctionByString(_s)
	local start = string.find(_s, string.char(4))
	local fString = string.sub(_s, 1, start-1)
	if Sync.UseWhitelist and not Sync.Whitelist[fString] then
		SW.PreciseLog.Log("Bad fs: ".._s, "SyncError")
		return;
	end
	local arguments = Sync.StringToTable(string.sub(_s, start+1))
	local ref = _G;
	local sep = string.find(fString, ".", 1, true)
	while(sep) do
		ref = ref[string.sub(fString, 1, sep-1)]
		fString = string.sub(fString, sep+1)
		sep = string.find(fString, ".", 1, true)
	end
	ref[fString](unpack(arguments))
end

function Sync.TableToString(_table)
	local s = ""
	-- X as seperator
	local X = string.char(4)
	for key, value in pairs(_table) do
		s = s .. key .. X
		if type(value) == "string" then
			s = s .. "1" .. value .. X
		elseif type(value) == "number" then
			s = s .. "2" .. value .. X
		elseif type(value) == "boolean" then
			local bool = "6"
			if value then
				bool = "5"
			end
			s = s .. "4" .. bool .. X
		elseif type(value) == "table" then
			s = s .. "3" .. Sync.TableToString(value) .. X
		else
			s = s .. "1" .. tostring(value) .. X
		end
	end
	return s .. string.char(3)
end

function Sync.StringToTable(_string)
	local t = {}
	local getKeyAndVType = function()
		local next = string.find(_string, string.char(4))
		local key, vtype = string.sub(_string, 1, next-1), string.sub(_string, next+1, next+1)
		_string = string.sub(_string, next+2)
		return (tonumber(key) or key), vtype
	end
	local getValue = function()
		local next = string.find(_string, string.char(4))
		local value = string.sub(_string, 1, next-1)
		_string = string.sub(_string, next+1)
		return value
	end
	local isEnd = function()
		if string.find(_string, string.char(3)) == 1 then
			return true
		end
	end
	local key, vtype, v
	repeat
		if isEnd() then
			return t, string.sub(_string, 3)
		end
		key, vtype = getKeyAndVType()
		if vtype == "3" then
			v, _string = Sync.StringToTable(_string)
		elseif vtype == "2" then
			v = tonumber(getValue())
		elseif vtype == "4" then
			v = (getValue()=="5")
		else
			v = getValue()
		end
		t[key] = v
	until(false)
end
-- X=Sync.StringToTable(Sync.TableToString({1,2}))
