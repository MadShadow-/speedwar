--RessCheck

--Tool to check player ressources are syncedd

--Receive message:
--MPGame_ApplicationCallback_ReceivedChatMessage
--Send message:
--XNetwork.Chat_SendMessageToAll

SW = SW or {}
SW.RessCheck = {}
SW.RessCheck.Initiated = false
SW.RessCheck.LastWave = 0
function SW.RessCheck.Start()		--Starts the check process, do call while pause for best experience
	if not SW.RessCheck.Initiated then
		SW.RessCheck.Init()
	end
	for i = 1, 8 do
		XNetwork.Chat_SendMessageToAll("RS"..i.." "..SW.RessCheck.GenerateStringForPlayer( i))
	end
end
function SW.RessCheck.StartSecondaryWave(_sender)
	for i = 1, 8 do
		if _sender ~= i then
			XNetwork.Chat_SendMessageToAllied("RS"..i.." "..SW.RessCheck.GenerateStringForPlayer( i))
		end
	end
end
function SW.RessCheck.Init()
	SW.RessCheck.Initiated = true
	SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _teamChat, _sender)
		if string.find(_msg, "RS") == 1 then
			SW.RessCheck.ReceivedMsg(_msg,_sender, _teamChat)
		elseif string.find(_msg, ":") == 2 then
			if LuaDebugger.Log then
				LuaDebugger.Log(_msg)
			end
			SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessage(_msg, _teamChat, _sender)
		else
			SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessage(_msg, _teamChat, _sender)
		end
	end
end
function SW.RessCheck.ReceivedMsg( _msg, _sender, _teamChat)
	local player = string.byte(_msg,3)-48
	if player > 8 or player < 1 then   -- i call bullshit
		return
	end
	local myMsg = "RS"..player.." "..SW.RessCheck.GenerateStringForPlayer( player)
	if myMsg ~= _msg then
		XNetwork.Chat_SendMessageToAll(GUI.GetPlayerID()..": ".._sender.." und ich haben verschiedene Ress fuer "..player)
		XNetwork.Chat_SendMessageToAll(GUI.GetPlayerID()..": "..myMsg)
		XNetwork.Chat_SendMessageToAll(_sender..": ".._msg)
	end
	if _teamChat == 0 and Logic.GetTime() > SW.RessCheck.LastWave + 30 and _sender ~= GUI.GetPlayerID() then
		SW.RessCheck.LastWave = Logic.GetTime()
		SW.RessCheck.StartSecondaryWave(_sender)
	end
end
function SW.RessCheck.GenerateStringForPlayer( _pId)
	local s = ""
	for k,v in pairs(ResourceType) do
		s = s.." "..k..Logic.GetPlayersGlobalResource( _pId, v )
	end
	return s
end

-- Allow easier check sums
-- _pId == 0 => no Predicate.OfPlayer in checksum		|| _pId ~= 0 => use only this player for checkSum
-- _eType == 0 => all entityTypes
-- if _eType is table: consider entityTypesIds with _eType[1] <= TypeID <= _eType[2]
-- _considerHealth == true => use currentHealth of entity for calculation
-- _considerPos == true => use position in checksum
function SW.RessCheck.GenerateCheckSum( _pId, _eType, _considerHealth, _considerPos)
	if type(_eType) == "table" then
		sum = 0
		for i = _eType[1],_eType[2] do
			if Logic.GetEntityTypeName(i) ~= nil then
				sum = SW.RessCheck.CheckSumAddNumber( sum, SW.RessCheck.GenerateCheckSum( _pId, i, _considerHealth, _considerPos))
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
		sum = SW.RessCheck.CheckSumAddNumber( sum, eId)
		sum = SW.RessCheck.CheckSumAddNumber( sum, Logic.GetEntityType(eId))
		if _considerHealth then
			sum = SW.RessCheck.CheckSumAddNumber( sum, Logic.GetEntityHealth(eId))
		end
		if _considerPos then
			local pos = GetPosition(eId)
			sum = SW.RessCheck.CheckSumAddNumber( sum, pos.X)
			sum = SW.RessCheck.CheckSumAddNumber( sum, pos.Y)
		end
	end
	return sum
end
function SW.RessCheck.CheckSumAddNumber( _sum, _number)
	_sum = math.floor(math.abs(_sum))+1
	_number = math.floor(math.abs(_number))+1
	return math.mod(_sum*SW.RessCheck.GetGCD(_sum,_number)+_number, 2017)+1			--use GCD to destroy associativity/commutativity, Mod to limit size of number
end
function SW.RessCheck.GetGCD( _a, _b)
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
	return SW.RessCheck.GetGCD( _b, math.mod( _a, _b))
end
function SW.RessCheck.GenerateFunctionCheckSum(_f)
	local str = "";
	xpcall(function() str = string.dump( _f) end, function(_s) end)
	local checkSum = 0
	for i = 1, string.len(str) do
		checkSum = math.mod(checkSum + i*i*string.byte( str, i), 2017)
	end
	return checkSum
end
function SW.RessCheck.GenerateStringCheckSum( _s)
	local checkSum = 0
	for i = 1, string.len(_s) do
		checkSum = math.mod(checkSum + i*i*string.byte( _s, i), 2017)
	end
	return checkSum
