-- Apply given tech tree to the game
-- Alters tooltips
-- Gives building rights once conditions are met, e.g. if a player has all requirements for a stable, he gets B_Stable
-- Can manipulate building requirements, tech requirements, troop upgrade requirements
-- Requirements can include techs and tiers

--DO NOT GATE: B_Residence, B_Farm, B_University, B_VillageCenter, B_Mine

--TODO: Hide ShortMessages when technologies are given by or alter message written on screen
--				http://www.siedler-games.de/forum/showthread.php/18104-Tech-s-per-Skript-erforschen-ohne-quot-F%C3%A4hnchen-quot
--TODO: Relock MU_X, T_UPX and B_X, once conditions do not hold true anymore? Or remove this feature?


SW = SW or {}

SW.BuildingTooltips = {}
if not SW.BuildingTooltips.GetRank then
	SW.BuildingTooltips.GlobalRank = 4
	SW.BuildingTooltips.GetRank = function( _pId) return SW.BuildingTooltips.GlobalRank end
end
SW.BuildingTooltips.RankNames = {
	"Möchtegern",
	"Siedler",
	"Feldherr",
	"Eroberer"
}
SW.BuildingTooltips.BData = { --Data for new building tooltips in serf menu
	[Technologies.B_Barracks] = {	--Barracks are allowed frome the start
		Tier = 1,
	},
	[Technologies.B_Archery] = {
		Techs = {Technologies.GT_Mercenaries}
	},
    [Technologies.B_Stables] = {		--Requirements for this technology
		Tier = 2
	},
	[Technologies.B_Foundry] = {
		Techs = {Technologies.GT_Alloying},
		Buildings = {{Entities.PB_Alchemist1, Technologies.B_Alchemist}}, --list of needed buildings, every entry need eType and technology to find name of building
	},
	[Technologies.B_Sawmill] = {
		Tier = 1,
	},
	[Technologies.B_Brickworks] = {
		Tier = 1,
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
	--Gating for university techs: lvl1 always, lvl2 on tier 2, lvl3 on tier 3 & university, lvl 4 on tier 4
	--Chemistry path
	[Technologies.GT_Alloying] = {
		Techs = {Technologies.GT_Alchemy},
		Tier = 2,
	},
	[Technologies.GT_Metallurgy] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Alloying},
		Tier = 3,
	},
	[Technologies.GT_Chemistry] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Metallurgy},
		Tier = 4,
	},
	--Library path
	[Technologies.GT_Trading] = {
		Techs = {Technologies.GT_Literacy},
		Tier = 2,
	},
	[Technologies.GT_Printing] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Trading},
		Tier = 3,
	},
	[Technologies.GT_Library] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Printing},
		Tier = 4,
	}, 
	--Mathematics path
	[Technologies.GT_Binocular] = {
		Techs = {Technologies.GT_Mathematics},
		Tier = 2,
	},
	[Technologies.GT_Matchlock] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Binocular},
		Tier = 3,
	},
	[Technologies.GT_PulledBarrel] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Matchlock},
		Tier = 4,
	},
	--Architecture path
	[Technologies.GT_GearWheel] = {
		Techs = {Technologies.GT_Construction},
		Tier = 2,
	},
	[Technologies.GT_ChainBlock] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_GearWheel},
		Tier = 3,
	},
	[Technologies.GT_Architecture] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_ChainBlock},
		Tier = 4,
	},
	--Strategies path
	[Technologies.GT_StandingArmy] = {
		Techs = {Technologies.GT_Mercenaries},
		Tier = 2,
	},
	[Technologies.GT_Tactics] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_StandingArmy},
		Tier = 3,
	},
	[Technologies.GT_Strategies] = {
		currBuilding = {Entities.PB_University2, Technologies.UP1_University},
		Techs = {Technologies.GT_Tactics},
		Tier = 4,
	},
	--Now: Group upgrades
	--Infantry grows with tier
	--Allow best heavy cav on tier 4
	--Allow best light cav on tier 3
	[Technologies.T_UpgradeHeavyCavalry1] = {
		Techs = {Technologies.GT_Strategies}, 
	},
	[Technologies.T_UpgradeLightCavalry1] = {
		Techs = {Technologies.GT_Tactics}, 
	},
	[Technologies.T_UpgradeBow1] = {
		Tier = 2,
		Buildings = {{Entities.PB_Sawmill1, Technologies.B_Sawmill}}
	},
	[Technologies.T_UpgradeBow2] = {
		Tier = 3,
		Buildings = {{Entities.PB_Sawmill2, Technologies.UP1_Sawmill}},
		currBuilding = {Entities.PB_Archery2, Technologies.UP1_Archery}
	},
	[Technologies.T_UpgradeBow3] = {
		Tier = 4,
		Buildings = {{Entities.PB_Sawmill1, Technologies.UP1_Sawmill}},
		currBuilding = {Entities.PB_Archery2, Technologies.UP1_Archery}
	},
	[Technologies.T_UpgradeSpear1] = {
		Tier = 2,
		Buildings = {{Entities.PB_Sawmill1, Technologies.B_Sawmill}}
	},
	[Technologies.T_UpgradeSpear2] = {
		Tier = 3,
		Buildings = {{Entities.PB_Sawmill2, Technologies.UP1_Sawmill}},
		currBuilding = {Entities.PB_Barracks2, Technologies.UP1_Barracks}
	},
	[Technologies.T_UpgradeSpear3] = {
		Tier = 4,
		Buildings = {{Entities.PB_Sawmill1, Technologies.UP1_Sawmill}},
		currBuilding = {Entities.PB_Barracks2, Technologies.UP1_Barracks}
	},
	[Technologies.T_UpgradeSword1] = {
		Tier = 2,
		Buildings = {{Entities.PB_Blacksmith1, Technologies.B_Blacksmith}}
	},
	[Technologies.T_UpgradeSword2] = {
		Tier = 3,
		Buildings = {{Entities.PB_Blacksmith3, Technologies.UP2_Blacksmith}},
		currBuilding = {Entities.PB_Barracks2, Technologies.UP1_Barracks}
	},
	[Technologies.T_UpgradeSword3] = {
		Tier = 4,
		Buildings = {{Entities.PB_Blacksmith3, Technologies.UP2_Blacksmith}},
		currBuilding = {Entities.PB_Barracks2, Technologies.UP1_Barracks}
	},
	--Tech trees black smith
	--First armor techs on tier 2
	--First dmg tech, second armor tech on tier 3, lvl2 smith
	--Second dmg tech, third armor tech on tier 4, lvl3 smith
	--MasterOfSmithery -> IronCasting
	--LeatherMailArmor -> ChainMailArmor -> PlateMailArmor
	--SoftArcherArmor -> PaddedArcherArmor -> LeatherArcherArmor
	[Technologies.T_SoftArcherArmor] = {
		Tier = 2,
	},
	[Technologies.T_PaddedArcherArmor] = {
		Tier = 3, 
		Techs = {Technologies.T_SoftArcherArmor},
		currBuilding = { Entities.PB_Blacksmith2, Technologies.UP1_Blacksmith}
	},
	[Technologies.T_LeatherArcherArmor] = {
		Tier = 4, 
		Techs = {Technologies.T_PaddedArcherArmor},
		currBuilding = { Entities.PB_Blacksmith3, Technologies.UP2_Blacksmith}
	},
	[Technologies.T_LeatherMailArmor] = {
		Tier = 2,
	},
	[Technologies.T_ChainMailArmor] = {
		Tier = 3, 
		Techs = {Technologies.T_LeatherMailArmor},
		currBuilding = { Entities.PB_Blacksmith2, Technologies.UP1_Blacksmith}
	},
	[Technologies.T_PlateMailArmor] = {
		Tier = 4, 
		Techs = {Technologies.T_ChainMailArmor},
		currBuilding = { Entities.PB_Blacksmith3, Technologies.UP2_Blacksmith}
	},
	[Technologies.T_MasterOfSmithery] = {
		Tier = 3,
		currBuilding = { Entities.PB_Blacksmith2, Technologies.UP1_Blacksmith}
	},
	[Technologies.T_IronCasting] = {
		Tier = 4,
		Techs = {Technologies.MasterOfSmithery},
		currBuilding = { Entities.PB_Blacksmith3, Technologies.UP2_Blacksmith}
	}
} 
SW.BuildingTooltips.UData = { --Data for research tooltips
	[Technologies.UP1_Stables] = {		--Give stable upgrade on tier 3 for free
		Tier = 3,
	},
	[Technologies.UP1_Alchemist] = {	--Weather change on tier 2 possible
		Tier = 2,
		Techs = {Technologies.GT_Alloying}
	},
	[Technologies.UP2_Tower] = {		--Gate cannon towers behind tier 4
		Techs = {Technologies.GT_Chemistry},
	},
	[Technologies.UP1_Market] = {		--Gate markets behind tier 3
		Techs = {Technologies.GT_Printing},
	},
	[Technologies.UP1_Monastery] = {	--Allow lvl2 chapel on tier 2 in order to keep smiths and alchemists satisfied - Necessary?
		Techs = {Technologies.GT_Trading},
	}
} 
SW.BuildingTooltips.TechNames = {			--Gets generated on game start, [technologyId] = name, e.g. [Technologies.B_Residence] = "Wohnhaus"
}
SW.BuildingTooltips.TechFeatures = {		--Gets generated on game start, [technologyId] = lengthyDescription
}
SW.BuildingTooltips.WatchTechs = {}			--Gets generated on game start
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
	for i = 1, 8 do
		for k,v in pairs(SW.BuildingTooltips.MData) do
			Logic.SetTechnologyState(i, k, 0)
		end
		for k,v in pairs(SW.BuildingTooltips.BData) do
			Logic.SetTechnologyState(i, k, 0)
		end
		for k,v in pairs(SW.BuildingTooltips.RData) do
			Logic.SetTechnologyState(i, k, 0)
		end
		for k,v in pairs(SW.BuildingTooltips.UData) do
			Logic.SetTechnologyState(i, k, 0)
		end
	end
	SW.BuildingTooltips.InitWatch()
	-- Tools.GiveResouces( 1, 5000, 5000, 5000, 5000, 5000, 5000)
	SW.BuildingTooltips.FixMilitaryUpgradeButtons()
	SW.BuildingTooltips.FixNeededBuilding()
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
	return retString..SW.BuildingTooltips.ConstructGeneralTooltip(req, _tech)
