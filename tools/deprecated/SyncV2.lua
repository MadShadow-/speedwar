--	Sync2:
--		Sync2.Call sends Sync2.KeyPrep.."something" to all players via message
--		Receivers send Sync2.KeyAck message
--		Once all players sent Sync2.KeyAck, tribute will be paid

-- 		First, generate 100 tributes per player that are only paid by this player
--		If a player wants to sync smth, send out "KeyPrep";tributeId;functionstring
--			Once a player receives "KeyPrep"smth, send "KeyAck";tributeId and write tributeCallback
--			Once a player receives "KeyAck";tributeId and tributeId is one of our tributeIds, check a box
--		All players sent their KeyAck? PayTribute, create new tribute



Sync2 = {};
function Sync2.Init()
	
	Sync2.KeyPrep = "SyncPrep"
	Sync2.KeyPrep_Length = string.len(Sync2.KeyPrep)
	Sync2.KeyAck = "SyncAck"
	Sync2.KeyAck_Length = string.len(Sync2.KeyAck)
	Sync2.NumOfTributes = 100
	Sync2.Tributes = {}
	for playerId = 1,SW.MaxPlayers do
		for i = 1, Sync2.NumOfTributes do
			Sync2.NewTributeFor(playerId)
		end
	end
	Sync2.UseWhitelist = false
	Sync2.Whitelist = {
		["SW.Activate"] = true,
		["SW.Bastille.TrackGroup"] = true,
		["SW.Bastille.SpawnReleasedUnit"] = true,
		["SW.Walls.SellWall"] = true,
		["SW.Walls.ToggleGate"] = true,
		["SW.WallGUI.PayCosts"] = true,
		["SW.WallGUI.AddWallInConstructionToQueue"] = true,
	};

	GameCallback_FulfillTribute = function() return 1 end
	
	Sync2.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage;
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _Message, _AlliedOnly, _SenderPlayerID )
		SW.PreciseLog.Log( "Received by ".._SenderPlayerID.." ".._Message, "Chat")
		if string.find(_Message, Sync2.KeyPrep, 1, true) then
			Sync2.OnPrepMessageArrived( _Message, _SenderPlayerID)
			return
		elseif string.find(_Message, Sync2.KeyAck, 1, true) then
			Sync2.OnAckMessageArrived( _Message, _SenderPlayerID)
			return
		end
		Sync2.MPGame_ApplicationCallback_ReceivedChatMessage(_Message, _AlliedOnly, _SenderPlayerID);
	end

	Sync2.GameCallback_GUI_ChatStringInputDone = GameCallback_GUI_ChatStringInputDone;
	GameCallback_GUI_ChatStringInputDone = function(_Message, _WidgetID) 
		if string.find(_Message, "Sync" , 1, true) then
			return;
		end
		Sync2.GameCallback_GUI_ChatStringInputDone(_Message,_WidgetID)
	end
	
end
function Sync2.NewTributeFor(_pId)
	local tributeData = {
		text = "",
		cost = {},
		pId = 8,
		Callback = function()			--TO BE OVERRIDEN ONCE FUNCTION IS READY TO CALL
		end				
	}
	local tributeId = AddTribute(tributeData)
	Sync2.Tributes[tributeId] = tributeData
	Sync2.Tributes[tributeId].Player = _pId
	Sync2.Tributes[tributeId].Used = false 
	Sync2.Tributes[tributeId].myId = tributeId
end
function Sync2.OnPrepMessageArrived( _msg, _pId)
	local start, finish = string.find( _msg, "%d+")	--Search for number in stuff
	local tributeId = tonumber(string.sub( _msg, start, finish))	--Get me this number!
	local fs = string.sub( _msg, finish+2)		--function string, doing things
	Sync2.Tributes[tributeId].fs = fs
	Sync2.Tributes[tributeId].Callback = function()
		SW.PreciseLog.Log("Calling "..fs)
		Sync2.ExecuteFunctionByString(fs, _pId)
		Sync2.NewTributeFor(Sync2.Tributes[tributeId].Player)
		Sync2.ClearEntry(tributeId)
	end
	Sync2.Send(Sync2.KeyAck..";"..tributeId)
