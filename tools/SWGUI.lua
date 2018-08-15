--[[
	
	Enthält die GUI für das StartMenü, andere Teile der GUI.xml werden in SWWallGUI oder ProgressWindow angesprochen
	
]]

SW.GUI = {

	StartGameCounter = 5,
	GameStarted = false,
	
	Teamspawn = 0,
	Anonym = 0,
	Suddendeath = 90,
	
	Text = {
		[0] = "Nein",
		[1] = "Ja",
	},
	
	ShowHostOnly = false,
	ShowHostOnlyCounter = 0,
	
	ButtonCallbacks = {
		["Suddendeath"] = function()
			SW.GUI.SuddendeathCTI:Open();
		end,
		["Teamspawn"] = function()
			Sync.CallNoSync("SW.GUI.ToggleTeamSpawn");
		end,
		["Anonym"] = function()
			Sync.CallNoSync("SW.GUI.ToggleAnonym");
		end,
		["Startgame"] = function()
			Sync.Call("SW.GUI.StartGame");
			Sync.CallNoSync("SW.GUI.SetFinal", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Anonym, XGUIEng.GetSystemTime());
		end,
		["OpenStartMenu"] = function()
			SW.GUI.OpenStartMenu();
		end,
	},
	
	ButtonTooltips = {
		["Suddendeath"] = "Gibt die Anzahl an Spielminuten an, nach denen der Sieger ermittelt wird. "
						  .. "Sieger ist der Spieler mit dem größten besetzten Gebiet. Danach können die Spieler abstimmen, ob Sie weiterspielen möchten. @cr @cr Drücke auf den Button und du kannst die Minuten eingeben.",
						  
		["Teamspawn"]   = "Ermöglicht es Spielern aus dem gleichen Team an einem Ort auf der Karte zusammen zu starten.",
		["Anonym"]      = "Alle Feinde werden in der gleichen Farbe dargestellt. Dadurch wisst ihr nichtmehr direkt, mit wem ihr euch bekriegt.",
		["Startgame"]   = "@color:255,125,0 Startet das Spiel mit den aktuell eingestellten Regeln",
	},
	
};

function SW.GUI.Init()
	S5Hook.LoadGUI("maps\\user\\speedwar\\swgui.xml");
	SW.GUI.SuddendeathCTI = CTI.New({Widget="SWSMC1E1Button", Before = "@center ", Callback=SW.GUI.SuddendeathChanged, NumbersOnly=true, MaxLength=3});
	XGUIEng.SetText("SWSMC1E2Button", "@center " .. SW.GUI.Text[SW.GUI.Teamspawn]);
	XGUIEng.SetText("SWSMC1E3Button", "@center " .. SW.GUI.Text[SW.GUI.Anonym]);
	SW.GUI.ButtonTooltips["HostOnly"] = "@color:255,0,0 Nur der Host kann das Menü bedienen. Host ist " .. UserTool_GetPlayerName(SW.Host);
	
	if CNetwork then --is this on simi server?
		SW.IsHost = (CNetwork.GameInformation_GetHost()==XNetwork.GameInformation_GetLogicPlayerUserName( GUI.GetPlayerID()))
	else
		Sync.AddCall("SW.GUI.StartGame");
		Sync.AddCall("SW.GUI.ToggleTeamSpawn");
		Sync.AddCall("SW.GUI.ToggleAnonym");
		Sync.AddCall("SW.GUI.SetFinal");
	end
	SW.GUI.RemoveArrowCounter = 3;
	StartSimpleJob("SW_GUI_RemoveArrowCounterJob");
end
-- show stuff and tutorial arrows
function SW.GUI.OpenStartMenu()
	if XGUIEng.IsWidgetShown("SWStartMenu") == 1 then
		XGUIEng.ShowWidget("SWStartMenu",0);
	else
		XGUIEng.ShowWidget("SWStartMenu",1);
	end
	if not SW.GUI.OpenedStartMenu then
		XGUIEng.ShowWidget("SWSBCArrow",0);
		SW.GUI.OpenedStartMenu = true;
		SW.GUI.RemoveArrowCounter2 = 2;
		StartSimpleJob("SW_GUI_RemoveArrowCounterJob2");
	end
end

function SW_GUI_RemoveArrowCounterJob()
	SW.GUI.RemoveArrowCounter = SW.GUI.RemoveArrowCounter - 1;
	if SW.GUI.RemoveArrowCounter == 2 then
		XGUIEng.ShowWidget("SWShowButtonContainer", 1);
	end
	if SW.GUI.RemoveArrowCounter <= 0 then
		XGUIEng.ShowWidget("SWSBCArrow",0);
		return true;
	end
end

function SW_GUI_RemoveArrowCounterJob2()
	SW.GUI.RemoveArrowCounter2 = SW.GUI.RemoveArrowCounter2 - 1;
	if SW.GUI.RemoveArrowCounter2 <= 0 then
		XGUIEng.ShowWidget("SWSMCArrow",0);
		return true;
	end
