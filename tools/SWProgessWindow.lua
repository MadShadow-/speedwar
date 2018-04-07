SW = SW or {};
SW.ProgressWindow = {};
SW.ProgressWindow.IsShown = false;
SW.ProgressWindow.EntitiesLeftDisplayMax = 30;
SW.ProgressWindow.EntitiesLeftColor = "@color:255,140,0";

function SW.ProgressWindow.Init()

	SW.ProgressWindow.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged;
	GameCallback_GUI_SelectionChanged = function()
		local sel = GUI.GetSelectedEntity();
		if Logic.GetEntityType(sel) == Entities.PB_Outpost1 and Logic.IsConstructionComplete(sel) == 1 then
			XGUIEng.ShowWidget("SWBottomOverlayOutpost", 1);
			if SW.ProgressWindow.IsShown then
				SW.ProgressWindow.Show();
			end
		else
			if XGUIEng.IsWidgetShown("SWBottomOverlayOutpost") == 1 then
				XGUIEng.ShowWidget("SWBottomOverlayOutpost", 0);
			end
			if XGUIEng.IsWidgetShown("SWGameProgress") == 1 then
				SW.ProgressWindow.Hide();
			end
		end
		SW.ProgressWindow.GameCallback_GUI_SelectionChanged();
	end
	
	SW.ProgressWindow.PlayerNames = {};
	local r,g,b;
	for playerId = 1,8 do
		r,g,b = GUI.GetPlayerColor(playerId);
		SW.ProgressWindow.PlayerNames[playerId] = "@color:"..r..","..g..","..b.. " " ..UserTool_GetPlayerName(playerId);
	end
	
	-- initial GUI update
	SW.ProgressWindow.RankUpGUIUpdate();
	SW_ProgressWindow_UpdateScore();
end

function SW.ProgressWindow.Show()
	XGUIEng.ShowWidget("SWGameProgress", 1);
	SW.ProgressWindow.UpdateScoreJobId = StartSimpleHiResJob("SW_ProgressWindow_UpdateScore");
	-- receive win condition update
	SW.WinCondition.ForcePointUpdate();
end

function SW.ProgressWindow.Hide()
	XGUIEng.ShowWidget("SWGameProgress", 0);
	EndJob(SW.ProgressWindow.UpdateScoreJobId);
end

function SW.ProgressWindow.RankUpGUIUpdate()
	--[[
	TODO: Maybe remove this from rank up updates
	local curRank = SW.RankSystem.Rank[GUI.GetPlayerID()];
	for i = 1, 4 do
		if i == curRank then
			XGUIEng.SetText("SWGPRank"..i,
			SW.RankSystem.RankColors[i] .. " @center *..* " .. SW.BuildingTooltips.RankNames[i] .. " *..* ");
		else
			XGUIEng.SetText("SWGPRank"..i,
			"@color:150,150,150 @center " .. SW.BuildingTooltips.RankNames[i]);
		end
	end]]
end

function SW_ProgressWindow_UpdateScore()
	local curRank = SW.RankSystem.Rank[GUI.GetPlayerID()];
	local curPoints = SW.RankSystem.Points[GUI.GetPlayerID()];
	local threshold;
	if curRank <= 3 then
		threshold = SW.RankSystem.RankThresholds[curRank];
	else
		threshold = SW.RankSystem.RankThresholds[3];
		curPoints = threshold;
	end
	
	local curRank = SW.RankSystem.Rank[GUI.GetPlayerID()];
	local percentage = math.floor((curPoints / threshold) * 100);
	
	XGUIEng.SetText("SWGPRank", "Rang: " .. SW.RankSystem.RankColors[curRank] .. " " .. SW.BuildingTooltips.RankNames[curRank] ..
		" @color:255,255,255 "..curPoints.."/"..threshold.." ("..percentage.."%)");
		
	local playerOverview = "Punkte # "..SW.ProgressWindow.EntitiesLeftColor.." Anzahl Entities @color:255,255,255,255 # Name @cr ";
	local t = {};
	-- t contains for each player a table
	-- { pId, WinConditionPoints}
	table.foreach(SW.Players, 
	function(k, playerId)
		table.insert(t, {playerId, SW.WinCondition.GetPlayerPoints(playerId)});
	end);
	t = SW.ProgressWindow.SortPlayers(t);
	local entitiesleft;
	for i = 1, table.getn(t) do
		entitiesleft = SW.DefeatConditionPlayerEntities[t[i][1]];
		if entitiesleft > SW.ProgressWindow.EntitiesLeftDisplayMax then
			entitiesleft = SW.ProgressWindow.EntitiesLeftDisplayMax.."+";
		end
		playerOverview = playerOverview.." "..t[i][2].." "
		playerOverview = playerOverview..SW.ProgressWindow.EntitiesLeftColor.." "..entitiesleft.." "
		--playerOverview = playerOverview .. t[i][2] .. " " .. SW.ProgressWindow.PlayerNames[t[i][1]] .. " @color:255,255,255 : "
		--..SW.ProgressWindow.GetRankName(t[i][1])..SW.ProgressWindow.EntitiesLeftColor.." "..entitiesleft.." @cr @color:255,255,255 ";
		playerOverview = playerOverview..SW.RankSystem.RankColors[SW.RankSystem.Rank[t[i][1]]].." "..UserTool_GetPlayerName(t[i][1])
		.." @color:255,255,255 @cr "
	end
	XGUIEng.SetText("SWGPPlayerOverview", playerOverview);
		
	
	XGUIEng.SetText("SWGPLKavMoney", "@center Taler erbeutet: " .. tostring(SW.LKavBuff.Looted[GUI.GetPlayerID()]));
	if Counter.Tick2("SW_ProgressWindow_UpdateScore", 100) then
		-- every 10 seconds we update
		SW.WinCondition.ForcePointUpdate();
	end
end
function SW.ProgressWindow.GetPointString( _score, _n)
	local scoreString = "".._score
	while string.len(scoreString) < _n do
		scoreString = scoreString.." "
	end
	return scoreString
end
function SW.ProgressWindow.GetRankName( _pId)
	local rId = SW.RankSystem.Rank[_pId]
	return SW.RankSystem.RankColors[rId].." "..SW.BuildingTooltips.RankNames[rId].." @color:255,255,255 "
end

function SW.ProgressWindow.GUIAction_ShowProgressWindow()
	if XGUIEng.IsWidgetShown("SWGameProgress") == 1 then
		SW.ProgressWindow.Hide()
		SW.ProgressWindow.IsShown = false;
	else
		SW.ProgressWindow.Show()
		SW.ProgressWindow.IsShown = true;
	end
end

function SW.ProgressWindow.GUIUpdate_Tooltip()
	local tooltipDescr = "@color:152,251,152 Spielfortschritt @cr @color:220,220,220 Zeigt euch euren aktuellen Rang und die Anzahl der benötigten Punkte" ..
					   " bis zum nächsten Rangaufstieg an.";
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "");
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, tooltipDescr);
end

function SW.ProgressWindow.SortPlayers(_table)
	local tmp;
	for i = 1, table.getn(_table)-1 do
		if _table[i][2] < _table[i+1][2] then
			tmp = _table[i+1];
			_table[i+1] = _table[i];
			_table[i] = tmp;
			i = 1;
		end
	end
	return _table;
end
