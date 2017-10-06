--MAUERBAU

--NIEMAND HAT DIE ABSICHT, EINE MAUER ZU ERRICHTEN

--Beautifications used:
-- Entities.PB_Beautification04 -> Mauer
-- Entities.PB_Beautification01 -> Tor
-- Entities.PB_Beautification05 -> Abschlussmauer
-- Entities.PB_Beautification03 -> Mauerturm?

-- TODO LIST:

-- Change needed entity types
-- Change model while building beautification


-- Better use for repair elements:
--	Search for nearby corners
--	Check if a gate or a wall can be placed between 2 corners
--	If possible, place thing and stop working


SW = SW or {}
SW.Walls = {}
SW.Walls.Walllength = 400
SW.Walls.Walltype = Entities.XD_WallStraight
SW.Walls.CornerSize = 50
SW.Walls.CreateSchedule = {}
SW.Walls.DestroySchedule = {}
SW.Walls.DestroyedWalls = {}
SW.Walls.OnConstructionCompleteSchedule = {}
SW.Walls.ListOfWalls = {}	--List of all build walls to ever have existed
SW.Walls.ListOfCorners = {}
function SW.Walls.Init()
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_Walls_OnCreatedCondition", "SW_Walls_OnCreatedAction", 1)
	SW.Walls.DestroyTriggerId = Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_Walls_OnDestroyed", "SW_Walls_OnDestroyedAction", 1)
	StartSimpleJob("SW_Walls_Job")
	SW.Walls.GUIChanges()
	if not SW.IsMultiplayer() then
		Tools.GiveResouces(1, 10000, 10000, 10000, 10000, 10000, 10000)
		ResearchAllUniversityTechnologies(1)
		for i = 1, 10 do Game.GameTimeSpeedUp() end
	end
end
function SW.Walls.GUIChanges()
	-- Make walls sellable, but without ressource return
	SW.Walls.SellBuilding = GUI.SellBuilding
	GUI.SellBuilding = function( _eId)
		if SW.Walls.ListOfWalls[_eId]  then
			Sync.Call( "DestroyEntity", _eId)
		else
			SW.Walls.SellBuilding( _eId)
		end
	end
	-- Now make gates closeable
	XGUIEng.TransferMaterials("Research_Banking", "Research_PickAxe")
	SW.Walls.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()
		SW.Walls.GameCallback_GUI_SelectionChanged()
		local sel = GUI.GetSelectedEntity()
		if sel == nil then
			return
		end
		local typee = Logic.GetEntityType( sel)
		if typee == Entities.PB_ClayMine1 or typee == Entities.PB_ClayMine2 or typee == Entities.PB_ClayMine3 then
			XGUIEng.ShowWidget("Claymine", 1)
			XGUIEng.ShowWidget("Research_PickAxe", 0)
			return
		end
		if typee == Entities.XD_WallStraightGate_Closed or typee == Entities.XD_WallStraightGate then
			XGUIEng.ShowWidget("Claymine", 1)
			XGUIEng.ShowWidget("Research_PickAxe", 1)
			return 
		end
	end
	SW.Walls.GUITooltip_ResearchTechnologies = GUITooltip_ResearchTechnologies
	GUITooltip_ResearchTechnologies = function( ...)
		SW.Walls.GUITooltip_ResearchTechnologies(unpack(arg))
		if arg[1] == Technologies.T_PickAxe then
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "")
			if Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.XD_WallStraightGate then
				XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "Schliesst das Tor!")
			else
				XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "Öffnet das Tor!")
			end
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "")
		end
	end
	SW.Walls.GUIAction_ReserachTechnology = GUIAction_ReserachTechnology
	GUIAction_ReserachTechnology = function( ...)
		if arg[1] == Technologies.T_PickAxe then
			local sel = GUI.GetSelectedEntity()
			Sync.Call( "SW.Walls.ToggleGate", sel)
		else
			SW.Walls.GUIAction_ReserachTechnology(unpack(arg))
		end
	end
