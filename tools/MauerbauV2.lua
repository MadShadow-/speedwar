--MAUERBAU

--NIEMAND HAT DIE ABSICHT, EINE MAUER ZU ERRICHTEN

-- TODO LIST:

--	Alternative for closing wall: Search for corners, check all edge points for blocking and place wall in order to complete blocking?

SW = SW or {}
SW.Walls2 = {}
SW.Walls2.Walllength = 400		--Length of wall, used for assessing good position offsets
SW.Walls2.CornerSize = 50		--Radius of corner, used for assessing good position offsets
SW.Walls2.Gatelength = 600		--Length of gates, some thing
SW.Walls2.SnapDistance = 2500
SW.Walls2.WallType = Entities.XD_WallStraight
SW.Walls2.WorldSize = Logic.WorldGetSize()	--Used for checking if position is good
SW.Walls2.ListOfCorners = {}	--Values: [pId] = list of {X, Y, eId, numNeighbours}
SW.Walls2.GateOffsets = {}	--Values: {secondX, secondY, gateX, gateY}
SW.Walls2.WallOffsets = {}	--Values: {secondX, secondY, wallX, wallY, angle}
function SW.Walls2.Init()
	local self = SW.Walls2
	-- Get all good offsets
	local maxDisWall = math.floor((self.Walllength + self.CornerSize*2)/100)
	local minDisWall = math.floor((self.Walllength - self.CornerSize*2)/100)
	local maxDisGate = math.floor((self.Gatelength + self.CornerSize*2)/100)
	local minDisGate = math.floor((self.Gatelength - self.CornerSize*2)/100)
	local maxDisWallHalf = math.floor(maxDisWall/2)
	local maxDisGateHalf = math.floor(maxDisGate/2)
	for x = -maxDisWallHalf, maxDisWallHalf do
		for y = -maxDisWallHalf, maxDisWallHalf do
			local dis = (x*x+y*y)*4	--x and y is position of wall position; realdistance is double the distance
			if minDisWall*minDisWall <= dis and dis <= maxDisWall*maxDisWall then	--avoid sqrt for SPEED
				table.insert( self.WallOffsets, {100*x, 100*y, 200*x, 200*y, self.GetAngle( x, y)})
			end
		end
	end
	for x = -maxDisGateHalf, maxDisGateHalf do
		for y = -maxDisGateHalf, maxDisGateHalf do
			local dis = (x*x+y*y)*4	--x and y is position of wall position; realdistance is double the distance
			if minDisGate*minDisGate <= dis and dis <= maxDisGate*maxDisGate then	--avoid sqrt for SPEED
				table.insert( self.GateOffsets, {100*x, 100*y, 200*x, 200*y, self.GetAngle( x, y)})
			end
		end
	end
	for i = 1, 8 do
		SW.Walls2.ListOfCorners[i] = {}
	end
	self.InitGUIHooks()
	self.WorldSize = Logic.WorldGetSize()
	self.DestroyTriggerId = Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_Walls2_OnDestroyed", "SW_Walls2_OnDestroyedAction", 1)
end
function SW.Walls2.DebugStuff()
	for i = 1, 8 do
		ResearchAllUniversityTechnologies(i)
		AddStone(i, 5000)
	end
end
function SW_Walls2_OnDestroyed()
	-- Interesting events:
	-- Destruction of a wall or gate
	local typee = Logic.GetEntityType(Event.GetEntityID())
	return (typee == Entities.XD_WallStraight or typee == Entities.XD_WallStraightGate or typee == Entities.XD_WallStraightGate_Closed)
end
function SW_Walls2_OnDestroyedAction()
	-- Interesting piece was destroyed
	local eId = Event.GetEntityID()
	local pId = GetPlayer( eId)
	-- As of lack of better methods, recalculate all corners of this player
	local t = SW.Walls2.ListOfCorners[pId]
	for i = table.getn(t), 1, -1 do
		t[i].numNeighbours = SW.Walls2.GetNeighbourCount( t[i], pId, eId)
		if t[i].numNeighbours == 0 then
			MakeVulnerable(t[i].eId)
			SW_DestroySafe(t[i].eId)
			table.remove(t, i)
		end
	end
