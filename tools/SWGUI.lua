--[[
	
	Enthält die GUI für das StartMenü, andere Teile der GUI.xml werden in SWWallGUI oder ProgressWindow angesprochen
	
]]

SW.GUI = {

	StartGameCounter = 5,
	GameStarted = false,
	
	Teamspawn = 0,
	Teamrank = 0,
	Suddendeath = 90,
	
	Text = {
		[0] = "Nein",
		[1] = "Ja",
	},
	
	ShowHostOnly = false,
	ShowHostOnlyCounter = 0,
	
	ButtonCallbacks = {
		--["Suddendeath"] = function()
		--	SW.GUI.SuddendeathCTI:Open();
		--end,
		["Teamspawn"] = function()
			SW.GUI.Teamspawn = 1 - SW.GUI.Teamspawn
			XGUIEng.SetText("SWSMC1E2Button", "@center "..SW.GUI.Text[SW.GUI.Teamspawn])
		end,
		["Anonym"] = function()
			SW.GUI.Teamrank = 1 - SW.GUI.Teamrank
			XGUIEng.SetText("SWSMC1E3Button", "@center "..SW.GUI.Text[SW.GUI.Teamrank])
		end,
		["TimePlus"] = function()
			SW.GUI.Suddendeath = SW.GUI.Suddendeath + 5
			XGUIEng.SetText("SWSMC1E1Button", "@center "..SW.GUI.Suddendeath)
		end,
		["TimeMinus"] = function()
			SW.GUI.Suddendeath = math.max(SW.GUI.Suddendeath - 5, 5)
			XGUIEng.SetText("SWSMC1E1Button", "@center "..SW.GUI.Suddendeath)
		end
	},
	
	ButtonTooltips = {
		["Suddendeath"] = "Gibt die Anzahl an Spielminuten an, nach denen der Sieger ermittelt wird. "
						  .. "Sieger ist das Team, welches nach Ablauf der Zeit das größte Gebiet hält.",
						  
		["Teamspawn"]   = "Ermöglicht es Spielern aus dem gleichen Team an einem Ort auf der Karte zusammen zu starten.",
		["Anonym"]      = "Jeder Fortschritt zum nächsten Rang wird unter allen Teammitgliedern aufgeteilt.",
		["Startgame"]   = "@color:255,125,0 Startet das Spiel mit den aktuell eingestellten Regeln.",
	},
	
};

function SW.GUI.Init()
	S5Hook.LoadGUI("maps\\user\\speedwar\\swgui.xml")
	--XGUIEng.ShowWidget("SWStartMenu", 1)
	XGUIEng.ShowWidget("SWSBCArrow", 0)
	XGUIEng.ShowWidget("SWShowButtonContainer", 1)
	-- Teamspawn
	XGUIEng.SetText("SWSMC1E2Button", "@center "..SW.GUI.Text[SW.GUI.Teamspawn])
	XGUIEng.SetText("SWSMC1E3Button", "@center "..SW.GUI.Text[SW.GUI.Teamrank])
	XGUIEng.SetText("SWSMC1E1Button", "@center "..SW.GUI.Suddendeath)
	if CNetwork then
		for k,v in pairs(SW.GUI.ButtonCallbacks) do
			CNetwork.SetNetworkHandler( "SW.GUI.ButtonCallbacks."..k, v)
		end
		CNetwork.SetNetworkHandler( "SW.GUI.StartGameCNetwork", SW.GUI.StartGameCNetwork)
	else
		Sync.AddCall("SW.GUI.ButtonCallbacks.Teamspawn")
		Sync.AddCall("SW.GUI.ButtonCallbacks.Anonym")
		Sync.AddCall("SW.GUI.ButtonCallbacks.TimePlus")
		Sync.AddCall("SW.GUI.ButtonCallbacks.TimeMinus")
		Sync.AddCall("SW.GUI.StartGame")
	end
	if not SW.IsHost then
		SW.GUI.ButtonTooltips.Startgame = "@color:255,125,0 Schließt dieses Fenster."
	end
	--[[ old by Mad
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
	]]
