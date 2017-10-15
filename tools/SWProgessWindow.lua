SW = SW or {};
SW.ProgressWindow = {};
SW.ProgressWindow.IsShown = false;

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
	-- initial GUI update
	SW.ProgressWindow.RankUpGUIUpdate();
	SW_ProgressWindow_UpdateScore();
end

function SW.ProgressWindow.Show()
	XGUIEng.ShowWidget("SWGameProgress", 1);
	SW.ProgressWindow.UpdateScoreJobId = StartSimpleHiResJob("SW_ProgressWindow_UpdateScore");
end

function SW.ProgressWindow.Hide()
	XGUIEng.ShowWidget("SWGameProgress", 0);
	EndJob("SW.ProgressWindow.UpdateScoreJobId");
end

function SW.ProgressWindow.RankUpGUIUpdate()
	local curRank = SW.RankSystem.Rank[GUI.GetPlayerID()];
	for i = 1, 4 do
		if i == curRank then
			XGUIEng.SetText("SWGPRank"..i,
			SW.RankSystem.RankColors[i] .. " @center *..* " .. SW.BuildingTooltips.RankNames[i] .. " *..* ");
		else
			XGUIEng.SetText("SWGPRank"..i,
			"@color:150,150,150 @center " .. SW.BuildingTooltips.RankNames[i]);
		end
	end
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
	XGUIEng.SetText("SWGPPoints", "@center " ..curPoints.."/"..threshold);
	
	local percentage = math.floor((curPoints / threshold) * 100);
	XGUIEng.SetText("SWGPPercentage", "@center " .. percentage .. "%");
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