end
function SW.Walls2.InitGUIHooks() --Sell building and toggle gate
	-- Sell building stuff
	SW.Walls2.SellBuilding = GUI.SellBuilding
	GUI.SellBuilding = function( _eId)
		local typee = Logic.GetEntityType(_eId)
		if typee == Entities.XD_WallStraightGate or typee == Entities.XD_WallStraightGate_Closed or typee == Entities.XD_WallStraight then
			Sync.Call( "SW.Walls2.SellWall", _eId)
		else
			SW.Walls2.SellBuilding( _eId)
		end
	end
	-- Now: Toggle gate
	-- Give used icon a good texture
	XGUIEng.TransferMaterials("Research_Banking", "Research_PickAxe")
	SW.Walls2.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()	-- Hide icon if clay mine is selected
		SW.Walls2.GameCallback_GUI_SelectionChanged()
		local sel = GUI.GetSelectedEntity()
		if sel == nil then
			return
		end
		local typee = Logic.GetEntityType( sel)
		--show claymine menu on selection
		XGUIEng.ShowWidget("Claymine", 1)
		XGUIEng.ShowWidget("Commands_Claymine", 1)
		XGUIEng.ShowAllSubWidgets("Commands_Claymine", 0)
		if typee == Entities.PB_ClayMine1 then --Show only UP1
			if not SW.Walls2.IsBusy(sel) then
				XGUIEng.ShowWidget("Upgrade_Claymine1", 1)
			end
			return
		end
		if typee == Entities.PB_ClayMine2 then --Show only UP2
			if not SW.Walls2.IsBusy(sel) then
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
	-- Give the button a nice tool tip
	SW.Walls2.GUITooltip_ResearchTechnologies = GUITooltip_ResearchTechnologies
	GUITooltip_ResearchTechnologies = function( ...)
		SW.Walls2.GUITooltip_ResearchTechnologies(unpack(arg))
		if arg[1] == Technologies.T_PickAxe then
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "")
			if Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.XD_WallStraightGate then
				XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "Eure Vasallen werden das Tor unverzüglich schließen.")
			else
				XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, "Eure Vasallen werden das Tor unverzüglich öffnen.")
			end
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "")
		end
	end
	SW.Walls2.GUIAction_ReserachTechnology = GUIAction_ReserachTechnology
	GUIAction_ReserachTechnology = function( ...)
		if arg[1] == Technologies.T_PickAxe then
			local sel = GUI.GetSelectedEntity()
			if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
				local pos = GetPosition(sel);
				local type = Logic.GetEntityType(sel);
				local gates = {Logic.GetPlayerEntitiesInArea(GUI.GetPlayerID(), type, pos.X, pos.Y, 2000, 16)};
				if gates[1] > 0 then
					for i = 2, table.getn(gates) do
						Sync.Call( "SW.Walls2.ToggleGate", gates[i]);
					end
				end
			else
				Sync.Call( "SW.Walls2.ToggleGate", sel);
			end
		else
			SW.Walls.GUIAction_ReserachTechnology(unpack(arg))
		end
	end