end
function Sync2.OnAckMessageArrived( _msg, _pId)
	local start, finish = string.find( _msg, "%d+")	--Search for number in stuff
	local tributeId = tonumber(string.sub( _msg, start, finish))	--Get me this number!
	-- Is tributeId for this player?
	if GUI.GetPlayerID() == Sync2.Tributes[tributeId].Player then
		Sync2.Tributes[tributeId].AckData[_pId] = true
	else
		return
	end
	for i = 1, SW.MaxPlayers do
		if not Sync2.Tributes[tributeId].AckData[i] then
			return
		end
	end
	-- All players have acknowledged? GO
	GUI.PayTribute(8, tributeId)
end
function Sync2.GetUnusedId( _pId)
	for k,v in pairs(Sync2.Tributes) do
		if (not v.Used) and (v.Player == _pId) then
			return k
		end
	end
	return "FUCKYOU"
end
function Sync2.ClearEntry( _tId)
	Sync2.Tributes[_tId] = nil
end

function Sync2.Complete(_player, _index, _ackPlayer)
	Sync2.Tributes[_player][_index].Completion = Sync2.Tributes[_player][_index].Completion or {};
	table.insert(Sync2.Tributes[_player][_index].Completion, _ackPlayer);
	for i = 1, table.getn(SW.Players) do
		if not table.contains(Sync2.Tributes[_player][_index].Completion, SW.Players[i]) then
			-- not all players have acknowledged yet
			return;
		end
	end
	-- all players acknowledged
	GUI.PayTribute(8, Sync2.Tributes[GUI.GetPlayerID()][_index].Id);
end

function Sync2.Call( _func, ...)
	local player = GUI.GetPlayerID()
	local id = Sync2.GetUnusedId(player)
	if id == "FUCKYOU" then
		Message("NO ID FOR THIS SYNC FOUND")
		return
	end
	--"KeyPrep";tributeId;functionstring
	Sync2.Tributes[id].Used = true
	--Prepare AckData
	Sync2.Tributes[id].AckData = {}
	for i = 1, SW.MaxPlayers do
		Sync2.Tributes[id].AckData[i] = ((XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) ~= 1) or GUI.GetPlayerID() == i or (XNetwork.GameInformation_IsHumanPlayerThatLeftAttachedToPlayerID(i) == 1))
	end
	local fs = Sync2.ConvertFunctionToString( _func, unpack(arg))
	Sync2.Tributes[id].fs = fs
	Sync2.Tributes[id].Callback = function()
		SW.PreciseLog.Log("Calling "..fs)
		Sync2.ExecuteFunctionByString(fs)
		Sync2.NewTributeFor(Sync2.Tributes[id].Player)
		Sync2.ClearEntry(id)
	end
	Sync2.Send(Sync2.KeyPrep..";"..id..";"..fs)
end

function table.contains(_table, _value)
	for k,v in pairs(_table) do
		if v == _value then
			return true;
		end
	end
	return false;
end

function Sync2.GenerateTribute(_pId)		--Generates a ready to use tribute for player
	local tributeId = 0
	tributeId = AddTribute()
end
Sync2.String = {};
Sync2.String.Separators = {
	string.char(2),  -- replaces "("
	string.char(3),  -- replaces ")"
	string.char(4),  -- replaces "<"
	string.char(21), -- replaces ">"
	string.char(22), -- replaces ","
};

function Sync2.ConvertFunctionToString(_funcName, ...)
	local sx = Sync2.String.Separators;
	local str = _funcName;
	for i = 1, table.getn(arg) do
		if type(arg[i]) == "table" then
			str = str .. sx[1] .. type(arg[i]) .. sx[5] .. Sync2.ConvertTableToString(arg[i]) .. sx[2];
		else
			str = str .. sx[1] .. type(arg[i]) .. sx[5] .. tostring(arg[i]) .. sx[2];
		end
	end
	return str;
end

