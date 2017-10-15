--RessCheck

--Tool to check player ressources are synced

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


--[[
Log: "2: 1 und ich haben verschiedene Ress fuer 1"
Log: "2: RS1  Wood0 SilverRaw0 Iron0 Knowledge0 GoldRaw0 Gold0 ClayRaw700 SulfurRaw0 WoodRaw500 Faith0 Stone0 StoneRaw0 Clay0 IronRaw0 Silver0 Sulfur0 WeatherEnergy0"
Log: "1: RS1  Wood0 SilverRaw0 Iron0 Knowledge0 GoldRaw0 Gold50 ClayRaw700 SulfurRaw0 WoodRaw500 Faith0 Stone0 StoneRaw0 Clay0 IronRaw0 Silver0 Sulfur0 WeatherEnergy0"
Log: "1: 2 und ich haben verschiedene Ress fuer 1"
Log: "1: RS1  Wood0 SilverRaw0 Iron0 Knowledge0 GoldRaw0 Gold50 ClayRaw700 SulfurRaw0 WoodRaw500 Faith0 Stone0 StoneRaw0 Clay0 IronRaw0 Silver0 Sulfur0 WeatherEnergy0"
Log: "2: RS1  Wood0 SilverRaw0 Iron0 Knowledge0 GoldRaw0 Gold0 ClayRaw700 SulfurRaw0 WoodRaw500 Faith0 Stone0 StoneRaw0 Clay0 IronRaw0 Silver0 Sulfur0 WeatherEnergy0"

]]