end
function SW.Walls2.ToggleGate( _eId)
	if IsDead(_eId) then
		return
	end
	Trigger.DisableTrigger(SW.Walls2.DestroyTriggerId)
	local typee = Logic.GetEntityType( _eId)
	local selected = (GUI.GetSelectedEntity() == _eId)
	local pos = GetPosition( _eId)
	local rot = Logic.GetEntityOrientation( _eId)
	local pId = GetPlayer( _eId)
	if typee == Entities.XD_WallStraightGate then
		local hpDiff = Logic.GetEntityMaxHealth( _eId) - Logic.GetEntityHealth( _eId)
		DestroyEntity( _eId)
		local eId = SW.Walls2.CreateGate( pId, pos, rot+90)
		Logic.HurtEntity( eId, hpDiff)
		if selected then
			GUI.SelectEntity( eId)
		end
	else
		local hpDiff = Logic.GetEntityMaxHealth( _eId) - Logic.GetEntityHealth( _eId)
		DestroyEntity( _eId)
		local eId = SW.Walls2.CreateGateOpen( pId, pos, rot+90)
		Logic.HurtEntity( eId, hpDiff)
		if selected then
			GUI.SelectEntity( eId)
		end
	end
	Trigger.EnableTrigger(SW.Walls.DestroyTriggerId)
end
function SW.Walls2.SellWall( _eId)
	if IsDead(_eId) then return end
	local pos = GetPosition(_eId)
	Logic.CreateEffect( GGL_Effects.FXCrushBuilding, pos.X, pos.Y, 1)
	DestroyEntity( _eId)
end
function SW.Walls2.IsBusy(_eId)
	if Logic.IsConstructionComplete( _eId) == 0 then
		return true
	end
	if Logic.GetRemainingUpgradeTimeForBuilding( _eId) ~= Logic.GetTotalUpgradeTimeForBuilding( _eId) then
		return true
	end
	return false
end
function SW.Walls2.UpdateCornerList( _pId)
	local t = SW.Walls2.ListOfCorners[_pId]
	for i = table.getn(t), 1, -1 do
		t[i].numNeighbours = SW.Walls2.GetNeighbourCount( t[i], _pId)
	end
end
function SW.Walls2.PlaceNormalWall( _pos, _pId, _angle)
	local self = SW.Walls2
	-- first get all nearby corners
	local cornerKey
	local cornerDis = self.SnapDistance*self.SnapDistance
	for k,v in pairs(self.ListOfCorners[_pId]) do
		-- v = { X, Y, eId}
		if self.GetDistanceSquared( _pos, {X = v.X, Y = v.Y}) < cornerDis then	--Distance is good enough
			cornerKey = k
			cornerDis = self.GetDistanceSquared( _pos, v)
		end
	end
	if cornerKey == nil then	-- No corner found? Create new wall
		SW.Walls2.PlaceStartWall( _pos, _pId, _angle)
		--SW.Walls2.CreateWall( _pId, _pos, 90, {X = _pos.X, Y = _pos.Y+200}, {X = _pos.X, Y = _pos.Y-200})
	else	-- Corner found? Place wall next to it!
		-- We found a good corner, calculate angle
		local data = self.ListOfCorners[_pId][cornerKey]
		local cornerAngle = self.GetAngle( _pos.X - data.X, _pos.Y - data.Y)
		-- Check for diff compared to all possible offsets
		local key
		local angle = 360
		for k,v in pairs(self.WallOffsets) do
			if self.GetAngleDiff( cornerAngle, v[5]) < angle then
				key = k
				angle = self.GetAngleDiff( cornerAngle, v[5])
			end
		end
		-- Found some good offset?
		if key == nil then
			--Message("Mauerbau: Fuck that shit.")
			return
		end
		-- Good offset found? Get position!
		local wData = self.WallOffsets[key]
		SW.Walls2.CreateWall( _pId, {X = data.X + wData[1], Y = data.Y + wData[2]}, wData[5], {X = data.X + wData[3], Y = data.Y + wData[4]})
	end
