--[[
	Fire Mod
	
	This Addition will burn houses as soon they drop below 40% hp and will then
	start to burn down.
	Once it reaches 30% hp it will once try to inflict nearby buildings which will slowly start burning.
	The lower the hp drops the faster the fire will destroy the building.
	
	This can be prevented by:
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
		InflictBuildingOnAttackThreshold = 0.5; -- at 50% hp building starts burn
		InflictOthersBuildingsOnBurnThreshold = 0.5; -- at 25% hp it starts inflicting surrounding buildings
		StopBurnThreshold = 0.6; -- musst be >= InflictThreshold - stops burning at 60% hp when getting repaired
		InflictBuildingsRange = 2000; -- range in scm, in which closeby buildings are inflicted by fire
		DamageMissingHealthPerTick = 0.03; -- 0.01 = 1% of missing health per damage tick
		ChanceBurningBuildingInflictsOthers = 10; -- chance to inflict another building on each damage tick => 10 => chance < 10%
		FountainSaveBuildingsRange = 4000;
	};
	
	-- add any entity type which should be excluded from beeing burned
	SW.FireMod.InvincibleBuildings = {};
	
	SW.FireMod.BurningBuildings = {};
	for playerId = 1,8 do
		SW.FireMod.BurningBuildings[playerId] = {};
	end
	
	-- Fountains simply protect surrounding buildings
	SW.FireMod.SaveBuildings = {};
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_FireMod_Condition_FountainOrBuildingCreated", "SW_FireMod_Action_FountainOrBuildingCreated", 1);
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_FireMod_Condition_FountainOrBuildingDestroyed", "SW_FireMod_Action_FountainOrBuildingDestroyed", 1);
	SW.FireMod.GameCallback_OnBuildingConstructionComplete = GameCallback_OnBuildingConstructionComplete;
	GameCallback_OnBuildingConstructionComplete = function(_entity, _playerId)
		local eType = Logic.GetEntityType(_entity);
		local pos = GetPosition(_entity);
		if eType == Entities.PB_Beautification02 or eType == Entities.PB_Beautification08 then
			for eID in S5Hook.EntityIterator(Predicate.InCircle(pos.X, pos.Y, SW.FireMod.Config.FountainSaveBuildingsRange), Predicate.IsBuilding()) do
				-- make sure its not a construction site
				if string.find(Logic.GetEntityTypeName(Logic.GetEntityType(eID)), "PB", 1, true) then
					if SW.FireMod.SaveBuildings[eID] then
						table.insert(SW.FireMod.SaveBuildings[eID], _entity);
					else
						SW.FireMod.SaveBuildings[eID] = {_entity};
					end
				end
			end
		end
		SW.FireMod.GameCallback_OnBuildingConstructionComplete(_entity, _playerId);
	end
	function ViewX()
		local pos;
		for k,v in pairs(SW.FireMod.SaveBuildings) do
			pos = GetPosition(k);
			Logic.CreateEffect(GGL_Effects.FXDieHero,pos.X,pos.Y,3);
		end
	end
	StartSimpleJob("ViewX");
	
	-- setup OSI
	SW.FireMod.BurnIcon = S5Hook.OSILoadImage("graphics\\textures\\gui\\fire");
    SW.FireMod.BurnIconSize = {S5Hook.OSIGetImageSize(SW.FireMod.BurnIcon)};
	SW.FireMod.BurnIconDisabled = S5Hook.OSILoadImage("graphics\\textures\\gui\\fire_disabled");
	SW.FireMod.BurnIconDisabledSize = {S5Hook.OSIGetImageSize(SW.FireMod.BurnIconDisabled)};
	
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "SW_FireMod_Condition_InflictBuilding", "SW_FireMod_Action_InflictBuilding", 1);
end

