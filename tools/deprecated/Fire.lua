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
	
	-- todo:
	ausbreitung soll nicht gleichzeitig mehrere Gebäude angreifen - aus breitung bei einem brennden gebäude alle x sek 1 mal
	ein Gebäude droppt nicht auf 50 hp nachdem es angezündet wird
	damage schneller machen und gleichmäßig
	damage und ausbreitung mit spiel dauer skalieren - anfangs schwach, später stark
	kontrollieren ob ein gebäude gehealed wird
	
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
		BaseDamagePerTick = 10;
		DamageMissingHealthPerTick = 0.01; -- 0.01 = 1% of missing health per damage tick
		ChanceBurningBuildingInflictsOthers = 100; -- chance to inflict another building on each damage tick => 10 => chance < 10%
		FountainSaveBuildingsRange = 4000;
	};
	
	-- add any entity type which should be excluded from beeing burned
	SW.FireMod.InvincibleBuildings = {
	};
	
	SW.FireMod.BurningBuildings = {};
	for playerId = 1,SW.MaxPlayers do
		SW.FireMod.BurningBuildings[playerId] = {};
	end
	
	-- don't trigger every single attack
	SW.FireMod.CheckRecentlyAttackedBuildingsJobId = -1;
	SW.FireMod.RecentlyAttackedBuildings = {};
	-- stops recently attacked buildings job
	SW.FireMod.IdleCounter = 0;
	
	
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
	
	SW.FireMod.EntityHurtTrigger = Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "", "SW_FireMod_Action_EntityHurt", 1);
end

function SW_FireMod_Action_EntityHurt()
	-- Id of target entity
	local eId = Event.GetEntityID2();
	if Logic.IsBuilding(eId) == 0 then
		return false;
	end
	if Logic.IsConstructionComplete() == 0 then
		-- don't ignite unfinished buildings
		return false;
	end
	if SW.FireMod.InvincibleBuildings[Logic.GetEntityType(eId)] then
		-- building type not allowed
		return false;
	end
	-- to prevent controlling conditions on each single attack,
	-- attacks are gathered and checked all together
	SW.FireMod.RecentlyAttackedBuildings[eId] = 0;
	if JobIsRunning(SW.FireMod.CheckRecentlyAttackedBuildingsJobId) == 0 then
		SW.FireMod.CheckRecentlyAttackedBuildingsJobId = StartSimpleJob("SW_FireMod_CheckRecentlyAttackedBuildings");
	end
end
function SW_FireMod_CheckRecentlyAttackedBuildings()
	if Logic.GetWeatherState() == 2 then
		return;
	end
	local entries = 0;
	local HP = 0;

	for eId,v in pairs(SW.FireMod.RecentlyAttackedBuildings) do
		entries = entries + 1;
		if Logic.GetWeatherState() ~= 2
		and not SW.FireMod.InvincibleBuildings[Logic.GetEntityType(eId)]
		and not SW.FireMod.BurningBuildings[Logic.EntityGetPlayer(eId)][eId]
		and not SW.FireMod.SaveBuildings[eId] then
			HP = Logic.GetEntityHealth(eId)/Logic.GetEntityMaxHealth(eId);
			if HP <= SW.FireMod.Config.InflictBuildingOnAttackThreshold then
				SW.FireMod.BurningBuildings[Logic.EntityGetPlayer(eId)][eId] = {InflictedOthers = false; HPAfterLastDamage = HP;};
				if JobIsRunning(SW.FireMod.ControlJob) == 0 then
					SW.FireMod.OSITriggerId = OSI.AddDrawTrigger(SW.FireMod.OSITrigger)
					Message("Start BURNING");
					SW.FireMod.ControlJob = StartSimpleJob("SW_FireMod_ControlJob_BurnBuildings");
				end
			end
		else
			-- remove building from list - conditions not fullfilled
			SW.FireMod.RecentlyAttackedBuildings[eId] = nil;
		end
	end
	if entries > 0 then
		SW.FireMod.IdleCounter = 0;
	else
		SW.FireMod.IdleCounter = SW.FireMod.IdleCounter + 1;
		if SW.FireMod.IdleCounter > 5 then
			-- no buildings checked the last 5 seconds
			SW.FireMod.IdleCounter = 0;
			return true;
		end
	end
