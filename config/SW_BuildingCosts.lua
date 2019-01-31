--[[
##	ResourceType.Gold
##	ResourceType.Clay
##	ResourceType.Wood
##	ResourceType.Stone
##	ResourceType.Iron
##	ResourceType.Sulfur
]]
SW = SW or {};
SW.BuildingConstructionCosts = {
	["PB_Residence1"] = { [ResourceType.Wood] = 50, [ResourceType.Clay] = 50  },
	["PB_Farm1"] = { [ResourceType.Wood] = 75, [ResourceType.Clay] = 50  },
	["PB_Brickworks1"] = { [ResourceType.Wood] = 125  },
	["PB_Sawmill1"] = { [ResourceType.Clay] = 125 },
	["PB_Market1"] = { [ResourceType.Wood] = 100, [ResourceType.Stone] = 200  },
	["PB_GenericMine"] = { [ResourceType.Wood] = 100, [ResourceType.Clay] = 50  },
	["PB_University1"] = { [ResourceType.Wood] = 300, [ResourceType.Clay] = 400  },
	["PB_Barracks1"] = { [ResourceType.Wood] = 200, [ResourceType.Clay] = 150  },
	["PB_Archery1"] = { [ResourceType.Wood] = 150, [ResourceType.Clay] = 150  },
	["PB_Tower1"] = { [ResourceType.Wood] = 200, [ResourceType.Stone] = 150  },
	--["PB_Blacksmith1"] = { [ResourceType.Clay] = 200, [ResourceType.Stone] = 150  },
	["PB_Blacksmith1"] = { },
	["PB_Beautification12"] = {},
	["PB_Market1"] = { [ResourceType.Wood] = 150, [ResourceType.Clay] = 150  },
	["PB_Monastery1"] = { [ResourceType.Wood] = 600, [ResourceType.Clay] = 500  },
	["PB_Alchemist1"] = { [ResourceType.Wood] = 200, [ResourceType.Stone] = 200  },
	["PB_StoneMason1"] = { [ResourceType.Wood] = 150, [ResourceType.Clay] = 200  },
	["PB_Bank1"] = { [ResourceType.Wood] = 200, [ResourceType.Clay] = 400, [ResourceType.Stone] = 400},
	["PB_WeatherTower1"] = { [ResourceType.Wood] = 300, [ResourceType.Sulfur] = 900, [ResourceType.Stone] = 200},
	["PB_PowerPlant1"] = { [ResourceType.Clay] = 600, [ResourceType.Wood] = 300, [ResourceType.Stone] = 400},
};

SW.BuildingUpgradeCosts = {
	["PB_Farm1"] = { [ResourceType.Wood] = 50, [ResourceType.Clay] = 50  },
	["PB_Farm2"] = { [ResourceType.Wood] = 100, [ResourceType.Clay] = 150  },
	["PB_Residence1"] = { [ResourceType.Wood] = 50, [ResourceType.Clay] = 50  },
	["PB_Residence2"] = { [ResourceType.Wood] = 100, [ResourceType.Clay] = 150  },
	["PB_University1"] = { [ResourceType.Gold] = 500, [ResourceType.Clay] = 250, [ResourceType.Stone] = 300  },
	["PB_Tower1"] = { [ResourceType.Wood] = 300, [ResourceType.Stone] = 400  },
	["PB_Tower2"] = { [ResourceType.Sulfur] = 400, [ResourceType.Stone] = 500  },
	["PB_Monastery1"] = { [ResourceType.Gold] = 500, [ResourceType.Clay] = 700, [ResourceType.Stone] = 500},
	["PB_Monastery2"] = { [ResourceType.Gold] = 1000, [ResourceType.Clay] = 1200, [ResourceType.Stone] = 700}
};