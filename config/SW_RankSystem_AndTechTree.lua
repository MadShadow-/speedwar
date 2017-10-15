SW = SW or {}
SW.BuildingTooltips = SW.BuildingTooltips or {}
SW.RankSystem = SW.RankSystem or {}

SW.RankSystem.RankColors = {
	"@color:139,69,19",
	"@color:255,255,51",
	"@color:255,153,51",
	"@color:255,0,51",
};
SW.BuildingTooltips.RankNames = {
	"Siedler",
	"Krieger",
	"Feldherr",
	"Eroberer"
}
SW.RankSystem.RankNames = {
	SW.RankSystem.RankColors[1]..": "..SW.BuildingTooltips.RankNames[1],
	SW.RankSystem.RankColors[2]..": "..SW.BuildingTooltips.RankNames[2],
	SW.RankSystem.RankColors[3]..": "..SW.BuildingTooltips.RankNames[3],
	SW.RankSystem.RankColors[4]..": "..SW.BuildingTooltips.RankNames[4]
}
SW.RankSystem.RankThresholds = {
	500,
	2000,
	8000
}
SW.RankSystem.KillPoints = 5		-- Points per settler killed
SW.RankSystem.LosePoints = 1		-- Points per settler lost
SW.RankSystem.BuildingPoints = 75	-- Points per building destroyed
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
	[Technologies.UP1_Farm] = {
		Techs = {Technologies.GT_Construction},
	},
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
	},
	[Technologies.UP1_Tower] = {
		Tier = 3,
		Techs = {Technologies.GT_StandingArmy}
	}
} 