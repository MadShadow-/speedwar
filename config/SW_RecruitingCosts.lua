SW = SW or {};
SW.RecruitingCosts = SW.RecruitingCosts or {};
SW.RecruitingCosts.Extra = {
	["PU_Serf"] = {
		[ResourceType.Wood] = 15
	}
};
SW.RecruitingCosts.Military = { --New costs for first half of tech tree
	-- LEADER BOW
	[Entities.PU_LeaderBow1] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 30,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderBow2] = {
		[ResourceType.Gold] = 50,
		[ResourceType.Wood] = 30,
		[ResourceType.Iron] = 00,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderBow3] = {
		[ResourceType.Gold] = 70,
		[ResourceType.Wood] = 30,
		[ResourceType.Iron] = 60,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderBow4] = {
		[ResourceType.Gold] = 80,
		[ResourceType.Wood] = 30,
		[ResourceType.Iron] = 60,
		[ResourceType.Sulfur] = 0
	},
	-- SOLDIER BOW
	[Entities.PU_SoldierBow1] = {
		[ResourceType.Gold] = 30,
		[ResourceType.Wood] = 15,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierBow2] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 15,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierBow3] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 15,
		[ResourceType.Iron] = 15,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierBow4] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 15,
		[ResourceType.Iron] = 30,
		[ResourceType.Sulfur] = 0
	},
	-- LEADER CAVALRY
	[Entities.PU_LeaderCavalry1] = {
		[ResourceType.Gold] = 100,
		[ResourceType.Wood] = 80,
		[ResourceType.Iron] = 20,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderCavalry2] = {
		[ResourceType.Gold] = 120,
		[ResourceType.Wood] = 80,
		[ResourceType.Iron] = 80,
		[ResourceType.Sulfur] = 0
	},
	-- SOLDIER CAVALRY
	[Entities.PU_SoldierCavalry1] = {
		[ResourceType.Gold] = 50,
		[ResourceType.Wood] = 40,
		[ResourceType.Iron] = 10,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierCavalry2] = {
		[ResourceType.Gold] = 60,
		[ResourceType.Wood] = 40,
		[ResourceType.Iron] = 40,
		[ResourceType.Sulfur] = 0
	},
	-- LEADER HEAVY CAVALRY
	[Entities.PU_LeaderHeavyCavalry1] = {
		[ResourceType.Gold] = 160,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 80,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderHeavyCavalry2] = {
		[ResourceType.Gold] = 200,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 100,
		[ResourceType.Sulfur] = 0
	},
	-- SOLDIER HEAVY CAVALRY
	[Entities.PU_SoldierHeavyCavalry1] = {
		[ResourceType.Gold] = 80,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 40,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierHeavyCavalry2] = {
		[ResourceType.Gold] = 100,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 50,
		[ResourceType.Sulfur] = 0
	},
	-- LEADER RIFLE
	[Entities.PU_LeaderRifle1] = {
		[ResourceType.Gold] = 100,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 60
	},
	[Entities.PU_LeaderRifle2] = {
		[ResourceType.Gold] = 100,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 60
	},
	-- SOLDIER RIFLE
	[Entities.PU_SoldierRifle1] = {
		[ResourceType.Gold] = 50,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 30
	},
	[Entities.PU_SoldierRifle2] = {
		[ResourceType.Gold] = 50,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 30
	},
	-- LEADER POLEARM
	[Entities.PU_LeaderPoleArm1] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 30,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderPoleArm2] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 30,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderPoleArm3] = {
		[ResourceType.Gold] = 50,
		[ResourceType.Wood] = 40,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderPoleArm4] = {
		[ResourceType.Gold] = 50,
		[ResourceType.Wood] = 40,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	-- SOLDIER POLEARM
	[Entities.PU_SoldierPoleArm1] = {
		[ResourceType.Gold] = 20,
		[ResourceType.Wood] = 15,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierPoleArm2] = {
		[ResourceType.Gold] = 20,
		[ResourceType.Wood] = 15,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierPoleArm3] = {
		[ResourceType.Gold] = 25,
		[ResourceType.Wood] = 20,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierPoleArm4] = {
		[ResourceType.Gold] = 25,
		[ResourceType.Wood] = 20,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	},
	-- LEADER SWORD
	[Entities.PU_LeaderSword1] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 30,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderSword2] = {
		[ResourceType.Gold] = 40,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 30,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderSword3] = {
		[ResourceType.Gold] = 60,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 60,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_LeaderSword4] = {
		[ResourceType.Gold] = 60,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 60,
		[ResourceType.Sulfur] = 0
	},
	-- SOLDIER SWORD
	[Entities.PU_SoldierSword1] = {
		[ResourceType.Gold] = 20,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 15,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierSword2] = {
		[ResourceType.Gold] = 20,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 15,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierSword3] = {
		[ResourceType.Gold] = 30,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 30,
		[ResourceType.Sulfur] = 0
	},
	[Entities.PU_SoldierSword4] = {
		[ResourceType.Gold] = 30,
		[ResourceType.Wood] = 0,
		[ResourceType.Iron] = 30,
		[ResourceType.Sulfur] = 0
	}
};
