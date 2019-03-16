SW = SW or {};
SW.Reconnect = {
	StartedReconnect = false,
	LastActionTimestamp = 0,
	DelayNextAction = 0,
	CurrentActionIndex = 0,
	Text = " Verbindung verloren ",
	Started = false,
	GameNotOpenAnymore = false,
	Actions =
	{
		[1] = function()
			CUtil.SetGameTimeFactor(1);
			XNetworkUbiCom.Manager_Destroy();
			XNetworkUbiCom.Manager_Create();
			SW.Reconnect.Started = true;
			SW.Reconnect.Text = " Verbinden ";
			XGUIEng.ShowWidget("SWReconnectState",1);
			return 1;
		end,
		
		[2] = XNetworkUbiCom.Manager_LogIn_Connect,
		[3] = XNetworkUbiCom.Manager_LogIn_Start,
		
		[4] = function()
			return XNetworkUbiCom.Lobby_Group_Enter(NETWORK_GAME_LOBBY);
		end,
		
		[5] = function()
			XNetworkUbiCom.Lobby_Group_Enter(NETWORK_GAME_LOBBY);
			--if XNetworkUbiCom.Lobby_Group_GetIndexOfCurrent() == -1 then
				--SW.Reconnect.GameNotOpenAnymore = true;
				--return 1;
			--end
			XNetwork.Chat_SendMessageToAll(".join"); return 1;
		end,
		
		[6] = function()
			CNetwork.set_ready();
			return 1;
		end,
		
		[7] = function()
			CNetwork.send_need_ticks(Network_GetLastTickReceived() + 2000);
			-- reset params
			SW.Reconnect.Started = false;
			SW.Reconnect.CurrentActionIndex = 0;
			-- update GUI
			SW.Reconnect.Text = " @color:0,255,0 Verbunden! ";
			local count = 3;
			SW_Reconnect_Hide = function()
				if count > 0 then count = count - 1; return; end
				XGUIEng.ShowWidget("SWReconnectState",0);
				return true;
			end
			StartSimpleJob("SW_Reconnect_Hide");
			XGUIEng.SetText( "SWReconnectState", SW.Reconnect.Text);
			XNetwork.Manager_Create();
			return 1;
		end,
	},
};

function SW.Reconnect.UpdateEveryFrame()
	if not SW.Reconnect.Started then
		if table.getn(GetIngamePlayers()) > 0 then
			return;
		end
		if table.getn(GetSpectators()) > 0 then
			return;
		end
	end
	if SW.Reconnect.GameNotOpenAnymore then
		XGUIEng.SetText( "SWReconnectState", " @color:255,0,0 Spiel nicht mehr offen! Kann nicht verbinden! ");
		return;
	end
	-- disconnected => reconnect
	local currentTimestamp = math.floor(XGUIEng.GetSystemTime());
	local delay = currentTimestamp - SW.Reconnect.LastActionTimestamp;
	XGUIEng.SetText( "SWReconnectState", "("..SW.Reconnect.CurrentActionIndex.."/7) "..SW.Reconnect.Text.." in "..(SW.Reconnect.DelayNextAction-delay));
	if delay > SW.Reconnect.DelayNextAction then
		-- update timestamp
		SW.Reconnect.LastActionTimestamp = currentTimestamp;
		-- next action
		SW.Reconnect.CurrentActionIndex = SW.Reconnect.CurrentActionIndex + 1;
		-- execute
		local res = SW.Reconnect.Actions[SW.Reconnect.CurrentActionIndex]();
		if res ~= 1 then
			-- action failed
			SW.Reconnect.CurrentActionIndex = 0;
			SW.Reconnect.DelayNextAction = 5;
			SW.Reconnect.Text = " @color:255,0,0 Fehlgeschlagen! ";
			return;
		end
		SW.Reconnect.DelayNextAction = 2;
	end
end