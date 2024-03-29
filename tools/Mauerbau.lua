--MAUERBAU

--NIEMAND HAT DIE ABSICHT, EINE MAUER ZU ERRICHTEN

--Beautifications used:
-- Entities.PB_Beautification04 -> Mauer
-- Entities.PB_Beautification01 -> Tor
-- Entities.PB_Beautification05 -> Abschlussmauer
-- Entities.PB_Beautification03 -> Mauerturm?

-- TODO LIST:

-- Change algorithm for closing wall, currently not good.


-- Better use for closing elements:
--	Search for nearby corners
--	Check if a gate or a wall can be placed between 2 corners
--	If possible, place thing and stop working
--	If not, check for the nearest corner and place a wall to continue the great wall

--	Alternative: Search for corners, check all edge points for blocking and place wall in order to complete blocking?

--Problem: Continuation of wall allows to build a wall through a mountain.


SW = SW or {}
SW.Walls = {}
SW.Walls.Walllength = 400
SW.Walls.Walltype = Entities.XD_WallStraight
SW.Walls.WorldSize = Logic.WorldGetSize()
SW.Walls.CornerSize = 50
SW.Walls.CreateSchedule = {}
SW.Walls.DestroySchedule = {}
SW.Walls.DestroyedWalls = {}
SW.Walls.OnConstructionCompleteSchedule = {}
SW.Walls.ListOfWalls = {}	--List of all build walls to ever have existed
SW.Walls.ListOfCorners = {}
function SW.Walls.Init()
	--Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_Walls_OnCreatedCondition", "SW_Walls_OnCreatedAction", 1)
	SW.Walls.DestroyTriggerId = Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_Walls_OnDestroyed", "SW_Walls_OnDestroyedAction", 1)
	StartSimpleJob("SW_Walls_Job")
	SW.Walls.GUIChanges()
end
function SW.Walls.GUIChanges()
	-- Make walls sellable, but without ressource return
	SW.Walls.SellBuilding = GUI.SellBuilding
	GUI.SellBuilding = function( _eId)
		if SW.Walls.ListOfWalls[_eId]  then
			Sync.Call( "SW.Walls.SellWall", _eId)
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
		--[[ Structure of GUI for Claymine
		Claymine
			Commands_Claymine
				Research_PickAxe
				Upgrade_Claymine1
				Upgrade_Claymine2
		]]
		--show claymine menu on selection
		XGUIEng.ShowWidget("Claymine", 1)
		XGUIEng.ShowWidget("Commands_Claymine", 1)
		XGUIEng.ShowAllSubWidgets("Commands_Claymine", 0)
		if typee == Entities.PB_ClayMine1 then --Show only UP1
			if not SW.Walls.IsBusy(sel) then
				XGUIEng.ShowWidget("Upgrade_Claymine1", 1)
			end
			return
		end
		if typee == Entities.PB_ClayMine2 then --Show only UP2
			if not SW.Walls.IsBusy(sel) then
				XGUIEng.ShowWidget("Upgrade_Claymine2", 1)
			end
			return
		end
		if typee == Entities.PB_ClayMine3 then --Show nothing
			return
		end
		if typee == Entities.XD_WallStraightGate_Closed or typee == Entities.XD_WallStraightGate then --only show Research_PickAxe
			XGUIEng.ShowWidget("Research_PickAxe", 1)
			return 
		end
		--if there is no "return" until now, hide claymine menu
		XGUIEng.ShowWidget("Claymine", 0)
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
			if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
				local pos = GetPosition(sel);
				local type = Logic.GetEntityType(sel);
				local gates = {Logic.GetPlayerEntitiesInArea(GUI.GetPlayerID(), type, pos.X, pos.Y, 2000, 16)};
				if gates[1] > 0 then
					for i = 2, table.getn(gates) do
						Sync.Call( "SW.Walls.ToggleGate", gates[i]);
					end
				end
			else
				Sync.Call( "SW.Walls.ToggleGate", sel);
			end
		else
			SW.Walls.GUIAction_ReserachTechnology(unpack(arg))
		end
	end
