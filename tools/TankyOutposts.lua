--			MAKE HQ TANKIER WITH EVERY BUILDING IN RANGE

--	Outposts can dissipate damage onto nearby allied buildings
--	This only works until all nearby buildings are reduced to a given percentage of their max hp
--	The damage doesnt spread instantly, it´s more like a maxHP-a*e^(-b*t) curve
--	The speed can be adjusted aswell

-- Theory crafting for better HP transfer
-- Every building has some kind of attraction factor ranging from 0 to 1, factor = (currHP - threshold*maxHP)/maxHP/(1-threshold) or 0
-- HQ is hurt and needs to sweat damage out
-- HQ collects data of all nearby buildings
-- Select buildings from list and heal up, until max heal/tick is reached or building on full hp
-- Selection according to attraction factor
-- Create small indicator for heal from building X

SW = SW or {}
SW.TankyHQ = {}
-- Keep configs here for development
SW.TankyHQ.Range = 5000 --Buildings in this range will add to the defense of the HQ
SW.TankyHQ.Threshold = 0.6	--Buildings can be damaged until 60% maxHP is left
SW.TankyHQ.DissipationSpeed = 0.04	--20% of damage on HQ will be spread out every second
SW.TankyHQ.PenaltyFactor = 2		--1 point of HQ damage converts to 2 points of non-HQ-damage
									--Village during testing had summed up 40600 MaxHP
SW.TankyHQ.VisualizationSpeed = 150	--100 Scm per 1/10 s
SW.TankyHQ.DataTransferVisualization = {} --Entry: { start = PosTable, target = PosTable, t = 2}
SW.TankyHQ.Data = {} --Key: outpostId, Value: table with ids of nearby buildings
SW.TankyHQ.GoodType = {}
function SW.TankyHQ.Init()
	for k,v in pairs(Entities) do
		local found = string.find( k, "PB")
		if found then
			SW.TankyHQ.GoodType[v] = true
		end
	end
	SW.TankyHQ.InitialScan()
	StartSimpleJob("SW_TankyHQ_Job")
	StartSimpleHiResJob("SW_TankyHQ_HiResJob")
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_TankyHQ_ConditionOnCreated", "SW_TankyHQ_ActionOnCreated", 1)
end
function SW.TankyHQ.InitialScan()
	for eId in S5Hook.EntityIterator(Predicate.OfType(Entities.PB_Outpost1)) do
		SW.TankyHQ.OnNewHQ( eId)
	end
end
function SW_TankyHQ_Job()
	SW.TankyHQ.CheckDestroyedBuildings()
	SW.TankyHQ.Tick()
end
function SW.TankyHQ.CheckDestroyedBuildings()
	for k,v in pairs(SW.TankyHQ.Data) do
		if IsDead(k) then
			SW.TankyHQ.Data[k] = nil
		end
	end
	for k,v in pairs(SW.TankyHQ.Data) do
		for i = table.getn(v), 1, -1 do
			if IsDead(v[i]) then
				table.remove( v, i)
			end
		end
	end
end
function SW_TankyHQ_ConditionOnCreated()
	if SW.TankyHQ.GoodType[Logic.GetEntityType(Event.GetEntityID())] then
		return true
	end
	return false
end
function SW_TankyHQ_ActionOnCreated()	--Register newly created outposts, find outposts for new buildings
	local eId = Event.GetEntityID()
	if Logic.GetEntityType( eId) == Entities.PB_Outpost1 then
		SW.TankyHQ.OnNewHQ( eId)
	else	--Is a outpost nearby? Add to list of near buildings
		for k,v in pairs(SW.TankyHQ.Data) do
			if SW.TankyHQ.GetDistance( k, eId) <= SW.TankyHQ.Range then
				if GetPlayer(k) == GetPlayer(eId) then
					table.insert( v, eId)
				end
			end
		end
	end
