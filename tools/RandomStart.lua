SW = SW or {}
SW.RandomStartWeights = {
	[Entities.XD_Clay1]		= 500, 
	[Entities.XD_ClayPit1]	= 4000,
	[Entities.XD_Iron1]		= 300,
	[Entities.XD_IronPit1]	= 2000,
	[Entities.XD_Stone1]	= 700,
	[Entities.XD_StonePit1]	= 5000,
	[Entities.XD_Sulfur1]	= 1000,
	[Entities.XD_SulfurPit1]= 4000
}
--SW.RandomStartAllyWeight = 5000
--SW.RandomStartEnemyWeight = 15000
SW.RandomStartPlayerWeight = 24000
SW.RandomStartEntropyWeight = 5000
SW.RandomStartRessources = {} --list of all things that increase spawn chance
SW.RandomStartEntropyPos = {}
SW.RandomStartUseNewAlgorithm = false
SW.RandomStartTeamSpawns = {}; -- i use this to let teams spawn together
function SW.EnableRandomStart()
	SW.RandomStartPositions = {};
	SW.RandomStartValidSectors = {}
	local sector
	for i = 1,table.getn(SW.MapSpecific.PlayerStartSectors) do
		_, _, sector = S5Hook.GetTerrainInfo(SW.MapSpecific.PlayerStartSectors[i].X, SW.MapSpecific.PlayerStartSectors[i].Y);
		table.insert(SW.RandomStartValidSectors, sector)
	end;
	if SW.IsMultiplayer() then
		local isHuman;
		if SW.GUI.Rules.SharedSpawn == 0 then
			for i = 1, 8 do
				isHuman = XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i);
				if isHuman == 1 then
					-- TODO remove spectators.
					SW.RandomPosForPlayer(i);
				end;
			end;
		else --team spawn
			local team = XNetwork.GameInformation_GetLogicPlayerTeam
			local teamData = {}
			local teamCount = 0
			for i = 1, 8 do
				if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) == 1 then
					local teamId = team(i)
					if teamData[team(i)] == nil then
						teamData[team(i)] = true
						teamCount = teamCount + 1
					end
				end
			end
			local positions = SW.GetRandomPositions( teamCount)
			local posIndex = 1
			for k,v in pairs(teamData) do
				SW.SpawnTeamAt( k, positions[posIndex])
				posIndex = posIndex + 1
			end
		end
	else
		SW.RandomPosForPlayer(1);
	end;
end

function SW.RandomPosForPlayer(_player)
	local div = math.min(table.getn(SW.Players), 4);
	div = math.max(2,div); -- be > 1
	local minDistanceToNextPlayer = (Logic.WorldGetSize() / div)^2;
	local success = false
	local sectors = SW.RandomStartValidSectors
	local worldSize = Logic.WorldGetSize()
	local ranX, ranY, sectorID
	local sectorValid, minDistanceValid;
	local spawnAttempts = 0;
	while not success do
		-- infinite loop protection
		spawnAttempts = spawnAttempts + 1;
		if spawnAttempts > 1000 then
			-- reset reserved start positon table to enable a free spawn
			SW.RandomStartPositions = {};
		end
		ranX = math.random()*worldSize
		ranY = math.random()*worldSize
		-- falls die neue zufalls pos zu nahe an einer bestehenden start pos liegt muss neu gewürfelt werden
		minDistanceValid = true;
		for i = 1,table.getn(SW.RandomStartPositions) do
			if ((SW.RandomStartPositions[i].X-ranX)^2 + (SW.RandomStartPositions[i].Y-ranY)^2) < minDistanceToNextPlayer then
				minDistanceValid = false;
				break;
			end
		end
		_, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY);
		sectorValid = false --invalid until proven otherwise
		for j = 1, table.getn(sectors) do
			if sectors[j] == sectorID then
				--LuaDebugger.Log("sector valid")
				sectorValid = true
				break;
			end
		end
		if sectorValid and minDistanceValid then
			success = true
			if GUI.GetPlayerID() == _player then
				GUI.CreateMinimapMarker(ranX,ranY,0);
			else
				if Logic.GetDiplomacyState(GUI.GetPlayerID(),_player) == Diplomacy.Hostile then
					GUI.CreateMinimapMarker(ranX,ranY,3);
				else
					GUI.CreateMinimapMarker(ranX,ranY,0);
				end
			end
			table.insert(SW.RandomStartPositions,{X=ranX,Y=ranY});
			local newEnt, oldEnt, newRanX, newRanY;
			local rndSector = -1;
			for i = 1, 8 do
				oldEnt = newEnt;
				while(rndSector ~= sectorID) do
					newRanX = ranX+math.random(-200,200);
					newRanY = ranY+math.random(-200,200);
					_, _, rndSector = S5Hook.GetTerrainInfo(ranX, ranY);
				end
				newEnt = AI.Entity_CreateFormation(_player, Entities.PU_Serf, 0, 0, newRanX, newRanY, 0, ranX, ranY, 0)
				Logic.EntityLookAt(newEnt, oldEnt);
				if GUI.GetPlayerID() == _player then
					Camera.ScrollSetLookAt(ranX,ranY);
				end
			end
		end 
	end