end
function SW.Walls.ToggleGate( _eId)
	if IsDead(_eId) then
		return
	end
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
	if x == 0 and y == 0 then return 0 end
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
	local minn = _walllength/2 - SW.Walls.CornerSize
	local maxx = _walllength/2 + SW.Walls.CornerSize
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
	if true then return end
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
function SW.Walls.PlaceNormalWall( pos, player)
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
	if nearestCorner == 0 then --No corner found? Create wall at location
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-200, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+200, 0, player)
		return SW.Walls.CreateEntity(Entities.XD_WallStraight, pos.X, pos.Y, 0, player)
	else
		--Corner found, search for best placement
		local cornerPos = GetPosition( nearestCorner)
		local newPos = SW.Walls.GetBestFit( cornerPos, pos, 400)
		--Calculate angle between corner and proposed position
		local angle = SW.Walls.GetAngle( newPos.X - cornerPos.X, newPos.Y - cornerPos.Y)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, newPos.X + math.cos(math.rad(angle))*200, newPos.Y+ math.sin(math.rad(angle))*200, angle, player)
		return SW.Walls.CreateEntity(Entities.XD_WallStraight, newPos.X, newPos.Y, angle+90, player)
	end
end
function SW.Walls.PlaceClosingWall( pos, player)
	--New algorithm, will do for now
	if true then return SW.Walls.PlaceClosingWallNEW( pos, player) end
	--Stop now and dont use the old algorithm
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
function SW.Walls.PlaceStartWall( pos, player)
	SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-200, 0, player)
	SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+200, 0, player)
	return SW.Walls.CreateEntity(Entities.XD_WallStraight, pos.X, pos.Y, 0, player)
end
function SW.Walls.PlaceStartGate( pos, player)
	SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-300, 0, player)
	SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+300, 0, player)
	return SW.Walls.CreateEntity(Entities.XD_WallStraightGate, pos.X, pos.Y, 0, player)
end
function SW.Walls.GetAdjacentWalls( _pos, _player)
	return Logic.GetPlayerEntitiesInArea( _player, Entities.XD_WallStraight, _pos.X, _pos.Y, 400, 5) 
		+ Logic.GetPlayerEntitiesInArea( _player, Entities.XD_WallStraightGate, _pos.X, _pos.Y, 600, 5)
		+ Logic.GetPlayerEntitiesInArea( _player, Entities.XD_WallStraightGate_Closed, _pos.X, _pos.Y, 600, 5)
end
function SW.Walls.AreWallsAdjacent( _pos, _eId) --use _eId as black list
	local data = {Logic.GetEntitiesInArea( Entities.XD_WallStraight, _pos.X, _pos.Y, 500, 16)}
	for i = 2, data[1]+1 do
		if data[i] ~= _eId then
			if SW.Walls.WallAdjacentToPos( _pos, data[i]) then
				return true
			end
		end
	end
	data = {Logic.GetEntitiesInArea( Entities.XD_WallStraightGate, _pos.X, _pos.Y, 700, 16)}
	for i = 2, data[1]+1 do
		if data[i] ~= _eId then
			if SW.Walls.WallAdjacentToPos( _pos, data[i]) then
				return true
			end
		end
	end
	data = {Logic.GetEntitiesInArea( Entities.XD_WallStraightGate_Closed, _pos.X, _pos.Y, 700, 16)}
	for i = 2, data[1]+1 do
		if data[i] ~= _eId then
			if SW.Walls.WallAdjacentToPos( _pos, data[i]) then
				return true
			end
		end
	end
	return false
end
function SW.Walls.WallAdjacentToPos( _pos, _eId)		-- returns true if the _eId is connected with the corner
	local secondPos = GetPosition( _eId)
	local orientation = Logic.GetEntityOrientation( _eId)
	local realAngle = SW.Walls.GetAngle( _pos.X - secondPos.X, _pos.Y - secondPos.Y)
	local diff = math.mod(orientation - realAngle + 90, 360)		--range: [0,360]-[0,360]+90 = [-270, 450]
	if (diff < 5 and diff > -5) or (diff < -175 and diff > -185) or (diff < 185 and diff > 175) or (diff < 365 and diff > 355) then		--diff == 0 or diff == 180, float isnt precise enough
		return true
	end
	return false
