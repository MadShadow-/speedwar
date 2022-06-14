--[[
	
	Enthält die GUI für das StartMenü, andere Teile der GUI.xml werden in SWWallGUI oder ProgressWindow angesprochen
	
]]

SW.GUI = {

	StartGameCounter = 5,
	GameStarted = false,
	
	Teamspawn = 0,
	Teamrank = 1,
	Suddendeath = 90,
	MaxHQ = 0,
	
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
		end,
		["HQPlus"] = function()
			SW.GUI.MaxHQ = SW.GUI.MaxHQ + 1
			XGUIEng.SetText("SWSMC1E4Button", "@center "..SW.GUI.MaxHQ)
		end,
		["HQMinus"] = function()
			SW.GUI.MaxHQ = math.max(SW.GUI.MaxHQ - 1, 0)
			if SW.GUI.MaxHQ == 0 then
				XGUIEng.SetText("SWSMC1E4Button", "@center Inf")
			else
				XGUIEng.SetText("SWSMC1E4Button", "@center "..SW.GUI.MaxHQ)
			end
		end
	},
	
	ButtonTooltips = {
		["Suddendeath"] = "Gibt die Anzahl an Spielminuten an, nach denen der Sieger ermittelt wird. "
			.. "Sieger ist das Team, welches nach Ablauf der Zeit das größte Gebiet hält.",			  
		["Teamspawn"]   = "Ermöglicht es Spielern aus dem gleichen Team an einem Ort auf der Karte zusammen zu starten. Teamspawn hat keinen Effekt, "
			.."wenn die Karte fixe Startpositionen hat.",
		["Anonym"]      = "Jeder Fortschritt zum nächsten Rang wird unter allen Teammitgliedern aufgeteilt.",
		["Startgame"]   = "@color:255,125,0 Startet das Spiel mit den aktuell eingestellten Regeln.",
		["MaxHQ"]		= "Gibt an, wie die Außenpostenkosten anwachsen. Inf = Kosten wachsen unendlich, alles andere cappt die Kosten ab dem 8. Außenposten."
	},
	
};

function SW.GUI.Init()
	S5Hook.LoadGUI("maps\\user\\speedwar\\swgui.xml")
	--XGUIEng.ShowWidget("SWStartMenu", 1)
	XGUIEng.ShowWidget("SWSBCArrow", 0)
	XGUIEng.ShowWidget("SWShowButtonContainer", 1)
	
	-- Apply default rules if possible
	if SpeedwarConfig ~= nil then
		if SpeedwarConfig.InitialRules ~= nil then
			SW.GUI.Teamspawn = SpeedwarConfig.InitialRules.Teamspawn
			SW.GUI.Teamrank = SpeedwarConfig.InitialRules.Teamrank
			SW.GUI.Suddendeath = SpeedwarConfig.InitialRules.Suddendeath
			SW.GUI.MaxHQ = SpeedwarConfig.InitialRules.MaxHQ
		end
	end	
	
	-- Show GUI by default
	--SW.GUI.OpenStartMenu()
	-- Hide start menu for some time
	if SW.IsHost then
		XGUIEng.ShowWidget( "SWStartMenu", 0)
		XGUIEng.ShowWidget("SWShowButtonContainer", 0)
		StartSimpleJob("SW_GUI_OpenMenuForHost")
	end
	-- Teamspawn
	XGUIEng.SetText("SWSMC1E2Button", "@center "..SW.GUI.Text[SW.GUI.Teamspawn])
	XGUIEng.SetText("SWSMC1E3Button", "@center "..SW.GUI.Text[SW.GUI.Teamrank])
	XGUIEng.SetText("SWSMC1E1Button", "@center "..SW.GUI.Suddendeath)
	
	-- Check if mapper decided to disable some rule selections
	if SpeedwarConfig ~= nil then
		if SpeedwarConfig.FixedRules ~= nil then
			local rTable = SpeedwarConfig.FixedRules
			if rTable.ChangeTime then
				SW.GUI.ButtonCallbacks.TimePlus = nil
				SW.GUI.ButtonCallbacks.TimeMinus = nil
			end
			if rTable.ChangeHQLimit then
				SW.GUI.ButtonCallbacks.HQPlus = nil
				SW.GUI.ButtonCallbacks.HQMinus = nil
			end
			if rTable.TeamSpawn then
				SW.GUI.ButtonCallbacks.Teamspawn = nil
			end
			if rTable.TeamRank then
				SW.GUI.ButtonCallbacks.Anonym = nil
			end
		end
	end
	
	
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
		Sync.AddCall("SW.GUI.ButtonCallbacks.HQPlus")
		Sync.AddCall("SW.GUI.ButtonCallbacks.HQMinus")
		Sync.AddCall("SW.GUI.StartGame")
	end
	if not SW.IsHost then
		SW.GUI.ButtonTooltips.Startgame = "@color:255,125,0 Schließt dieses Fenster."
	end
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
			CNetwork.SendCommand("SW.GUI.StartGameCNetwork", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Teamrank, SW.GUI.MaxHQ)
		else
			Sync.Call("SW.GUI.StartGame", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Teamrank, SW.GUI.MaxHQ)
		end
		-- protect host from himself
		XGUIEng.ShowWidget("SWStartMenu", 0)
		XGUIEng.ShowWidget("SWShowButtonContainer", 0)
	end
	if SW.GUI.ButtonCallbacks[_name] then
		if CNetwork then
			CNetwork.SendCommand("SW.GUI.ButtonCallbacks.".._name)
		else
			Sync.Call("SW.GUI.ButtonCallbacks.".._name)
		end
	end