function SW_FireMod_Condition_InflictBuilding()
	local target = Event.GetEntityID2();
	if Logic.IsBuilding(target) == 0 then
		-- only inflicht buildings
		return false;
	end
	if Logic.IsConstructionComplete() == 0 then
		-- don't inflict any unfinished buildings
		return false;
	end
	if SW.FireMod.InvincibleBuildings[Logic.GetEntityType(target)] then
		-- building type not allowed to burn
		return false;
	end
	if SW.FireMod.BurningBuildings[GetPlayer(target)][target] then
		-- building burns already
		return false;
	end
	if SW.FireMod.SaveBuildings[target] then
		-- is protected by a fountain from burning
		return false;
	end
	if Logic.GetEntityHealth(target)/Logic.GetEntityMaxHealth(target) > SW.FireMod.Config.InflictBuildingOnAttackThreshold then
		return false;
	end
	return true;
end

function SW_FireMod_Action_InflictBuilding()
	local target = Event.GetEntityID2();
	SW.FireMod.BurningBuildings[GetPlayer(target)][target] = {InflictedOthers = false;};
	if JobIsRunning(SW.FireMod.ControlJob) == 0 then
		SW.FireMod.OSITriggerId = OSI.AddDrawTrigger(SW.FireMod.OSITrigger)
		SW.FireMod.ControlJob = StartSimpleJob("SW_FireMod_ControlJob_BurnBuildings");
	end
end

function SW_FireMod_Condition_FountainOrBuildingCreated()
	local entity = Event.GetEntityID();
	if Logic.IsBuilding(entity) == 1 and Logic.IsConstructionComplete(entity) == 0 then
		return true;
	end
	return false;
end

function SW_FireMod_Action_FountainOrBuildingCreated()
	local entity = Event.GetEntityID();
	local eType = Logic.GetEntityType(entity);
	local pos = GetPosition(entity);

	-- check if nearby fountains can protect building - even for fountains
	local foundFountain = {};
	for eID in S5Hook.EntityIterator(Predicate.InCircle(pos.X, pos.Y, SW.FireMod.Config.FountainSaveBuildingsRange), Predicate.IsBuilding(), Predicate.OfType(Entities.PB_Beautification02)) do
		if Logic.IsConstructionComplete(eID) == 1 then
			table.insert(foundFountain, eID);
		end
	end
	for eID in S5Hook.EntityIterator(Predicate.InCircle(pos.X, pos.Y, SW.FireMod.Config.FountainSaveBuildingsRange), Predicate.IsBuilding(), Predicate.OfType(Entities.PB_Beautification08)) do
		if Logic.IsConstructionComplete(eID) == 1 then
			table.insert(foundFountain, eID);
		end
	end
	if table.getn(foundFountain) > 0 then
		SW.FireMod.SaveBuildings[entity] = foundFountain;
	end

end

function SW_FireMod_Condition_FountainOrBuildingDestroyed()
	local entity = Event.GetEntityID();
	if Logic.IsBuilding(entity) == 1 then
		return true;
	end
end

function SW_FireMod_Action_FountainOrBuildingDestroyed()
	local entity = Event.GetEntityID();
	local eType = Logic.GetEntityType(entity);
	local pos = GetPosition(entity);
	local tsize;
	if eType == Entities.PB_Beautification02 or eType == Entities.PB_Beautification08 then
		-- its a fountain -> check if nearby buildings get vulernable to fire
		for eID in S5Hook.EntityIterator(Predicate.InCircle(pos.X, pos.Y, SW.FireMod.Config.FountainSaveBuildingsRange), Predicate.IsBuilding()) do
			if SW.FireMod.SaveBuildings[eID] then
				tsize = table.getn(SW.FireMod.SaveBuildings[eID]);
				if tsize == 1 then
					SW.FireMod.SaveBuildings[eID] = nil;
				else
					for i = 1, tsize do
						if SW.FireMod.SaveBuildings[eID][i] == entity then
							table.remove(SW.FireMod.SaveBuildings[eID], i);
						end
					end
				end
			end
		end
	else
	-- its a building - remove it from save list
		SW.FireMod.SaveBuildings[entity] = nil;
	end
