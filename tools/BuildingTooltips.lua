-- Apply given tech tree to the game
-- Alters tooltips
-- Gives building rights once conditions are met, e.g. if a player has all requirements for a stable, he gets B_Stable
-- Can manipulate building requirements, tech requirements, troop upgrade requirements
-- Requirements can include techs and tiers

--DO NOT GATE: B_Residence, B_Farm, B_University, B_VillageCenter, B_Mine

--TODO: Unlock technology once conditions are met:
--				MU_X gets researched
--				T_X gets allowed
--				B_X gets researched
--				T_UPX gets researched
--TODO: Relock MU_X, T_UPX and B_X, once conditions do not hold true anymore?
--TODO: Fix MilitaryUnitButtons -> ForbidTechnology(Technologies.T_UpgradeSpear1) makes "Research_UpgradeSpear2" appear
--TODO: Implement requirement for selected building, e.g. the best armor techs can only be researched in lvl3-blacksmith

SW = SW or {}

SW.BuildingTooltips = {}
SW.BuildingTooltips.RankNames = {
	"Möchtegern",
	"Siedler",
	"Feldherr",
	"Eroberer"
}
--[[
Rang 1 Startrang
        Techs: Alle Tier1-Techs for free, abgesehen von Alchemie und evtl Mathematik?
        Gebäude: Alles, was durch gratis Techs geht, plus Archery
        Einheiten: Tier1-Schwert, Speer, Bogen
    Rang 2
        Techs: Alle Tier2-Techs erforschbar, erste ArmorTechs erforschbar?, WetterTech erforschbar
        Gebäude: Stall wird freigeschalten, Kanonenmacher?
        Einheiten: Tier2 Schwert, Bogen, Speer, Tier1 LKav, Leichte Kanonen?
    Rang 3
        Techs:         Alle Tier3-Techs erforschbar, Lvl2-ArmorTechs?
        Gebäude    Kanonentürme besser gaten als Tier3?
        Einheiten   Tier3 durch die Bank, Tier1 SKav, Tier2 LKav, Tier1-Scharfis?
Problem: Tier3 erlaubt DamageUpgrades für alles ausser Schwertis und SKav
    Rang 4
        Techs:        Alles offen
        Gebäude   Alles offen
        Einheiten   Tier4-Einheiten durch die Bank, Große Kanonen und Lvl2-Skav
]]
SW.BuildingTooltips.BData = { --Data for new building tooltips in serf menu
	[Technologies.B_Archery] = {
		Techs = {Technologies.GT_Mercenaries}
	},
    [Technologies.B_Stables] = {		--Requirements for this technology
		Tier = 2
	},
	[Technologies.B_Foundry] = {
		Techs = {Technologies.GT_Alloying},
		Buildings = {{Entities.PB_Alchemist1, Technologies.B_Alchemist}}, --list of needed buildings, every entry need eType and technology to find name of building
	}
}
SW.BuildingTooltips.MData = { --Data for military unit tooltips
	[Technologies.MU_LeaderHeavyCavalry] = {
		Tier = 3
	},
	[Technologies.MU_LeaderSword] = {
		Buildings = {{Entities.PB_Blacksmith1, Technologies.B_Blacksmith}}
	},
}
SW.BuildingTooltips.RData = { --Data for research tooltips
	[Technologies.T_UpgradeSpear1] = {
		Tier = 2,
		Buildings = {{Entities.PB_Sawmill1, Technologies.B_Sawmill}}
	}
} 
SW.BuildingTooltips.UData = { --Data for research tooltips
	[Technologies.UP1_Alchemist] = {
		Tier = 2,
		Techs = {Technologies.GT_Alloying}
	}
} 
SW.BuildingTooltips.TechNames = {			--Gets generated on game start, [technologyId] = name, e.g. [Technologies.B_Residence] = "Wohnhaus"
}
SW.BuildingTooltips.TechFeatures = {		--Gets generated on game start, [technologyId] = lengthyDescription
}
SW.BuildingTooltips.TooltipConstructRaw = {
	["MenuSerf/residence_"]	= Technologies.B_Residence,
	["MenuSerf/farm_"] = Technologies.B_Farm,
	["MenuSerf/mine_"] = Technologies.B_Claymine,		
	["MenuSerf/village_"] = Technologies.B_Village,
	["MenuSerf/blacksmith_"] = Technologies.B_Blacksmith,
	["MenuSerf/stonemason_"] = Technologies.B_StoneMason,
	["MenuSerf/alchemist_"] = Technologies.B_Alchemist,
	["MenuSerf/monastery_"] = Technologies.B_Monastery,
	["MenuSerf/university_"] = Technologies.B_University,
	["MenuSerf/market_"] = Technologies.B_Market,
	["MenuSerf/bank_"] = Technologies.B_Bank,
	["MenuSerf/barracks_"] = Technologies.B_Barracks,
	["MenuSerf/archery_"] = Technologies.B_Archery,
	["MenuSerf/stables_"] = Technologies.B_Stables,
	["MenuSerf/foundry_"] = Technologies.B_Foundry,
	["MenuSerf/brickworks_"] = Technologies.B_Brickworks,
	["MenuSerf/Tower_"] = Technologies.B_Tower,
	["MenuSerf/sawmill_"] = Technologies.B_Sawmill,
	["MenuSerf/Weathermachine_"] = Technologies.B_Weathermachine,
	["MenuSerf/PowerPlant_"] = Technologies.B_PowerPlant,
	["AOMenuSerf/tavern_"] = Technologies.B_Tavern,
	["AOMenuSerf/gunsmithworkshop_"] = Technologies.B_GunsmithWorkshop,
	["AOMenuSerf/MasterBuilderWorkshop_"] = Technologies.B_MasterBuilderWorkshop,
	["AOMenuSerf/bridge_"] = Technologies.B_Bridge
}
SW.BuildingTooltips.TooltipBuyMilitaryRaw = {
	["MenuArchery/BuyLeaderBow_"] = Technologies.MU_LeaderBow,
	["AOMenuArchery/BuyLeaderRifle_"] = Technologies.MU_LeaderRifle,
	["MenuStables/BuyLeaderCavalryLight_"] = Technologies.MU_LeaderLightCavalry,
	["MenuStables/BuyLeaderCavalryHeavy_"] = Technologies.MU_LeaderHeavyCavalry,
	["MenuBarracks/BuyLeaderSword_"] = Technologies.MU_LeaderSword,
	["MenuBarracks/BuyLeaderSpear_"] = Technologies.MU_LeaderSpear,
	["MenuFoundry/BuyCannon1_"] = Technologies.MU_Cannon1,
	["MenuFoundry/BuyCannon2_"] = Technologies.MU_Cannon2,
	["MenuFoundry/BuyCannon3_"] = Technologies.MU_Cannon3,
	["MenuFoundry/BuyCannon4_"] = Technologies.MU_Cannon4
}
SW.BuildingTooltips.TooltipsResearchRaw = {
	[Technologies.T_UpgradeHeavyCavalry1] = "MenuStables/UpgradeCavalryHeavy1",
	[Technologies.T_Fletching] = "MenuSawmill/Fletching",
	[Technologies.T_BodkinArrow] = "MenuSawmill/BodkinArrow",
	[Technologies.T_WoodAging] = "MenuSawmill/WoodAging",
	[Technologies.T_Turnery] = "MenuSawmill/Turnery",
	[Technologies.T_UpgradeBow1] = "MenuArchery/UpgradeBow1",
	[Technologies.T_UpgradeBow2] = "MenuArchery/UpgradeBow2",
	[Technologies.T_UpgradeBow3] = "MenuArchery/UpgradeBow3",
	[Technologies.T_BetterTrainingArchery] = "MenuArchery/BetterTrainingArchery",
	[Technologies.T_UpgradeLightCavalry1] = "MenuStables/UpgradeCavalryLight1",
	[Technologies.T_Shoeing] = "MenuStables/Shoeing",
	[Technologies.T_UpgradeRifle1] = "AOMenuArchery/UpgradeRifle1",
	[Technologies.T_PlateMailArmor] = "MenuBlacksmith/PlateMailArmor",
	[Technologies.T_PaddedArcherArmor] = "MenuBlacksmith/PaddedArcherArmor",
	[Technologies.T_LeatherArcherArmor] = "MenuBlacksmith/LeatherArcherArmor",
	[Technologies.T_LeatherMailArmor] = "MenuBlacksmith/LeatherMailArmor",
	[Technologies.T_ChainMailArmor] = "MenuBlacksmith/ChainMailArmor",
	[Technologies.T_SoftArcherArmor] = "MenuBlacksmith/SoftArcherArmor",
	[Technologies.T_MasterOfSmithery] = "MenuBlacksmith/MasterOfSmithery",
	[Technologies.T_IronCasting] = "MenuBlacksmith/IronCasting",
	[Technologies.T_Masonry] = "MenuStoneMason/Masonry",
	[Technologies.T_EnhancedGunPowder] = "MenuAlchemist/EnhancedGunPowder",
	[Technologies.T_BlisteringCannonballs] = "MenuAlchemist/BlisteringCannonballs",
	[Technologies.T_WeatherForecast] = "MenuAlchemist/WeatherForecast",
	[Technologies.T_ChangeWeather] = "MenuAlchemist/ChangeWeather",
	[Technologies.T_TownGuard] = "MenuVillage/TownGuard",
	[Technologies.T_Loom] = "MenuVillage/Loom",
	[Technologies.T_Shoes] = "MenuVillage/Shoes",
	[Technologies.T_UpgradeSword1] = "MenuBarracks/UpgradeSword1",
	[Technologies.T_UpgradeSpear1] = "MenuBarracks/UpgradeSpear1",
	[Technologies.T_UpgradeSword2] = "MenuBarracks/UpgradeSword2",
	[Technologies.T_UpgradeSword3] = "MenuBarracks/UpgradeSword3",
	[Technologies.T_UpgradeSpear2] = "MenuBarracks/UpgradeSpear2",
	[Technologies.T_UpgradeSpear3] = "MenuBarracks/UpgradeSpear3",
	[Technologies.T_BetterTrainingBarracks] = "MenuBarracks/BetterTrainingBarracks",
	[Technologies.GT_Alloying] = "MenuUniversity/Alloying",
	[Technologies.GT_Mathematics] = "AOMenuUniversity/Mathematics",
	[Technologies.GT_Binocular] = "AOMenuUniversity/Binocular",
	[Technologies.GT_Matchlock] = "AOMenuUniversity/Matchlock",
	[Technologies.GT_PulledBarrel] = "AOMenuUniversity/PulledBarrel",
	[Technologies.T_BetterChassis] = "MenuFoundry/BetterChassis",
	[Technologies.T_Tracking] = "MenuHeadquarter/Tracking",
	[Technologies.GT_Construction] = "MenuUniversity/Construction",
	[Technologies.GT_ChainBlock] = "MenuUniversity/ChainBlock",
	[Technologies.GT_GearWheel] = "MenuUniversity/GearWheel",
	[Technologies.GT_Architecture] = "MenuUniversity/Architecture",
	[Technologies.GT_Alchemy] = "MenuUniversity/Alchemy",
	[Technologies.GT_Metallurgy] = "MenuUniversity/Metallurgy",
	[Technologies.GT_Chemistry] = "MenuUniversity/Chemistry",
	[Technologies.GT_Trading] = "MenuUniversity/Trading",
	[Technologies.GT_Literacy] = "MenuUniversity/Literacy",
	[Technologies.GT_Printing] = "MenuUniversity/Printing",
	[Technologies.GT_Library] = "MenuUniversity/Library",
	[Technologies.GT_Mercenaries] = "MenuUniversity/Mercenaries",
	[Technologies.GT_StandingArmy] = "MenuUniversity/StandingArmy",
	[Technologies.GT_Tactics] = "MenuUniversity/Tactics",
	[Technologies.GT_Strategies] = "MenuUniversity/Strategies"
}
SW.BuildingTooltips.TooltipsUpgradeRaw = {
	["MenuClaymine/upgradeclaymine1_"] = Technologies.UP1_Claymine,
	["MenuClaymine/upgradeclaymine2_"] = Technologies.UP2_Claymine,
	["MenuBrickworks/UpgradeBrickworks1_"] = Technologies.UP1_Brickworks,
	["MenuTower/UpgradeTower1_"] = Technologies.UP1_Tower,
	["MenuTower/UpgradeTower2_"] = Technologies.UP2_Tower,
	["MenuSawmill/UpgradeSawmill1_"] = Technologies.UP1_Sawmill,
	["MenuStables/UpgradeStables1_"] = Technologies.UP1_Stables,
	["MenuBank/Upgradebank1_"] = Technologies.UP1_Bank,
	["MenuMonastery/UpgradeMonastery1_"] = Technologies.UP1_Monastery,
	["MenuMonastery/UpgradeMonastery2_"] = Technologies.UP2_Monastery,
	["MenuMarket/UpgradeMarket1_"] = Technologies.UP1_Market,
	["MenuArchery/UpgradeArchery1_"] = Technologies.UP1_Archery,
	["MenuFoundry/UpgradeFoundry1_"] = Technologies.UP1_Foundry,
	["MenuUniversity/UpgradeUniversity1_"] = Technologies.UP1_University,
	["MenuBarracks/upgradeBarracks1_"] = Technologies.UP1_Barracks,
	["MenuVillage/UpgradeVillage1_"] = Technologies.UP1_Village,
	["MenuVillage/UpgradeVillage2_"] = Technologies.UP2_Village,
	["MenuAlchemist/UpgradeAlchemist1_"] = Technologies.UP1_Alchemist,
	["MenuBlacksmith/UpgradeBlacksmith1_"] = Technologies.UP1_Blacksmith,
	["MenuBlacksmith/UpgradeBlacksmith2_"] = Technologies.UP2_Blacksmith,
	["MenuStonemason/UpgradeStonemason1_"] = Technologies.UP1_StoneMason
}
--[[		--Not necessary anymore
--GUITooltip_ConstructBuilding, second and third arg
	["MenuSerf/residence_disabled"]	= Technologies.B_Residence,
	["MenuSerf/farm_disabled"] = Technologies.B_Farm,
	["MenuSerf/mine_disabled"] = Technologies.B_Claymine,		
	["MenuSerf/village_disabled"] = Technologies.B_Village,
	["MenuSerf/blacksmith_disabled"] = Technologies.B_Blacksmith,
	["MenuSerf/stonemason_disabled"] = Technologies.B_StoneMason,
	["MenuSerf/alchemist_disabled"] = Technologies.B_Alchemist,
	["MenuSerf/monastery_disabled"] = Technologies.B_Monastery,
	["MenuSerf/university_disabled"] = Technologies.B_University,
	["MenuSerf/market_disabled"] = Technologies.B_Market,
	["MenuSerf/bank_disabled"] = Technologies.B_Bank,
	["MenuSerf/barracks_disabled"] = Technologies.B_Barracks,
	["MenuSerf/archery_disabled"] =Technologies.B_Archery,
	["MenuSerf/stables_disabled"] = Technologies.B_Stables,
	["MenuSerf/foundry_disabled"] = Technologies.B_Foundry,
	["MenuSerf/brickworks_disabled"] = Technologies.B_Brickworks,
	["MenuSerf/Tower_disabled"] = Technologies.B_Tower,
	["MenuSerf/sawmill_disabled"] = Technologies.B_Sawmill,
	["MenuSerf/Weathermachine_disabled"] = Technologies.B_Weathermachine,
	["MenuSerf/PowerPlant_disabled"] = Technologies.B_PowerPlant,
	["AOMenuSerf/tavern_disabled"] = Technologies.B_Tavern,
	["AOMenuSerf/gunsmithworkshop_disabled"] = Technologies.B_GunsmithWorkshop,
	["AOMenuSerf/MasterBuilderWorkshop_disabled"] = Technologies.B_MasterBuilderWorkshop,
	["AOMenuSerf/bridge_disabled"] = Technologies.B_Bridge

--GUITooltip_BuyMilitaryUnit
	["MenuArchery/BuyLeaderBow_"] = Technologies.MU_LeaderBow,
	["AOMenuArchery/BuyLeaderRifle_"] = Technologies.MU_LeaderRifle,
	["MenuStables/BuyLeaderCavalryLight_"] = Technologies.MU_LeaderLightCavalry,
	["MenuStables/BuyLeaderCavalryHeavy_"] = Technologies.MU_LeaderHeavyCavalry,
	["MenuBarracks/BuyLeaderSword_"] = Technologies.MU_LeaderSword,
	["MenuBarracks/BuyLeaderSpear_"] = Technologies.MU_LeaderSpear,
	["MenuFoundry/BuyCannon1_"] = Technologies.MU_Cannon1,
	["MenuFoundry/BuyCannon2_"] = Technologies.MU_Cannon2,
	["MenuFoundry/BuyCannon3_"] = Technologies.MU_Cannon3,
	["MenuFoundry/BuyCannon4_"] = Technologies.MU_Cannon4

--GUITooltip_ResearchTechnologies
	[Technologies.T_UpgradeHeavyCavalry1] = "MenuStables/UpgradeCavalryHeavy1",
	[Technologies.T_Fletching] = "MenuSawmill/Fletching",
	[Technologies.T_BodkinArrow] = "MenuSawmill/BodkinArrow",
	[Technologies.T_WoodAging] = "MenuSawmill/WoodAging",
	[Technologies.T_Turnery] = "MenuSawmill/Turnery",
	[Technologies.T_UpgradeBow1] = "MenuArchery/UpgradeBow1",
	[Technologies.T_UpgradeBow2] = "MenuArchery/UpgradeBow2",
	[Technologies.T_UpgradeBow3] = "MenuArchery/UpgradeBow3",
	[Technologies.T_BetterTrainingArchery] = "MenuArchery/BetterTrainingArchery",
	[Technologies.T_UpgradeLightCavalry1] = "MenuStables/UpgradeCavalryLight1",
	[Technologies.T_Shoeing] = "MenuStables/Shoeing",
	[Technologies.T_UpgradeRifle1] = "AOMenuArchery/UpgradeRifle1",
	[Technologies.T_PlateMailArmor] = "MenuBlacksmith/PlateMailArmor",
	[Technologies.T_PaddedArcherArmor] = "MenuBlacksmith/PaddedArcherArmor",
	[Technologies.T_LeatherArcherArmor] = "MenuBlacksmith/LeatherArcherArmor",
	[Technologies.T_LeatherMailArmor] = "MenuBlacksmith/LeatherMailArmor",
	[Technologies.T_ChainMailArmor] = "MenuBlacksmith/ChainMailArmor",
	[Technologies.T_SoftArcherArmor] = "MenuBlacksmith/SoftArcherArmor",
	[Technologies.T_MasterOfSmithery] = "MenuBlacksmith/MasterOfSmithery",
	[Technologies.T_IronCasting] = "MenuBlacksmith/IronCasting",
	[Technologies.T_Masonry] = "MenuStoneMason/Masonry",
	[Technologies.T_EnhancedGunPowder] = "MenuAlchemist/EnhancedGunPowder",
	[Technologies.T_BlisteringCannonballs] = "MenuAlchemist/BlisteringCannonballs",
	[Technologies.T_WeatherForecast] = "MenuAlchemist/WeatherForecast",
	[Technologies.T_ChangeWeather] = "MenuAlchemist/ChangeWeather",
	[Technologies.T_TownGuard] = "MenuVillage/TownGuard",
	[Technologies.T_Loom] = "MenuVillage/Loom",
	[Technologies.T_Shoes] = "MenuVillage/Shoes",
	[Technologies.T_UpgradeSword1] = "MenuBarracks/UpgradeSword1",
	[Technologies.T_UpgradeSpear1] = "MenuBarracks/UpgradeSpear1",
	[Technologies.T_UpgradeSword2] = "MenuBarracks/UpgradeSword2",
	[Technologies.T_UpgradeSword3] = "MenuBarracks/UpgradeSword3",
	[Technologies.T_UpgradeSpear2] = "MenuBarracks/UpgradeSpear2",
	[Technologies.T_UpgradeSpear3] = "MenuBarracks/UpgradeSpear3",
	[Technologies.T_BetterTrainingBarracks] = "MenuBarracks/BetterTrainingBarracks",
	[Technologies.GT_Alloying] = "MenuUniversity/Alloying",
	[Technologies.GT_Mathematics] = "AOMenuUniversity/Mathematics",
	[Technologies.GT_Binocular] = "AOMenuUniversity/Binocular",
	[Technologies.GT_Matchlock] = "AOMenuUniversity/Matchlock",
	[Technologies.GT_PulledBarrel] = "AOMenuUniversity/PulledBarrel",
	[Technologies.T_BetterChassis] = "MenuFoundry/BetterChassis",
	[Technologies.T_Tracking] = "MenuHeadquarter/Tracking",
	[Technologies.GT_Construction] = "MenuUniversity/Construction",
	[Technologies.GT_ChainBlock] = "MenuUniversity/ChainBlock",
	[Technologies.GT_GearWheel] = "MenuUniversity/GearWheel",
	[Technologies.GT_Architecture] = "MenuUniversity/Architecture",
	[Technologies.GT_Alchemy] = "MenuUniversity/Alchemy",
	[Technologies.GT_Metallurgy] = "MenuUniversity/Metallurgy",
	[Technologies.GT_Chemistry] = "MenuUniversity/Chemistry",
	[Technologies.GT_Trading] = "MenuUniversity/Trading",
	[Technologies.GT_Literacy] = "MenuUniversity/Literacy",
	[Technologies.GT_Printing] = "MenuUniversity/Printing",
	[Technologies.GT_Library] = "MenuUniversity/Library",
	[Technologies.GT_Mercenaries] = "MenuUniversity/Mercenaries",
	[Technologies.GT_StandingArmy] = "MenuUniversity/StandingArmy",
	[Technologies.GT_Tactics] = "MenuUniversity/Tactics",
	[Technologies.GT_Strategies] = "MenuUniversity/Strategies"

--GUITooltip_UpgradeBuilding, second and fourth arg
	["MenuClaymine/upgradeclaymine1_disable"] = Technologies.UP1_Claymine,
	["MenuClaymine/upgradeclaymine2_disable"] = Technologies.UP2_Claymine,
	["MenuBrickworks/UpgradeBrickworks1_disabled"] = Technologies.UP1_Brickworks,
	["MenuTower/UpgradeTower1_disabled"] = Technologies.UP1_Tower,
	["MenuTower/UpgradeTower2_disabled"] = Technologies.UP2_Tower,
	["MenuSawmill/UpgradeSawmill1_disabled"] = Technologies.UP1_Sawmill,
	["MenuStables/UpgradeStables1_disabled"] = Technologies.UP1_Stables,
	["MenuBank/Upgradebank1_disabled"] = Technologies.UP1_Bank,
	["MenuMonastery/UpgradeMonastery1_disabled"] = Technologies.UP1_Monastery,
	["MenuMonastery/UpgradeMonastery2_disabled"] = Technologies.UP2_Monastery,
	["MenuMarket/UpgradeMarket1_disabled"] = Technologies.UP1_Market,
	["MenuArchery/UpgradeArchery1_disabled"] = Technologies.UP1_Archery,
	["MenuFoundry/UpgradeFoundry1_disabled"] = Technologies.UP1_Foundry,
	["MenuUniversity/UpgradeUniversity1_disabled"] = Technologies.UP1_University,
	["MenuBarracks/upgradeBarracks1_disabled"] = Technologies.UP1_Barracks,
	["MenuVillage/UpgradeVillage1_disabled"] = Technologies.UP1_Village,
	["MenuVillage/UpgradeVillage2_disabled"] = Technologies.UP2_Village,
	["MenuAlchemist/UpgradeAlchemist1_disabled"] =Technologies.UP1_Alchemist,
	["MenuBlacksmith/UpgradeBlacksmith1_disabled"] = Technologies.UP1_Blacksmith,
	["MenuBlacksmith/UpgradeBlacksmith2_disabled"] = Technologies.UP2_Blacksmith,
	["MenuStonemason/UpgradeStonemason1_disabled"] = Technologies.UP1_StoneMason
]]
function SW.BuildingTooltipsInit()			--Has to be called via Debugger! Not started on map start yet!
	SW.BuildingTooltips.GenerateTechNames()
	SW.BuildingTooltips.GenerateTechStrings()
	SW.BuildingTooltips.ChangeGUI()
	for k,v in pairs(SW.BuildingTooltips.MData) do
		ForbidTechnology(k)
	end
	for k,v in pairs(SW.BuildingTooltips.BData) do
		ForbidTechnology(k)
	end
	for k,v in pairs(SW.BuildingTooltips.RData) do
		ForbidTechnology(k)
	end
	for k,v in pairs(SW.BuildingTooltips.UData) do
		ForbidTechnology(k)
	end
