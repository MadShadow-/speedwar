--VersionCheck

--Tool to check player ressources are syncedd

--Receive message:
--MPGame_ApplicationCallback_ReceivedChatMessage
--Send message:
--XNetwork.Chat_SendMessageToAll

SW = SW or {}
SW.VersionCheck = {}
-- Allow easier check sums
-- _pId == 0 => no Predicate.OfPlayer in checksum		|| _pId ~= 0 => use only this player for checkSum
-- _eType == 0 => all entityTypes
-- if _eType is table: consider entityTypesIds with _eType[1] <= TypeID <= _eType[2]
-- _considerHealth == true => use currentHealth of entity for calculation
-- _considerPos == true => use position in checksum
function SW.VersionCheck.GenerateCheckSum( _pId, _eType, _considerHealth, _considerPos)
	if type(_eType) == "table" then
		sum = 0
		for i = _eType[1],_eType[2] do
			if Logic.GetEntityTypeName(i) ~= nil then
				sum = SW.VersionCheck.CheckSumAddNumber( sum, SW.VersionCheck.GenerateCheckSum( _pId, i, _considerHealth, _considerPos))
			end
		end
		return sum
	end
	local preds = {}
	if _pId ~= 0 then
		table.insert(preds, Predicate.OfPlayer(_pId))
	end
	if _eType ~= 0 then
		table.insert(preds, Predicate.OfType(_eType))
	end
	local sum = 0
	for eId in S5Hook.EntityIterator(unpack(preds)) do
		sum = SW.VersionCheck.CheckSumAddNumber( sum, eId)
		sum = SW.VersionCheck.CheckSumAddNumber( sum, Logic.GetEntityType(eId))
		if _considerHealth then
			sum = SW.VersionCheck.CheckSumAddNumber( sum, Logic.GetEntityHealth(eId))
		end
		if _considerPos then
			local pos = GetPosition(eId)
			sum = SW.VersionCheck.CheckSumAddNumber( sum, pos.X)
			sum = SW.VersionCheck.CheckSumAddNumber( sum, pos.Y)
		end
	end
	return sum
end
function SW.VersionCheck.CheckSumAddNumber( _sum, _number)
	_sum = math.floor(math.abs(_sum))+1
	_number = math.floor(math.abs(_number))+1
	return math.mod(_sum*SW.VersionCheck.GetGCD(_sum,_number)+_number, 2017)+1			--use GCD to destroy associativity/commutativity, Mod to limit size of number
end
function SW.VersionCheck.GetGCD( _a, _b)
	if _a < _b then			--guarantee _a >= _b 
		local temp = _a
		_a = _b
		_b = temp
	end
	if _b == 1 then
		return 1
	end
	if _b == 0 then
		return _a
	end
	return SW.VersionCheck.GetGCD( _b, math.mod( _a, _b))
end
function SW.VersionCheck.GenerateFunctionCheckSum(_f)
	local str = "";
	xpcall(function() str = string.dump( _f) end, function(_s) end)
	local checkSum = 0
	for i = 1, string.len(str) do
		checkSum = math.mod(checkSum + i*i*string.byte( str, i), 2017)
	end
	return checkSum
end
function SW.VersionCheck.GenerateStringCheckSum( _s)
	local checkSum = 0
	for i = 1, string.len(_s) do
		checkSum = math.mod(checkSum + i*i*string.byte( _s, i), 2017)
	end
	return checkSum
end
function SW.VersionCheck.GetTableCheckSum( _t)
	local checkSum = 0
	for k,v in pairs(_t) do
		if type(v) == "table" then
			checkSum = SW.VersionCheck.CheckSumAddNumber( checkSum, SW.VersionCheck.GetTableCheckSum(v))
		elseif type(v) == "function" then
			checkSum = SW.VersionCheck.CheckSumAddNumber( checkSum, SW.VersionCheck.GenerateFunctionCheckSum(v))
		elseif type(v) == "boolean" then
			if v then
				checkSum = SW.VersionCheck.CheckSumAddNumber( checkSum, 1001)
			end
		elseif type(v) == "number" then
			checkSum = SW.VersionCheck.CheckSumAddNumber( checkSum, math.abs(math.floor(math.mod(v,2017))))
		elseif type(v) == "string" then
			checkSum = SW.VersionCheck.CheckSumAddNumber( checkSum, SW.VersionCheck.GenerateStringCheckSum(v))
		end
	end
	return checkSum
end

SW.VersionCheck.VersionKey = "VSKeyDONOTUSE"
-- called on game start
function SW.VersionCheck.CalculateVersion()
	local t1 = XGUIEng.GetSystemTime()
	local myVersion = SW.VersionCheck.GetTableCheckSum(SW) + SW.VersionCheck.GetTableCheckSum(Sync)
	SW.TimeForCheckSum = XGUIEng.GetSystemTime()-t1
	SW.Version = myVersion
	if SW.VersionCheck.Initiated == nil then
		SW.VersionCheck.Init()
	end