end
function SW.Walls.PlaceGate( pos, player)
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
	if nearestCorner == 0 then --No corner found? Create wall at location
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y-300, 0, player)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, pos.X, pos.Y+300, 0, player)
		return SW.Walls.CreateEntity(Entities.XD_WallStraightGate, pos.X, pos.Y, 0, player)
	else
		--Corner found, search for best placement
		local cornerPos = GetPosition( nearestCorner)
		local newPos = SW.Walls.GetBestFit( cornerPos, pos, 600)
		--LuaDebugger.Log("X:"..newPos.X.." Y:"..newPos.Y)
		--Calculate angle between corner and proposed position
		local angle = SW.Walls.GetAngle( newPos.X - cornerPos.X, newPos.Y - cornerPos.Y)
		SW.Walls.CreateEntity(Entities.XD_WallCorner, newPos.X + math.cos(math.rad(angle))*300, newPos.Y+ math.sin(math.rad(angle))*300, angle, player)
		return SW.Walls.CreateEntity(Entities.XD_WallStraightGate, newPos.X, newPos.Y, angle+90, player)
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
	SW.PreciseLog.Log("Mauerbau: Creating "..(Logic.GetEntityTypeName(_eType) or "unknown").." at X=".._x.." Y=".._y.." rot=".._rot.." for player ".._pos)
	if _x <= 0 or _x >= SW.Walls.WorldSize or _y <= 0 or _y >= SW.Walls.WorldSize then
		_x = 100
		_y = 100
	end
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
function SW.Walls.IsBusy(_eId)
	if Logic.IsConstructionComplete( _eId) == 0 then
		return true
	end
	if Logic.GetRemainingUpgradeTimeForBuilding( _eId) ~= Logic.GetTotalUpgradeTimeForBuilding( _eId) then
		return true
	end
	return false
