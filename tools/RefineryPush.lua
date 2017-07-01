--Refinery Push


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

--[[
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
]]
SW = SW or {}

SW.RefineryPush = {}
SW.RefineryPush.Config = {		--Sets amount of ressources generated per refinery tick
	[Entities.PB_Blacksmith1] = 50,
	[Entities.PB_Blacksmith2] = 50,
	[Entities.PB_Blacksmith3] = 50,
	[Entities.PB_Brickworks1] = 50,
	[Entities.PB_Brickworks2] = 50,
	[Entities.PB_Sawmill1] = 75,
	[Entities.PB_Sawmill2] = 75,
	[Entities.PB_Alchemist1] = 15,
	[Entities.PB_Alchemist2] = 15,
	[Entities.PB_Bank1] = 15,
	[Entities.PB_Bank2] = 25,
	[Entities.PB_StoneMason1] = 25,
	[Entities.PB_StoneMason2] = 25
}
SW.RefineryPush.ConfigWorker = {
	[Entities.PU_BrickMaker] = 25,
	[Entities.PU_Alchemist] = 25,
	[Entities.PU_BrickMaker] = 25,
	[Entities.PU_Coiner] = 25,
	[Entities.PU_Gunsmith] = 25,
	[Entities.PU_Sawmillworker] = 25,
	[Entities.PU_Smith] = 25,
	[Entities.PU_Stonecutter] = 25,
	[Entities.PU_Treasurer] = 25
}
SW.RefineryPush.ConfigMines = {
	[Entities.PB_ClayMine1] = 10,
	[Entities.PB_ClayMine2] = 10,
	[Entities.PB_ClayMine3] = 10,
	[Entities.PB_IronMine1] = 10,
	[Entities.PB_IronMine2] = 10,
	[Entities.PB_IronMine3] = 10,
	[Entities.PB_StoneMine1] = 10,
	[Entities.PB_StoneMine2] = 10,
	[Entities.PB_StoneMine3] = 10,
	[Entities.PB_SulfurMine1] = 10,
	[Entities.PB_SulfurMine2] = 10,
	[Entities.PB_SulfurMine3] = 10
}
--S5Hook.GetRawMem(9002416)[0][16][Entities.PB_IronMine1*8+5][2][4]:SetInt(50)
--> S5Hook.GetRawMem(9002416)[0][16][Entities.PB_IronMine1*8+5][2][0]:GetInt()
--7821340
function SW.RefineryPush.Init()
	for k,v in pairs(SW.RefineryPush.Config) do
		if S5Hook.GetRawMem(9002416)[0][16][k*8+5][2][0]:GetInt() == 7818276 then
			S5Hook.GetRawMem(9002416)[0][16][k*8+5][2][5]:SetFloat(v)
		else
			Message("SW.RefineryPush: Failed to set value for "..Logic.GetEntityTypeName(k))
		end
	end
	for k,v in pairs(SW.RefineryPush.ConfigWorker) do
		if S5Hook.GetRawMem(9002416)[0][16][k*8+5][4][0]:GetInt() == 7809936 then
			S5Hook.GetRawMem(9002416)[0][16][k*8+5][4][24]:SetInt(v)
		else
			Message("SW.RefineryPush: Failed to set value for "..Logic.GetEntityTypeName(k))
		end
	end
	for k,v in pairs(SW.RefineryPush.ConfigMines) do
		if S5Hook.GetRawMem(9002416)[0][16][k*8+5][2][0]:GetInt() == 7821340 then
			S5Hook.GetRawMem(9002416)[0][16][k*8+5][2][4]:SetInt(v)
		else
			Message("SW.RefineryPush: Failed to set value for "..Logic.GetEntityTypeName(k))
		end
	end
end