end
function SW.TankyHQ.OnNewHQ( _eId)
	SW.TankyHQ.Data[_eId] = {}
	local pos = GetPosition( _eId)
	for eId in S5Hook.EntityIterator( Predicate.IsBuilding(), Predicate.InCircle( pos.X, pos.Y, SW.TankyHQ.Range), Predicate.OfPlayer(GetPlayer(_eId))) do
		local eType = Logic.GetEntityType(eId)
		if SW.TankyHQ.GoodType[eType] and eType ~= Entities.PB_Outpost1 then
			table.insert( SW.TankyHQ.Data[_eId], eId)
		end
	end
end
function SW.TankyHQ.Tick()	--Gets called each second, manages damage spread
	for k,v in pairs(SW.TankyHQ.Data) do
		if Logic.IsConstructionComplete(k) == 1 then
			local currHP = Logic.GetEntityHealth( k)
			local maxHP = Logic.GetEntityMaxHealth( k)
			if currHP < maxHP then
				local spreaded = SW.TankyHQ.SpreadDamage( v, math.ceil(SW.TankyHQ.DissipationSpeed*(maxHP-currHP)), k)
			end
		end
	end
end
function SW.TankyHQ.SpreadDamage( _list, _toSpread, _hqId) --returns damage that has been successfully spreaded to other buildings
	local spreaded = 0
	local newList = {}
	for i = 1, table.getn( _list) do
		local currHP_ = Logic.GetEntityHealth( _list[i])
		local maxHP_ = Logic.GetEntityMaxHealth( _list[i])
		local factor = SW.TankyHQ.GetAttractionFactor( currHP_, maxHP_)
		if factor > 0 then
			table.insert( newList, {_list[i], factor})
		end
	end
	-- use some form of heat transfer from HQ( _toSpread) to nearby buildings
	-- buildings with 100% HP are cold, less percentual HP -> warmer building
	while spreaded < _toSpread do
		local index = SW.TankyHQ.GetBestEntry( newList)
		if index == 0 then break end
		local currHP = Logic.GetEntityHealth(newList[index][1])
		local maxHP = Logic.GetEntityMaxHealth(newList[index][1])
		local ableToSend = math.ceil(currHP - maxHP*SW.TankyHQ.Threshold)
		local ableToHeal = math.ceil( ableToSend/SW.TankyHQ.PenaltyFactor)
		local toHeal = math.min( ableToHeal, _toSpread - spreaded)
		local toHurt = math.ceil( toHeal*SW.TankyHQ.PenaltyFactor)
		Logic.HurtEntity( newList[index][1], toHurt)
		table.insert( SW.TankyHQ.DataTransferVisualization, { start = GetPosition(newList[index][1]), target = GetPosition( _hqId), t = 0, heal = toHeal, healTarget = _hqId})
		spreaded = spreaded + toHeal
		table.remove( newList, index)
	end
	return spreaded
end
function SW.TankyHQ.GetBestEntry(_list)
	local index = 0
	local val = 0
	for i = 1, table.getn( _list) do
		if val < _list[i][2] then
			index = i
			val = _list[i][2]
		end
	end
	return index
end
function SW.TankyHQ.GetAttractionFactor( _currHp, _maxHp)
	--(currHP - threshold*maxHP)/maxHP/(1-threshold)
	-- = (hp over threshold)/( hp over threshold if full life)
	return math.max(0, (_currHp - SW.TankyHQ.Threshold*_maxHp)/_maxHp/(1-SW.TankyHQ.Threshold))
end
function SW.TankyHQ.GetDistance( _eId1, _eId2)
	local pos1 = GetPosition(_eId1)
	local pos2 = GetPosition(_eId2)
	local deltaX = pos1.X - pos2.X
	local deltaY = pos1.Y - pos2.Y
	return math.sqrt( deltaX*deltaX + deltaY*deltaY)
