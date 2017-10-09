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
	["PB_Residence1"] = { [ResourceType.Wood] = 50, [ResourceType.Clay] = 75  },
	["PB_Farm1"] = { [ResourceType.Wood] = 100, [ResourceType.Clay] = 75  },
	["PB_Brickworks1"] = { [ResourceType.Wood] = 125  },
	["PB_Sawmill1"] = { [ResourceType.Clay] = 125 },
	["PB_Market1"] = { [ResourceType.Wood] = 100, [ResourceType.Stone] = 200  },
	["PB_GenericMine"] = { [ResourceType.Wood] = 100, [ResourceType.Clay] = 50  },
	["PB_University1"] = { [ResourceType.Wood] = 300, [ResourceType.Clay] = 400  },
	["PB_Barracks1"] = { [ResourceType.Wood] = 200, [ResourceType.Clay] = 150  },
	["PB_Archery1"] = { [ResourceType.Wood] = 150, [ResourceType.Clay] = 150  },
	["PB_Tower1"] = { [ResourceType.Wood] = 250, [ResourceType.Stone] = 350  },
	--["PB_Blacksmith1"] = { [ResourceType.Clay] = 200, [ResourceType.Stone] = 150  },
	["PB_Blacksmith1"] = { },
	["PB_Market1"] = { [ResourceType.Wood] = 150, [ResourceType.Clay] = 150  },
	["PB_Monastery1"] = { [ResourceType.Wood] = 700, [ResourceType.Clay] = 550  },
};

SW.BuildingUpgradeCosts = {
	["PB_Farm1"] = { [ResourceType.Wood] = 50, [ResourceType.Clay] = 50  },
	["PB_Farm2"] = { [ResourceType.Wood] = 100, [ResourceType.Stone] = 50  },
	["PB_Residence1"] = { [ResourceType.Wood] = 50, [ResourceType.Clay] = 50  },
	["PB_Residence2"] = { [ResourceType.Wood] = 75, [ResourceType.Clay] = 75  },
	["PB_University1"] = { [ResourceType.Gold] = 500, [ResourceType.Clay] = 250, [ResourceType.Stone] = 300  },
};