end
function SW.Walls2.PlaceGate( _pos, _pId, _angle)
	local self = SW.Walls2
	-- first get all nearby corners
	local cornerKey
	local cornerDis = self.SnapDistance*self.SnapDistance
	for k,v in pairs(self.ListOfCorners[_pId]) do
		-- v = { X, Y, eId}
		if self.GetDistanceSquared( _pos, {X = v.X, Y = v.Y}) < cornerDis then	--Distance is good enough
			cornerKey = k
			cornerDis = self.GetDistanceSquared( _pos, v)
		end
	end
	if cornerKey == nil then	-- No corner found? Create new gate
		SW.Walls2.PlaceStartGate( _pos, _pId, _angle)
		--SW.Walls2.CreateGate( _pId, _pos, 90, {X = _pos.X, Y = _pos.Y+300}, {X = _pos.X, Y = _pos.Y-300})
	else	-- Corner found? Place wall next to it!
		-- We found a good corner, calculate angle
		local data = self.ListOfCorners[_pId][cornerKey]
		local cornerAngle = self.GetAngle( _pos.X - data.X, _pos.Y - data.Y)
		-- Check for diff compared to all possible offsets
		local key
		local angle = 360
		for k,v in pairs(self.GateOffsets) do
			if self.GetAngleDiff( cornerAngle, v[5]) < angle then
				key = k
				angle = self.GetAngleDiff( cornerAngle, v[5])
			end
		end
		-- Found some good offset?
		if key == nil then
			--Message("Mauerbau: Fuck that shit.")
			return
		end
		-- Good offset found? Get position!
		local wData = self.GateOffsets[key]
		SW.Walls2.CreateGate( _pId, {X = data.X + wData[1], Y = data.Y + wData[2]}, wData[5], {X = data.X + wData[3], Y = data.Y + wData[4]})
	end
end
function SW.Walls2.PlaceStartWall( _pos, _pId, _angle)
	if not _angle then
		_angle = 90
	end
	local offSize = 200
	local offX = math.cos(math.rad(_angle))*offSize
	local offY = math.sin(math.rad(_angle))*offSize
	SW.Walls2.CreateWall( _pId, _pos, _angle, {X = _pos.X+offX, Y = _pos.Y+offY}, {X = _pos.X-offX, Y = _pos.Y-offY})
end
function SW.Walls2.PlaceStartGate( _pos, _pId, _angle)
	if not _angle then
		_angle = 90
	end
	local offSize = 300
	local offX = math.cos(math.rad(_angle))*offSize
	local offY = math.sin(math.rad(_angle))*offSize
	SW.Walls2.CreateGate( _pId, _pos, _angle, {X = _pos.X+offX, Y = _pos.Y+offY}, {X = _pos.X-offX, Y = _pos.Y-offY})
end
-- rotation logic:
-- 	rotation of 90 degrees equals corners at x, y \pm 200
-- 	rotation of 0 degrees equals corners at x\pm 200, y
--  so in general fpr rotation \alpha use x \pm cos(\alpha), y \pm sin(\alpha)

