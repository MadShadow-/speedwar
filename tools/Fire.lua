--[[
	Fire Mod
	
	This Addition will burn houses as soon they drop below 40% hp and will then
	start to burn down.
	Once it reaches 30% hp it will once try to inflict nearby buildings which will slowly start burning.
	The lower the hp drops the faster the fire will destroy the building.
	
	This can be prevented by:
	- Winter
	- Rain
	- nearby fountains
	
	Also if serfs repair a building and it does regain 60% of its health, it stops burn
]]
SW = SW or {};
SW.FireMod = {}
function SW.FireMod.Init()
	Message("FireMod Activated");
	
	-- config
	SW.FireMod.Config = {
		InflictBuildingOnAttackThreshold = 0.5;
		InflictOthersBuildingsOnBurnThreshold = 0.25;
		StopBurnThreshold = 0.6; -- musst be >= InflictThreshold
		InflictBuildingsRange = 2000; -- range in scm
		DamageMissingHealthPerTick = 0.01; -- = 1% of missing health per damage tick
		ChanceBurningBuildingInflictsOthers = 10; -- chance <10% on each tick
	};
	
	-- add any entity type which should be excluded from beeing burned
	SW.FireMod.UnvincibleBuildings = {};
	
	SW.FireMod.BurningBuildings = {};
	for playerId = 1,8 do
		SW.FireMod.BurningBuildings[playerId] = {};
	end
	
	-- how to find out whether an house has to be taken i list?
	-- -> on each a attack - check building hp
	
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "SW_FireMod_Condition_InflictBuilding", "SW_FireMod_Action_InflictBuilding", 1);
	Trigger.RequestTrigger(Events.LOGIC_EVENT_WEATHER_STATE_CHANGED , "", "SW_FireMod_Action_WeatherChanged", 1);
end

function SW_FireMod_Condition_InflictBuilding()
	local target = Event.GetEntityID2();
	if Logic.GetWeatherState() ~= 1 then
		-- no burning in winter and rain
		return false;
	end
	if Logic.IsBuilding(target) == 0 then
		-- only inflicht buildings
		return false;
	end
	if Logic.IsConstructionComplete() == 0 then
		-- don't inflict any unfinished buildings
		return false;
	end
	if SW.FireMod.UnvincibleBuildings[Logic.GetEntityType(target)] then
		return false;
	end
	if Logic.GetEntityHealth(target)/Logic.GetEntityMaxHealth(target) > SW.FireMod.Config.InflictBuildingOnAttackThreshold then
		return false;
	end
	return true;
end

function SW_FireMod_Action_InflictBuilding()
	local target = Event.GetEntityID2();
	if not SW.FireMod.BurningBuildings[GetPlayer(target)][target] then
		SW.FireMod.BurningBuildings[GetPlayer(target)][target] = {InflictedOthers = false;};
		if JobIsRunning(SW.FireMod.ControlJob) == 0 then
			SW.FireMod.ControlJob = StartSimpleJob("SW_FireMod_ControlJob_BurnBuildings");
		end
	end
end

function SW_FireMod_Action_WeatherChanged()
	if Logic.GetWeatherState() > 1 then
		for playerId = 1,8 do
			EndJob(SW.FireMod.ControlJob);
			SW.FireMod.BurningBuildings[playerId] = {};
		end
	end
end

function SW_FireMod_ControlJob_BurnBuildings()
	local HP;
	for playerId = 1,8 do
		for buildingId, t in pairs(SW.FireMod.BurningBuildings[playerId]) do
			HP = Logic.GetEntityHealth(buildingId)/Logic.GetEntityMaxHealth(buildingId)
			if HP < SW.FireMod.Config.StopBurnThreshold then
				SW.FireMod.DamageBuilding(buildingId, HP);
			else
				SW.FireMod.BurningBuildings[playerId][buildingId] = nil;
			end
		end
	end
end

function SW.FireMod.TryInflictBuildingsInArea(_buildingId)
	local pos = GetPosition(_buildingId);
	local buildingMaxHealth, buildingHealth;
	for eID in S5Hook.EntityIterator(Predicate.InCircle(pos.X, pos.Y, SW.FireMod.Config.InflictBuildingsRange), Predicate.IsBuilding()) do
		if Logic.IsConstructionComplete(eID) == 1 and eID ~= _buildingId then
			-- inflict a building with burn -> health less 50%
			buildingHealth = Logic.GetEntityHealth(eID);
			buildingMaxHealth = Logic.GetEntityMaxHealth(eID);
			if buildingHealth/buildingMaxHealth >= 0.5 then
				Logic.HurtEntity(eID, buildingHealth - (buildingMaxHealth/2) + 1);
			end
			SW.FireMod.BurningBuildings[GetPlayer(eID)][eID] = {};
		end
	end
end

function SW.FireMod.DamageBuilding(_buildingId, _HPInPercent)
	local buildingHealth = Logic.GetEntityHealth(_buildingId);
	local buildingMaxHealth = Logic.GetEntityMaxHealth(_buildingId);
	
	-- building inflicts only once -> check if inflicted already and hp below threshold
	if not SW.FireMod.BurningBuildings[GetPlayer(_buildingId)][_buildingId].InflictedOthers and
    _HPInPercent < SW.FireMod.Config.InflictOthersBuildingsOnBurnThreshold then
		-- chance in percentage to inflict is given in config
		local inflictOtherBuilding = math.random(1, 100);
		if inflictOtherBuilding < SW.FireMod.Config.ChanceBurningBuildingInflictsOthers then
			SW.FireMod.BurningBuildings[GetPlayer(_buildingId)][_buildingId].InflictedOthers = true;
			SW.FireMod.TryInflictBuildingsInArea(_buildingId);
		end
	end
	
	-- chance that a burn ticks is 50% in the beginning
	-- the less hp the building got, the higher is the chance for a burn tick
	local burn = math.random(_HPInPercent*100,100);
	if burn > 50 then
		--log("reached ".. burn .. " between ".. _HPInPercent*100 .." and 100 ");
		return;
	end
	-- Damage: 1% of missing health per Tick
	local damage = SW.FireMod.Config.DamageMissingHealthPerTick * (buildingMaxHealth - buildingHealth);
	--log("Burn building ".._buildingId.." with " .. damage .. " damage! MaxHealth("..buildingMaxHealth..")".." Health("..buildingHealth..")");
	if damage < 0 then
		damage = 0;
	end
	Logic.HurtEntity(_buildingId, damage);
end