end
function SW.RessCheck.GetTableCheckSum( _t)
	local checkSum = 0
	for k,v in pairs(_t) do
		if type(v) == "table" then
			checkSum = SW.RessCheck.CheckSumAddNumber( checkSum, SW.RessCheck.GetTableCheckSum(v))
		elseif type(v) == "function" then
			checkSum = SW.RessCheck.CheckSumAddNumber( checkSum, SW.RessCheck.GenerateFunctionCheckSum(v))
		elseif type(v) == "boolean" then
			if v then
				checkSum = SW.RessCheck.CheckSumAddNumber( checkSum, 1001)
			end
		elseif type(v) == "number" then
			checkSum = SW.RessCheck.CheckSumAddNumber( checkSum, math.abs(math.floor(math.mod(v,2017))))
		elseif type(v) == "string" then
			checkSum = SW.RessCheck.CheckSumAddNumber( checkSum, SW.RessCheck.GenerateStringCheckSum(v))
		end
	end
	return checkSum
end
SW.RessCheck.VersionKey = "VSKeyDONOTUSE"
function SW.RessCheck.StartVersionCheck()
	local t1 = XGUIEng.GetSystemTime()
	local myVersion = SW.RessCheck.GetTableCheckSum(SW) + SW.RessCheck.GetTableCheckSum(Sync)
	SW.TimeForCheckSum = XGUIEng.GetSystemTime()-t1
	SW.Version = myVersion
	--LuaDebugger.Log("Version: "..myVersion)
	SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessageVersion = MPGame_ApplicationCallback_ReceivedChatMessage
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _teamChat, _sender)
		--LuaDebugger.Log(_msg)
		local _, endd = string.find( _msg, SW.RessCheck.VersionKey)
		--LuaDebugger.Log(endd)
		if endd then
			SW.RessCheck.ReceivedVersionMsg( string.sub( _msg, endd+1), _sender, _teamChat)
		else
			SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessageVersion(_msg, _teamChat, _sender)
		end
	end
	-- resend version if player joins
	if CNetwork == nil then return end
	SW.RessCheck.IngamePlayerList = {}
	for k,v in pairs(GetIngamePlayers()) do
		SW.RessCheck.IngamePlayerList[v] = true
	end
	SW_RessCheck_WatchIngamePlayers = function()
		local newPlayer = false
		for k,v in pairs(GetIngamePlayers()) do
			if SW.RessCheck.IngamePlayerList[v] == false then
				newPlayer = true
			end
		end
		if newPlayer then
			SW.RessCheck.SendMsg(SW.RessCheck.VersionKey..SW.Version)
		end
		SW.RessCheck.IngamePlayerList = {}
		for k,v in pairs(GetIngamePlayers()) do
			SW.RessCheck.IngamePlayerList[v] = true
		end
	end
	StartSimpleJob("SW_RessCheck_WatchIngamePlayers")
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
function SW.RessCheck.ReceivedVersionMsg( _msg, _sender, _teamChat)
	--LuaDebugger.Log( _msg)
	-- Pattern finding:
	--		%d is digit
	--		%d+ is number
	local start, finish = string.find(_msg, "%d+")
	local num = tonumber(string.sub(_msg,start, finish))
	LuaDebugger.Log("got version by ".._sender..": "..num)
	if num ~= SW.Version then
		Message("VersionChecker: "..UserTool_GetPlayerName(_sender).." has another version!")
		--XNetwork.Chat_SendMessageToAll("VersionChecker: Different versions for "..UserTool_GetPlayerName(_sender).." and "..UserTool_GetPlayerName(GUI.GetPlayerID()))
	end
	if SW.RessCheck.VersionMsgArrived then
		SW.RessCheck.VersionMsgArrived[_sender] = true
	end
	--LuaDebugger.Log("SUCCESS")
end
function SW.RessCheck.SendMsg(_s)
	if SW.IsMultiplayer() then
		XNetwork.Chat_SendMessageToAll(_s)
	end
end
function SW.RessCheck.ShoutVersion()
	--SW.RessCheck.SendMsg("VS"..SW.Version)
	LuaDebugger.Log("Shouting version "..SW.Version)
	if not SW.IsMultiplayer() then return end
	SW.RessCheck.InitHeartBeatStuff()
	StartSimpleJob("SW_RessCheckWaitForHeartBeat")
end
function SW.RessCheck.InitHeartBeatStuff()
	SW.RessCheck.VersionMsgArrived = {}
	for i = 1, 8 do
		SW.RessCheck.VersionMsgArrived[i] = ((XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) ~= 1) or GUI.GetPlayerID() == i)
	end
	SW.RessCheck.VersionCooldown = 5
	SW.RessCheck.HeartBeatCountDown = 15
end
function SW_RessCheckWaitForHeartBeat()
	SW.RessCheck.VersionCooldown = SW.RessCheck.VersionCooldown - 1
	if SW.RessCheck.VersionCooldown == 0 then
		SW.RessCheck.SendMsg(SW.RessCheck.VersionKey..SW.Version)
	end
	SW.RessCheck.HeartBeatCountDown = SW.RessCheck.HeartBeatCountDown - 1
	if SW.RessCheck.HeartBeatCountDown < 0 then
		for i = 1, 8 do
			if not SW.RessCheck.VersionMsgArrived[i] then
				Message( "VersionChecker: Player "..UserTool_GetPlayerName(i).." has no heartbeat!")
			end
		end
		return true
	end
end