-- closing wall simi edition
--	searches for nearby corners, then tries to attach wall to this corner in given rotation
--	note: there are only 12 valid angles, so the argument will be changed to the next good angle
--[[was ich noch ganz cool fände, wäre ein mauerstück, welches ähnlich der abschlussmauer 
angebaut wird, nur wird die rotation der mauer selbst verwendet 
(-> also anbauen in einem bestimmten winkel, unabh. der position)
]]
function SW.Walls2.PlaceSimiClosingWall( _pos, _pId, _angle)
	local self = SW.Walls2
	-- Get list of nearby corners
	local cornerKeyList = {}
	for k,v in pairs(self.ListOfCorners[_pId]) do
		-- v = { X, Y, eId}
		if self.GetDistanceSquared( _pos, {X = v.X, Y = v.Y}) < self.SnapDistance*self.SnapDistance then	--Distance is good enough
			table.insert(cornerKeyList, k)
		end
	end
	-- now find next best angle to attach thingie
	local offsetKey
	local dis = 1000
	for k,v in pairs(self.WallOffsets) do
		if self.GetAngleDiff( _angle, v[5]) < dis then
			offsetKey = k
			dis = self.GetAngleDiff( _angle, v[5])
		end
	end
	-- so angle is now a valid thing
	-- check all nearby corners if a wall is that angle is attachable
	local entry
	local wallX = self.WallOffsets[offsetKey][3]
	local wallY = self.WallOffsets[offsetKey][4]
	local validKeys = {}
	for k,v in pairs(cornerKeyList) do
		entry = self.ListOfCorners[_pId][v]
		--{X, Y, eId, numNeighbours}
		if self.IsPosValid{X = entry.X + wallX, Y = entry.Y + wallY} then
			table.insert( validKeys, v)
		end
	end
	-- now all valid positions are found, place wall at good spot(= closest to _pos)
	local dis = 1000000000
	local key
	for k,v in pairs(validKeys) do
		if self.GetDistanceSquared( _pos, self.ListOfCorners[_pId][v]) < dis then
			dis = self.GetDistanceSquared( _pos, self.ListOfCorners[_pId][v])
			key = v
		end
	end
	if key == nil then
		--Message("FUCK THIS SHUIT")
		return
	end
	local cornerData = self.ListOfCorners[_pId][key] 	-- {X, Y, eId, numNeighbours}
	local offsetData = self.WallOffsets[offsetKey] 		-- {secondX, secondY, wallX, wallY, angle}
	SW.Walls2.CreateWall( _pId, {X = cornerData.X + offsetData[1], Y = cornerData.Y + offsetData[2]}, offsetData[5], 
	                      {X = cornerData.X + offsetData[3], Y = cornerData.Y + offsetData[4]})
end

-- closing wall
-- Algorithm:
--	1. Search for corners where a wall is placeable inbetween
--	2. Same, but with gates
--	3. Search for corners with only one wall attached, continue that wall
--	4. Insult player
function SW.Walls2.PlaceClosingWall( _pos, _pId)
	local self = SW.Walls2
	-- Get list of nearby corners
	local cornerKeyList = {}
	for k,v in pairs(self.ListOfCorners[_pId]) do
		-- v = { X, Y, eId}
		if self.GetDistanceSquared( _pos, {X = v.X, Y = v.Y}) < self.SnapDistance*self.SnapDistance then	--Distance is good enough
			table.insert(cornerKeyList, k)
		end
	end
	-- STEP 1: Find nearby corners that can fit a wall in
	for _,k in pairs(cornerKeyList) do
		for _, k2 in pairs(cornerKeyList) do
			local v1 = self.ListOfCorners[_pId][k]
			local v2 = self.ListOfCorners[_pId][k2]
			local offX, offY, angle = SW.Walls2.IsOffsetGood( self.WallOffsets, v1.X-v2.X, v1.Y-v2.Y)
			if offX ~= nil then		-- offset is nice
				if Logic.GetEntityAtPosition( v2.X + offX, v2.Y + offY) == 0 then	-- no entity placed? go for it!
					SW.Walls2.CreateWall( _pId, { X = v2.X + offX, Y = v2.Y + offY}, angle)
					return
				end
			end
		end
	end
	-- STEP 2: Same with gates
	for _,k in pairs(cornerKeyList) do
		for _, k2 in pairs(cornerKeyList) do
			local v1 = self.ListOfCorners[_pId][k]
			local v2 = self.ListOfCorners[_pId][k2]
			local offX, offY, angle = SW.Walls2.IsOffsetGood( self.GateOffsets, v1.X-v2.X, v1.Y-v2.Y)
			if offX ~= nil then		-- offset is nice
				if Logic.GetEntityAtPosition( v2.X + offX, v2.Y + offY) == 0 then	-- no entity placed? go for it!
					SW.Walls2.CreateGate( _pId, { X = v2.X + offX, Y = v2.Y + offY}, angle)
					return
				end
			end
		end
	end
	-- STEP 3: Try to continue a wall
	for _,k in pairs(cornerKeyList) do
		local v = self.ListOfCorners[_pId][k]
		if v.numNeighbours == 1 then	-- thats a nice wall!
			local _, wallId = SW.Walls2.GetNeighbourCount( v, _pId)
			if wallId == 0 then return end
			local pos = GetPosition(wallId)
			local myAngle = self.GetAngle( - pos.X + v.X, - pos.Y + v.Y)
			local key
			local angle = 360
			for k,v in pairs(self.WallOffsets) do
				if self.GetAngleDiff( myAngle, v[5]) < angle then
					key = k
					angle = self.GetAngleDiff( myAngle, v[5])
				end
			end
			if key == nil then --Message("Mauerbau: WTF?") return end
			-- so found some nice wall, get angle from wall to corner and a nice offset to continue
			local wData = self.WallOffsets[key]
			SW.Walls2.CreateWall( _pId, {X = v.X + wData[1], Y = v.Y + wData[2]}, wData[5], {X = v.X + wData[3], Y = v.Y + wData[4]})
			return
		end
	end
	--SW.Walls2.MsgForPlayer( _pId, "Abschlussmauer: Kein guter Bauplatz gefunden. Leite Selbstzerstörung ein.")
