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
function SW.EnableRandomStart()
	for k,v in pairs(SW.RandomStartWeights) do
		for eId in S5Hook.EntityIterator(Predicate.OfType(k)) do
			local pos = GetPosition( eId)
			table.insert( SW.RandomStartRessources, {X = pos.X, Y = pos.Y, value = v})
		end
	end
	SW.RandomStartPositions = {};
	SW.RandomStartValidSectors = {}
	local sector
	for i = 1,table.getn(SW.StartPosData) do
		_, _, sector = S5Hook.GetTerrainInfo(SW.StartPosData[i].X, SW.StartPosData[i].Y);
		table.insert(SW.RandomStartValidSectors, sector)
	end;
	for i = 1, 8 do
		table.insert( SW.RandomStartEntropyPos, SW.RandomStartGeneratePos())
	end
	if SW.IsMultiplayer() then
		local isHuman;
		for i = 1, 8 do
			isHuman = XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i);
			if isHuman == 1 then
				-- TODO remove spectators.
				SW.RandomPosForPlayer(i);
			end;
		end;
	else
		SW.RandomPosForPlayer(1);
	end;
	SW.RandomStartNapo()
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

function SW.RandomStartNapo()
	if true then return end
	SW.RandomStartPositions = {}
	for i = 1, 8 do
		local sPos = SW.RandomStartGenerateStartForPlayer( i)
		GUI.CreateMinimapMarker( sPos.X, sPos.Y, 1)
		table.insert(SW.RandomStartPositions, sPos)
	end
end

function SW.RandomStartGenerateStartForPlayer( _pId)
	local highScore = nil
	local startPos = nil
	for i = 1, 20 do
		local pos = SW.RandomStartGeneratePos()
		local score = SW.RandomStartEvaluatePos( pos.X, pos.Y, _pId)
		LuaDebugger.Log( score.." "..pos.X.." "..pos.Y)
		highScore = highScore or score-1
		if highScore < score then
			highScore = score
			startPos = pos
		end
	end
	return startPos
end
function SW.RandomStartGeneratePos()
	local worldSize = Logic.WorldGetSize()
	local ranX, ranY, sectorID
	while true do
		ranX = math.random()*worldSize
		ranY = math.random()*worldSize
		_, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY)
		for j = 1, table.getn(SW.RandomStartValidSectors) do
			if SW.RandomStartValidSectors[j] == sectorID then
				sectorValid = true
				return {X = ranX, Y = ranY}
			end
		end
	end
end
function SW.RandomStartEvaluatePos( _x, _y, _pId)
	local score = 0
	for k,v in pairs(SW.RandomStartRessources) do
		score = score + SW.RandomStartCalcRealWeight( v.value, SW.RandomStartGetDistance( {X = _x, Y = _y}, v))
	end
	for k,v in pairs(SW.RandomStartEntropyPos) do
		score = score - SW.RandomStartCalcRealWeight( SW.RandomStartEntropyWeight, SW.RandomStartGetDistance( {X = _x, Y = _y}, v))
	end
	for k,v in pairs(SW.RandomStartPositions) do
		score = score - SW.RandomStartCalcRealWeight( SW.RandomStartPlayerWeight, SW.RandomStartGetDistance( {X = _x, Y = _y}, v))
	end
	return score
end
function SW.RandomStartCalcRealWeight( _weight, _dis)
	return math.max(0, _weight - _dis)
end
function SW.RandomStartGetDistance( _pos1, _pos2)
	return math.sqrt( (_pos1.X-_pos2.X)^2 + (_pos1.Y - _pos2.Y)^2)
end