end
-- gets called once per client
function SW.VersionCheck.Init()
	SW.VersionCheck.Initiated = true
	if CNetwork == nil then
		SW.VersionCheck.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage
		MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _teamChat, _sender)
			--LuaDebugger.Log(_msg)
			--LuaDebugger.Log(_sender)
			local _, endd = string.find( _msg, SW.VersionCheck.VersionKey)
			if endd then
				SW.VersionCheck.OnReceivedMsg( string.sub( _msg, endd+1), _sender, UserTool_GetPlayerName(_sender))
			else
				SW.VersionCheck.MPGame_ApplicationCallback_ReceivedChatMessage(_msg, _teamChat, _sender)
			end
		end
	else
		SW.VersionCheck.ApplicationCallback_ReceivedChatMessageRaw = ApplicationCallback_ReceivedChatMessageRaw
		ApplicationCallback_ReceivedChatMessageRaw = function( _name, _msg, color, allied, _sender)
			local _, endd = string.find( _msg, SW.VersionCheck.VersionKey)
			if endd then
				SW.VersionCheck.OnReceivedMsg( string.sub( _msg, endd+1), _sender, _name)
				return true
			else
				return SW.VersionCheck.ApplicationCallback_ReceivedChatMessageRaw( _name, _msg, color, allied, _sender)
			end
		end
		-- CNetwork exists? So we have to watch out for people joining later on?
		SW.VersionCheck.StartWatchingPlayers()
	end
end
function SW.VersionCheck.OnReceivedMsg( _msg, _senderId, _name)
	--LuaDebugger.Log("Got msg ".._msg)
	local start, endd = string.find( _msg, "%d+")
	if start == nil then return end
	local version = tonumber(string.sub( _msg, start, endd))
	--LuaDebugger.Log("Extracted version "..version)
	if version ~= SW.Version then
		Message(_name.." has another version: "..version)
	end
	if SW.VersionCheck.HeartbeatTable then
		SW.VersionCheck.HeartbeatTable[_senderId] = true
	end
end
function SW.VersionCheck.SendMsg(_s)
	if SW.IsMultiplayer() then
		XNetwork.Chat_SendMessageToAll(_s)
	end
end
function SW.VersionCheck.ShoutVersion()
	SW.VersionCheck.SendMsg(SW.VersionCheck.VersionKey..SW.Version)
	--LuaDebugger.Log("Shouting version "..SW.Version)
end
function SW.VersionCheck.StartHeartbeatCheck()
	if GUI.GetPlayerID() == 17 then return end -- no check for spectators!
	SW.VersionCheck.HeartbeatTable = {}
	for k,v in pairs(SW.Players) do
		SW.VersionCheck.HeartbeatTable[v] = false
	end
	SW.VersionCheck.HeartbeatWait = XGUIEng.GetSystemTime()
	StartSimpleJob("SW_VersionCheck_HeartbeatJob")
end
function SW_VersionCheck_HeartbeatJob()
	if XGUIEng.GetSystemTime() - 15 > SW.VersionCheck.HeartbeatWait then
		for k,v in pairs(SW.VersionCheck.HeartbeatTable) do
			if v == false then
				Message(UserTool_GetPlayerName(k).." has no heartbeat!")
			end
		end
		return true
	end
end
function SW.VersionCheck.StartWatchingPlayers()
	SW.VersionCheck.RebuildPlayerTable( GetIngamePlayers(), GetSpectators())
	StartSimpleJob("SW_VersionCheck_WatchPlayerJob")
end
function SW.VersionCheck.RebuildPlayerTable( _ing, _specs)
	SW.VersionCheck.PresentPlayers = {}
	for k,v in pairs(_ing) do
		SW.VersionCheck.PresentPlayers[v] = true
	end
	for k,v in pairs(_specs) do
		SW.VersionCheck.PresentPlayers[v] = true
	end
end
function SW_VersionCheck_WatchPlayerJob()
	local ingame = GetIngamePlayers()
	local specs = GetSpectators()
	local newPlayer = false
	for k,v in pairs(ingame) do
		if SW.VersionCheck.PresentPlayers[v] == nil then
			newPlayer = true
			break
		end
	end
	for k,v in pairs(specs) do
		if SW.VersionCheck.PresentPlayers[v] == nil then
			newPlayer = true
			break
		end
	end
	if newPlayer then
		Counter.Tick2("SW_VersionCheck_DelayedShoutJob",5)
		Counter.Reset("SW_VersionCheck_DelayedShoutJob")
		StartSimpleJob("SW_VersionCheck_DelayedShoutJob")
	end
	SW.VersionCheck.RebuildPlayerTable( ingame, specs)
end
function SW_VersionCheck_DelayedShoutJob()
	if Counter.Tick2("SW_VersionCheck_DelayedShoutJob",5) then
		SW.VersionCheck.ShoutVersion()
		return true
	end
end


function SW.VersionCheck.StartVersionCheck()
	-- resend version if player joins
	if CNetwork == nil then return end
	SW.VersionCheck.IngamePlayerList = {}
	for k,v in pairs(GetIngamePlayers()) do
		SW.VersionCheck.IngamePlayerList[v] = true
	end
	SW_VersionCheck_WatchIngamePlayers = function()
		local newPlayer = false
		for k,v in pairs(GetIngamePlayers()) do
			if SW.VersionCheck.IngamePlayerList[v] == false then
				newPlayer = true
			end
		end
		if newPlayer then
			SW.VersionCheck.SendMsg(SW.VersionCheck.VersionKey..SW.Version)
		end
		SW.VersionCheck.IngamePlayerList = {}
		for k,v in pairs(GetIngamePlayers()) do
			SW.VersionCheck.IngamePlayerList[v] = true
		end
	end
	StartSimpleJob("SW_VersionCheck_WatchIngamePlayers")
	--[[
	
    local spectators = GetSpectators();
    local activePlayers = GetIngamePlayers();
    local t2 = {};
    
    for i = 1,table.getn(activePlayers) do
        local name = activePlayers[i];
        t2[name] = true;
    end;
    
    for name, v in pairs(t2) do
        if not CGameState.activePlayers[name] then
            Message("Player '" .. name .. "' joined.");
            CGameState.activePlayers[name] = true;
        end;
    end;
	]]
end