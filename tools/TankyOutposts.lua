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
SW.TankyHQ.VisualizationSpeed = 100	--100 Scm per 1/10 s
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
	--LuaDebugger.Log(""..eId)
	if Logic.GetEntityType( eId) == Entities.PB_Outpost1 then
		SW.TankyHQ.OnNewHQ( eId)
	else	--Is a outpost nearby? Add to list of near buildings
		for k,v in pairs(SW.TankyHQ.Data) do
			--LuaDebugger.Log("k: "..k.." eId: "..eId)
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
				--LuaDebugger.Log("Need to heal "..k)
				local spreaded = SW.TankyHQ.SpreadDamage( v, math.floor(SW.TankyHQ.DissipationSpeed*(maxHP-currHP)), k)
				Logic.HealEntity( k, spreaded)
			end
		end
	end
end
function SW.TankyHQ.SpreadDamage( _list, _toSpread, _hqId) --returns damage that has been successfully given out
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
	while spreaded < _toSpread do
		local index = SW.TankyHQ.GetBestEntry( newList)
		if index == 0 then break end
		local currHP = Logic.GetEntityHealth(newList[index][1])
		local maxHP = Logic.GetEntityMaxHealth(newList[index][1])
		local toTransfer = math.min( math.floor(currHP - maxHP*SW.TankyHQ.Threshold), _toSpread - spreaded)
		Logic.HurtEntity( newList[index][1], toTransfer)
		table.insert( SW.TankyHQ.DataTransferVisualization, { start = GetPosition(newList[index][1]), target = GetPosition( _hqId), t = 0})
		spreaded = spreaded + _toSpread
		table.remove( newList, index)
	end
	--[[for i = 1, table.getn(newList) do
		if spreaded >= _toSpread then
			break
		end
		local currHP_ = Logic.GetEntityHealth( _list[i])
		local maxHP_ = Logic.GetEntityMaxHealth( _list[i])
		local spread = 0
		if  currHP_ > SW.TankyHQ.Threshold*maxHP_ then
			spread = math.floor(currHP_ - SW.TankyHQ.Threshold*maxHP_)
			spread = math.min( spread, _toSpread - spreaded)
		end
		Logic.HurtEntity( _list[i], spread)
		spreaded = spreaded + spread
	end]]
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
	--Message("HI")
	for k,v in pairs(SW.TankyHQ.DataTransferVisualization) do
		if v.length == nil then
			local deltaX = v.start.X - v.target.X
			local deltaY = v.start.Y - v.target.Y
			v.length = math.sqrt( deltaX*deltaX + deltaY*deltaY)
		end
	end
	for k,v in pairs(SW.TankyHQ.DataTransferVisualization) do
		SW.TankyHQ.GenerateEffect(v)
		v.t = v.t + 1
	end
	for i = table.getn(SW.TankyHQ.DataTransferVisualization), 1, -1 do
		if SW.TankyHQ.DataTransferVisualization[i].t*100 > SW.TankyHQ.DataTransferVisualization[i].length then
			table.remove( SW.TankyHQ.DataTransferVisualization, i)
		end
	end
end
function SW.TankyHQ.GenerateEffect(_entry)
	local alpha = _entry.t*SW.TankyHQ.VisualizationSpeed/_entry.length
	--Message("alpha "..alpha)
	local x = _entry.start.X + (_entry.target.X - _entry.start.X)*alpha
	local y = _entry.start.Y + (_entry.target.Y - _entry.start.Y)*alpha
	--Message("x "..x.." y "..y)
	Logic.CreateEffect( GGL_Effects.FXSalimHeal, x, y, 1)
end