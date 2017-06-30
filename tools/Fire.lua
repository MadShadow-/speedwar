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
		InflictBuildingOnAttackThreshold = 0.6;
		InflictOthersBuildingsOnBurnThreshold = 0.25;
		StopBurnThreshold = 0.6; -- musst be >= InflictThreshold
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
end

function SW_FireMod_Condition_InflictBuilding()
	local target = Event.GetEntityID2();
	Message(Event.GetEntityID1() .. " attacked " .. target);
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
		SW.FireMod.BurningBuildings[GetPlayer(target)][target] = {InflictedOthers=false};
		if not SW.FireMod.ControlJob then
			SW.FireMod.ControlJob = StartSimpleJob("SW_FireMod_ControlJob_BurnBuildings");
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
	
end

function SW.FireMod.DamageBuilding(_buildingId, _HPInPercent)
	local buildingHealth = Logic.GetEntityHealth(_buildingId);
	local buildingMaxHealth = Logic.GetEntityMaxHealth(_buildingId);
	
	if _HPInPercent < SW.FireMod.Config.InflictOthersBuildingsOnBurnThreshold then
		local inflictOtherBuilding = math.random((1-_HPInPercent)*100, 100);
		if inflictOtherBuilding > 80 then
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
	local damage = 0.01 * (buildingMaxHealth - buildingHealth);
	--log("Burn building ".._buildingId.." with " .. damage .. " damage! MaxHealth("..buildingMaxHealth..")".." Health("..buildingHealth..")");
	if damage < 0 then
		damage = 0;
	end
	Logic.HurtEntity(_buildingId, damage);
end