end
-- list is like list of offsets in init
-- returns postion table if good, nil if not
function SW.Walls2.IsOffsetGood( _list, _offX, _offY)
	for k,v in pairs(_list) do
		-- v = {secondX, secondY, offX, offY}
		if SW.Walls2.GetDistanceSquared( { X = v[3], Y = v[4]}, { X = _offX, Y = _offY}) <= 100 then
			return v[1], v[2], v[5]
		end
	end
end
function SW.Walls2.GetDistanceSquared( _pos1, _pos2)
	return (_pos1.X-_pos2.X)*(_pos1.X-_pos2.X) + (_pos1.Y-_pos2.Y)*(_pos1.Y-_pos2.Y)
end
-- Calculates the angle of a given vector relative to the x-Axis, ranging from 0 to 360
function SW.Walls2.GetAngle( x, y)
	if x == 0 and y == 0 then return 0 end
	-- Normalize (x,y), then cos alpha = x, sin alpha = y
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
-- Calcutes x = |_a1 - _a2| with 0 <= x < 360 
function SW.Walls2.GetAngleDiff( _a1, _a2)
	return math.mod( _a1-_a2 + 360, 360)
end
-- the additional arguments are positions for wall corners that have to be placed
function SW.Walls2.CreateWall( _pId, _pos, _angle, ...)
	if not SW.Walls2.IsPosValid( _pos) then return end
	Logic.CreateEntity( SW.Walls2.WallType, _pos.X, _pos.Y, _angle+90, _pId)
	for i = 1, arg.n do
		if SW.Walls2.IsPosValid(arg[i]) then
			local eId = Logic.CreateEntity( Entities.XD_WallCorner, arg[i].X, arg[i].Y, 0, _pId)
			MakeInvulnerable( eId)
			Logic.SetEntitySelectableFlag( eId, 0)
			table.insert(SW.Walls2.ListOfCorners[_pId], { X = arg[i].X, Y = arg[i].Y, eId = eId, numNeighbours = SW.Walls2.GetNeighbourCount(arg[i], _pId)})
		else
			--Message("Mauerbau: Failed to create corner at X="..arg[i].X.." Y="..arg[i].Y..": Pos invalid or used")
		end
	end
	SW.Walls2.UpdateCornerList( _pId)
