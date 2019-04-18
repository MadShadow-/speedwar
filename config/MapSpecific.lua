SW = SW or {};
SW.MapSpecific = {};
-- loads a config file. in case none is found, uses default values
function SW.MapSpecific.LoadConfig()
	local MapName = tostring(Framework.GetCurrentMapName());
	Script.Load("maps\\user\\speedwar\\mapscripts\\"..MapName..".lua");
	if not SpeedwarConfig then
		Script.Load("Data\\Maps\\ExternalMap\\config.lua")
		if not SpeedwarConfig then
			SW.MapSpecific.NoConfigFound = true;
			SpeedwarConfig = {};
		end
	end
	
	-- start ressources
	SpeedwarConfig.StartRessources = SpeedwarConfig.StartRessources or {};
	SW.MapSpecific.StartRessources = {
		[ResourceType.Gold]   = SpeedwarConfig.StartRessources[ResourceType.Gold]   or 0, 
		[ResourceType.Wood]   = SpeedwarConfig.StartRessources[ResourceType.Wood]   or 700, 
		[ResourceType.Clay]   = SpeedwarConfig.StartRessources[ResourceType.Clay]   or 500,
		[ResourceType.Stone]  = SpeedwarConfig.StartRessources[ResourceType.Stone]  or 0,
		[ResourceType.Iron]   = SpeedwarConfig.StartRessources[ResourceType.Iron]   or 0, 
		[ResourceType.Sulfur] = SpeedwarConfig.StartRessources[ResourceType.Sulfur] or 0,
	};
	
	-- spawn sectors
	SW.MapSpecific.PlayerStartSectors = SpeedwarConfig.PlayerStartSectors or {};
	-- find sectors specified by script entities on map
	local n = 1
	while IsExisting("SpawnSector"..n) do
		table.insert(SW.MapSpecific.PlayerStartSectors, GetPosition("SpawnSector"..n))
		n = n + 1
	end
	-- find sectors if none have been found so far
	if table.getn(SW.MapSpecific.PlayerStartSectors) == 0 then
		SW.MapSpecific.PlayerStartSectors = SW.MapSpecific.GetStartSectors();
	end
	
	-- weather configuration
	SW.MapSpecific.WeatherBaseChances = SpeedwarConfig.WeatherBaseChances or {};
	SW.MapSpecific.WeatherDuration = SpeedwarConfig.WeatherDuration or {};
	
	-- game start callback
	SW.MapSpecific.OnGameStartCallback = SpeedwarConfig.OnGameStartCallback or function() end;
end

-- to be used if there are no sectors found
function SW.MapSpecific.GetStartSectors()
	local NumberOfValidPositionsNecessary = 5000; -- minimum number of sector positions to be a spawn area
	local sectors, values, sectorInfo = {},{},{};
	local worldSize = (Logic.WorldGetSize())/100;
	local _, sector;
	for X = 1, worldSize do
		for Y = 1, worldSize do
			_, _, sector = S5Hook.GetTerrainInfo(X*100, Y*100);
			sector = sector or 0;
			if sector > 0 then
				if not values[sector] then
					values[sector] = 1;
					sectorInfo[sector] = {X=X*100, Y=Y*100};
				else
					values[sector] = values[sector] + 1;
				end
			end
		end
	end
	for sectorId, amount in pairs(values) do
		if amount >= NumberOfValidPositionsNecessary then
			table.insert(sectors, sectorInfo[sectorId]);
		end
	end
	return sectors;
end