end
function SW.BuildingTooltips.GenerateTechNames()
	local rawString
	local _, endSpaces, endText
	for k,v in pairs(SW.BuildingTooltips.TooltipConstructRaw) do
		rawString = XGUIEng.GetStringTableText(k.."normal")
		_, endSpaces = string.find( rawString, "%s+") --Get rid of the first few spaces
		rawString = string.sub( rawString, endSpaces + 1)
		endText = string.find( rawString, "%s+") or 1	--Find end of first text by searching for spaces
		rawString = string.sub( rawString, 1, endText - 1)
		SW.BuildingTooltips.TechNames[v] = rawString
	end
	for k,v in pairs(SW.BuildingTooltips.TooltipBuyMilitaryRaw) do
		rawString = XGUIEng.GetStringTableText(k.."normal")
		--LuaDebugger.Log(rawString)
		_, endSpaces = string.find( rawString, "%s+") --Get rid of the first few spaces
		rawString = string.sub( rawString, endSpaces + 1)
		--LuaDebugger.Log(rawString)
		endText = string.find( rawString, "%s+@") or 1	--Find end of first text by searching for spaces followed by @
		rawString = string.sub( rawString, 1, endText - 1)
		--LuaDebugger.Log(rawString)
		SW.BuildingTooltips.TechNames[v] = rawString
	end
	for k,v in pairs(SW.BuildingTooltips.TooltipsResearchRaw) do
		rawString = XGUIEng.GetStringTableText(v.."_normal")
		--LuaDebugger.Log(rawString)
		_, endSpaces = string.find( rawString, "%s+") --Get rid of the first few spaces
		rawString = string.sub( rawString, endSpaces + 1)
		--LuaDebugger.Log(rawString)
		endText = string.find( rawString, "%s+@") or 1	--Find end of first text by searching for spaces followed by @
		rawString = string.sub( rawString, 1, endText - 1)
		--LuaDebugger.Log(rawString)
		SW.BuildingTooltips.TechNames[k] = rawString
	end
	for k,v in pairs(SW.BuildingTooltips.TooltipsUpgradeRaw) do
		rawString = XGUIEng.GetStringTableText(k.."normal")
		--LuaDebugger.Log(rawString)
		_, endSpaces = string.find( rawString, "%s+") --Get rid of the first few spaces
		rawString = string.sub( rawString, endSpaces + 1)
		--LuaDebugger.Log(rawString)
		endText = string.find( rawString, "%s+@") or 1	--Find end of first text by searching for spaces followed by @
		rawString = string.sub( rawString, 1, endText - 1)
		--LuaDebugger.Log(rawString)
		SW.BuildingTooltips.TechNames[v] = rawString
	end