end
function SW.Walls.ToggleGate( _eId)
	Trigger.DisableTrigger(SW.Walls.DestroyTriggerId)
	local typee = Logic.GetEntityType( _eId)
	local selected = (GUI.GetSelectedEntity() == _eId)
	if typee == Entities.XD_WallStraightGate then
		local data = SW.Walls.ListOfWalls[_eId]
		local hpDiff = Logic.GetEntityMaxHealth( _eId) - Logic.GetEntityHealth( _eId)
		DestroyEntity( _eId)
		local eId = SW.Walls.CreateEntity( Entities.XD_WallStraightGate_Closed, data.X, data.Y, data.rot, data.pId)
		Logic.HurtEntity( eId, hpDiff)
		if selected then
			GUI.SelectEntity( eId)
		end
	else
		local data = SW.Walls.ListOfWalls[_eId]
		local hpDiff = Logic.GetEntityMaxHealth( _eId) - Logic.GetEntityHealth( _eId)
		DestroyEntity( _eId)
		local eId = SW.Walls.CreateEntity( Entities.XD_WallStraightGate, data.X, data.Y, data.rot, data.pId)
		Logic.HurtEntity( eId, hpDiff)
		if selected then
			GUI.SelectEntity( eId)
		end
	end
	Trigger.EnableTrigger(SW.Walls.DestroyTriggerId)
end
--Calculates the angle of a given vector relative to the x-Axis, ranging from 0 to 2 Pi
function SW.Walls.GetAngle( x, y)
	--Consider (x,y) as normed vector, then cos alpha = x, sin alpha = y
	local cosAlpha = math.acos( x/ math.sqrt(x*x + y*y))
	local sinAlpha = math.asin( y/ math.sqrt(x*x + y*y))
	local alpha = 0
	if sinAlpha >= 0 then --First or second quadrant
		alpha = math.deg(cosAlpha)
	else
		alpha = 360 - math.deg( cosAlpha)
	end
	return alpha
end
function SW.Walls.SearchValidPoints(x,y, _walllength)
	local retList = {}
	local wallLength = math.floor( _walllength/200)
	local minn = SW.Walls.Walllength/2 - SW.Walls.CornerSize
	local maxx = SW.Walls.Walllength/2 + SW.Walls.CornerSize
	for dx = - wallLength, wallLength do
		for dy = -wallLength, wallLength do
			local delta = math.sqrt(dx*dx + dy*dy)*100
			if minn < delta and delta < maxx then
				--LuaDebugger.Log( ""..dx.." "..dy)
				table.insert( retList, {X = x + dx*100, Y = y + dy*100})
			end
		end
	end
	return retList
end
--Searches for best wall placement pos
function SW.Walls.GetBestFit( _cornerPos, _currPos, _walllength)
	local possiblePos = SW.Walls.SearchValidPoints( _cornerPos.X, _cornerPos.Y, _walllength)
	local alpha = SW.Walls.GetAngle( _currPos.X - _cornerPos.X, _currPos.Y - _cornerPos.Y)
	local bestPos = {X = 0, Y = 0}
	local bestDiff = 1000
	for k,v in pairs(possiblePos) do
		local beta = SW.Walls.GetAngle( v.X - _cornerPos.X, v.Y - _cornerPos.Y)
		local diff = math.min( math.abs(alpha - beta), math.abs(alpha - beta + 360), math.abs(alpha - beta - 360))
		if diff < bestDiff then
			bestDiff = diff
			bestPos = v
		end
	end
	return bestPos
end
function SW_Walls_OnCreatedCondition()	--currently finds all beautifications, which leads to removal of all unwanted beautifications when completely built
	local eId = Event.GetEntityID()
	local typee = Logic.GetEntityType( eId)
	if string.find(Logic.GetEntityTypeName(typee), "Beautification") then
		return true
	end
	return false
end
function SW_Walls_OnCreatedAction()
	local eId = Event.GetEntityID()
	table.insert(SW.Walls.OnConstructionCompleteSchedule, eId)
end
function SW_Walls_OnDestroyed()
	local eId = Event.GetEntityID()
	if SW.Walls.ListOfWalls[eId] then
		return true
	end
	return false
end
function SW_Walls_OnDestroyedAction()
	local eId = Event.GetEntityID()
	SW.Walls.OnWallDestroyed(eId)
end
function SW.Walls.OnConstructionComplete( _eId, _type)
	if _type == Entities.PB_Beautification06 then
		SW.Walls.PlaceNormalWall( _eId)
	elseif _type == Entities.PB_Beautification02 then
		SW.Walls.PlaceGate( _eId)
	elseif _type == Entities.PB_Beautification07 then
		SW.Walls.PlaceClosingWall( _eId)
	elseif _type == Entities.PB_Beautification10 then
		SW.Walls.PlaceRepairElement( _eId)
	end