end
function SW_TankyHQ_HiResJob()
	-- calculate length of route for visualization
	for k,v in pairs(SW.TankyHQ.DataTransferVisualization) do
		if v.length == nil then
			local deltaX = v.start.X - v.target.X
			local deltaY = v.start.Y - v.target.Y
			v.length = math.sqrt( deltaX*deltaX + deltaY*deltaY)
		end
	end
	-- do actual visualization
	for k,v in pairs(SW.TankyHQ.DataTransferVisualization) do
		SW.TankyHQ.GenerateEffect(v)
		v.t = v.t + 1
	end
	-- arrived at target? HEAL!
	for i = table.getn(SW.TankyHQ.DataTransferVisualization), 1, -1 do
		if SW.TankyHQ.DataTransferVisualization[i].t*SW.TankyHQ.VisualizationSpeed > SW.TankyHQ.DataTransferVisualization[i].length then
			SW.TankyHQ.ApplyHeal( SW.TankyHQ.DataTransferVisualization[i].healTarget, SW.TankyHQ.DataTransferVisualization[i].heal)
			table.remove( SW.TankyHQ.DataTransferVisualization, i)
		end
	end
end
function SW.TankyHQ.GenerateEffect(_entry)
	local alpha = _entry.t*SW.TankyHQ.VisualizationSpeed/_entry.length
	-- alpha = progress made; 0 to 1
	local x = _entry.start.X + (_entry.target.X - _entry.start.X)*alpha
	local y = _entry.start.Y + (_entry.target.Y - _entry.start.Y)*alpha
	Logic.CreateEffect( GGL_Effects.FXSalimHeal, x, y, 1)
end
function SW.TankyHQ.ApplyHeal( _id, _heal)
	if not IsExisting( _id) then return end
	local myHeal = math.min( _heal, Logic.GetEntityMaxHealth( _id)-Logic.GetEntityHealth(_id))
	Logic.HealEntity( _id, myHeal)
end

function SW.TankyHQ.CreateTestVillage()
	local toCreate = {
		{9,25200,64300},
		{3,26300,63100},
		{56,34200,67300},
		{56,33900,66000},
		{9,29400,62100},
		{9,27300,67200},
		{3,31700,66500},
		{9,30200,62100},
		{9,27700,62900},
		{9,32700,66300},
		{9,28400,67500},
		{3,23700,66700},
		{9,32100,63500},
		{9,23800,65500},
		{27,24900,59600},
		{31,26200,64400},
		{1,26100,68600},
		{3,25200,68600},
		{9,26900,68700},
		{3,32200,70000},
		{3,34700,70000},
		{9,35000,65200},
		{9,33600,65000},
		{9,34900,66000},
		{9,34300,65000},
		{36,26000,65600},
		{9,31800,67800},
		{3,30400,67600},
		{3,27200,65300},
		{3,27200,64000},
		{27,31000,63500},
		{3,32800,65100},
		{3,29300,67700},
		{26,28300,66100},
		{26,28300,64200},
		{3,28500,62500},
		{26,29600,63400},
		{24,29500,65100},
		{24,29500,66500},
		{24,30600,66400},
		{24,30800,65000},
		{24,31900,65300},
		{36,32900,67400},
		{26,31200,61800},
		{56,32200,68800},
		{56,33300,68800},
		{3,35200,66900},
		{51,26300,67200},
		{51,25200,67200},
		{51,24800,65500}
	}
	Tools.GiveResouces( 1, 1000, 1000, 1000, 1000, 1000, 1000)
	for i = 1, table.getn(toCreate) do
		Logic.CreateEntity( toCreate[i][1], toCreate[i][2], toCreate[i][3], 0, 1)
	end
end
function SW.TankyHQ.ScanVillage(_pId)
	for eId in S5Hook.EntityIterator(Predicate.OfPlayer(_pId),Predicate.IsBuilding()) do 
		LuaDebugger.Log("{"..Logic.GetEntityType(eId)..","..GetPosition(eId).X..","..GetPosition(eId).Y.."}")
	end
end