end
function SW.Walls.PlaceClosingWallNEW( pos, player)
	local list = {}
	local listOfCorners = S5Hook.EntityIteratorTableize(Predicate.OfPlayer(player), Predicate.OfType(Entities.XD_WallCorner), Predicate.InCircle( pos.X, pos.Y, 2000))
	local listOfPos = {}
	for k,v in pairs(listOfCorners) do
		listOfPos[k] = GetPosition(v)
	end
	local delX, delY
	local dis
	local disMin = SW.Walls.Walllength - 2*SW.Walls.CornerSize
	disMin = disMin*disMin
	-- 600 == Length of gate
	local disMax = 600 + 2*SW.Walls.CornerSize
	disMax = disMax*disMax
	-- use val^2 to avoid math.sqrt
	-- search for corners with appropriate distance
	for k,v in pairs(listOfCorners) do
		for k2,v2 in pairs(listOfCorners) do
			if k2 > k then
				delX = listOfPos[k].X - listOfPos[k2].X
				delY = listOfPos[k].Y - listOfPos[k2].Y
				dis = delX*delX+delY*delY
				if dis >= disMin and dis <= disMax then
					table.insert( list, { listOfPos[k], listOfPos[k2]})
				end
			end
		end
	end
	-- list now contains a list of pairs of positions where a wall might be good
	-- Found all corners in suitable distance
	local list2 = {}
	for k,v in pairs(list) do
		local posNew, angleNew, typee
		posNew, angleNew = SW.Walls.IsWallSegmentPlaceable( v[1], v[2], 400)
		if posNew ~= nil then
			if Logic.GetEntityAtPosition( posNew.X, posNew.Y) == 0 then
				typee = "Wall"
				table.insert( list2, {posNew, angleNew, typee})
			end
		end
		posNew, angleNew = SW.Walls.IsWallSegmentPlaceable( v[1], v[2], 600)
		if posNew ~= nil then
			if Logic.GetEntityAtPosition( posNew.X, posNew.Y) == 0 then
				typee = "Gate"
				table.insert( list2, {posNew, angleNew, typee})
			end
		end
	end
	-- list2 contains entries with pos, angle und walltype that might complete a wall
	--LuaDebugger.Break()
	local toPlace = SW.Walls.GetNearestCandidate( pos, list2)
	if toPlace ~= nil then
		local posNew, angleNew, typee = toPlace[1], toPlace[2], toPlace[3]
		SW.Walls.DbgMsg("Abschlussmauer bei "..posNew.X.." "..posNew.Y.." mit Winkel "..angleNew.." und Typ "..typee)
		--Corners are already placed, so just place wall or gate
		if typee == "Wall" then		-- place wall
			return SW.Walls.CreateEntity( Entities.XD_WallStraight, posNew.X, posNew.Y, angleNew+90, player)
		else						-- place gate
			return SW.Walls.CreateEntity( Entities.XD_WallStraightGate, posNew.X, posNew.Y, angleNew+90, player)
		end
		return
	end
	-- END OF TRYING TO CLOSE WALL PIECE
	--	It wasnt possible to close a missing wall piece
	--	Now search for nearby corners with exactly 1 wall piece nearby
	local candidate = nil
	local dis = 5000*5000
	for eId in S5Hook.EntityIterator(Predicate.OfPlayer( player), Predicate.OfType(Entities.XD_WallCorner), Predicate.InCircle( pos.X, pos.Y, 2000)) do
		local pos2 = GetPosition(eId)
		if SW.Walls.GetAdjacentWalls( pos2, player) == 1 then
			if (pos.X-pos2.X)*(pos.X-pos2.X)+(pos.Y-pos2.Y)*(pos.Y-pos2.Y) < dis then
				candidate = eId
				dis = (pos.X-pos2.X)*(pos.X-pos2.X)+(pos.Y-pos2.Y)*(pos.Y-pos2.Y)
			end
		end
	end
	if candidate == nil then
		SW.Walls.DbgMsg("Keine geeignete Ecke gefunden!")
		return
	end
	-- Found a corner with exactly 1 wall nearby? BRING ME THIS WALL
	local wallId = nil
	local cornerPos = GetPosition(candidate)
	local n1, possId1 = Logic.GetPlayerEntitiesInArea( player, Entities.XD_WallStraight, cornerPos.X, cornerPos.Y, 500, 5)
	local n2, possId2 = Logic.GetPlayerEntitiesInArea( player, Entities.XD_WallStraightGate, cornerPos.X, cornerPos.Y, 700, 5)
	local n3, possId3 = Logic.GetPlayerEntitiesInArea( player, Entities.XD_WallStraightGate_Closed, cornerPos.X, cornerPos.Y, 700, 5)
	if n1 == 1 then wallId = possId1
	elseif n2 == 1 then wallId = possId2
	elseif n3 == 1 then wallId = possId3 end
	if wallId == nil then
		SW.Walls.DbgMsg("Found corner with 1 adjacent element, wasnt able to find element.")
		return
	end
	local wallPos = GetPosition(wallId)
	-- Wanted position: cornerPos + (cornerPos-wallPos)
	local toPlace = SW.Walls.GetBestFit( cornerPos, {X = cornerPos.X*2-wallPos.X, Y = cornerPos.Y*2-wallPos.Y}, 400)
	local toPlaceAngle = SW.Walls.GetAngle( toPlace.X-cornerPos.X, toPlace.Y-cornerPos.Y)
	--Everything decided
	SW.Walls.CreateEntity(Entities.XD_WallCorner, toPlace.X + math.cos(math.rad(toPlaceAngle))*200, toPlace.Y+ math.sin(math.rad(toPlaceAngle))*200, 0, player)
	return SW.Walls.CreateEntity(Entities.XD_WallStraight, toPlace.X, toPlace.Y, toPlaceAngle+90, player)
end
function SW.Walls.IsWallSegmentPlaceable( _pos1, _pos2, _walllength)
	-- Returns the position and rotation of a valid wall segment that´ll connect both corners
	local retList = SW.Walls.SearchValidPoints( _pos1.X, _pos1.Y, _walllength)
	local angle, tablee
	local n, dir, length
	local target, dis
	for k,v in pairs(retList) do
		--direction: v-pos1
		dir = { X = v.X - _pos1.X, Y = v.Y - _pos1.Y}
		length = math.sqrt(dir.X*dir.X+dir.Y*dir.Y)
		n = { X = dir.X/length*_walllength/2, Y = dir.Y/length*_walllength/2}
		--norm it to 1: n
		--calc v+n*walllength/2
		target = { X = v.X + n.X, Y = v.Y + n.Y}
		--check if close enough
		dis = math.sqrt((target.X-_pos2.X)*(target.X-_pos2.X)+(target.Y-_pos2.Y)*(target.Y-_pos2.Y))
		if dis <= SW.Walls.CornerSize then
			tablee = v
			angle = SW.Walls.GetAngle( _pos1.X-v.X, _pos1.Y-v.Y)
			break;
		end
	end
	if tablee ~= nil  then
		return tablee, SW.Walls.GetAngle( _pos1.X-tablee.X, _pos1.Y-tablee.Y)
	end