end
function SW.BuildingTooltips.GenerateTechStrings()
	local rawString
	local _, endSpaces, endText
	for k,v in pairs(SW.BuildingTooltips.TooltipConstructRaw) do
		rawString = XGUIEng.GetStringTableText(k.."disabled")
		if rawString ~= nil then
			_, endSpaces = string.find( rawString, ".+@") --Get rid of the first data
			if endSpaces == nil then endSpaces = 0 end
			rawString = string.sub( rawString, endSpaces)
			--endText = string.find( rawString, "%s+") or 1	--Find end of first text by searching for spaces
			--rawString = string.sub( rawString, 1, endText - 1)
			SW.BuildingTooltips.TechFeatures[v] = rawString
		else
			SW.BuildingTooltips.TechFeatures[v] = "BS"
		end
	end
	for k,v in pairs(SW.BuildingTooltips.TooltipsResearchRaw) do
		rawString = XGUIEng.GetStringTableText(v.."_normal")
		if rawString ~= nil then
			--LuaDebugger.Log( rawString)
			_, endSpaces = string.find( rawString, "@.+@") --Get rid of the first data
			if endSpaces == nil then endSpaces = 0 end
			rawString = string.sub( rawString, endSpaces)
			--endText = string.find( rawString, "%s+") or 1	--Find end of first text by searching for spaces
			--rawString = string.sub( rawString, 1, endText - 1)
			SW.BuildingTooltips.TechFeatures[k] = rawString
		else
			SW.BuildingTooltips.TechFeatures[k] = "BS"
		end
	end
	for k,v in pairs(SW.BuildingTooltips.TooltipBuyMilitaryRaw) do
		rawString = XGUIEng.GetStringTableText(k.."normal")
		if rawString ~= nil then
			_, endSpaces = string.find( rawString, "@.-@.-@") --Get rid of the first data
			if endSpaces == nil then endSpaces = 0 end
			rawString = string.sub( rawString, endSpaces)
			--endText = string.find( rawString, "%s+") or 1	--Find end of first text by searching for spaces
			--rawString = string.sub( rawString, 1, endText - 1)
			SW.BuildingTooltips.TechFeatures[v] = rawString
		else
			SW.BuildingTooltips.TechFeatures[v] = "BS"
		end
	end
	for k,v in pairs(SW.BuildingTooltips.TooltipsUpgradeRaw) do
		rawString = XGUIEng.GetStringTableText(k.."normal")
		if rawString ~= nil then
			_, endSpaces = string.find( rawString, "@.+@") --Get rid of the first data
			if endSpaces == nil then endSpaces = 0 end
			rawString = string.sub( rawString, endSpaces)
			--endText = string.find( rawString, "%s+") or 1	--Find end of first text by searching for spaces
			--rawString = string.sub( rawString, 1, endText - 1)
			--LuaDebugger.Log(rawString)
			SW.BuildingTooltips.TechFeatures[v] = rawString
		else
			SW.BuildingTooltips.TechFeatures[v] = "BS"
		end
	end