end
function SW.GUI.Button(_name)
	if _name == "OpenStartMenu" then
		SW.GUI.ToggleStartMenu()
		return
	end
	if not SW.IsHost then
		if _name == "Startgame" then
			XGUIEng.ShowWidget("SWStartMenu", 0)
			XGUIEng.ShowWidget("SWSBCArrow", 1)
			XGUIEng.ShowWidget("SWShowButtonContainer", 1)
		else
			SW.GUI.StartShowHostOnly();
		end
		return;
	end
	if _name == "Startgame" then
		if CNetwork then
			CNetwork.send_command("SW.GUI.StartGameCNetwork", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Teamrank)
		else
			Sync.Call("SW.GUI.StartGame", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Teamrank)
		end
		-- protect host from himself
		XGUIEng.ShowWidget("SWStartMenu", 0)
		XGUIEng.ShowWidget("SWShowButtonContainer", 0)
	end
	if SW.GUI.ButtonCallbacks[_name] then
		if CNetwork then
			CNetwork.send_command("SW.GUI.ButtonCallbacks.".._name)
		else
			Sync.Call("SW.GUI.ButtonCallbacks.".._name)
		end
	end
end
function SW.GUI.StartGameCNetwork( _sender, _time, _sharedSpawn, _sharedRank)
	if SW.GUI.GameStarted then
		return;
	end
	if _sender ~= CNetwork.GameInformation_GetHost() then
		Message(_sender.." wollte das Spiel starten!")
		return
	end
	SW.GUI.GameStarted = true
	XGUIEng.ShowWidget("SWStartMenu", 0)
	XGUIEng.ShowWidget("SWShowButtonContainer", 0)
	Message("Starting speedwar with parameters")
	Message("Time: ".._time)
	Message("Shared Spawn: ".._sharedSpawn)
	Message("Shared Rank: ".._sharedRank)
	SW.GUI.Rules = {}
	SW.GUI.Rules.Time = _time
	SW.GUI.Rules.SharedSpawn = _sharedSpawn
	SW.GUI.Rules.SharedRank = _sharedRank
	-- actual game start
	-- reinstall colors
	for _,v in pairs(SW.Players) do
		Display.SetPlayerColorMapping( v, XNetwork.GameInformation_GetLogicPlayerColor(v))
	end
	-- fix statistic names
	
	SW.Activate(CXNetwork.GameInformation_GetRandomseed())
end
function SW.GUI.StartGame( _time, _sharedSpawn, _sharedRank)
	if SW.GUI.GameStarted then
		return;
	end
	SW.GUI.GameStarted = true
	XGUIEng.ShowWidget("SWStartMenu", 0)
	XGUIEng.ShowWidget("SWShowButtonContainer", 0)
	Message("Starting speedwar with parameters")
	Message("Time: ".._time)
	Message("Shared Spawn: ".._sharedSpawn)
	Message("Shared Rank: ".._sharedRank)
	SW.GUI.Rules = {}
	SW.GUI.Rules.Time = _time
	SW.GUI.Rules.SharedSpawn = _sharedSpawn
	SW.GUI.Rules.SharedRank = _sharedRank
	-- actual game start
	SpeedwarStarter = function()
		if Counter.Tick2("test",2) then
			if SW.IsHost then
				Sync.Call( "SW.Activate", math.floor(XGUIEng.GetSystemTime()*1000))
			end
			return true
		end
	end
	StartSimpleJob("SpeedwarStarter")
end
-- discourage non hosts from clicking stuff with annyoing sounds
function SW.GUI.StartShowHostOnly()
	Sound.PlayGUISound( Sounds.VoicesMentor_COMMENT_BadPlay_rnd_01, 0)
end
function SW.GUI.UpdateStartMenuTooltip(_name)
	if SW.GUI.ShowHostOnly then
		XGUIEng.SetText("SWSMTText", SW.GUI.ButtonTooltips["HostOnly"]);
		return;
	end
	XGUIEng.SetText("SWSMTText", SW.GUI.ButtonTooltips[_name] or "Tooltip for "..tostring(_name).." undefined");
end
-- more like toggle start menu
function SW.GUI.OpenStartMenu()
	if XGUIEng.IsWidgetShown("SWStartMenu") == 1 then
		XGUIEng.ShowWidget( "SWStartMenu", 0)
	else
		XGUIEng.ShowWidget( "SWStartMenu", 1)
		XGUIEng.ShowWidget("SWSMCArrow", 0)
		XGUIEng.SetText("SWSMC1E2Button", "@center "..SW.GUI.Text[SW.GUI.Teamspawn])
		XGUIEng.SetText("SWSMC1E3Button", "@center "..SW.GUI.Text[SW.GUI.Teamrank])
		XGUIEng.SetText("SWSMC1E1Button", "@center "..SW.GUI.Suddendeath)
	end
end



-- OLD STUFF

-- show stuff and tutorial arrows

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