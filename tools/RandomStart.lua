SW = SW or {}
SW.RandomStartWeights = {
	[Entities.XD_Clay1]		= 500 
	[Entities.XD_ClayPit1]	= 4000
	[Entities.XD_Iron1]		= 300
	[Entities.XD_IronPit1]	= 2000
	[Entities.XD_Stone1]	= 700
	[Entities.XD_StonePit1]	= 5000
	[Entities.XD_Sulfur1]	= 1000
	[Entities.XD_SulfurPit1]= 4000
}
SW.RandomStartAllyWeight = 15000
SW.RandomStartEnemyWeight = 25000
SW.RandomStartRessources = {} --list of all things that increase spawn chance

function SW.EnableRandomStart()
	SW.RandomStartPositions = {};
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
end

function SW.RandomPosForPlayer(_player)
	local div = math.min(table.getn(SW.Players), 4);
	div = math.max(2,div); -- be > 1
	local minDistanceToNextPlayer = (Logic.WorldGetSize() / div)^2;
	local success = false
	local positions = SW.StartPosData
	local sectors = {};
	local _, _, sector;
	for i = 1,table.getn(positions) do
		_, _, sector = S5Hook.GetTerrainInfo(positions[i].X, positions[i].Y);
		table.insert(sectors, sector)
	end;
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
				while(rndSector ~= sector) do
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

function SW.RandomStartEvaluatePos( _x, _y)
	
	
end