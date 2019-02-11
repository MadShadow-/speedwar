SW = SW or {}
-- PROBLEM:
-- SPIEL PAUSIERT -> SIMPLE JOB WIRD NICHT AUSGEFÜHRT
-- EINKLINKEN IN IRGENDWAS, WAS PRO FRAME GECALLT WIRD, SEHR SINNVOLL
SW.Reconnecter = {}
SW.Reconnecter.Stages = {
	[1] = function() XNetworkUbiCom.Manager_Destroy() end,
	[2] = function() XNetworkUbiCom.Manager_Create() end,
	[3] = function() XNetworkUbiCom.Manager_LogIn_Connect() end,
	[4] = function() XNetworkUbiCom.Manager_LogIn_Start() end,
	[5] = function() XNetworkUbiCom.Lobby_Group_Enter(NETWORK_GAME_LOBBY) end,
	[6] = function() XNetwork.Chat_SendMessageToAll(".join") end,
	[7] = function() CNetwork.set_ready() end,
	[8] = function() CNetwork.send_need_ticks(Network_GetLastTickReceived() + 2000) end
}
SW.Reconnecter.StageNames = {
	[1] = "Alte Verbindung wird gekappt.",
	[2] = "Bereite Siedler vor.",
	[3] = "Verbinde zu ubi.com.",
	[4] = "Starte LogIn-Prozess.",
	[5] = "Trete Raum bei.",
	[6] = "Trete Spiel bei.",
	[7] = "Spielstand wird vorbereitet.",
	[8] = "Fordere neue Ticks an."
}
SW.Reconnecter.CurrentStage = 0
--[[
XNetworkUbiCom.Manager_Destroy();

XNetworkUbiCom.Manager_Create()
XNetworkUbiCom.Manager_LogIn_Connect()
XNetworkUbiCom.Manager_LogIn_Start()
XNetworkUbiCom.Lobby_Group_Enter(NETWORK_GAME_LOBBY)
XNetwork.Chat_SendMessageToAll(".join");
CNetwork.set_ready();
CNetwork.send_need_ticks(Network_GetLastTickReceived() + 2000);
]]
function SW.Reconnecter.Init()
	if CNetwork == nil then return end
	SW.Reconnecter.GameCallback_GUI_ChatStringInputDone = GameCallback_GUI_ChatStringInputDone
	GameCallback_GUI_ChatStringInputDone = function(_msg, _wId)
		if _msg == ".reconnect" then
			SW.Reconnecter.StartReconnectProcess()
		else
			SW.Reconnecter.GameCallback_GUI_ChatStringInputDone(_msg, _wId)
		end
	end
end
function SW.Reconnecter.StartReconnectProcess()
	if SW.Reconnecter.Running then Message("Reconnecter is already running!") return end
	SW.Reconnecter.Running = true
	SW.Reconnecter.CurrentStage = 0
	StartSimpleJob("SW_Reconnecter_Job")
end
function SW_Reconnecter_Job()
	if Counter.Tick2("ReconnectorJob", 5) then
		SW.Reconnecter.CurrentStage = SW.Reconnecter.CurrentStage + 1
		if SW.Reconnecter.Stages[SW.Reconnecter.CurrentStage] ~= nil then
			Message("Stage "..SW.Reconnecter.CurrentStage..": "..SW.Reconnecter.StageNames[SW.Reconnecter.CurrentStage])
			SW.Reconnecter.Stages[SW.Reconnecter.CurrentStage]()
		else
			SW.Reconnecter.Running = false
			Message("Reconnect abgeschlossen.")
			return true
		end
	end
end