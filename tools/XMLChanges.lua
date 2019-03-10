SW = SW or {}

SW.XMLChanges = {}
function SW.XMLChanges.DoChanges()
	-- Refinery push
	for k,v in pairs(SW.XMLChanges.RefPush.Config) do
		SW.SetRefinedPerTick( k, v)
	end
	for k,v in pairs(SW.XMLChanges.RefPush.ConfigWorker) do
		SW.SetWorkerTransportAmount( k, v)
	end
	for k,v in pairs(SW.XMLChanges.RefPush.ConfigMines) do
		SW.SetAmountToMine( k, v)
	end
	-- Make outposts more resilient against thieves
	SW.SetKegFactor( Entities.PB_Outpost1, 0.1)
	-- building costs
	for buildingType, costTable in pairs(SW.BuildingConstructionCosts) do
		SW.SetConstructionCosts( Entities[buildingType], costTable);
	end
	-- upgrade costs
	for buildingType, costTable in pairs(SW.BuildingUpgradeCosts) do
		SW.SetUpgradeCosts( Entities[buildingType], costTable);
	end
	-- building health
	for buildingType, maxHealth in pairs(SW.BuildingMaxHealth) do
		SW.SetBuildingMaxHealth( Entities[buildingType], maxHealth)
	end
	-- exploration range
	for k,v in pairs( SW.AfflictedTowerTypes) do
		SW.SetExploration( v, SW.NewTowerRange)
	end
	-- recruiting costs
	for entityType, costTable in pairs(SW.RecruitingCosts.Extra) do
		SW.SetRecruitingCosts( Entities[entityType], costTable);
	end
	for eType, costTable in pairs(SW.RecruitingCosts.Military) do
		SW.SetRecruitingCosts( eType, costTable)
	end
	--			FASTER BUILDING
	-- First change construction time
	for k,v in Entities do
		if SW.FasterBuildConstructionTimeChange[v] then		--construction speed of eType should be changed
			local time = SW.FasterBuildConstruction[v]
			if time == nil then
				time = SW.FasterBuildFactor * SW.GetConstructionTime( v)
			end
			SW.SetConstructionTime( v, time)
		end
	end
	-- Now change upgrade time
	for k,v in Entities do
		if SW.FasterBuildUpgradeTimeChange[v] then		--construction speed of eType should be changed
			local time = SW.FasterBuildUpgrade[v]
			if time == nil then
				time = SW.FasterBuildFactor * SW.GetUpgradeTime( v)
			end
			SW.SetUpgradeTime( v, time)
		end
	end
	-- recruiting time
	local types = {
		Entities.PB_Barracks1,
		Entities.PB_Barracks2,
		Entities.PB_Archery1,
		Entities.PB_Archery2,
		Entities.PB_Stable1,
		Entities.PB_Stable2
	}
	for k,v in pairs(types) do
		SW.SetRecruitingTime( v, 20)
	end	
	-- make walls die after one bomb; KegFactor = 1 equals 70% MaxHP damage
	SW.SetKegFactor( Entities.XD_WallStraight, 2)
	SW.SetKegFactor( Entities.XD_WallStraightGate, 2)
	SW.SetKegFactor( Entities.XD_WallStraightGate_Closed, 2)
	-- LKAV BUFFS
	local lvl1Dmg = 10
	local lvl1Bonus = 0
	local lvl1Range = 2800
	local lvl2Dmg = 18
	local lvl2Bonus = 0
	local lvl2Range = 3200
	-- Lvl1 leader
	SW.SetLeaderDamage( Entities.PU_LeaderCavalry1, lvl1Dmg)
	SW.SetLeaderRandomDamageBonus( Entities.PU_LeaderCavalry1, lvl1Bonus)
	SW.SetLeaderMaxRange( Entities.PU_LeaderCavalry1, lvl1Range)
	SW.SetLeaderAutoRange( Entities.PU_LeaderCavalry1, lvl1Range)
	SW.SetSettlerExploration( Entities.PU_LeaderCavalry1, lvl1Range/100)
	-- Lvl2 leader
	SW.SetLeaderDamage( Entities.PU_LeaderCavalry2, lvl2Dmg)
	SW.SetLeaderRandomDamageBonus( Entities.PU_LeaderCavalry2, lvl2Bonus)
	SW.SetLeaderMaxRange( Entities.PU_LeaderCavalry2, lvl2Range)
	SW.SetLeaderAutoRange( Entities.PU_LeaderCavalry2, lvl2Range)
	SW.SetSettlerExploration( Entities.PU_LeaderCavalry2, lvl2Range/100)
	-- Lvl1 soldier
	SW.SetSoldierDamage( Entities.PU_SoldierCavalry1, lvl1Dmg)
	SW.SetSoldierRandomDamageBonus( Entities.PU_SoldierCavalry1, lvl1Bonus)
	SW.SetSoldierMaxRange( Entities.PU_SoldierCavalry1, lvl1Range + 200)
	SW.SetSettlerExploration( Entities.PU_SoldierCavalry1, lvl1Range/100 + 2)
	-- Lvl2 soldier
	SW.SetSoldierDamage( Entities.PU_SoldierCavalry2, lvl2Dmg)
	SW.SetSoldierRandomDamageBonus( Entities.PU_SoldierCavalry2, lvl2Bonus)
	SW.SetSoldierMaxRange( Entities.PU_SoldierCavalry2, lvl2Range + 200)
	SW.SetSettlerExploration( Entities.PU_SoldierCavalry2, lvl2Range/100 + 2)
	-- Make dem leibis quicker
	SW.SetSerfExtractionAmount(Entities.XD_ResourceTree, 3);
	-- Change residences and farms
	SW.SetPlacesProvided( Entities.PB_Farm1, 5)
	SW.SetPlacesProvided( Entities.PB_Farm2, 10)
	SW.SetPlacesProvided( Entities.PB_Farm3, 15)
	SW.SetPlacesProvided( Entities.PB_Residence1, 4)
	SW.SetPlacesProvided( Entities.PB_Residence2, 8)
	SW.SetPlacesProvided( Entities.PB_Residence3, 12)
	-- Make traders faster, 100 Ress dealt with per tick( default: 45)
	SW.SetGlobalMarketSpeed( 10)
	-- Make cannons worse against units and better against buildings
	SW.SetLeaderAoERange(Entities.PV_Cannon3, 150)
	SW.SetLeaderAoERange(Entities.PV_Cannon4, 200)
	-- universtiy technology speed changed
	local time;
	for name, id in pairs(Technologies) do
		if string.find(name, "GT_", 1, true) then
			time = SW.GetTechnologyTimeToResearch(id) * 0.5;
			SW.SetTechnologyTimeToResearch( id, time);
		end
	end
