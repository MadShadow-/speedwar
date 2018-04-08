SW = SW or {};
SW.AutoBuilder = {};

function SW.AutoBuilder.Init()
	SW.AutoBuilder.BuildingQueue = {};
	SW.AutoBuilder.GameCallback_OnBuildingConstructionComplete = GameCallback_OnBuildingConstructionComplete;
	GameCallback_OnBuildingConstructionComplete = function(_BuildingID, _PlayerID)
		SW.AutoBuilder.GameCallback_OnBuildingConstructionComplete(_BuildingID, _PlayerID);
		local pos = GetPosition(_BuildingID);
		local buildings = {};
		local serfs = {};
		local FindBuildingRange = 10000;
		local AffectedSerfsRange = 10000;
		for eId in S5Hook.EntityIterator(Predicate.InCircle(pos.X,pos.Y,FindBuildingRange), Predicate.IsBuilding(), Predicate.OfPlayer(_PlayerID)) do
			if Logic.IsConstructionComplete(eId) == 0 then
				table.insert(buildings, eId);
			end
		end
		for eId in S5Hook.EntityIterator(Predicate.InCircle(pos.X,pos.Y,AffectedSerfsRange), Predicate.OfType(Entities.PU_Serf), Predicate.OfPlayer(_PlayerID)) do
				table.insert(serfs, eId);
		end
		if table.getn(serfs) <= 0 or table.getn(buildings) <= 0 then
			return
		end
		table.insert(SW.AutoBuilder.BuildingQueue, {serfs, _PlayerID, buildings});
		if not SW.AutoBuilder.SendSerfsDelayedJob then
			SW.AutoBuilder.SendSerfsDelayedJob = StartSimpleHiResJob("SW_AutoBuilder_SendSerfsDelayed");
		end
	end
	
	SW_AutoBuilder_SendSerfsDelayed = function()
		local serfs, playerId, buildings;
		local pos, serfId, sortedBuildings;
		for i = 1, table.getn(SW.AutoBuilder.BuildingQueue) do
			serfs = SW.AutoBuilder.BuildingQueue[i][1];
			playerId = SW.AutoBuilder.BuildingQueue[i][2];
			buildings = SW.AutoBuilder.BuildingQueue[i][3];
			for j = 1, table.getn(buildings) do
				buildings[j] = {buildings[j], GetPosition(buildings[j])};
			end
			for j = 1, table.getn(serfs) do
				serfId = serfs[j];
				if Logic.GetCurrentTaskList(serfId) == "TL_SERF_IDLE" then
					pos = GetPosition(serfId);
					sortedBuildings = SW.AutoBuilder.SortBuildingsAfterRange(pos, buildings);
					for k = 1, table.getn(sortedBuildings) do
						PostEvent.SerfConstructBuilding( serfId, sortedBuildings[k] );
					end
				end
			end
		end
		
		SW.AutoBuilder.BuildingQueue = {};
		SW.AutoBuilder.SendSerfsDelayedJob = nil;
		return true;
	end
end
--SW.AutoBuilder.Init()

function SW.AutoBuilder.SortBuildingsAfterRange(_pos, _buildings)
	local buildingsIndex = {};
	local buildingsToSort = {};
	local distance = 0;
	local buildingsSorted = {};
	for i = 1, table.getn(_buildings) do
		distance = (_pos.X - _buildings[i][2].X)^2 + (_pos.Y - _buildings[i][2].Y)^2;
		buildingsIndex[distance] = _buildings[i][1];
		table.insert(buildingsToSort, distance);
	end
	table.sort(buildingsToSort);
	for i = 1, table.getn(buildingsToSort) do
		buildingsSorted[i] = buildingsIndex[buildingsToSort[i]];
	end
	return buildingsSorted;
end