end
function SW.BuildingTooltips.ConstructTooltipM(_tech)		--creates tooltips for military units
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.MData[_tech]
	return retString..SW.BuildingTooltips.ConstructGeneralTooltip(req, _tech)
end
function SW.BuildingTooltips.ConstructTooltipR(_tech)		--creates tooltips for researches
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.RData[_tech]
	return retString..SW.BuildingTooltips.ConstructGeneralTooltip(req, _tech)
end
function SW.BuildingTooltips.ConstructTooltipU(_tech)		--creates tooltips for upgrades
	local retString = "@color:180,180,180,255  "..SW.BuildingTooltips.TechNames[_tech].." @cr @color:255,255,255,255" --title complete
		.." @color:255,204,51,255 benötigt: @color:255,255,255,255 "
	local req = SW.BuildingTooltips.UData[_tech]
	return retString..SW.BuildingTooltips.ConstructGeneralTooltip(req, _tech)
end
function SW.BuildingTooltips.ConstructGeneralTooltip(req, _tech)
	local retString = ""
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
	if req.currBuilding then
		--local eType = Logic.GetEntityType(GUI.GetSelectedEntity())
		--if eType == req.currBuilding[1] then
		if not first then 
			retString = retString..", "
		end
		retString = retString..SW.BuildingTooltips.TechNames[req.currBuilding[2]]
		first = false
		--end
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
function SW.BuildingTooltips.InitWatch()
	for k,v in pairs(SW.BuildingTooltips.BData) do
		table.insert(SW.BuildingTooltips.WatchTechs, k)
	end
	for k,v in pairs(SW.BuildingTooltips.MData) do
		table.insert(SW.BuildingTooltips.WatchTechs, k)
	end
	for k,v in pairs(SW.BuildingTooltips.RData) do
		table.insert(SW.BuildingTooltips.WatchTechs, k)
	end
	for k,v in pairs(SW.BuildingTooltips.UData) do
		table.insert(SW.BuildingTooltips.WatchTechs, k)
	end
	StartSimpleJob("SW_BuildingTooltips_WatchJob")
