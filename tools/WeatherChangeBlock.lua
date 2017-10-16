-- Weather change block

-- After manually altering the weather state, changes in weather state are forbidden for x seconds
SW = SW or {}
SW.WeatherBlock = {}
SW.WeatherBlock.Duration = 30		--Duration of blocking
SW.WeatherBlock.LastChange = (-1)*SW.WeatherBlock.Duration
SW.WeatherBlock.EnergyLevels = {}
SW.WeatherBlock.WidgetIds = { "WeatherTower_MakeRain", "WeatherTower_MakeSnow", "WeatherTower_MakeSummer"}
function SW.WeatherBlock.Init()
	for i = 1, 8 do
		SW.WeatherBlock.EnergyLevels[i] = Logic.GetPlayersGlobalResource( i, ResourceType.WeatherEnergy)
	end
	StartSimpleJob("SW_WeatherBlock_WatchEnergy")
	SW.WeatherBlock.GUIUpdate_ChangeWeatherButtons = GUIUpdate_ChangeWeatherButtons
	GUIUpdate_ChangeWeatherButtons = function( _s, _tech, _index)
		SW.WeatherBlock.GUIUpdate_ChangeWeatherButtons( _s, _tech, _index)
		if Logic.GetTime() < SW.WeatherBlock.LastChange+SW.WeatherBlock.Duration then
			for i = 1, 3 do
				XGUIEng.DisableButton( SW.WeatherBlock.WidgetIds[i], 1)
			end
		end
	end
	SW.WeatherBlock.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()
		SW.WeatherBlock.GameCallback_GUI_SelectionChanged()
		if Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.PB_WeatherTower1 and Logic.GetTime() < SW.WeatherBlock.LastChange+SW.WeatherBlock.Duration then
			Message("Wetterwechsel noch @color:255,0,0 "..math.ceil(SW.WeatherBlock.LastChange+SW.WeatherBlock.Duration - Logic.GetTime()).." @color:255,255,255 Sekunden gesperrt.")
		end
	end
end
function SW_WeatherBlock_WatchEnergy()
	for i = 1, 8 do
		local currEnergy = Logic.GetPlayersGlobalResource( i, ResourceType.WeatherEnergy)
		if currEnergy < SW.WeatherBlock.EnergyLevels[i] then	--weather change happened
			SW.WeatherBlock.OnWeatherChange()
		end
		SW.WeatherBlock.EnergyLevels[i] = currEnergy
	end
end
function SW.WeatherBlock.OnWeatherChange()
	SW.WeatherBlock.LastChange = Logic.GetTime()
	for i = 1, 3 do
		XGUIEng.DisableButton( SW.WeatherBlock.WidgetIds[i], 1)
	end
	if Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.PB_WeatherTower1 then
		Message("Wetterwechsel wird für @color:255,0,0 "..math.ceil(SW.WeatherBlock.LastChange+SW.WeatherBlock.Duration - Logic.GetTime()).." @color:255,255,255 Sekunden gesperrt.")
	end
end

