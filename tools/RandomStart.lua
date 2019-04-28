SW = SW or {}
SW.RandomStart = {}
SW.RandomStartTeamSpawns = {}; -- i use this to let teams spawn together
function SW.EnableRandomStart()
	SW.RandomStartPositions = {};
	-- find all valid sectors
	SW.RandomStart.UpdateValidSectors()
	-- how many spawn positions have to be generated?
	local numOfSpawns = 0
	local idList = {}	-- list of player/team ids for which spawn positions have to be generated
	if SW.IsMultiplayer() then
		if SW.GUI.Rules.SharedSpawn == 0 then
			local isHuman
			for i = 1, SW.MaxPlayers do
				isHuman = XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i);
				if isHuman == 1 then
					numOfSpawns = numOfSpawns + 1
					table.insert( idList, i)
				end
			end
		else
			local team = XNetwork.GameInformation_GetLogicPlayerTeam
			local teamData = {}
			for i = 1, SW.MaxPlayers do
				if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) == 1 then
					local teamId = team(i)
					if teamData[team(i)] == nil then
						teamData[team(i)] = true
						numOfSpawns = numOfSpawns + 1
						table.insert( idList, team(i))
					end
				end
			end
		end
	else
		SW.GUI.Rules.SharedSpawn = 0
		numOfSpawns = 1
		idList = {1}
	end
	-- DEBUG
	if false then
		numOfSpawns = 2
		idList = {}
		for i = 1, numOfSpawns do
			idList[i] = i
		end
		SW.GUI.Rules.SharedSpawn = 0
	end
	-- END DEBUG
	-- now we have a list of ids for which spawn positions have to be generated
	local positions = SW.RandomStart.GetRandomPositions( numOfSpawns)
	if SW.GUI.Rules.SharedSpawn == 0 then
		for k,v in pairs(idList) do
			SW.SpawnPlayerAt( v, positions[k])
			SW.SpawnPlayerMarker( v, positions[k])
		end
	else
		for k,v in pairs(idList) do
			SW.SpawnTeamAt( v, positions[k])
		end
	end
	if true then return end
	if SW.IsMultiplayer() then
		local isHuman;
		if SW.GUI.Rules.SharedSpawn == 0 then
			for i = 1, SW.MaxPlayers do
				isHuman = XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i);
				if isHuman == 1 then
					SW.RandomPosForPlayer(i);
				end;
			end;
		else --team spawn
			local team = XNetwork.GameInformation_GetLogicPlayerTeam
			local teamData = {}
			local teamCount = 0
			for i = 1, SW.MaxPlayers do
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
function SW.RandomStart.UpdateValidSectors()
	SW.RandomStartValidSectors = {}
	local sector
	for i = 1,table.getn(SW.MapSpecific.PlayerStartSectors) do
		_, _, sector = S5Hook.GetTerrainInfo(SW.MapSpecific.PlayerStartSectors[i].X, SW.MapSpecific.PlayerStartSectors[i].Y);
		table.insert(SW.RandomStartValidSectors, sector)
	end;
end

-- some mad stuff
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
			SW.SpawnPlayerAt( _player, {X=ranX,Y=ranY})
		end 
	end
end

-- returns _numOfSpawns spawns for players
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
-- spawns a team at given position; CREATES MARKERS
function SW.SpawnTeamAt( _teamId, _p)
	local team = XNetwork.GameInformation_GetLogicPlayerTeam
	if team(GUI.GetPlayerID()) == _teamId then
		GUI.CreateMinimapMarker( _p.X, _p.Y, 0);
	else
		GUI.CreateMinimapMarker( _p.X, _p.Y,3);
	end
	for k = 1, table.getn(SW.Players) do
		local pId = SW.Players[k]
		if team(pId) == _teamId then
			SW.SpawnPlayerAt( pId, _p)
		end
	end