end
function SW.Walls.PlaceRepairElement( _eId)
	local pos = GetPosition( _eId)
	local player = GetPlayer( _eId)
	Logic.DestroyEntity( _eId)
	local targetIndex = 0
	local dis = 100000
	for i = 1, table.getn(SW.Walls.DestroyedWalls) do
		local entry = SW.Walls.DestroyedWalls[i]
		local delX = pos.X - entry.pos.X
		local delY = pos.Y - entry.pos.Y
		if delX*delX + delY*delY < dis*dis then
			targetIndex = i
			dis = math.sqrt(delX*delX + delY*delY)
		end
	end
	if targetIndex == 0 then
		SW.Walls.MessForPlayer( "Keine kaputte Mauer gefunden. Ressourcen behalte ich aber.", player)
		return true
	end
	local entry = SW.Walls.DestroyedWalls[targetIndex]
	table.remove( SW.Walls.DestroyedWalls, targetIndex)
	SW.Walls.CreateEntity( entry.type, entry.pos.X, entry.pos.Y, entry.rot, player)
end
function SW.Walls.PlaceNormalWall( _eId)
	local pos = GetPosition( _eId)
	local player = GetPlayer( _eId)
	--Search for nearby corners
	local nearestCorner = 0
	local distance = 50000
	for cornerId in S5Hook.EntityIterator(Predicate.OfPlayer( player), Predicate.OfType(Entities.XD_WallCorner), Predicate.InCircle( pos.X, pos.Y, 2000)) do
		local cornerPos = GetPosition( cornerId)
		local deltaX = cornerPos.X - pos.X
		local deltaY = cornerPos.Y - pos.Y
		if deltaX*deltaX + deltaY*deltaY < distance*distance then
			distance = math.sqrt(deltaX*deltaX + deltaY*deltaY)
			nearestCorner = cornerId
		end
	end
	table.insert(SW.Walls.DestroySchedule, _eId)
	if nearestCorner == 0 then --No corner found? Create wall at location
		SW.Walls.CreateEntity(Entities.XD_WallStraight, pos.X, pos.Y, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-200, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+200, 0, player)
	else
		--Corner found, search for best placement
		local cornerPos = GetPosition( nearestCorner)
		local newPos = SW.Walls.GetBestFit( cornerPos, pos, 400)
		--Calculate angle between corner and proposed position
		local angle = SW.Walls.GetAngle( newPos.X - cornerPos.X, newPos.Y - cornerPos.Y)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, newPos.X + math.cos(math.rad(angle))*200, newPos.Y+ math.sin(math.rad(angle))*200, angle, player)
		SW.Walls.CreateEntity(Entities.XD_WallStraight, newPos.X, newPos.Y, angle+90, player)
	end
end
function SW.Walls.PlaceClosingWall( _eId)
	local pos = GetPosition( _eId)
	local player = GetPlayer( _eId)
	--Search for nearby corners
	local nearestCorner = 0
	local distance = 50000
	for cornerId in S5Hook.EntityIterator(Predicate.OfPlayer( player), Predicate.OfType(Entities.XD_WallCorner), Predicate.InCircle( pos.X, pos.Y, 1500)) do
		local cornerPos = GetPosition( cornerId)
		local deltaX = cornerPos.X - pos.X
		local deltaY = cornerPos.Y - pos.Y
		if deltaX*deltaX + deltaY*deltaY < distance*distance and SW.Walls.GetAdjacentWalls( cornerPos, player) == 1 then
			distance = math.sqrt(deltaX*deltaX + deltaY*deltaY)
			nearestCorner = cornerId
		end
	end
	table.insert(SW.Walls.DestroySchedule, _eId)
	if nearestCorner == 0 then --No corner found? Create wall at location
		SW.Walls.CreateEntity(Entities.XD_WallStraightGate, pos.X, pos.Y, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-200, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+200, 0, player)
	else
		--Corner found, search for nearby walls
		local cornerPos = GetPosition( nearestCorner)
		local wallID = 0
		local dis = 100000
		for wallId in S5Hook.EntityIterator(Predicate.OfPlayer(player), Predicate.OfType(Entities.XD_WallStraight), Predicate.InCircle( cornerPos.X, cornerPos.Y, 2000)) do
			local wallPos = GetPosition(wallId)
			local deltaX = cornerPos.X - wallPos.X
			local deltaY = cornerPos.Y - wallPos.Y
			if deltaX*deltaX + deltaY*deltaY < dis*dis then
				wallID = wallId
				dis = math.sqrt(deltaX*deltaX + deltaY*deltaY)
			end
		end
		local wallPos = GetPosition(wallID)
		-- Wall and corner pos found, now extrapolate data & create entities
		-- newPos = cornerPos + (cornerPos - WallPos)
		-- newCornerPos = cornerPos + 2(cornerPos - WallPos)
		SW.Walls.CreateEntity(Entities.XD_WallStraight, 2*cornerPos.X - wallPos.X, 2*cornerPos.Y - wallPos.Y, Logic.GetEntityOrientation( wallID), player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, 3*cornerPos.X - 2*wallPos.X, 3*cornerPos.Y - 2*wallPos.Y, 0, player)
		--Calculate angle between corner and proposed position
		--local angle = SW.Walls.GetAngle( newPos.X - cornerPos.X, newPos.Y - cornerPos.Y)
		--Logic.CreateEntity(Entities.XD_WallCorner, newPos.X + math.cos(math.rad(angle))*300, newPos.Y+ math.sin(math.rad(angle))*300, angle, player)
		--Logic.CreateEntity(Entities.XD_WallStraightGate, newPos.X, newPos.Y, angle+90, player)
	end