end
function SW.GetRandomPositions(_numOfSpawns)
	local div = math.min(_numOfSpawns, 4);
	div = math.max(2,div); -- be > 1
	local minDistanceToNextPlayer = (Logic.WorldGetSize() / div)^2;
	local success = false
	local sectors = {}
	for i = 1,table.getn(SW.MapSpecific.PlayerStartSectors) do
		_, _, sector = S5Hook.GetTerrainInfo(SW.MapSpecific.PlayerStartSectors[i].X, SW.MapSpecific.PlayerStartSectors[i].Y);
		table.insert(sectors, sector)
	end;
	local worldSize = Logic.WorldGetSize()
	local ranX, ranY, sectorID
	local sectorValid, minDistanceValid;
	local spawnAttempts = 0;
	local retTable = {}
	for i = 1, _numOfSpawns do
		spawnAttempts = 0;
		--LuaDebugger.Log(i)
		while not success do
			-- infinite loop protection
			spawnAttempts = spawnAttempts + 1;
			ranX = math.random()*worldSize
			ranY = math.random()*worldSize
			--LuaDebugger.Log("X: "..ranX.." Y: "..ranY)
			--LuaDebugger.Log(spawnAttempts)
			-- falls die neue zufalls pos zu nahe an einer bestehenden start pos liegt muss neu gewürfelt werden
			minDistanceValid = true;
			for j = 1,table.getn(retTable) do
				if ((retTable[j].X-ranX)^2 + (retTable[j].Y-ranY)^2) < minDistanceToNextPlayer*(1000-spawnAttempts)/1000 then
					minDistanceValid = false;
					--LuaDebugger.Log("minDistance hurt "..spawnAttempts)
					break;
				end
			end
			_, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY);
			--LuaDebugger.Log("Sektor: "..sectorID)
			sectorValid = false --invalid until proven otherwise
			for j = 1, table.getn(sectors) do
				if sectors[j] == sectorID then
					sectorValid = true
					--LuaDebugger.Log("sector valid")
					break;
				end
			end
			if sectorValid and minDistanceValid then
				--LuaDebugger.Log("found "..ranX.." "..ranY)
				table.insert( retTable, {X = ranX, Y = ranY})
				break
			end 
		end
	end
	return retTable
end
function SW.SpawnTeamAt( _teamId, _p)
	local team = XNetwork.GameInformation_GetLogicPlayerTeam
	if team(GUI.GetPlayerID()) == _teamId then
		GUI.CreateMinimapMarker( _p.X, _p.Y, 0);
	else
		GUI.CreateMinimapMarker( _p.X, _p.Y,3);
	end
	local _,_,sectorID = S5Hook.GetTerrainInfo( _p.X, _p.Y)
	for k = 1, table.getn(SW.Players) do
		local pId = SW.Players[k]
		if team(pId) == _teamId then
			local newRanX, newRanY;
			local rndSector = -1;
			for i = 1, 8 do
				oldEnt = newEnt;
				while(rndSector ~= sectorID) do
					newRanX = _p.X+math.random(-500,500);
					newRanY = _p.Y+math.random(-500,500);
					_, _, rndSector = S5Hook.GetTerrainInfo(newRanX, newRanY);
				end
				AI.Entity_CreateFormation( pId, Entities.PU_Serf, 0, 0, newRanX, newRanY, 0, _p.X, _p.Y, 0)
			end
			if GUI.GetPlayerID() == pId then
				Camera.ScrollSetLookAt( _p.X, _p.Y);
			end
		end
	end
