-- Apply given tech tree to the game
-- Alters tooltips
-- Gives building rights once conditions are met, e.g. if a player has all requirements for a stable, he gets B_Stable
-- Can manipulate building requirements, tech requirements, troop upgrade requirements
-- Requirements can include techs and tiers


--Aufbau Tooltip:
--
--"@color:180,180,180,255  Schmiede @cr 
--@color:255,255,255,255 @color:255,204,51,255 @color:255,204,51,255 benÃ¶tigt: @color:255,255,255,255 @color:255,255,255,255 Alchimie @cr
-- 			@color:255,204,51,255 ermÃ¶glicht: @color:255,255,255,255 Veredelung von Eisen, Verbesserungen fÃ¼r Waffen und RÃ¼stungen"

--"@color:180,180,180,255  Lager @cr 
--@color:255,255,255,255 @color:255,204,51,255 @color:255,204,51,255 benÃ¶tigt: @color:255,255,255,255 @color:255,255,255,255 Bildung @cr
-- 			@color:255,204,51,255 ermÃ¶glicht: @color:255,255,255,255 dient als Rohstofflager und spÃ¤ter auch als Handelsplatz"

SW = SW or {}

SW.BuildingTooltips = {}
SW.BuildingTooltips.RankNames = {
	"Möchtegern",
	"Siedler",
	"Feldherr",
	"Eroberer"
}
SW.BuildingTooltips.BData = { --Data for new building tooltips
    [UpgradeCategories.Stable] = {		--Requirements for building stables
		Tier = 2,
		Tech = Technologies.B_Stables	--This technology is granted once conditions are met
	},
	[UpgradeCategories.Blacksmith] = {
		Tier = 2,
		Techs = {Technologies.GT_Alchemy},
		Tech = Technologies.B_Blacksmith
	}
}
SW.BuildingTooltips.TechnologyNamesRaw = {
	--Associate technologies with a text string
	--Use text string and string functions to filter out name of technology
	
}
--[[
--GUITooltip_ConstructBuilding, second and third arg
"MenuSerf/residence_disabled", Technologies.B_Residence
"MenuSerf/farm_disabled", Technologies.B_Farm
"MenuSerf/mine_disabled", Technologies.B_Claymine		
"MenuSerf/village_disabled", Technologies.B_Village
"MenuSerf/blacksmith_disabled", Technologies.B_Blacksmith
"MenuSerf/stonemason_disabled", Technologies.B_StoneMason
"MenuSerf/alchemist_disabled", Technologies.B_Alchemist
"MenuSerf/monastery_disabled", Technologies.B_Monastery
"MenuSerf/university_disabled", Technologies.B_University
"MenuSerf/market_disabled", Technologies.B_Market
"MenuSerf/bank_disabled", Technologies.B_Bank
"MenuSerf/barracks_disabled", Technologies.B_Barracks
"MenuSerf/archery_disabled",Technologies.B_Archery
"MenuSerf/stables_disabled", Technologies.B_Stables
"MenuSerf/foundry_disabled", Technologies.B_Foundry
"MenuSerf/brickworks_disabled", Technologies.B_Brickworks
"MenuSerf/Tower_disabled", Technologies.B_Tower
"MenuSerf/sawmill_disabled", Technologies.B_Sawmill
"MenuSerf/Weathermachine_disabled", Technologies.B_Weathermachine
"MenuSerf/PowerPlant_disabled", Technologies.B_PowerPlant
"AOMenuSerf/tavern_disabled", Technologies.B_Tavern
"AOMenuSerf/gunsmithworkshop_disabled", Technologies.B_GunsmithWorkshop
"AOMenuSerf/MasterBuilderWorkshop_disabled", Technologies.B_MasterBuilderWorkshop
"AOMenuSerf/bridge_disabled", Technologies.B_Bridge

--GUITooltip_BuyMilitaryUnit
"MenuArchery/BuyLeaderBow_normal", Technologies.MU_LeaderBow
"AOMenuArchery/BuyLeaderRifle_normal", Technologies.MU_LeaderRifle
"MenuStables/BuyLeaderCavalryLight_normal", Technologies.MU_LeaderLightCavalry
"MenuStables/BuyLeaderCavalryHeavy_normal", Technologies.MU_LeaderHeavyCavalry
"MenuBarracks/BuyLeaderSword_normal", Technologies.MU_LeaderSword
"MenuBarracks/BuyLeaderSpear_normal", Technologies.MU_LeaderSpear
"MenuFoundry/BuyCannon1_normal",Technologies.MU_Cannon1
"MenuFoundry/BuyCannon2_normal", Technologies.MU_Cannon2
"MenuFoundry/BuyCannon3_normal", Technologies.MU_Cannon3
"MenuFoundry/BuyCannon4_normal", Technologies.MU_Cannon4

--GUITooltip_ResearchTechnologies
Technologies.T_UpgradeHeavyCavalry1,"MenuStables/UpgradeCavalryHeavy1"
Technologies.T_Fletching,"MenuSawmill/Fletching"
Technologies.T_BodkinArrow,"MenuSawmill/BodkinArrow"
Technologies.T_WoodAging,"MenuSawmill/WoodAging"
Technologies.T_Turnery,"MenuSawmill/Turnery"
Technologies.T_UpgradeBow1,"MenuArchery/UpgradeBow1"
Technologies.T_UpgradeBow2,"MenuArchery/UpgradeBow2"
Technologies.T_UpgradeBow3,"MenuArchery/UpgradeBow3"
Technologies.T_BetterTrainingArchery,"MenuArchery/BetterTrainingArchery"
Technologies.T_UpgradeLightCavalry1,"MenuStables/UpgradeCavalryLight1"
Technologies.T_Shoeing,"MenuStables/Shoeing"
Technologies.T_UpgradeRifle1,"AOMenuArchery/UpgradeRifle1"
Technologies.T_PlateMailArmor,"MenuBlacksmith/PlateMailArmor"
Technologies.T_PaddedArcherArmor,"MenuBlacksmith/PaddedArcherArmor"
Technologies.T_LeatherArcherArmor,"MenuBlacksmith/LeatherArcherArmor"
Technologies.T_LeatherMailArmor,"MenuBlacksmith/LeatherMailArmor"
Technologies.T_ChainMailArmor,"MenuBlacksmith/ChainMailArmor"
Technologies.T_SoftArcherArmor,"MenuBlacksmith/SoftArcherArmor"
Technologies.T_MasterOfSmithery,"MenuBlacksmith/MasterOfSmithery"
Technologies.T_IronCasting,"MenuBlacksmith/IronCasting"
Technologies.T_Masonry,"MenuStoneMason/Masonry","KeyBindings/ReserachTechnologies1"
Technologies.T_EnhancedGunPowder,"MenuAlchemist/EnhancedGunPowder"
Technologies.T_BlisteringCannonballs,"MenuAlchemist/BlisteringCannonballs"
Technologies.T_WeatherForecast,"MenuAlchemist/WeatherForecast"
Technologies.T_ChangeWeather,"MenuAlchemist/ChangeWeather"
Technologies.T_TownGuard,"MenuVillage/TownGuard"
Technologies.T_Loom,"MenuVillage/Loom"
Technologies.T_Shoes,"MenuVillage/Shoes"
Technologies.T_UpgradeSword1,"MenuBarracks/UpgradeSword1"
Technologies.T_UpgradeSpear1,"MenuBarracks/UpgradeSpear1"
Technologies.T_UpgradeSword2,"MenuBarracks/UpgradeSword2"
Technologies.T_UpgradeSword3,"MenuBarracks/UpgradeSword3"
Technologies.T_UpgradeSpear2,"MenuBarracks/UpgradeSpear2"
Technologies.T_UpgradeSpear3,"MenuBarracks/UpgradeSpear3"
Technologies.T_BetterTrainingBarracks,"MenuBarracks/BetterTrainingBarracks"
Technologies.GT_Alloying,"MenuUniversity/Alloying"
Technologies.GT_Mathematics,"AOMenuUniversity/Mathematics"
Technologies.GT_Binocular,"AOMenuUniversity/Binocular"
Technologies.GT_Matchlock,"AOMenuUniversity/Matchlock"
Technologies.GT_PulledBarrel,"AOMenuUniversity/PulledBarrel"
Technologies.T_BetterChassis,"MenuFoundry/BetterChassis"
Technologies.T_Tracking,"MenuHeadquarter/Tracking"
Technologies.GT_Construction,"MenuUniversity/Construction"
Technologies.GT_ChainBlock,"MenuUniversity/ChainBlock"
Technologies.GT_GearWheel,"MenuUniversity/GearWheel"
Technologies.GT_Architecture,"MenuUniversity/Architecture"
Technologies.GT_Alchemy,"MenuUniversity/Alchemy"
Technologies.GT_Metallurgy,"MenuUniversity/Metallurgy"
Technologies.GT_Chemistry,"MenuUniversity/Chemistry"
Technologies.GT_Trading,"MenuUniversity/Trading"
Technologies.GT_Literacy,"MenuUniversity/Literacy"
Technologies.GT_Printing,"MenuUniversity/Printing"
Technologies.GT_Library,"MenuUniversity/Library"
Technologies.GT_Mercenaries,"MenuUniversity/Mercenaries"
Technologies.GT_StandingArmy,"MenuUniversity/StandingArmy"
Technologies.GT_Tactics,"MenuUniversity/Tactics"
Technologies.GT_Strategies,"MenuUniversity/Strategies"

--GUITooltip_UpgradeBuilding, second and fourth arg
"MenuClaymine/upgradeclaymine1_disable" Technologies.UP1_Claymine
"MenuClaymine/upgradeclaymine2_disable" Technologies.UP2_Claymine
"MenuBrickworks/UpgradeBrickworks1_disabled", Technologies.UP1_Brickworks
"MenuTower/UpgradeTower1_disabled", Technologies.UP1_Tower
"MenuTower/UpgradeTower2_disabled", Technologies.UP2_Tower
"MenuSawmill/UpgradeSawmill1_disabled", Technologies.UP1_Sawmill
"MenuStables/UpgradeStables1_disabled", Technologies.UP1_Stables
"MenuBank/Upgradebank1_disabled", Technologies.UP1_Bank
"MenuMonastery/UpgradeMonastery1_disabled", Technologies.UP1_Monastery
"MenuMonastery/UpgradeMonastery2_disabled", Technologies.UP2_Monastery
"MenuMarket/UpgradeMarket1_disabled", Technologies.UP1_Market
"MenuArchery/UpgradeArchery1_disabled", Technologies.UP1_Archery
"MenuFoundry/UpgradeFoundry1_disabled",, Technologies.UP1_Foundry
"MenuUniversity/UpgradeUniversity1_disabled", Technologies.UP1_University
"MenuBarracks/upgradeBarracks1_disabled", Technologies.UP1_Barracks
"MenuVillage/UpgradeVillage1_disabled", Technologies.UP1_Village
"MenuVillage/UpgradeVillage2_disabled", Technologies.UP2_Village
"MenuAlchemist/UpgradeAlchemist1_disabled",Technologies.UP1_Alchemist
"MenuBlacksmith/UpgradeBlacksmith1_disabled", Technologies.UP1_Blacksmith
"MenuBlacksmith/UpgradeBlacksmith2_disabled", Technologies.UP2_Blacksmith
"MenuStonemason/UpgradeStonemason1_disabled" Technologies.UP1_StoneMason
]]
function SW.BuildingTooltipsInit()
	
end
function SW.BuildingTooltipsChangeGUI()
	--Start with building tech tree
	SW.BuildingTooltips.GUITooltip_ConstructBuilding = GUITooltip_ConstructBuilding
	GUITooltip_ConstructBuilding = function ( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
		if Logic.GetTechnologyState(GUI.GetPlayerID, _tech) == 4 then --Already teched, use original function
			SW.BuildingTooltips.GUITooltip_ConstructBuilding( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
			return
		end	
		if SW.BuildingTooltips.BData[_uc] == nil then					--Requirements not altered, use normal tooltip
			SW.BuildingTooltips.GUITooltip_ConstructBuilding( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
			return
		end
		--Use of custom tooltip necessary
		--Use original func first to set things like hotkey
		SW.BuildingTooltips.GUITooltip_ConstructBuilding( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
	end
end