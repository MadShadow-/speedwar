--RessCheck

--Tool to check player ressources are synced

--Receive message:
--MPGame_ApplicationCallback_ReceivedChatMessage
--Send message:
--XNetwork.Chat_SendMessageToAll

SW = SW or {}
SW.RessCheck = {}
SW.RessCheck.Initiated = false
function SW.RessCheck.Start()		--Starts the check process, do call while pause for best experience
	if not SW.RessCheck.Initiated then
		SW.RessCheck.Init()
	end
	for i = 1, 8 do
		XNetwork.Chat_SendMessageToAll("RS"..i.." "..SW.RessCheck.GenerateStringForPlayer( i))
	end
end
function SW.RessCheck.Init()
	SW.RessCheck.Initiated = true
	SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _teamChat, _sender)
		if string.find(_msg, "RS") == 1 then
			SW.RessCheck.ReceivedMsg(_msg,_sender)
		else
			SW.RessCheck.MPGame_ApplicationCallback_ReceivedChatMessage(_msg, _teamChat, _sender)
		end
	end
end
function SW.RessCheck.ReceivedMsg( _msg, _sender)
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
end
function SW.RessCheck.GenerateStringForPlayer( _pId)
	local s = ""
	for k,v in pairs(ResourceType) do
		s = s.." "..k..Logic.GetPlayersGlobalResource( _pId, v )
	end
	return s
end