end
function SW.GUI.StartGameCNetwork( _sender, _time, _sharedSpawn, _sharedRank, _maxHQ)
	if SW.GUI.GameStarted then
		return;
	end
	if _sender ~= XNetwork.EXTENDED_GameInformation_GetHost() then
		Message(_sender.." wollte das Spiel starten!")
		return
	end
	SW.GUI.GameStarted = true
	XGUIEng.ShowWidget("SWStartMenu", 0)
	XGUIEng.ShowWidget("SWShowButtonContainer", 0)
	Message("Starting speedwar with parameters")
	Message("Sudden Death: ".._time)
	Message("Shared Spawn: ".._sharedSpawn)
	Message("Shared Rank: ".._sharedRank)
	if _maxHQ == 0 then
		Message("Outpost cost: capped")
		SW.FLAG_USE_FIXED_OUTPOST_COSTS = true
	else
		Message("Outpost cost: uncapped")
		SW.FLAG_USE_FIXED_OUTPOST_COSTS = false
	end
	SW.GUI.Rules = {}
	SW.GUI.Rules.Time = _time
	SW.GUI.Rules.SharedSpawn = _sharedSpawn
	SW.GUI.Rules.SharedRank = _sharedRank
	SW.GUI.Rules.MaxHQ = _maxHQ
	-- actual game start
	-- reinstall colors
	for _,v in pairs(SW.Players) do
		Display.SetPlayerColorMapping( v, XNetwork.GameInformation_GetLogicPlayerColor(v))
		local r,g,b = GUI.GetPlayerColor( v)
		Logic.PlayerSetPlayerColor( v, r, g, b)
	end
	SW.Activate(XNetwork.EXTENDED_GameInformation_GetRandomseed())
end
function SW.GUI.StartGame( _time, _sharedSpawn, _sharedRank, _maxHQ)
	if SW.GUI.GameStarted then
		return;
	end
	SW.GUI.GameStarted = true
	XGUIEng.ShowWidget("SWStartMenu", 0)
	XGUIEng.ShowWidget("SWShowButtonContainer", 0)
	Message("Starting speedwar with parameters")
	Message("Sudden Death: ".._time)
	Message("Shared Spawn: ".._sharedSpawn)
	Message("Shared Rank: ".._sharedRank)
	if _maxHQ == 0 then
		Message("Outpost cost: capped")
		SW.FLAG_USE_FIXED_OUTPOST_COSTS = true
	else
		Message("Outpost cost: uncapped")
		SW.FLAG_USE_FIXED_OUTPOST_COSTS = false
	end
	SW.GUI.Rules = {}
	SW.GUI.Rules.Time = _time
	SW.GUI.Rules.SharedSpawn = _sharedSpawn
	SW.GUI.Rules.SharedRank = _sharedRank
	SW.GUI.Rules.MaxHQ = _maxHQ
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
function SW_GUI_OpenMenuForHost()
	if Counter.Tick2("OpenHostMenu", 3) then
		--XGUIEng.ShowWidget( "SWStartMenu", 1)
		XGUIEng.ShowWidget("SWShowButtonContainer", 1)
		SW.GUI.OpenStartMenu()
		return true
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
	if _senderName ~= XNetwork.EXTENDED_GameInformation_GetHost() then return end
	-- correct caller may change rules
	if _buttonName == "Teamspawn" then
		SW.GUI.ToggleTeamSpawn()
	elseif _buttonName == "Anonym" then
		Message("AnonFeature not implemented.")
	elseif _buttonName == "Startgame" then
		if SW.IsHost then
			CNetwork.SendCommand("SW_GUI_StartGameCNetwork", SW.GUI.Suddendeath, SW.GUI.Teamspawn, SW.GUI.Anonym)
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
			SW.Activate(XNetwork.EXTENDED_GameInformation_GetRandomseed())
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
	if _senderName ~= XNetwork.EXTENDED_GameInformation_GetHost() then return end
	SW.GUI.Suddendeath = _suddendeathMin;
	SW.GUI.Teamspawn = _teamSpawn;
	SW.GUI.Anonym = _anon;
	SW.WinCondition.Time = SW.GUI.Suddendeath * 60;
	SW.GUI.StartGame()
end