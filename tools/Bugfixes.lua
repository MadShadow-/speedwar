-- Bug fixes

-- Fix sell building bug & overclocking/blessing bug


SW = SW or {}

SW.Bugfixes = {}
SW.Bugfixes.BlessingCooldown = 90	--Cooldown for 90 seconds
SW.Bugfixes.ListOfSoldBuildings = {}
SW.Bugfixes.BlessingData = {}
function SW.Bugfixes.Init()
	SW.Bugfixes.SellBuilding = GUI.SellBuilding
	GUI.SellBuilding = function( _eId)
		if SW.Bugfixes.ListOfSoldBuildings[_eId] == nil then
			SW.Bugfixes.ListOfSoldBuildings[_eId] = Logic.GetTime()
			SW.Bugfixes.SellBuilding( _eId)
		elseif  SW.Bugfixes.ListOfSoldBuildings[_eId] + 60 < Logic.GetTime() then
			SW.Bugfixes.ListOfSoldBuildings[_eId] = Logic.GetTime()
			SW.Bugfixes.SellBuilding( _eId)
		else
			Message("Dieses Gebäude wird schon abgerissen!")
		end
	end
	for i = 1, 8 do
		SW.Bugfixes.BlessingData[i] = {}
	end
	SW.Bugfixes.GUIAction_BlessSettlers = GUIAction_BlessSettlers
	GUIAction_BlessSettlers = function( _blessCategory)
		local player = GUI.GetPlayerID()
		local currFaith = Logic.GetPlayersGlobalResource( player, ResourceType.Faith )	
		local costs = Logic.GetBlessCostByBlessCategory( _blessCategory)
		if currFaith < costs then
			SW.Bugfixes.GUIAction_BlessSettlers(_blessCategory)
			return
		end
		if SW.Bugfixes.BlessingData[player][_blessCategory] == nil then		--first blessing? ok.
			SW.Bugfixes.GUIAction_BlessSettlers(_blessCategory)
			SW.Bugfixes.BlessingData[player][_blessCategory] = Logic.GetTime()
			return
		end
		local timee = Logic.GetTime()
		if SW.Bugfixes.BlessingData[player][_blessCategory] + SW.Bugfixes.BlessingCooldown > timee then
			Message("Wartet noch @color:255,0,0 "..math.ceil(SW.Bugfixes.BlessingData[player][_blessCategory] + SW.Bugfixes.BlessingCooldown - timee).." @color:255,255,255 Sekunden!")
			return
		end
		SW.Bugfixes.GUIAction_BlessSettlers(_blessCategory)
		SW.Bugfixes.BlessingData[player][_blessCategory] = timee
	end
end