end
function SW.BuildingTooltips.ChangeGUI()
	--Start with building tech tree
	SW.BuildingTooltips.GUITooltip_ConstructBuilding = GUITooltip_ConstructBuilding
	GUITooltip_ConstructBuilding = function ( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
		if Logic.GetTechnologyState(GUI.GetPlayerID(), _tech) == 4 then --Already teched, use original function
			SW.BuildingTooltips.GUITooltip_ConstructBuilding( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
			return
		end	
		if SW.BuildingTooltips.BData[_tech] == nil then					--Requirements not altered, use normal tooltip
			SW.BuildingTooltips.GUITooltip_ConstructBuilding( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
			return
		end
		--Use of custom tooltip necessary
		--Use original func first to set things like hotkey
		SW.BuildingTooltips.GUITooltip_ConstructBuilding( _uc, _tooltipStringNormal, _tooltipStringDisabled, _tech, _keyBindingString)
		--Now build custom tooltip
		XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomText, SW.BuildingTooltips.ConstructTooltipB(_tech))
	end
	--GUITooltip_BuyMilitaryUnit( _uc, _s1, _s2, _tech, _s3)
	SW.BuildingTooltips.GUITooltip_BuyMilitaryUnit = GUITooltip_BuyMilitaryUnit
	GUITooltip_BuyMilitaryUnit = function( _uc, _s1, _s2, _tech, _s3)
		if Logic.GetTechnologyState(GUI.GetPlayerID(), _tech) == 4 then --Already teched, use original function
			SW.BuildingTooltips.GUITooltip_BuyMilitaryUnit( _uc, _s1, _s2, _tech, _s3)
			return
		end	
		if SW.BuildingTooltips.MData[_tech] == nil then					--Requirements not altered, use normal tooltip
			SW.BuildingTooltips.GUITooltip_BuyMilitaryUnit( _uc, _s1, _s2, _tech, _s3)
			return
		end
		SW.BuildingTooltips.GUITooltip_BuyMilitaryUnit( _uc, _s1, _s2, _tech, _s3)
		XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomText, SW.BuildingTooltips.ConstructTooltipM(_tech))
	end
	--GUITooltip_ResearchTechnologies(Technologies.T_BetterChassis,"MenuFoundry/BetterChassis","KeyBindings/ReserachTechnologies1")
	SW.BuildingTooltips.GUITooltip_ResearchTechnologies = GUITooltip_ResearchTechnologies
	GUITooltip_ResearchTechnologies = function( _tech, _s1, _s2)
		if Logic.GetTechnologyState(GUI.GetPlayerID(), _tech) == 4 then --Already teched, use original function
			SW.BuildingTooltips.GUITooltip_ResearchTechnologies( _tech, _s1, _s2)
			return
		end	
		if SW.BuildingTooltips.RData[_tech] == nil then					--Requirements not altered, use normal tooltip
			SW.BuildingTooltips.GUITooltip_ResearchTechnologies( _tech, _s1, _s2)
			return
		end
		SW.BuildingTooltips.GUITooltip_ResearchTechnologies( _tech, _s1, _s2)
		XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomText, SW.BuildingTooltips.ConstructTooltipR(_tech))
	end
	--GUITooltip_UpgradeBuilding( _eId, _s1, _s2, _tech)
	SW.BuildingTooltips.GUITooltip_UpgradeBuilding = GUITooltip_UpgradeBuilding
	GUITooltip_UpgradeBuilding = function( _eId, _s1, _s2, _tech)
		if Logic.GetTechnologyState(GUI.GetPlayerID(), _tech) == 4 then --Already teched, use original function
			SW.BuildingTooltips.GUITooltip_UpgradeBuilding( _eId, _s1, _s2, _tech)
			return
		end	
		if SW.BuildingTooltips.UData[_tech] == nil then					--Requirements not altered, use normal tooltip
			SW.BuildingTooltips.GUITooltip_UpgradeBuilding( _eId, _s1, _s2, _tech)
			return
		end
		SW.BuildingTooltips.GUITooltip_UpgradeBuilding( _eId, _s1, _s2, _tech)
		XGUIEng.SetText( gvGUI_WidgetID.TooltipBottomText, SW.BuildingTooltips.ConstructTooltipU(_tech))
	end