function Sync2.ExecuteFunctionByString(_str, _sender)
	local sx = Sync2.String.Separators;
	local layers = {};
	local parameters = {};
	local separator;
	local pType;
	local pValue;
	local layer, layerEnd;
	while(string.find( _str, ".", 1, true) ~= nil ) do
		separator = string.find( _str, ".", 1, true);
		if string.find( _str, sx[1], 1, true) ~= nil then
			if separator > string.find( _str, sx[1], 1, true) then
				-- we may have fullstops in our paramters too.
				break;
			end
		end
		table.insert(layers, string.sub( _str, 1, separator-1));
		_str = string.sub(_str, separator+1);
	end
	separator = string.find( _str, sx[1], 1, true) or (string.len(_str)+1);
	table.insert(layers, string.sub( _str, 1, separator-1));
	_str = string.sub(_str, separator);

	while( string.find( _str, sx[1], 1, true) ~= nil ) do
		separator = string.find( _str, sx[1], 1, true);
		_str = string.sub( _str, separator + 1);
		separator = string.find( _str, sx[5], 1, true);
		pType = string.sub( _str, 1, separator - 1 );
		_str = string.sub( _str, separator + 1 );
		
		if pType == "table" then
			layer = string.find( _str, sx[3], 1, true);
			layerEnd = string.find( _str, sx[3], layer+1, true);
			layer = string.sub(_str, layer+1, layerEnd-1);
			separator = string.find( _str, sx[4] .. layer .. sx[4], 1, true);
			pValue = string.sub( _str, 1, separator);
			pValue = Sync2.ConvertStringToTable(pValue)
			_str = string.sub(_str, separator + string.len(sx[4] .. layer .. sx[4]));
		else
			separator = string.find( _str, sx[2], 1, true);
			pValue = string.sub( _str, 1, separator-1);
			if pType == "number" then
				pValue = tonumber(pValue);
			elseif pType == "boolean" then
				if pValue == "true" then
					pValue = true;
				else
					pValue = false;
				end
			elseif pType == "nil" then
				pValue = nil;
			end
		end
		table.insert( parameters, pValue );
	end
	table.insert( parameters, _sender)
	local ref = _G[layers[1]];
	for i = 2, table.getn(layers) do
		ref = ref[layers[i]];
	end
	if not Sync2.UseWhitelist then
		ref(unpack(parameters));
	elseif Sync2.Whitelist[ref] then
		ref(unpack(parameters));
	else
		local f = "";
		for i = 1, table.getn(layers) do
			f = f .. " " .. tostring(layers[i]);
		end
		local s = "";
		for i = 1, table.getn(parameters) do
			s = s .. "(" .. parameters[i] .. ") ";
		end
		SW.Logging.AddSync2Log("Unauthorized Sync2 call: " .. f .. " with params " .. s);
	end
end

function Sync2.ConvertTableToString(_t, _layer)
	local sx = Sync2.String.Separators;
	_layer = _layer or 1;
	local str = sx[3] .. _layer .. sx[3];
	for k,v in pairs(_t) do
		str = str .. sx[1] .. type(k) .. sx[5] .. tostring(k) .. sx[5] .. type(v) .. sx[5];
		if type(v) == "table" then
			str = str .. Sync2.ConvertTableToString(v, _layer + 1);
		else
			str = str .. tostring(v);
		end
		str = str .. sx[2];
	end
	return str .. sx[4] .. _layer .. sx[4];
end

function Sync2.ConvertStringToTable(_str)
	-- ( key type, key, value type, value )
	local sx = Sync2.String.Separators;
	local t = {};
	local p = {};
	local layer;
	local layerEnd;
	local separator;
	while( string.find( _str , sx[1], 1, true) ~= nil ) do
		separator = string.find( _str , sx[1], 1, true);
		_str = string.sub(_str, separator+1 );
		for i = 1,3 do
			separator = string.find( _str , sx[5], 1, true);
			p[i] = string.sub( _str, 1, separator - 1);
			_str = string.sub( _str, separator + 1);
		end
		if p[3] == "table" then
			layer = string.find( _str, sx[3], 1, true);
			layerEnd = string.find( _str, sx[3], layer+1, true);
			layer = string.sub(_str, layer+1, layerEnd-1);
			separator = string.find( _str, sx[4] .. layer .. sx[4], 1, true);
			p[4] = string.sub( _str, 1, separator);
			_str = string.sub( _str, separator + 1);
			p[4] = Sync2.ConvertStringToTable( p[4] );
		else
			p[4] = string.sub( _str, 1, string.find( _str, sx[2], 1, true) - 1 );
			if p[3] == "number" then
				p[4] = tonumber(p[4]);
			elseif p[3] == "boolean" then
				if p[4] == "false" then
					p[4] = false;
				else
					p[4] = true;
				end
			end
		end
		if p[1] == "number" then
			p[2] = tonumber(p[2]);
		end
		t[p[2]] = p[4];
	end
	return t;
end

function Sync2.Send( _str )
	SW.PreciseLog.Log("Sending ".._str, "Chat")
	if SW.IsMultiplayer() then
		XNetwork.Chat_SendMessageToAll( _str );
	else
		MPGame_ApplicationCallback_ReceivedChatMessage( _str, 0, GUI.GetPlayerID() );
	end
end

Sync = Sync2