end
function SW_BuildingTooltips_WatchJob()
	if not Counter.Tick2("SW_BuildingTooltipsJob", 5) then
		return
	end
	for k,v in pairs(SW.BuildingTooltips.WatchTechs) do
		local req = SW.BuildingTooltips.BData[v] or SW.BuildingTooltips.MData[v] or SW.BuildingTooltips.RData[v] or SW.BuildingTooltips.UData[v]
		if req ~= nil then
			for i = 1, 8 do
				if Logic.GetTechnologyState( i, v) == 0 then	--Technology is locked, can be unlocked
					if SW.BuildingTooltips.IsUnlocked( i, req) then
						--LuaDebugger.Log("Unlocking "..v.." for player "..i)
						if SW.BuildingTooltips.RData[v] then		--Allow
							Logic.SetTechnologyState(i , v, 2) 	
						else										--Research
							Logic.SetTechnologyState(i , v, 3)
							--Logic.SetTechnologyState(i , v, 4)
						end
					end
				end
			end
		end
	end
end
function SW.BuildingTooltips.IsUnlocked( _pId, _req)
	--Check tier
	if _req.Tier then
		if _req.Tier > SW.BuildingTooltips.GetRank(_pId) then
			return false
		end
	end
	--Check techs
	if _req.Techs then
		for k,v in pairs(_req.Techs) do
			if Logic.GetTechnologyState( _pId, v) ~= 4 then
				return false
			end
		end
	end	
	--Check buildings on map
	if _req.Buildings then
		for k,v in pairs(_req.Buildings) do
			if  Logic.GetNumberOfEntitiesOfTypeOfPlayer( _pId, v[1]) < 1 then
				return false
			end
		end
	end
	return true