end
function SW.BuildingTooltips.ConstructTooltipB(_tech)		--creates tooltips for buildings
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.BData[_tech]
	local first = true
	if req.Tier then
		retString = retString.."Rang: "..SW.BuildingTooltips.RankNames[req.Tier]
		first = false
	end
	if req.Techs then
		for k, v in pairs(req.Techs) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v]
			first = false
		end
	end
	if req.Buildings then
		for k, v in pairs(req.Buildings) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v[2]]
			first = false
		end
	end
	retString = retString.." @cr @color:255,204,51,255 ermöglicht: "..SW.BuildingTooltips.TechFeatures[_tech]
	return retString
end
function SW.BuildingTooltips.ConstructTooltipM(_tech)		--creates tooltips for military units
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.MData[_tech]
	local first = true
	if req.Tier then
		retString = retString.."Rang: "..SW.BuildingTooltips.RankNames[req.Tier]
		first = false
	end
	if req.Techs then
		for k, v in pairs(req.Techs) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v]
			first = false
		end
	end
	if req.Buildings then
		for k, v in pairs(req.Buildings) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v[2]]
			first = false
		end
	end
	retString = retString.." @cr @color:255,204,51,255 ermöglicht: "..SW.BuildingTooltips.TechFeatures[_tech]
	return retString