end
function SW.Walls2.CreateGate( _pId, _pos, _angle, ...)
	for i = 1, arg.n do
		if SW.Walls2.IsPosValid(arg[i]) then
			local eId = Logic.CreateEntity( Entities.XD_WallCorner, arg[i].X, arg[i].Y, 0, _pId)
			MakeInvulnerable( eId)
			Logic.SetEntitySelectableFlag( eId, 0)
			table.insert(SW.Walls2.ListOfCorners[_pId], { X = arg[i].X, Y = arg[i].Y, eId = eId, numNeighbours = SW.Walls2.GetNeighbourCount(arg[i], _pId)})
		end
	end
	if not SW.Walls2.IsPosValid( _pos) then return 0 end
	local eId = Logic.CreateEntity( Entities.XD_WallStraightGate_Closed, _pos.X, _pos.Y, _angle+90, _pId)
	SW.Walls2.UpdateCornerList( _pId)
	return eId
end
function SW.Walls2.CreateGateOpen( _pId, _pos, _angle, ...)
	for i = 1, arg.n do
		if SW.Walls2.IsPosValid(arg[i]) then
			local eId = Logic.CreateEntity( Entities.XD_WallCorner, arg[i].X, arg[i].Y, 0, _pId)
			MakeInvulnerable( eId)
			Logic.SetEntitySelectableFlag( eId, 0)
			table.insert(SW.Walls2.ListOfCorners[_pId], { X = arg[i].X, Y = arg[i].Y, eId = eId, numNeighbours = SW.Walls2.GetNeighbourCount(arg[i], _pId)})
		end
	end
	if not SW.Walls2.IsPosValid( _pos) then return 0 end
	local eId = Logic.CreateEntity( Entities.XD_WallStraightGate, _pos.X, _pos.Y, _angle+90, _pId)
	SW.Walls2.UpdateCornerList( _pId)
	return eId
end
function SW.Walls2.GetNeighbourCount( _pos, _pId, _exclude)
	local self = SW.Walls2
	local count = 0
	local maxDis = 1000*1000
	local lastEntity = 0
	for k,v in pairs(self.ListOfCorners[_pId]) do
		if self.GetDistanceSquared( _pos, v) <= maxDis then	--Distance is good, check if corner is neighbour
			local deltaPos = { X = v.X - _pos.X, Y = v.Y - _pos.Y}			
			for k2, v2 in pairs(self.WallOffsets) do
				if self.GetDistanceSquared( deltaPos, {X = v2[3], Y = v2[4]}) <= 100 then	--Offsets match! Use tolerance cause of float
					local eId = Logic.GetEntityAtPosition(_pos.X + v2[1], _pos.Y + v2[2])
					local typee = Logic.GetEntityType( eId)
					if typee == Entities.XD_WallStraight and eId ~= _exclude then
						count = count + 1
						lastEntity = eId
					end
				end
			end
			for k2, v2 in pairs(self.GateOffsets) do
				if self.GetDistanceSquared( deltaPos, {X = v2[3], Y = v2[4]}) <= 100 then	--Offsets match! Use tolerance cause of float
					local eId = Logic.GetEntityAtPosition(_pos.X + v2[1], _pos.Y + v2[2])
					local typee = Logic.GetEntityType( eId)
					if (typee == Entities.XD_WallStraightGate or typee == Entities.XD_WallStraightGate_Closed) and eId ~= _exclude then
						count = count + 1
						lastEntity = eId
					end
				end
			end
		end
	end
	return count, lastEntity
end
function SW.Walls2.IsPosValid( _pos)
	return ((_pos.X > 0 and _pos.X < SW.Walls2.WorldSize and _pos.Y > 0 and _pos.Y < SW.Walls2.WorldSize) and not SW.Walls2.IsWall( Logic.GetEntityType( Logic.GetEntityAtPosition( _pos.X, _pos.Y))))
end
function SW.Walls2.IsWall( _type)
	return ( _type == Entities.XD_WallStraightGate or _type == Entities.XD_WallStraightGate_Closed or _type == Entities.XD_WallStraight)
end

function SW.Walls2.MsgForPlayer( _pId, _s)
	if GUI.GetPlayerID() == _pId then
		Message( _s)
	end
end



SW.Walls = SW.Walls2