end

-- TODO
function SW.RandomStartPlacePlayer()
	if GUI.GetPlayerID() == _player then
		GUI.CreateMinimapMarker(ranX,ranY,0);
	else
		if Logic.GetDiplomacyState(GUI.GetPlayerID(),_player) == Diplomacy.Hostile then
			GUI.CreateMinimapMarker(ranX,ranY,3);
		else
			GUI.CreateMinimapMarker(ranX,ranY,0);
		end
	end
	table.insert(SW.RandomStartPositions,{X=ranX,Y=ranY});
	local newEnt, oldEnt, newRanX, newRanY;
	local rndSector = -1;
	for i = 1, 8 do
		oldEnt = newEnt;
		while(rndSector ~= sectorID) do
			newRanX = ranX+math.random(-200,200);
			newRanY = ranY+math.random(-200,200);
			_, _, rndSector = S5Hook.GetTerrainInfo(ranX, ranY);
		end
		newEnt = AI.Entity_CreateFormation(_player, Entities.PU_Serf, 0, 0, newRanX, newRanY, 0, ranX, ranY, 0)
		Logic.EntityLookAt(newEnt, oldEnt);
		if GUI.GetPlayerID() == _player then
			Camera.ScrollSetLookAt(ranX,ranY);
		end
	end
end

--Fixed starts
function SW.DoFixedPositions()
	if SW.IsMultiplayer() then
		local isHuman;
		for i = 1, 8 do
			isHuman = XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i);
			if isHuman == 1 then
				-- TODO remove spectators.
				SW.FixedPosForPlayer(i);
			end;
		end;
	else
		SW.FixedPosForPlayer(1);
	end;
end
function SW.FixedPosForPlayer( _pId)
	local data = SpeedwarConfig.PlayerStartPos[_pId]
	if type(data) ~= "table" then
		data = GetPosition(data)
	end
	SW.CreatePlayerAtPos( _pId, data.X, data.Y)
end
function SW.CreatePlayerAtPos( _pId, _x, _y)
	if SW.IsMultiplayer() and SW.GUI.Teamspawn == 1 then
		if SW.GetTeamSpawn(_pId, _x, _y) then
			_x, _y = SW.GetTeamSpawn(_pId);
		end
	end
	if GUI.GetPlayerID() == _pId then
		GUI.CreateMinimapMarker( _x, _y, 0);
	else
		if Logic.GetDiplomacyState(GUI.GetPlayerID(), _pId) == Diplomacy.Hostile then
			GUI.CreateMinimapMarker(_x,_y,3);
		else
			GUI.CreateMinimapMarker(_x,_y,0);
		end
	end
	table.insert(SW.RandomStartPositions,{X=_x,Y=_y});
	local newEnt, oldEnt, newRanX, newRanY;
	local rndSector = -1;
	for i = 1, 8 do
		oldEnt = newEnt;
		while(rndSector ~= sectorID) do
			newRanX = _x+math.random(-200,200);
			newRanY = _y+math.random(-200,200);
			_, _, rndSector = S5Hook.GetTerrainInfo(_x, _y);
		end
		newEnt = AI.Entity_CreateFormation(_pId, Entities.PU_Serf, 0, 0, newRanX, newRanY, 0, _x, _y, 0)
		Logic.EntityLookAt(newEnt, oldEnt);
		if GUI.GetPlayerID() == _pId then
			Camera.ScrollSetLookAt(_x,_y);
		end
	end
end

function SW.GetTeamSpawn(_playerId, _x, _y)
	local team = XNetwork.GameInformation_GetPlayerTeam(_playerId);
	if SW.RandomStartTeamSpawns[team] then
		return SW.RandomStartTeamSpawns[team].X, SW.RandomStartTeamSpawns[team].Y;
	end
	SW.RandomStartTeamSpawns[team] = {X=_x,Y=_y};
end