end
function SW.Walls.GetAdjacentWalls( _pos, _player)
	return Logic.GetPlayerEntitiesInArea( _player, Entities.XD_WallStraight, _pos.X, _pos.Y, 400, 5) 
		+ Logic.GetPlayerEntitiesInArea( _player, Entities.XD_WallStraightGate, _pos.X, _pos.Y, 600, 5)
		+ Logic.GetPlayerEntitiesInArea( _player, Entities.XD_WallStraightGate_Closed, _pos.X, _pos.Y, 600, 5)
end
function SW.Walls.AreWallsAdjacent( _pos, _eId) --use _eId as black list
	local n, e1, e2 = Logic.GetEntitiesInArea( Entities.XD_WallStraight, _pos.X, _pos.Y, 400, 2)
	if e1 == _eId or e2 == _eId then
		n = n - 1
	end
	if n ~= 0 then
		return true
	end
	n, e1, e2 = Logic.GetEntitiesInArea( Entities.XD_WallStraightGate, _pos.X, _pos.Y, 400, 2)
	if e1 == _eId or e2 == _eId then
		n = n - 1
	end
	if n ~= 0 then
		return true
	end
	n, e1, e2 = Logic.GetEntitiesInArea( Entities.XD_WallStraightGate_Closed, _pos.X, _pos.Y, 400, 2)
	if e1 == _eId or e2 == _eId then
		n = n - 1
	end
	if n ~= 0 then
		return true
	end
	return false
end
function SW.Walls.PlaceGate( _eId)
	local pos = GetPosition( _eId)
	local player = GetPlayer( _eId)
	--Search for nearby corners
	local nearestCorner = 0
	local distance = 50000
	for cornerId in S5Hook.EntityIterator(Predicate.OfPlayer( player), Predicate.OfType(Entities.XD_WallCorner), Predicate.InCircle( pos.X, pos.Y, 2000)) do
		local cornerPos = GetPosition( cornerId)
		local deltaX = cornerPos.X - pos.X
		local deltaY = cornerPos.Y - pos.Y
		if deltaX*deltaX + deltaY*deltaY < distance*distance then
			distance = math.sqrt(deltaX*deltaX + deltaY*deltaY)
			nearestCorner = cornerId
		end
	end
	table.insert(SW.Walls.DestroySchedule, _eId)
	if nearestCorner == 0 then --No corner found? Create wall at location
		SW.Walls.CreateEntity(Entities.XD_WallStraightGate, pos.X, pos.Y, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-300, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+300, 0, player)
	else
		--Corner found, search for best placement
		local cornerPos = GetPosition( nearestCorner)
		local newPos = SW.Walls.GetBestFit( cornerPos, pos, 600)
		--LuaDebugger.Log("X:"..newPos.X.." Y:"..newPos.Y)
		--Calculate angle between corner and proposed position
		local angle = SW.Walls.GetAngle( newPos.X - cornerPos.X, newPos.Y - cornerPos.Y)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, newPos.X + math.cos(math.rad(angle))*300, newPos.Y+ math.sin(math.rad(angle))*300, angle, player)
		SW.Walls.CreateEntity(Entities.XD_WallStraightGate, newPos.X, newPos.Y, angle+90, player)
	end