end
-- spawns a player at a given position, optional arg '_serfCount'; DOES NOT CREATE MARKERS
function SW.SpawnPlayerAt( _pId, _p, _serfCount)
	if _serfCount == nil then 
		_serfCount = 16 
	end
	local _,_,sectorID = S5Hook.GetTerrainInfo( _p.X, _p.Y)
	local newRanX, newRanY;
	local rndSector = -1;
	local newEnt, oldEnt
	for i = 1, _serfCount do
		oldEnt = newEnt;
		while(rndSector ~= sectorID) do
			newRanX = _p.X+math.random(-500,500);
			newRanY = _p.Y+math.random(-500,500);
			_, _, rndSector = S5Hook.GetTerrainInfo(newRanX, newRanY);
		end
		newEnt = AI.Entity_CreateFormation( _pId, Entities.PU_Serf, 0, 0, newRanX, newRanY, 0, _p.X, _p.Y, 0)
		Logic.EntityLookAt(newEnt, oldEnt)
	end
	if GUI.GetPlayerID() == _pId then
		Camera.ScrollSetLookAt( _p.X, _p.Y);
	end
end
-- creates a marker at given position, color depending on diplomacy to _pId
function SW.SpawnPlayerMarker( _pId, _p)
	if GUI.GetPlayerID() == _pId then
		GUI.CreateMinimapMarker( _p.X, _p.Y, 0);
	else
		if Logic.GetDiplomacyState( GUI.GetPlayerID(), _pId) == Diplomacy.Hostile then
			GUI.CreateMinimapMarker( _p.X, _p.Y, 3);
		else
			GUI.CreateMinimapMarker( _p.X, _p.Y, 0);
		end
	end
end

-- new spawn algo
function SW.RandomStart.GetRandomPositions( _n)
	local t1 = XGUIEng.GetSystemTime()
	local tries = 25*_n
	local posList, bestPos, score
	local bestScore = -1
	local x,y
	for i = 1, tries do
		-- Get some nice positions
		posList = {}
		for j = 1, _n do
			x, y = SW.RandomStart.GetPosition()
			table.insert( posList, { X = x, Y = y})
		end
		score = SW.RandomStart.RateList( posList)
		if score > bestScore then
			bestScore = score
			bestPos = {}
			for k,v in pairs(posList) do
				bestPos[k] = {X = v.X, Y = v.Y}
			end
		end
	end
	LuaDebugger.Log("StartAlgTime: "..(XGUIEng.GetSystemTime() - t1))
	return bestPos
end
-- rates a list of spawns, high score is good
function SW.RandomStart.RateList( _list)
	-- following assumptions to rate a list:
	-- the world border is bad -> points near the border will be rated badly
	-- points close to each other are bad -> will be rated badly aswell
	
	-- calculate a sum of penalties, return 1/sum
	-- some config stuff
	local borderPenalty = 1		-- how bad is spawning near border? penalty = borderPenalty*weight(dis)
	local posPenalty = 1		-- how bad is spawning near someone else? penalty = posPenalty*weight(dis)
	
	-- actual code
	local worldSize = Logic.WorldGetSize()
	local disToCenter, disToBorder, disToPlayer
	local points = 0
	local n = table.getn(_list)
	for i = 1, n do
		-- get distance to world border
		disToCenter = SW.RandomStart.GetDistance( _list[i], {X = worldSize/2, Y = worldSize/2})
		disToBorder = worldSize/2 - disToCenter
		points = points + borderPenalty*SW.RandomStart.Weight(disToBorder)
		for j = i+1, n do
			disToPlayer = SW.RandomStart.GetDistance( _list[i], _list[j])
			points = points + posPenalty*SW.RandomStart.Weight( disToPlayer)
		end
	end
	return 1/points
end
-- gives a given distance a weight. Small distances should have a high weight
function SW.RandomStart.Weight( _v)
	-- weight = 2^(-v / dis)
	local dis = 5000
	return math.exp( - _v/5000 * 0.6931)
end
function SW.RandomStart.GetDistance(_p1, _p2)
	return math.sqrt( (_p1.X - _p2.X)*(_p1.X - _p2.X) + (_p1.Y - _p2.Y)*(_p1.Y - _p2.Y))
end
-- returns a position in a valid sector
function SW.RandomStart.GetPosition()
	local x,y,sectorID,sectorValid
	local sectorList = SW.RandomStartValidSectors
	local sectorListN = table.getn(sectorList)
	local worldSize = Logic.WorldGetSize()
	--LuaDebugger.Break()
	for i = 1, 50 do
		x = math.random()*worldSize
		y = math.random()*worldSize
		_, _, sectorID = S5Hook.GetTerrainInfo( x, y)
		sectorValid = false
		for i = 1, sectorListN do
			if sectorID == sectorList[i] then
				sectorValid = true
				break
			end
		end
		if sectorValid then
			return x,y
		end
	end
	return worldSize/2, worldSize/2
end