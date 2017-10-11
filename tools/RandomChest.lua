-- RANDOM CHESTS :D

SW = SW or {}

SW.RandomChest = {}
SW.RandomChest.Number = 15 --Number of random chests generated
SW.RandomChest.OpeningRange = 500
SW.RandomChest.Action =  {}
SW.RandomChest.Keys = {}
SW.RandomChest.ListOfChests = {}
function SW.RandomChest.Init()
	for k,v in pairs(SW.RandomChest.Action) do
		table.insert(SW.RandomChest.Keys, k)
	end
	for i = 1, SW.RandomChest.Number do
		SW.RandomChest.GenerateChest()
	end
	StartSimpleJob("SW_RandomChest_Job")
end
function SW.RandomChest.GenerateChest()
	--Same procedure as random start
	local success = false
	local positions = {
		{ X = 36000, Y = 28500 },
	};
	local sectors = {};
	local _, _, sector;
	for i = 1,table.getn(positions) do
		_, _, sector = S5Hook.GetTerrainInfo(positions[i].X, positions[i].Y);
		table.insert(sectors, sector)
	end;
	local worldSize = Logic.WorldGetSize()
	local ranX, ranY, sectorID
	local valid;
	while not success do
		ranX = math.random()*worldSize
		ranY = math.random()*worldSize
		_, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY);
		valid = false --invalid until proven otherwise
		for j = 1, table.getn(sectors) do
			if sectors[j] == sectorID then
				valid = true
				break;
			end
		end
		if valid then
			success = true
			SW.RandomChest.GenerateAtPos( ranX, ranY)
		end 
	end
end
function SW.RandomChest.GenerateAtPos( _x, _y)
	--Message("Chest at X: ".._x.." Y: ".._y)
	local key = SW.RandomChest.Keys[math.random(table.getn(SW.RandomChest.Keys))]
	--Message(key)
	local chestId = Logic.CreateEntity( Entities.XD_ChestClose, _x, _y, 0, 0)
	table.insert(SW.RandomChest.ListOfChests, {_x, _y, key, chestId})
end
function SW.RandomChest.ChestFound( _x, _y)
	for i = 1, 8 do
		for eId in S5Hook.EntityIterator(Predicate.OfPlayer(i), Predicate.InCircle( _x, _y, SW.RandomChest.OpeningRange)) do
			return i
		end
	end
	return 0
end
function SW_RandomChest_Job()
	for i = table.getn(SW.RandomChest.ListOfChests), 1, -1 do
		local v = SW.RandomChest.ListOfChests[i]
		local player = SW.RandomChest.ChestFound( v[1], v[2])
		if player ~= 0 then
			SW.RandomChest.OnChestFound( v, player)
			DestroyEntity( v[4])
			local stoneId = Logic.CreateEntity( Entities.XD_Rock1, v[1], v[2], 0, 0)
			Logic.SetModelAndAnimSet( stoneId, Models.XD_ChestOpen)
			table.remove( SW.RandomChest.ListOfChests, i)
		end
	end
end
function SW.RandomChest.OnChestFound( _data, _pId)
	if GUI.GetPlayerID() == _pId then
		Message("Ihr habt eine Truhe gefunden!")
		--Message(_data[3])
		GUI.ScriptSignal( _data[1], _data[2], 2, 0 )
		Sound.PlayGUISound( Sounds.Misc_Chat, 0 )
	end
	SW.RandomChest.Action[_data[3]]( _pId, _data[1], _data[2])
end
function SW.RandomChest.Action.EternalFire( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war Feuer!")
	end
	Logic.SetModelAndAnimSet( Logic.CreateEntity(Entities.XD_Rock1, _x, _y, 0, 0), Models.Effects_XF_HouseFireMedium)
end
function SW.RandomChest.Action.Stone( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war ein Stein!")
	end
	local eId = Logic.CreateEntity(Entities.XD_Rock1, _x, _y, 0, 0)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(25)
end
function SW.RandomChest.Action.Sonic( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war Sonic!")
	end
	local eId = Logic.CreateEntity( Entities.CU_AggressiveWolf, _x, _y, 0, _pId)
	SW.SetMovementspeed( eId, 1600)
end
function SW.RandomChest.Action.Tree( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war ein Baum!")
	end
	local eId = Logic.CreateEntity(Entities.XD_ResourceTree, _x, _y, 0, 0)
	Logic.SetModelAndAnimSet( eId, Models.XD_Fir1)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(5)
	S5Hook.GetEntityMem( eId)[67]:SetInt(1000)
	--Message( eId)
	--for i = 0, 100 do
	--	LuaDebugger.Log(i.." "..S5Hook.GetEntityMem(eId)[i]:GetInt())
	--end
end
function SW.RandomChest.Action.SolarEclipse( _pId, _x, _y)		--TODO
	if GUI.GetPlayerID() == _pId then
		Message("Darin war nix!")
	end
end

--Ideen:
--	SONIC
--	Ein eisiger Winter
--	Eine Läuterung?
--	Ewiges Feuer
--	Konfetti
--	Ein Stein
--	Endraläer Krustenbrot
--	Eine Sonnenfinsternis
--	Ein Baum
--	Ein Ring, sie zu knechten, sie alle zu finden, ins Dunkel zu treiben und ewig zu binden