end

--[[
function SW_FireMod_Condition_InflictBuilding()
	local target = Event.GetEntityID2();
	if Logic.IsBuilding(target) == 0 then
		-- only inflicht buildings
		return false;
	end
	if Logic.IsConstructionComplete() == 0 then
		-- don't ignite unfinished buildings
		return false;
	end
	if Logic.GetWeatherState() == 2 then
		-- dont ignite buildings while rain
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
end ]]

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
		for playerId = 1,SW.MaxPlayers do
			SW.FireMod.BurningBuildings[playerId] = {};
		end
		OSI.RemoveDrawTrigger(SW.FireMod.OSITriggerId);
		Trigger.UnrequestTrigger(SW.FireMod.ControlJob);
		return true;
	end
	local count = 0;
	for playerId = 1,SW.MaxPlayers do
		for buildingId, t in pairs(SW.FireMod.BurningBuildings[playerId]) do
			count = count + 1;
			HP = Logic.GetEntityHealth(buildingId)/Logic.GetEntityMaxHealth(buildingId);
			if HP < SW.FireMod.Config.InflictBuildingOnAttackThreshold or HP <= t.HPAfterLastDamage then
				SW.FireMod.DamageBuilding(buildingId, HP);
			else
				-- building gets repaired and HP > Threshold
				SW.FireMod.BurningBuildings[playerId][buildingId] = nil;
			end
		end
	end
	if count == 0 then
		OSI.RemoveDrawTrigger(SW.FireMod.OSITriggerId);
		Trigger.UnrequestTrigger(SW.FireMod.ControlJob);
		return true;
	end
end

function SW.FireMod.TryInflictBuildingsInArea(_buildingId)
	local pos = GetPosition(_buildingId);
	local buildingMaxHealth, buildingHealth, HP;
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
				HP = buildingHealth/buildingMaxHealth;
				if HP >= 0.5 then
					--Logic.HurtEntity(eID, buildingHealth - (buildingMaxHealth/2) + 1);
				end
				SW.FireMod.BurningBuildings[Logic.EntityGetPlayer(eID)][eID] = {InflictedOthers = false; HPAfterLastDamage = HP;};
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
	
	-- Damage: 1% of missing health per Tick
	local damage = math.random(1,SW.FireMod.Config.BaseDamagePerTick) + SW.FireMod.Config.DamageMissingHealthPerTick * (buildingMaxHealth - buildingHealth);
	--log("Burn building ".._buildingId.." with " .. damage .. " damage! MaxHealth("..buildingMaxHealth..")".." Health("..buildingHealth..")");
	if damage < 0 then
		damage = 0;
	end
	Logic.HurtEntity(_buildingId, damage);
	-- update new hp percentage
	SW.FireMod.BurningBuildings[Logic.EntityGetPlayer(_buildingId)][_buildingId].HPAfterLastDamage = buildingHealth/buildingMaxHealth;
end

function SW.FireMod.OSITrigger(_eID, _active, _x, _y)
	local player = Logic.EntityGetPlayer(_eID);
	if not SW.FireMod.BurningBuildings[player] then
		return;
	end
	if not SW.FireMod.BurningBuildings[player][_eID] then
		return;
	end
	LuaDebugger.Log("ShowBurnIcon on " .. _eID);
	local offsetX = 0;
	local offsetY = 0;
	if _active then
		offsetX = -30;
	end
	if Logic.GetWeatherState() == 2 then
		S5Hook.OSIDrawImage(SW.FireMod.BurnIconDisabled, _x+offsetX, _y+offsetY, 32, 32);
	else
		S5Hook.OSIDrawImage(SW.FireMod.BurnIcon, _x+offsetX, _y+offsetY, 32, 32);
	end
end