end



function SW.GUI.Button(_name)
	if not SW.IsHost then
		SW.GUI.StartShowHostOnly();
		return;
	end
	if SW.GUI.ButtonCallbacks[_name] then
		if CNetwork then
			if _name == "OpenStartMenu" or _name == "Suddendeath" then --local changes stay local.
				SW.GUI.ButtonCallbacks[_name]()
			else
				CNetwork.send_command("SW_GUI_OnButtonPressedCNetwork", _name)
			end
			return
		else
			SW.GUI.ButtonCallbacks[_name]();
			return;
		end
	end
	log("Button "..tostring(_name).." has no function defined.");
end

function SW_GUI_OnButtonPressedCNetwork( _senderName, _buttonName)
	-- wrong caller? Do nothing
	if _senderName ~= CNetwork.GameInformation_GetHost() then return end
	-- correct caller may change rules
	if _buttonName == "Teamspawn" then
		SW.GUI.ToggleTeamSpawn()
	elseif _buttonName == "Anonym" then
		Message("AnonFeature not implemented.")
	elseif _buttonName == "Startgame" then
		if SW.IsHost then
			CNetwork.send_command("SW_GUI_StartGameCNetwork", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Anonym)
		end
	end
end

function SW.GUI.UpdateStartMenuTooltip(_name)
	if SW.GUI.ShowHostOnly then
		XGUIEng.SetText("SWSMTText", SW.GUI.ButtonTooltips["HostOnly"]);
		return;
	end
	XGUIEng.SetText("SWSMTText", SW.GUI.ButtonTooltips[_name] or "Tooltip for "..tostring(_name).." undefined");
end

function SW.GUI.StartShowHostOnly()
	ShowHostOnly = true;
	ShowHostOnlyCounter = 3;
	StartSimpleJob("SW_GUI_HostOnlyDecay");
end

function SW_GUI_HostOnlyDecay()
	ShowHostOnlyCounter = ShowHostOnlyCounter - 1;
	if ShowHostOnlyCounter <= 0 then
		ShowHostOnly = false;
		return true;
	end
end

function SW.GUI.ToggleTeamSpawn()
	SW.GUI.Teamspawn = 1 - SW.GUI.Teamspawn;
	XGUIEng.SetText("SWSMC1E2Button", "@center " .. SW.GUI.Text[SW.GUI.Teamspawn]);
end

function SW.GUI.ToggleAnonym()
	SW.GUI.Anonym = 1 - SW.GUI.Anonym;
	XGUIEng.SetText("SWSMC1E3Button", "@center " .. SW.GUI.Text[SW.GUI.Anonym]);
end

function SW.GUI.SuddendeathChanged(_text)
	SW.GUI.Suddendeath = tonumber(_text);
end

function SW.GUI.StartGame()
	if SW.GUI.GameStarted then
		return;
	end
	SW.GUI.GameStarted = true;
	XGUIEng.ShowWidget("SWCounter", 1);
	XGUIEng.ShowWidget("SWStartMenu", 0);
	XGUIEng.ShowWidget("SWShowButtonContainer", 0);
	StartSimpleJob("SW_GUI_StartGameCounterJob");
end

function SW_GUI_StartGameCounterJob()
	SW.GUI.StartGameCounter = SW.GUI.StartGameCounter - 1;
	XGUIEng.SetText("SWCounter", "@center " .. SW.GUI.StartGameCounter);
	if SW.GUI.StartGameCounter <= 0 then
		if CNetwork then
			SW.Activate(CXNetwork.GameInformation_GetRandomseed())
		else
			SW.Activate();
			if SW.GUI.Anonym == 1 then
				SW.GUI.AnonymizePlayers();
			end
			XGUIEng.ShowWidget("SWCounter", 0);
			return true;
		end
	end
end

function SW.GUI.SetFinal(_suddendeath, _teamspawn, _anonym, _seed)
	SW.GUI.Suddendeath = _suddendeath;
	SW.GUI.Teamspawn = _teamspawn;
	SW.GUI.Anonym = _anonym;
	math.randomseed(_seed);
	SW.WinCondition.Time = SW.GUI.Suddendeath * 60;
end

function SW.GUI.AnonymizePlayers()
	Message("TODO: anonymize players");
end

function SW_GUI_StartGameCNetwork( _senderName, _suddendeathMin, _teamSpawn, _anon)
	if _senderName ~= CNetwork.GameInformation_GetHost() then return end
	SW.GUI.Suddendeath = _suddendeathMin;
	SW.GUI.Teamspawn = _teamSpawn;
	SW.GUI.Anonym = _anon;
	SW.WinCondition.Time = SW.GUI.Suddendeath * 60;
	SW.GUI.StartGame()
end