end
function SW.BuildingTooltips.FixMilitaryUpgradeButtons()	--Fix for vanishing Research_UpgradeX-buttons
	GUIUpdate_SettlersUpgradeButtons = function( _button, _tech)
		--critical are sword, spear and bow as there are multiple upgrade buttons for this type
		--light cav, heavy cav and rifles are easier as there is only one button
		if _tech == Technologies.T_UpgradeHeavyCavalry1 or Technologies.T_UpgradeLightCavalry1 == _tech or _tech == Technologies.T_UpgradeRifle1 then
			local techState = Logic.GetTechnologyState( GUI.GetPlayerID(), _tech)
			if techState == 4 then	--Technology researched - hide button
				XGUIEng.ShowWidget( _button, 0)
			elseif techState == 2 or techState == 3 then --Technology not researched but researchable - show and enable button
				XGUIEng.ShowWidget( _button, 1)
				XGUIEng.DisableButton( _button, 0)
			else --Show button but disable it
				XGUIEng.ShowWidget( _button, 1)
				XGUIEng.DisableButton( _button, 1)	
			end
			return --not need to do further work
		end
		--now the harder part
		--possible states: tech researched, tech ready to research & lower tech researched, tech ready to research but lower tech not researched, not researchable now
		--needed lower tech not researched - hide button
		if not SW.BuildingTooltips.IsLowerTechResearched(_tech) then
			XGUIEng.ShowWidget( _button, 0)
			return
		end
		--possible state: forbidden(not all requirements fulfilled), allowed, researched
		local techState = Logic.GetTechnologyState( GUI.GetPlayerID(), _tech)
		if techState == 4 then	--Already researched - hide button
			XGUIEng.ShowWidget( _button, 0)
		elseif techState == 2 or techState == 3 then	--Researchable, show & enable button
			XGUIEng.ShowWidget( _button, 1)
			XGUIEng.DisableButton( _button, 0)
		else
			XGUIEng.ShowWidget( _button, 1)
			XGUIEng.DisableButton( _button, 1)
		end
	end
