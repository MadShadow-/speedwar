SW = SW or {}
SW.PillagingRate = 75 --25% of building costs get refunded when destroyed
SW.ListOfPillageBuildings = {
	"PB_Alchemist1",
	"PB_Alchemist2",
	"PB_Archery1",
	"PB_Archery2",
	"PB_Bank1",
	"PB_Bank2",
	"PB_Barracks1",
	"PB_Barracks2",
	"PB_Beautification01",
	"PB_Beautification02",
	"PB_Beautification03",
	"PB_Beautification04",
	"PB_Beautification05",
	"PB_Beautification06",
	"PB_Beautification07",
	"PB_Beautification08",
	"PB_Beautification09",
	"PB_Beautification10",
	"PB_Beautification11",
	"PB_Beautification12",
	"PB_Blacksmith1",
	"PB_Blacksmith2",
	"PB_Blacksmith3",
	"PB_Brickworks1",
	"PB_Brickworks2",
	"PB_Farm1",
	"PB_Farm2",
	"PB_Farm3",
	"PB_Foundry1",
	"PB_Foundry2",
	"PB_GunsmithWorkshop1",
	"PB_GunsmithWorkshop2",
	"PB_Market1",
	"PB_Market2",
	"PB_MasterBuilderWorkshop",
	"PB_Monastery1",
	"PB_Monastery2",
	"PB_Monastery3",
	"PB_PowerPlant1",
	"PB_Residence1",
	"PB_Residence2",
	"PB_Residence3",
	"PB_Sawmill1",
	"PB_Sawmill2",
	"PB_Stable1",
	"PB_Stable2",
	"PB_StoneMason1",
	"PB_StoneMason2",
	"PB_Tavern1",
	"PB_Tavern2",
	"PB_Tower1",
	"PB_Tower2",
	"PB_Tower3",
	"PB_University1",
	"PB_University2",
	"PB_VillageCenter1",
	"PB_VillageCenter2",
	"PB_VillageCenter3",
	"PB_WeatherTower1"
}
SW.ListOfPillageBuildingsDowngrades = {  --value is one lvl below key, val = "" -> Basic
	["PB_Alchemist1"] = "",
	["PB_Alchemist2"] = "PB_Alchemist1",
	["PB_Archery1"] = "",
	["PB_Archery2"] = "PB_Archery1",
	["PB_Bank1"] = "",
	["PB_Bank2"] = "PB_Bank1",
	["PB_Barracks1"] = "",
	["PB_Barracks2"] = "PB_Barracks1",
	["PB_Beautification01"] = "",
	["PB_Beautification02"] = "",
	["PB_Beautification03"] = "",
	["PB_Beautification04"] = "",
	["PB_Beautification05"] = "",
	["PB_Beautification06"] = "",
	["PB_Beautification07"] = "",
	["PB_Beautification08"] = "",
	["PB_Beautification09"] = "",
	["PB_Beautification10"] = "",
	["PB_Beautification11"] = "",
	["PB_Beautification12"] = "",
	["PB_Blacksmith1"] = "",
	["PB_Blacksmith2"] = "PB_Blacksmith1",
	["PB_Blacksmith3"] = "PB_Blacksmith2",
	["PB_Brickworks1"] = "",
	["PB_Brickworks2"] = "PB_Brickworks1",
	["PB_Farm1"] = "",
	["PB_Farm2"] = "PB_Farm1",
	["PB_Farm3"] = "PB_Farm2",
	["PB_Foundry1"] = "",
	["PB_Foundry2"] = "PB_Foundry1",
	["PB_GunsmithWorkshop1"] = "",
	["PB_GunsmithWorkshop2"] = "PB_GunsmithWorkshop1",
	["PB_Market1"] = "",
	["PB_Market2"] = "PB_Market1",
	["PB_MasterBuilderWorkshop"] = "",
	["PB_Monastery1"] = "",
	["PB_Monastery2"] = "PB_Monastery1",
	["PB_Monastery3"] = "PB_Monastery2",
	["PB_PowerPlant1"] = "",
	["PB_Residence1"] = "",
	["PB_Residence2"] = "PB_Residence1",
	["PB_Residence3"] = "PB_Residence2",
	["PB_Sawmill1"] = "",
	["PB_Sawmill2"] = "PB_Sawmill1",
	["PB_Stable1"] = "",
	["PB_Stable2"] = "PB_Stable1",
	["PB_StoneMason1"] = "",
	["PB_StoneMason2"] = "PB_StoneMason1",
	["PB_Tavern1"] = "",
	["PB_Tavern2"] = "PB_Tavern1",
	["PB_Tower1"] = "",
	["PB_Tower2"] = "PB_Tower1",
	["PB_Tower3"] = "PB_Tower2",
	["PB_University1"] = "",
	["PB_University2"] = "PB_University1",
	["PB_VillageCenter1"] = "",
	["PB_VillageCenter2"] = "PB_VillageCenter1",
	["PB_VillageCenter3"] = "PB_VillageCenter2",
	["PB_WeatherTower1"] = ""
}

function SW.PillageCreateCostTable()
	--SW.GetConstructionCosts( _eType)
	--SW.GetUpgradeCosts( _eType)
	SW.PillageEntityTypeCost = {}
	for k,v in pairs(SW.ListOfPillageBuildings) do --v == EntityTypeName
		local costTable = {}
		local currETypeName = v
		while SW.ListOfPillageBuildingsDowngrades[currETypeName] ~= "" do --Kein Grundgebäude
			local currCost = SW.GetUpgradeCosts( Entities[SW.ListOfPillageBuildingsDowngrades[currETypeName]])
			currETypeName = SW.ListOfPillageBuildingsDowngrades[currETypeName]
			for k1,v1 in pairs(currCost) do
				costTable[k1] = costTable[k1] or 0
				costTable[k1] = costTable[k1] + v1
			end
		end
		local currCost = SW.GetConstructionCosts( Entities[currETypeName])
		for k1,v1 in pairs( currCost) do
			costTable[k1] = costTable[k1] or 0
			costTable[k1] = costTable[k1] + v1
		end
		SW.PillageEntityTypeCost[Entities[v]] = costTable
	end
end