end
function SW.BuildingTooltips.ConstructTooltipR(_tech)		--creates tooltips for researches
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.RData[_tech]
	local first = true
	if req.Tier then
		retString = retString.."Rang: "..SW.BuildingTooltips.RankNames[req.Tier]
		first = false
	end
	if req.Techs then
		for k, v in pairs(req.Techs) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v]
			first = false
		end
	end
	if req.Buildings then
		for k, v in pairs(req.Buildings) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v[2]]
			first = false
		end
	end
	retString = retString.." @cr @color:255,204,51,255 ermöglicht: "..SW.BuildingTooltips.TechFeatures[_tech]
	return retString
end
function SW.BuildingTooltips.ConstructTooltipU(_tech)		--creates tooltips for upgrades
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.UData[_tech]
	local first = true
	if req.Tier then
		retString = retString.."Rang: "..SW.BuildingTooltips.RankNames[req.Tier]
		first = false
	end
	if req.Techs then
		for k, v in pairs(req.Techs) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v]
			first = false
		end
	end
	if req.Buildings then
		for k, v in pairs(req.Buildings) do
			if not first then 
				retString = retString..", "
			end
			retString = retString..SW.BuildingTooltips.TechNames[v[2]]
			first = false
		end
	end
	retString = retString.." @cr @color:255,204,51,255 ermöglicht: "..SW.BuildingTooltips.TechFeatures[_tech]
	return retString
end