end

function SW_FireMod_ControlJob_BurnBuildings()
	local HP;
	if Logic.GetWeatherState() == 2 then
		for playerId = 1,8 do
			SW.FireMod.BurningBuildings[playerId] = {};
		end
		return true;
	end
	local count = 0;
	for playerId = 1,8 do
		for buildingId, t in pairs(SW.FireMod.BurningBuildings[playerId]) do
			count = count + 1;
			HP = Logic.GetEntityHealth(buildingId)/Logic.GetEntityMaxHealth(buildingId)
			if HP < SW.FireMod.Config.StopBurnThreshold then
				SW.FireMod.DamageBuilding(buildingId, HP);
			else
				SW.FireMod.BurningBuildings[playerId][buildingId] = nil;
			end
		end
	end
	if count == 0 then
		OSI.RemoveDrawTrigger(SW.FireMod.OSITriggerId)
		return true;
	end
end

function SW.FireMod.TryInflictBuildingsInArea(_buildingId)
	local pos = GetPosition(_buildingId);
	local buildingMaxHealth, buildingHealth;
	local chance;
	for eID in S5Hook.EntityIterator(Predicate.InCircle(pos.X, pos.Y, SW.FireMod.Config.InflictBuildingsRange), Predicate.IsBuilding()) do
		if Logic.IsConstructionComplete(eID) == 1 and eID ~= _buildingId and not SW.FireMod.SaveBuildings[eID] and
			string.find(Logic.GetEntityTypeName(Logic.GetEntityType(eID)), "PB", 1, true) then
			-- chance to inflict building is 10% - dont inflict all of them at the same time
			chance = math.random(1,100);
			if chance <= 10 then
				-- inflict a building with burn -> health less 50%
				buildingHealth = Logic.GetEntityHealth(eID);
				buildingMaxHealth = Logic.GetEntityMaxHealth(eID);
				if buildingHealth/buildingMaxHealth >= 0.5 then
					Logic.HurtEntity(eID, buildingHealth - (buildingMaxHealth/2) + 1);
				end
				SW.FireMod.BurningBuildings[GetPlayer(eID)][eID] = 1;
			end
		end
	end
end

function SW.FireMod.DamageBuilding(_buildingId, _HPInPercent)
	local buildingHealth = Logic.GetEntityHealth(_buildingId);
	local buildingMaxHealth = Logic.GetEntityMaxHealth(_buildingId);
	
	-- building inflicts only once -> check if inflicted already and hp below threshold
	if _HPInPercent < SW.FireMod.Config.InflictOthersBuildingsOnBurnThreshold then
		-- chance in percentage to inflict is given in config
		local inflictOtherBuilding = math.random(1, 100);
		if inflictOtherBuilding < SW.FireMod.Config.ChanceBurningBuildingInflictsOthers then
			SW.FireMod.TryInflictBuildingsInArea(_buildingId);
		end
	end
	
	-- chance that a burn ticks is 50% in the beginning
	-- the less hp the building got, the higher is the chance for a burn tick
	local burn = math.random(_HPInPercent*100, 100);
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

function SW.FireMod.OSITrigger(_eID, _active, _x, _y)
	local player = GetPlayer(_eID);
	if not SW.FireMod.BurningBuildings[player] then
		return;
	end
	if not SW.FireMod.BurningBuildings[player][_eID] then
		return;
	end
	if _active then
		return;
	end
	if Logic.GetWeatherState() == 2 then
		S5Hook.OSIDrawImage(SW.FireMod.BurnIconDisabled, _x, _y, 32, 32);
	else
		S5Hook.OSIDrawImage(SW.FireMod.BurnIcon, _x, _y, 32, 32);
	end
end




