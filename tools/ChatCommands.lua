SW = SW or {}

SW.ChatCommands = {}
SW.ChatCommands.CommandsSynced = {}
SW.ChatCommands.CallbacksSynced = {}
SW.ChatCommands.Commands = {}		-- for commands that dont need to be synced, receiving those will trigger callback
SW.ChatCommands.Callbacks = {}
function SW.ChatCommands.Init()
	for k,v in pairs(SW.ChatCommands.CallbacksSynced) do
		table.insert( SW.ChatCommands.CommandsSynced, k)
		Sync.Whitelist["SW.ChatCommands.CallbacksSynced."..k] = true
	end
	for k,v in pairs(SW.ChatCommands.Callbacks) do
		table.insert( SW.ChatCommands.Commands, k)
	end
	SW.ChatCommands.GameCallback_GUI_ChatStringInputDone = GameCallback_GUI_ChatStringInputDone
	GameCallback_GUI_ChatStringInputDone = function( _msg, _wId)
		for k,v in pairs(SW.ChatCommands.CommandsSynced) do
			if string.find( _msg, "!"..v) then
				Sync.Call("SW.ChatCommands.CallbacksSynced."..v, GUI.GetPlayerID())
				return
			end
		end
		SW.ChatCommands.GameCallback_GUI_ChatStringInputDone( _msg, _wId)
	end
	SW.ChatCommands.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _msg, _sender, _teamChat)
		for k,v in pairs(SW.ChatCommands.Commands) do
			if string.find( _msg, "!"..v) then
				SW.ChatCommands.Callbacks[v]( GUI.GetPlayerID())
				return
			end
		end
		SW.ChatCommands.MPGame_ApplicationCallback_ReceivedChatMessage( _msg, _sender, _teamChat)
	end
end
function SW.ChatCommands.SendMsg( _s)
	if SW.IsMultiplayer() then
		XNetwork.Chat_SendMessageToAll(_s)
	end
end
function SW.ChatCommands.GetPlayerName(_pId)
	local userName = XNetwork.GameInformation_GetLogicPlayerUserName( _pId)
	local r,g,b = GUI.GetPlayerColor( _pId)
	return " @color:"..r..","..g..","..b.." "..userName.." @color:255,255,255 "
end
function SW.ChatCommands.Callbacks.version( _pId)
	SW.ChatCommands.SendMsg(SW.ChatCommands.GetPlayerName( GUI.GetPlayerID()).."> Check sum: "..SW.Version)
end
function SW.ChatCommands.CallbacksSynced.resume( _pId)
	Message("Spieler"..SW.ChatCommands.GetPlayerName(_pId).."will das Spiel fortsetzen.")
	if not SW.WinCondition.GameOver then
		Message("Das Spiel ist noch nicht vorbei!")
		return
	end
	if SW.ChatCommands.VoteStarted then	--vote already started? fuck this.
		return
	end
	SW.ChatCommands.VoteStarted = true
	SW.ChatCommands.VoteRemaining = 60
	SW.ChatCommands.VoteData = {}
	for k,v in pairs(SW.Players) do
		SW.ChatCommands.VoteData[v] = false
	end
	StartSimpleJob("SW_ChatCommands_resumeVoteJob")
	Message("Schreibe im Chat <!participate<, um weiter mitzuspielen.")
	Message("Schreibe im Chat <!abstain<, um neutral zu bleiben.")
	Message("60 Sekunden ohne Antwort wird als !abstain interpretiert.")
end
function SW_ChatCommands_resumeVoteJob()
	SW.ChatCommands.VoteRemaining = SW.ChatCommands.VoteRemaining - 1
	if SW.ChatCommands.VoteRemaining < 1 then
		Message("Die Abstimmung ist vorbei!")
		SW.ResumeGame()
		for k,v in pairs(SW.Players) do
			if SW.ChatCommands.VoteData[v] == false then
				for _, v2 in pairs(SW.Players) do
					if v2 ~= v then
						Logic.SetDiplomacyState( v, v2, Diplomacy.Neutral)
						Logic.SetShareExplorationWithPlayerFlag( v2, v, 0)
						Logic.SetShareExplorationWithPlayerFlag( v, v2, 0)
					end
				end
				local viewCenter = Logic.CreateEntity(Entities.XD_ScriptEntity, -1, -1, 90, v)
				Logic.SetEntityExplorationRange( viewCenter, 2000) --2000 > 768 * sqrt(2)
			end
		end
		-- make stuff unselectable if abstained
		if SW.ChatCommands.VoteData[GUI.GetPlayerID()] == false then
			GUI.ClearSelection()
			GameCallback_GUI_SelectionChanged = function()
				GUI.ClearSelection()
			end
		end
		return true
	end
end
function SW.ChatCommands.CallbacksSynced.participate( _pId)
	if SW.ChatCommands.VoteStarted then
		SW.ChatCommands.VoteData[_pId] = true
		Message(SW.ChatCommands.GetPlayerName(_pId).."bleibt im Spiel.")
	end
end
function SW.ChatCommands.CallbacksSynced.abstain( _pId)
	if SW.ChatCommands.VoteStarted then
		SW.ChatCommands.VoteData[_pId] = false
		Message(SW.ChatCommands.GetPlayerName(_pId).."will neutral bleiben.")
	end
end


--