end
--Refinery Push
--[[

-- Make refining buildings more effective by increasing amount of ressources gained per worker tick
-- Also change amount of material a worker is carrying home in order to use up raw materials faster

--S5Hook.GetRawMem(9002416)[0][16][Entities.PB_Brickworks1*8+5][1][14]:GetInt() --Amount of ressources gained per tick
--S5Hook.GetEntityMem(131806)[31][1][3][5]:GetFloat()) 
--S5Hook.GetEntityMem(131806)[31][1][3][0]:GetInt()
--7818276
--> S5Hook.GetRawMem(9002416)[0][16][23*8+5][2][5]:GetFloat()
--10
--Start of first beh table: --PU_BrickMaker
-- S5Hook.GetRawMem(9002416)[0][16][23*8+5][2][0]:GetInt()

> for i = 0, 25 do LuaDebugger.Log(i.." "..S5Hook.GetRawMem(9002416)[0][16][Entities.PU_BrickMaker*8+5][4][i]:GetInt()) end
Anprechbar mit S5Hook.GetRawMem(9002416)[0][16][_eType*8+5][4][i]:GetInt() bzw GetFloat()
-- Ints
Log: "0 7809936"			-- GGL::CWorkerBehaviorProps
Log: "7 30000"				-- WorkWaitUntil
Log: "10 2000"				-- EatWait
Log: "13 3000"				-- RestWait
Log: "17 -50"				-- WorkTimeChangeWork
Log: "21 100"				-- WorkTimeMaxChangeFarm
Log: "22 400"				-- WorkTimeMaxChangeResidence
Log: "24 5"					-- TransportAmount

-- Floats
Log: "16 1.5"				-- AmountResearched
Log: "18 0.69999998807907"	-- WorkTimeChangeFarm
Log: "19 0.5"				-- WorkTimeChangeResidence
Log: "20 0.10000000149012"	-- WorkTimeChangeCamp????
Log: "23 0.20000000298023"	-- ExhaustedWorkMotivationMalus
Log: "28 0.10000000149012"	-- WorkTimeChangeCamp????
--]]
SW.XMLChanges.RefPush = {}
SW.XMLChanges.RefPush.Config = {		--Sets amount of ressources generated per refinery tick
	[Entities.PB_Blacksmith1] = 6,
	[Entities.PB_Blacksmith2] = 9,
	[Entities.PB_Blacksmith3] = 12,
	[Entities.PB_Brickworks1] = 6,
	[Entities.PB_Brickworks2] = 12,
	[Entities.PB_Sawmill1] = 8,
	[Entities.PB_Sawmill2] = 16,
	[Entities.PB_Alchemist1] = 8,
	[Entities.PB_Alchemist2] = 12,
	[Entities.PB_Bank1] = 4,
	[Entities.PB_Bank2] = 6,
	[Entities.PB_StoneMason1] = 6,
	[Entities.PB_StoneMason2] = 9
}
SW.XMLChanges.RefPush.ConfigWorker = {		--Amount of ressources worker "steals" before work
	[Entities.PU_Alchemist] = 8,
	[Entities.PU_BrickMaker] = 6,
	[Entities.PU_Coiner] = 4,
	[Entities.PU_Gunsmith] = 4,
	[Entities.PU_Sawmillworker] = 8,
	[Entities.PU_Smith] = 6,
	[Entities.PU_Stonecutter] = 6,
	[Entities.PU_Treasurer] = 4
}
SW.XMLChanges.RefPush.ConfigMines = {
	[Entities.PB_ClayMine1] = 16,
	[Entities.PB_ClayMine2] = 20,
	[Entities.PB_ClayMine3] = 24,
	[Entities.PB_IronMine1] = 16,
	[Entities.PB_IronMine2] = 20,
	[Entities.PB_IronMine3] = 24,
	[Entities.PB_StoneMine1] = 16,
	[Entities.PB_StoneMine2] = 20,
	[Entities.PB_StoneMine3] = 24,
	[Entities.PB_SulfurMine1] = 16,
	[Entities.PB_SulfurMine2] = 20,
	[Entities.PB_SulfurMine3] = 24
}