end
function SW.BuildingTooltips.IsLowerTechResearched(_tech)
	local lowerTechs = {
		[Technologies.T_UpgradeBow2] = Technologies.T_UpgradeBow1,
		[Technologies.T_UpgradeBow3] = Technologies.T_UpgradeBow2,
		[Technologies.T_UpgradeSpear2] = Technologies.T_UpgradeSpear1,
		[Technologies.T_UpgradeSpear3] = Technologies.T_UpgradeSpear2,
		[Technologies.T_UpgradeSword2] = Technologies.T_UpgradeSword1,
		[Technologies.T_UpgradeSword3] = Technologies.T_UpgradeSword2
	}
	if lowerTechs[_tech] == nil then
		return true --return true as there is no lower tech that might be not researched
	end
	if Logic.GetTechnologyState( GUI.GetPlayerID(), lowerTechs[_tech]) == 4 then
		return true
	end
	return false
end
function SW.BuildingTooltips.FixNeededBuilding()			--Used to give the currBuilding parameter effect, tech can ONLY be researched in this building
	--GUIUpdate_TechnologyButtons("Research_EnhancedGunPowder", Technologies.T_EnhancedGunPowder, Entities.PB_Alchemist2)
	--GUIUpdate_GlobalTechnologiesButtons("Research_Construction", Technologies.GT_Construction, Entities.PB_University1)
	--IsWidgetShown
	--Log: "IsWidgetExisting"
	--Log: "IsButtonDisabled"
	--Log: "IsButtonHighLighted"
	--Log: "IsWidgetShown"
	SW.BuildingTooltips.GUIUpdate_TechnologyButtons = GUIUpdate_TechnologyButtons
	GUIUpdate_TechnologyButtons = function( _button, _tech, _eType)
		SW.BuildingTooltips.GUIUpdate_TechnologyButtons( _button, _tech, _eType) --call original
		if XGUIEng.IsButtonDisabled( _button) == 0 then
			if SW.BuildingTooltips.RData[_tech] then
				if SW.BuildingTooltips.RData[_tech].currBuilding then
					if SW.BuildingTooltips.RData[_tech].currBuilding[1] ~= Logic.GetEntityType(GUI.GetSelectedEntity()) then --wrong building
						XGUIEng.DisableButton( _button, 1)
					end
				end
			end
		end
	end
	SW.BuildingTooltips.GUIUpdate_GlobalTechnologiesButtons = GUIUpdate_GlobalTechnologiesButtons
	GUIUpdate_GlobalTechnologiesButtons = function( _button, _tech, _eType)
		SW.BuildingTooltips.GUIUpdate_GlobalTechnologiesButtons( _button, _tech, _eType)
		if XGUIEng.IsButtonDisabled( _button) == 0 then
			if SW.BuildingTooltips.RData[_tech] then
				if SW.BuildingTooltips.RData[_tech].currBuilding then
					if SW.BuildingTooltips.RData[_tech].currBuilding[1] ~= Logic.GetEntityType(GUI.GetSelectedEntity()) then --wrong building
						XGUIEng.DisableButton( _button, 1)
					end
				end
			end
		end
	end
end

