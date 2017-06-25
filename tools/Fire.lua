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
		InflictBuildingThreshold = 0.3;
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
	if Logic.GetEntityHealth(target)/Logic.GetEntityMaxHealth(target) > SW.FireMod.Config.InflictBuildingThreshold then
		return false;
	end
	return true;
end

function SW_FireMod_Action_InflictBuilding()
	local target = Event.GetEntityID2();
	Message("Inflict " .. target);
	table.insert(SW.FireMod.BurningBuildings[GetPlayer(target)], target);
	if not SW.FireMod.ControlJob then
		SW.FireMod.ControlJob = StartSimpleJob("SW_FireMod_ControlJob_BurnBuildings");
	end
end

function SW_FireMod_ControlJob_BurnBuildings()
	for playerId = 1,8 do
		for i = table.getn(SW.FireMod.BurningBuildings[playerId]), 1, -1 do
			SW_FireMod_DamageBuilding(SW.FireMod.BurningBuildings[playerId][i]);
		end
	end
end

function SW_FireMod_DamageBuilding(_buildingId)
	Message("DamageBuilding " .. _buildingId);
end




