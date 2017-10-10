SW = SW or {}
SW.ECat = { --Own EntityCategories as native EntityCategories are incomplete
	Bow = {
		"PU_LeaderBow1",
		"PU_LeaderBow2",
		"PU_LeaderBow3",
		"PU_LeaderBow4",
		"PU_SoldierBow1",
		"PU_SoldierBow2",
		"PU_SoldierBow3",
		"PU_SoldierBow4",
	},
	Cannon = {
		"PV_Cannon1",
		"PV_Cannon2",
		"PV_Cannon3",
		"PV_Cannon4"
	},
	CavalryHeavy = {
		"PU_LeaderHeavyCavalry1",
		"PU_LeaderHeavyCavalry2",
		"PU_SoldierHeavyCavalry1",
		"PU_SoldierHeavyCavalry2"
	},
	CavalryLight = {
		"PU_LeaderCavalry1",
		"PU_LeaderCavalry2",
		"PU_SoldierCavalry1",
		"PU_SoldierCavalry2",
	},
	Hero = {
		"PU_Hero10",
		"PU_Hero11",
		"PU_Hero1c",
		"PU_Hero2",
		"PU_Hero3",
		"PU_Hero4",
		"PU_Hero5",
		"PU_Hero5_Outlaw",  --Kleine Beförderung ;)
		"PU_Hero6",
		"CU_Evil_Queen",
		"CU_BlackKnight",
		"CU_Barbarian_Hero",
		"CU_Mary_de_Mortfichet"
	},
	Rifle = {
		"PU_LeaderRifle1",
		"PU_LeaderRifle2",
		"PU_SoldierRifle1",
		"PU_SoldierRifle2"
	},
	Scout = {
		"PU_Scout"
	},
	Serf = {
		"PU_Serf",
		"PU_BattleSerf"
	},
	Spear = {
		"PU_LeaderPoleArm1",
		"PU_LeaderPoleArm2",
		"PU_LeaderPoleArm3",
		"PU_LeaderPoleArm4",
		"PU_SoldierPoleArm1",
		"PU_SoldierPoleArm2",
		"PU_SoldierPoleArm3",
		"PU_SoldierPoleArm4"
	},
	Sword = {
		"PU_LeaderSword1",
		"PU_LeaderSword2",
		"PU_LeaderSword3",
		"PU_LeaderSword4",
		"PU_SoldierSword1",
		"PU_SoldierSword2",
		"PU_SoldierSword3",
		"PU_SoldierSword4"
	},
	Thief = {
		"PU_Thief",
	},
	Worker = {
		"PU_Alchemist",
		"PU_BattleSerf",
		"PU_BrickMaker",
		"PU_Coiner",
		"PU_Engineer",
		"PU_Farmer",
		"PU_Gunsmith",
		"PU_MasterBuilder",
		"PU_Miner",
		"PU_Priest",
		"PU_Sawmillworker",
		"PU_Scholar",
		"PU_Smelter",
		"PU_Smith",
		"PU_Stonecutter",
		"PU_TavernBarkeeper",
		"PU_Trader",
		"PU_Treasurer"
	}
}
-- k is a string
function SW.IsEntityTypeInCategory(_eType, k)
	if SW.ECat[k] == nil then return 0; end
	for key,v in pairs(SW.ECat[k]) do
		if _eType == Entities[v] then
			return 1
		end
	end
	return 0
end
SW.BaseMovementspeed = { --Sets BaseMS by EntityCategory; Highest Value wins
	["Bow"] = 320,
	["Cannon"] = 180,  --Values for cannons: 240, 260, 220, 180
	["CavalryHeavy"] =  440,
	["CavalryLight"] = 520,
	["Hero"] = 400,
	["Rifle"] = 320,
	["Scout"] = 350,
	["Serf"]  = 400,
	["Spear"] = 360,
	["Sword"] = 360,
	["Thief"] = 400,
	["Worker"] = 320
}
for k,v in pairs(SW.BaseMovementspeed) do
	SW.BaseMovementspeed[k] = v*2
end
SW.MovementspeedTechInfluence = { --Balancechanges here!
	["T_BetterChassis"] = {
		Influenced = {"Cannon"},
		SumPreFactor = 0,
		Factor = 1.0,
		SumPostFactor = 30
	},
	["T_BetterTrainingArchery"]= {
		Influenced = {"Bow", "Rifle"},
		SumPreFactor = 0,
			Factor = 1.0,
		SumPostFactor = 40
	},
	["T_BetterTrainingBarracks"]= {
		Influenced = {"Sword", "Spear"},
		SumPreFactor = 0,
		Factor = 1.0,
		SumPostFactor = 30
	},
	["T_Shoeing"]= {
		Influenced = {"CavalryHeavy", "CavalryLight"},
		SumPreFactor = 0,
		Factor = 1.0,
		SumPostFactor = 50
	},
	["T_Shoes"]= {
		Influenced = {"Serf", "Worker"},
		SumPreFactor = 20,
		Factor = 1.0,
		SumPostFactor = 0
	},
	["T_SuperTechnology"]= {
		Influenced = {"Sword"},
		SumPreFactor = 10,
		Factor = 5.0,
		SumPostFactor = 50
	}
}



--[[ List of all supported ETypes
"PU_Alchemist",
"PU_BattleSerf",
"PU_BrickMaker",
"PU_Coiner",
"PU_Engineer",
"PU_Farmer",
"PU_Gunsmith",
"PU_Hero10",
"PU_Hero11",
"PU_Hero1c",
"PU_Hero2",
"PU_Hero3",
"PU_Hero4",
"PU_Hero5",
"PU_Hero5_Outlaw",
"PU_Hero6",
"PU_LeaderBow1",
"PU_LeaderBow2",
"PU_LeaderBow3",
"PU_LeaderBow4",
"PU_LeaderCavalry1",
"PU_LeaderCavalry2",
"PU_LeaderHeavyCavalry1",
"PU_LeaderHeavyCavalry2",
"PU_LeaderPoleArm1",
"PU_LeaderPoleArm2",
"PU_LeaderPoleArm3",
"PU_LeaderPoleArm4",
"PU_LeaderRifle1",
"PU_LeaderRifle2",
"PU_LeaderSword1",
"PU_LeaderSword2",
"PU_LeaderSword3",
"PU_LeaderSword4",
"PU_MasterBuilder",
"PU_Miner",
"PU_Priest",
"PU_Sawmillworker",
"PU_Scholar",
"PU_Scout",
"PU_Serf",
"PU_Smelter",
"PU_Smith",
"PU_SoldierBow1",
"PU_SoldierBow2",
"PU_SoldierBow3",
"PU_SoldierBow4",
"PU_SoldierCavalry1",
"PU_SoldierCavalry2",
"PU_SoldierHeavyCavalry1",
"PU_SoldierHeavyCavalry2",
"PU_SoldierPoleArm1",
"PU_SoldierPoleArm2",
"PU_SoldierPoleArm3",
"PU_SoldierPoleArm4",
"PU_SoldierRifle1",
"PU_SoldierRifle2",
"PU_SoldierSword1",
"PU_SoldierSword2",
"PU_SoldierSword3",
"PU_SoldierSword4",
"PU_Stonecutter",
"PU_TavernBarkeeper",
"PU_Thief",
"PU_Trader",
"PU_Treasurer",
"PV_Cannon1",
"PV_Cannon2",
"PV_Cannon3",
"PV_Cannon4",
"CU_Evil_Queen",
"CU_BlackKnight",
"CU_Barbarian_Hero",
"CU_Mary_de_Mortfichet",
]]