end
function SW_Walls_Job()
	for i = table.getn(SW.Walls.CreateSchedule), 1, -1 do
		local entry = SW.Walls.CreateSchedule[i]
		SW.Walls.CreateEntity( entry[1], entry[2], entry[3], entry[4], entry[5])
	end
	SW.Walls.CreateSchedule = {}
	for i = table.getn(SW.Walls.DestroySchedule), 1, -1 do
		local eId = SW.Walls.DestroySchedule[i]
		if Logic.IsBuilding( eId) ==  1 then
			if Logic.IsConstructionComplete(eId) == 1 then
				DestroyEntity( SW.Walls.DestroySchedule[i])
				table.remove( SW.Walls.DestroySchedule, i)
			end
		else
			DestroyEntity( SW.Walls.DestroySchedule[i])
			table.remove( SW.Walls.DestroySchedule, i)
		end
	end
	for i = table.getn(SW.Walls.OnConstructionCompleteSchedule), 1, -1 do
		local eId = SW.Walls.OnConstructionCompleteSchedule[i]
		if Logic.IsBuilding( eId) ==  1 then
			if Logic.IsConstructionComplete(eId) == 1 then
				SW.Walls.OnConstructionComplete( eId, Logic.GetEntityType( eId))
				DestroyEntity( SW.Walls.OnConstructionCompleteSchedule[i])
				table.remove( SW.Walls.OnConstructionCompleteSchedule, i)
			end
		else
			table.remove( SW.Walls.OnConstructionCompleteSchedule, i)
		end
	end
end
function SW.Walls.OnWallDestroyed( _eId)
	local entry = SW.Walls.ListOfWalls[_eId]
	table.insert(SW.Walls.DestroyedWalls, {type = entry.type, pos = {X = entry.X, Y = entry.Y}, rot = entry.rot})
	SW.Walls.ListOfWalls[_eId] = nil
	-- Procedere for repair element completed
	-- Now start cleaning up corners
	for eId in S5Hook.EntityIterator( Predicate.InCircle(entry.X, entry.Y, 800), Predicate.OfType( Entities.XD_WallCorner)) do
		if not SW.Walls.AreWallsAdjacent( GetPosition( eId), _eId) then
			DestroyEntity( eId)
			DestroyEntity( SW.Walls.ListOfCorners[eId])
			SW.Walls.ListOfCorners[eId] = nil
		end
	end
end
-- _pos is playerID
function SW.Walls.CreateEntity( _eType, _x, _y, _rot, _pos)
	if _eType == Entities.XD_WallCorner then	--Place real corner, hide it with model, create fake corner
		local eId = Logic.CreateEntity( _eType, _x, _y, _rot, _pos)
		Logic.SetModelAndAnimSet( eId, Models.XD_Rock1)
		MakeInvulnerable( eId)
		Logic.SetEntitySelectableFlag( eId, 0)
		local pos = GetPosition( eId)
		local eId2 = Logic.CreateEntity( Entities.XD_CoordinateEntity, pos.X, pos.Y, _rot, 0)
		--Logic.SetModelAndAnimSet( eId2, Models.XD_WallCorner)
		local pos = GetPosition(eId2)
		--Message( "Soll: "..pos.X.." "..pos.Y)
		local eId3 = Logic.CreateEntity( Entities.XD_Grave1, pos.X, pos.Y, _rot, _pos)
		Logic.SetModelAndAnimSet( eId3, Models.XD_WallCorner)
		pos = GetPosition(eId3)
		--Message("Ist: "..pos.X.." "..pos.Y)
		SW.Walls.ListOfCorners[eId] = eId3
		DestroyEntity( eId2)
		return eId
	else
		local eId = Logic.CreateEntity( _eType, _x, _y, _rot, _pos)
		SW.Walls.ListOfWalls[eId] = {type = _eType, X = _x, Y = _y, rot = _rot, pId = _pos}
		return eId
	end
end
function SW.Walls.MessForPlayer( _message, _pId)
	local controlled = GUI.GetPlayerID()
	if controlled == _pId then
		Message( _message)
	end
end
function SW.Walls.Round(_value, _factor)
	_factor = _factor or 1
	_value = _value / _factor
    local f = math.floor(_value);
	local t = _value - f
    if t > 0.5 then
        return math.ceil(_value)*_factor;
    else
        return f*_factor;
    end
end	

	--if _eType == Entities.PB_Beautification04  then
		--	Logic.SetModelAndAnimSet(_eId,Models.XD_WallStraight)
		--elseif _eType == Entities.PB_Beautification01  then
		--	Logic.SetModelAndAnimSet(_eId,Models.XD_WallStraightGate)
		--elseif _eType == Entities.PB_Beautification05  then
		--	Logic.SetModelAndAnimSet(_eId,Models.XD_DarkWallDistorted)
		--elseif _eType == Entities.PB_Beautification03  then
		--	Logic.SetModelAndAnimSet(_eId,Models.PB_DarkTower2)
		--end