end
function SW.Walls.GetNearestCandidate( _pos, _list)
	local dis
	local currIndex = nil
	for k,v in pairs(_list) do
		--if currIndex == nil then
		--	dis = (v[1].X-_pos.X)^2+(v[1].Y-_pos.Y)^2
		--	currIndex = k
		--end
		local newDis = (v[1].X-_pos.X)^2+(v[1].Y-_pos.Y)^2
		if currIndex == nil or newDis < dis then
			currIndex = k
			dis = newDis
		end
		--LuaDebugger.Break()
	end
	if currIndex ~= nil then
		return _list[currIndex]
	end
end
SW.Walls.ListOfSoldBuildings = {}
function SW.Walls.SellWall( _eId)
	if SW.Walls.ListOfSoldBuildings[_eId] == nil then
		SW.Walls.ListOfSoldBuildings[_eId] = Logic.GetTimeMs()
	else
		if SW.Walls.ListOfSoldBuildings[_eId] + 30000 <= Logic.GetTimeMs() then
			SW.Walls.ListOfSoldBuildings[_eId] = Logic.GetTimeMs()
		else 	--Gebäude wird schon abgerissen? RAUS
			return
		end
	end
	-- If script arrives at this point, wall may be sold
	local pos = GetPosition( _eId)
	Logic.CreateEffect( GGL_Effects.FXBuildingSmokeMedium, pos.X, pos.Y, 0)
	Logic.HurtEntity( _eId, 10000)
	-- Kein Ressourcereturn
end

function SW.Walls.Test(_len)
	for dx = -6, 6 do
		for dy = -6, 6 do
			local p = SW.Walls.IsWallSegmentPlaceable({X=0,Y=0}, {X = 100*dx,Y = 100*dy}, _len)
			if p ~= nil then
				LuaDebugger.Log("dx: "..dx.." dy: "..dy.." X "..p.X.." Y "..p.Y)
			end
		end
	end
end
function SW.Walls.FindCommonElement( _t1, _t2)
	for k,v in pairs(_t1) do
		for k2,v2 in pairs(_t2) do
			if SW.Walls.table_equals(v, v2) then
				return v
			end
		end
	end
end
function SW.Walls.table_equals(_t, _t2, _done)

    if not _done then
        if not SW.Walls.table_equals(_t2,_t, true) then
            return false;
        end;
    end;

    for k,v in pairs(_t) do

        if type(_t2[k]) == type(v) then

            if type(v) == "table" then
                if not SW.Walls.table_equals(_t2[k], v) then
                    return false;
                end;
            else
                if _t2[k] ~= v then
                    return false;
                end;
            end;
        else
            return false;
        end;
    end;

    return true;
end;
function SW.Walls.DbgMsg(_s)
	if LuaDebugger.Log then
		LuaDebugger.Log(_s)
	else
		Message( _s)
	end
end
function SW.Walls.CreateSettlement()
	local data = {
		{8, 29600, 28200},
		{2, 24600, 26600},
		{8, 30900, 30300},
		{8, 34700, 28000},
		{8, 33900, 28800},
		{8, 33700, 31500},
		{2, 33300, 44600},
		{2, 36500, 28400},
		{2, 28600, 30200},
		{2, 29500, 29100},
		{1, 30000, 32300},
		{8, 33900, 28000},
		{8, 33700, 27000},
		{8, 33000, 27000},
		{38, 35100, 31000},
		{2, 36500, 29700},
		{8, 23200, 27200},
		{25, 30000, 30800},
		{8, 33900, 43700},
		{20, 23125, 25950},
		{2, 32200, 26200},
		{25, 31200, 26000},
		{23, 33100, 28100},
		{25, 33800, 30100},
		{38, 35200, 29200},
		{23, 32000, 27700},
		{20, 31525, 31550},
		{23, 30900, 27700},
		{27, 30700, 29100},
		{14, 34442, 44703.3984375}
	}
	for i = 1, table.getn(data) do
		Logic.CreateEntity( data[i][1], data[i][2], data[i][3], 0, 1)
	end
end

SW.Walls = SW.Walls2