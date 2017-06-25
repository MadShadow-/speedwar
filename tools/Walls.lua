Score.Player[0] = {} 
Score.Player[0]["buildings"] = 0
Score.Player[0]["all"] = 0

Walls = Walls or {};
Walls.isInWallConstructionState = false; -- player local.
Walls.currentConstructionPlan = {}; -- player local.
Walls.areConstructionPlansShown = false; -- player local.

Walls.CreatedWalls = {};
Walls.LegacyWalls = {};

Walls.FIND_VIRTUALCORNER_RANGE = 2; -- Range to snap to corner
Walls.FIND_VIRTUALCORNER_RANGE2 = Walls.FIND_VIRTUALCORNER_RANGE ^ 2;
Walls.MIN_WALL_RANGE = 4; -- Range between two corners (min wall length = 4)
Walls.MIN_WALL_RANGE2 = Walls.MIN_WALL_RANGE * Walls.MIN_WALL_RANGE;
Walls.MIN_WALL_RANGE_TO_ADJUSTMENT = 5;
Walls.MIN_WALL_RANGE_TO_ADJUSTMENT2 = Walls.MIN_WALL_RANGE_TO_ADJUSTMENT * Walls.MIN_WALL_RANGE_TO_ADJUSTMENT;
Walls.RANGE_FIND_WALL_TO_CONTINUE = 4000;
Walls.RANGE_FIND_WALL_TO_CONTINUE2 = Walls.RANGE_FIND_WALL_TO_CONTINUE * Walls.RANGE_FIND_WALL_TO_CONTINUE;
Walls.Players = {};

for i = 1,8 do
	Walls.Players[i] = {ConstructionPlans = {}, CreatedWalls = {} };
end;

--[[
-- Construction Plan Format --
{
	[1] = <-- wände bei corner 1
	{
		X = 
		Y = 
		attachCorner1 = wId, -- wID (wall), false (frei), true (kein corner mehr nötig, da letzter oder erster corner des cp) <-- erster
		attachCorner2 = wId, -- <- letzter
	
		walls = {wId1, wId2, ..}
		wallsToPreviousCorner = false, <- kein previous corner
		wallsToNextCorner = {} -> von corner 1 bis 2
	},

	[2] = <-- wände bei corner 2
	{
		X =
		Y =
		attachCorner1 = wId, -- wID (wall), false (frei)
		attachCorner2 = wId,
	
		wallsToPreviousCorner = {wId1, wId2, ..} -- 1 bis 2
		wallsToNextCorner = {wId, wId2, ... } -- 2 bis 3 (falls vorhanden), sonst false.
	},
	...
}
-- Walls
Walls.CreatedWalls =
{
	[wallID] = {
		corner1,
		corner2,
		wall1 = neighbor1; -- << wID (wall), false (frei), true (corner)
		wall2 = neighbor2; -- << "	"	"		"
	}
}

]]


-- DEBUG
local GameCallback_GUI_SelectionChanged_orig = GameCallback_GUI_SelectionChanged;
GameCallback_GUI_SelectionChanged = function()
	local id = GUI.GetSelectedEntity();

	if id and Walls.CreatedWalls[id] then
		local string = "";
		string = string .. "Corner   #1:" .. Walls.CreatedWalls[id].corner1.X .. ", " .. Walls.CreatedWalls[id].corner1.Y .. ",  " .. tostring(Walls.CreatedWalls[id].corner1.attachCorner1) .. ", " .. tostring(Walls.CreatedWalls[id].corner1.attachCorner2) .. "\r\n";
		string = string .. "Corner   #2:" .. Walls.CreatedWalls[id].corner2.X .. ", " .. Walls.CreatedWalls[id].corner2.Y .. ",  " .. tostring(Walls.CreatedWalls[id].corner2.attachCorner1) .. ", " .. tostring(Walls.CreatedWalls[id].corner2.attachCorner2) .. "\r\n";
		string = string .. "Wall     #1:" .. tostring(Walls.CreatedWalls[id].wall1) .. "\r\n";
		string = string .. "Wall     #2:" .. tostring(Walls.CreatedWalls[id].wall2) .. "\r\n";
		local x,y = Logic.EntityGetPos(id);
		string = string .. "Pos        :" .. math.floor(x / 100 +  0.5) .. ", " .. math.floor(y / 100 + 0.5) .. "\r\n";
		string = string .. "ID         :" .. id .. "\r\n";
		string = string .. "Rotation   :" .. Logic.GetEntityOrientation(id) .. "\r\n";
		string = string .. "Rotation #2:" .. (Logic.GetEntityOrientation(id) - Walls.GetAngleOffsetByType(Logic.GetEntityType(id)));
		
		GUI.MiniMapDebug_SetText(string);
	else
		GUI.MiniMapDebug_SetText("");
	end
	
	GameCallback_GUI_SelectionChanged_orig();
end;

--[[
function GUI.SellBuilding()
	DestroyEntity(GUI.GetSelectedEntity());
end;
]]

function Walls_OnLegacyWallDestroyed_Condition()
	return Walls.LegacyWalls[Event.GetEntityID()] ~= nil;
end;

function Walls_OnLegacyWallDestroyed_Action()
	local id = Event.GetEntityID()
	DestroyEntity(Walls.LegacyWalls[id][1]);
end;

function Walls_OnWallDestroyed_Condition()
	local id = Event.GetEntityID();
	return Walls.CreatedWalls[id] ~= nil
end;

function Walls_OnWallDestroyed_Action()
	local corners;
	local corner;
	local id = Event.GetEntityID();
	local playerID = Logic.EntityGetPlayer(id);
	-- Remove wall from corners.
	local constructionPlans = Walls.GetConstructionPlansByPlayer(playerID);
	
	local wall = Walls.CreatedWalls[id];
	
	if wall.wall1 == true then
		wall.corner1.attachCorner2 = false;
	end;
	
	if wall.wall2 == true then
		wall.corner2.attachCorner1 = false;
	end;
	
	local w = Walls.CreatedWalls[id];

	if type(w.wall1) == "number" then
		Walls.CreatedWalls[Walls.CreatedWalls[id].wall1].wall2 = false;
	end;
	if type(w.wall2) == "number" then
		Walls.CreatedWalls[Walls.CreatedWalls[id].wall2].wall1 = false;
	end;
	
	if w.model1 then
		DestroyEntity(w.model1);
	end;
	
	if w.model2 then
		DestroyEntity(w.model2);
	end;
end;

Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "Walls_OnWallDestroyed_Condition", "Walls_OnWallDestroyed_Action", 1);
Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "Walls_OnLegacyWallDestroyed_Condition", "Walls_OnLegacyWallDestroyed_Action", 1);

function Walls.GetHalfWallLengthByType(type)
	if (type == Entities.XD_WallStraight) then
		return 2;
	elseif (type == Entities.XD_WallDistorted) then
		return 3;
	elseif (type == Entities.XD_WallStraightGate) then
		return 2.5;
	elseif (type == Entities.XD_WallStraightGate_Closed) then
		return 2.5;
	end;
end;

function Walls.GetAngleOffsetByType(type)
	if (type == Entities.XD_WallStraight) then
		return 90;
	elseif (type == Entities.XD_WallDistorted) then
		return 45;
	elseif (type == Entities.XD_WallStraightGate) then
		return 90;
	elseif (type == Entities.XD_WallStraightGate_Closed) then
		return 90;
	end;
end;

function Walls.Distance2(_x, _y, _x2, _y2)
	return (_x2 - _x)^2 + (_y2 - _y)^2;
end;

function Walls.Distance(_x, _y, _x2, _y2)
	return math.sqrt(Walls.Distance2(_x, _y, _x2, _y2));
end;

function Walls.Angle(_x, _y, _x2, _y2)

	local offset = 0;
	local x2x = _x2 - _x;
	local y2y = _y2 - _y;
	if x2x < 0 and y2y >= 0 then
		offset = 180; -- Q II;
	elseif x2x < 0 then
		offset = 180; -- Q III;
	elseif y2y < 0 then
		offset = 360; -- Q IV;
	end;
	
	return math.deg(math.atan((y2y) / (x2x))) + offset;
end;

function Walls.PlaceWallAtCorner(corner, prev, post, _x, _y, _eType, _playerID)
		-- TODO
	if _x == corner.X and _y == corner.Y then
		_x = _x - 1;
		_y = _y - 1;
	end;
	
	local angle,angle2;
	if prev then
		angle = Walls.Angle(corner.X, corner.Y, prev.X, prev.Y);
	end;
	
	if post then
		angle2 = Walls.Angle(corner.X, corner.Y, post.X, post.Y);
	end;
	
	local angleToCorner = Walls.Angle(corner.X, corner.Y, _x, _y);
	
	local usePrev = false;
	if not angle then
	elseif not angle2 then
		usePrev = true;
	else
		if math.min(math.abs(angleToCorner - angle), math.abs(angleToCorner - angle + 360)) < math.min(math.abs(angleToCorner - angle2), math.abs(angleToCorner - angle2 + 360)) then
			usePrev = true;
		end;
	end;
	
	if corner.attachCorner1 then
		usePrev = false;
	elseif corner.attachCorner2 then
		usePrev = true;
	end;
	
	local xM,yM;
	local x,y;
	
	local c2;
	
	if (usePrev) then
		c2 = prev;
		angleForWall = Walls.Angle(prev.X, prev.Y, corner.X, corner.Y);
		
		if (prev.X > corner.X) then
			xM =  1;
		else
			xM = - 1;
		end;
		
		if (prev.Y > corner.Y) then
			yM =  1;
		else
			yM = - 1;
		end;
	else
		c2 = post;
		angleForWall = Walls.Angle(corner.X, corner.Y, post.X, post.Y);
		
		if (post.X > corner.X) then
			xM =  1;
		else
			xM = - 1;
		end;
		
		if (post.Y > corner.Y) then
			yM =  1;
		else
			yM = - 1;
		end;
	end;
	

	
	local offset = Walls.GetHalfWallLengthByType(_eType);
	local offsetX = xM * math.abs(offset * math.cos(math.rad(angleForWall)));
	local offsetY = yM * math.abs(offset * math.sin(math.rad(angleForWall)));

	if Walls.Distance2(corner.X, corner.Y, c2.X, c2.Y) <= 4 * offset * offset + 1 then
		-- take middle of corner1 and corner2 if their distance is smaller than offset
		offsetX = xM * math.abs(c2.X - corner.X) / 2;
		offsetY = yM * math.abs(c2.Y - corner.Y) / 2;
	end;
	
	angleForWall = angleForWall + Walls.GetAngleOffsetByType(_eType);
	
	local id = Logic.CreateEntity(_eType, (corner.X + offsetX) * 100, (corner.Y + offsetY) * 100, angleForWall, _playerID);
	
	local t = {};
	Walls.CreatedWalls[id] = t;
	Walls.CreatedWalls[id].wall1 = false;
	Walls.CreatedWalls[id].wall2 = false;
	
	local x,y = Logic.EntityGetPos(id);
	x,y = Walls.CmToMeter(x,y);
	

	if (usePrev) then
		Walls.CreatedWalls[id].wall2 = true;
		t.corner1 = prev;
		t.corner2 = corner;
		corner.attachCorner1 = id;
		
		
		if Walls.Distance(x,y, prev.X, prev.Y) <= Walls.GetHalfWallLengthByType(_eType) + 1 then
			Walls.CreatedWalls[id].wall1 = true;
			prev.attachCorner2 = id;
		end;
		
		Walls.ConnectWallsIfNoGap(id, corner.wallsToPreviousCorner);
		
		table.insert(corner.wallsToPreviousCorner, id);
	else
		Walls.CreatedWalls[id].wall1 = true;
		corner.attachCorner2 = id;
		t.corner1 = corner;
		t.corner2 = post;
		
		-- THIS MIGHT LEAD TO BUGS...
		if Walls.Distance(x,y, post.X, post.Y) <= Walls.GetHalfWallLengthByType(_eType) + 1 then
			Walls.CreatedWalls[id].wall2 = true;
			post.attachCorner1 = id;
		end;
		-- A wall is created (too short...) another one is created (it fits the condition)
		--> wall1 is destroyed so corner is freed again.
		
		-- TODO IF WALL IS INTERSECTING OTHER WALL MERGE THEM.
		
		Walls.ConnectWallsIfNoGap(id, corner.wallsToNextCorner);

		table.insert(corner.wallsToNextCorner, id);
	end;
	
	return id;
end;

function Walls.CornerWallTable_Update(_table)

	for i = table.getn(_table),1, -1 do
		if IsDead(_table[i]) then
			table.remove(_table, i);
		end;
	end;
end;


function Walls.PlaceWallAtWall(wID, x, y, eType, playerID)
	local wall = Walls.CreatedWalls[wID];
	local angle = Walls.Angle(wall.corner1.X, wall.corner1.Y, wall.corner2.X, wall.corner2.Y);
	
	local x2,y2 = Logic.EntityGetPos(wID);
	x2,y2 = Walls.CmToMeter(x2,y2);
	
	local leftX,leftY;
	
	local xOffset = Walls.GetHalfWallLengthByType(Logic.GetEntityType(wID)) * math.abs(math.cos(math.rad(angle)));
	local yOffset = Walls.GetHalfWallLengthByType(Logic.GetEntityType(wID)) * math.abs(math.sin(math.rad(angle)));
	
	local xML, yML;
	if wall.corner1.X < x2 then
		xML = -1;
	else
		xML = 1;
	end;
	
	if wall.corner1.Y < y2 then
		yML = -1;
	else
		yML = 1;
	end;
	
	leftX = xML * xOffset + x2;
	leftY = yML * yOffset + y2;
	
	
	local rightX, rightY;
	
	if wall.corner2.X < x2 then
		xMR = -1;
	else
		xMR = 1;
	end;
	
	if wall.corner2.Y < y2 then
		yMR = -1;
	else
		yMR = 1;
	end;
	
	rightX = xMR * xOffset + x2;
	rightY = yMR * yOffset + y2;
	
	local chooseLeft = false;
	if (Walls.Distance2(x,y,leftX,leftY) < Walls.Distance2(x,y,rightX,rightY) and not wall.wall1) or (wall.wall2) then
		chooseLeft = true;
	end;
	
	local xOffset = Walls.GetHalfWallLengthByType(eType) * math.abs(math.cos(math.rad(angle)));
	local yOffset = Walls.GetHalfWallLengthByType(eType) * math.abs(math.sin(math.rad(angle)));
	
	angle = angle + Walls.GetAngleOffsetByType(eType);
		
	local t = {
		wall1 = false;
		wall2 = false;
		corner1 = wall.corner1;
		corner2 = wall.corner2;
	};
		
	local id;
	if (chooseLeft) then
		xOffset = xML * xOffset;
		yOffset = yML * yOffset;
		
		local posX = leftX + xOffset;
		local posY = leftY + yOffset;
		
		local v1 = Vector2.new(wall.corner1.X, wall.corner1.Y);
		local v2 = Vector2.new(wall.corner2.X, wall.corner2.Y);
		local v3 = Vector2.new(posX, posY);
		local n = (v1 - v2).normalize();
		local b = (v3-v2);
		local lotVektor = b - n * (n * b)
		
		local lot = v3 - lotVektor;
		
		if (lot - v1).magnitude() < Walls.GetHalfWallLengthByType(eType) then
			lot = v1 + Vector2.new(- xOffset, - yOffset);
		end;
		
		id = Logic.CreateEntity(eType, lot.X * 100, lot.Y * 100, angle, playerID);

		
		Walls.CreatedWalls[id] = t;
		t.wall2 = wID;
		wall.wall1 = id;
		
		if Walls.Distance(wall.corner1.X, wall.corner1.Y, leftX + xOffset, leftY + yOffset) <= Walls.GetHalfWallLengthByType(eType) + 1 then
			t.wall1 = true;
			t.corner1.attachCorner2 = id;
		end;
		
		-- A wall is created (too short...) another one is created (it fits the condition)
		--> wall1 is destroyed so corner is freed again.
		
		-- TODO IF WALL IS INTERSECTING OTHER WALL MERGE THEM.
		
		Walls.ConnectWallsIfNoGap(id, t.corner1.wallsToNextCorner);
		table.insert(t.corner1.wallsToNextCorner, id);
	else
		xOffset = xMR * xOffset;
		yOffset = yMR * yOffset;
		
		local posX = rightX + xOffset;
		local posY = rightY + yOffset;
		
		local v1 = Vector2.new(wall.corner1.X, wall.corner1.Y);
		local v2 = Vector2.new(wall.corner2.X, wall.corner2.Y);
		local v3 = Vector2.new(posX, posY);
		local n = (v1 - v2).normalize();
		local b = (v3-v2);
		local lotVektor = b - n * (n * b)
		
		local lot = v3 - lotVektor;
		
		if (lot - v2).magnitude() < Walls.GetHalfWallLengthByType(eType) then
			lot = v2 + Vector2.new(- xOffset, - yOffset);
		end;
		
		id = Logic.CreateEntity(eType, lot.X * 100, lot.Y * 100, angle, playerID);
		
		Walls.CreatedWalls[id] = t;
		t.wall1 = wID;
		wall.wall2 = id;
		
		if Walls.Distance(wall.corner2.X, wall.corner2.Y, rightX + xOffset, rightY + yOffset) <= Walls.GetHalfWallLengthByType(eType) + 1 then
			t.wall2 = true;
			t.corner2.attachCorner1 = id;
		end;
		
		-- A wall is created (too short...) another one is created (it fits the condition)
		--> wall1 is destroyed so corner is freed again.
		
		-- TODO IF WALL IS INTERSECTING OTHER WALL MERGE THEM.
		
		Walls.ConnectWallsIfNoGap(id, t.corner1.wallsToNextCorner);
		table.insert(t.corner1.wallsToNextCorner, id);
	end;
	
	return id;
end;

function Walls.FindNearestWall(_playerID, _eType, _x, _y)
	local min;
	local mindist2;
	local distance2;
	local x,y;
	for eID in S5Hook.EntityIterator(Predicate.OfType(_eType)) do
		x,y = Logic.EntityGetPos(eID);
		x,y = Walls.CmToMeter(x,y);
		distance2 = Walls.Distance2(_x, _y, x, y);
		if (not mindist2) or (mindist2 > distance2) then
			min = eID;
			mindist2 = distance2;
		end;
	end;
	
	if min then
		return min, math.sqrt(mindist2);
	else
		return nil, nil;
	end;
end;


function Walls.PlaceWallLegacy(_playerID, _eType, _x, _y)
	
	local nearest = {
		{Walls.FindNearestWall(_playerID, Entities.XD_WallStraight, _x, _y)};
		{Walls.FindNearestWall(_playerID, Entities.XD_WallDistorted, _x, _y)};
		{Walls.FindNearestWall(_playerID, Entities.XD_WallStraightGate, _x, _y)};
		{Walls.FindNearestWall(_playerID, Entities.XD_WallStraightGate_Closed, _x, _y)};
	};
	
	local mindist;
	local min;
	for i = 1,table.getn(nearest) do
		if nearest[i][1] then
			if not mindist or (mindist > nearest[i][2]) then
				min = nearest[i][1];
				mindist = nearest[i][2];
			end;
		end;
	end;
	
	if not min then
		Message("No wall found for legacy builds.");
		return;
	end;
	
	if mindist > 10 then
		Message("Wall out of range.");
		return;
	end;
	
	local x,y = Logic.EntityGetPos(min);
	local v1 = Vector2.new(x,y);
	local v2 = Vector2.new(_x * 100, _y * 100);
	local v1n = v1.normalize();
	local angle = Logic.GetEntityOrientation(min) - Walls.GetAngleOffsetByType(Logic.GetEntityType(min));
	
	local offset = Walls.GetHalfWallLengthByType(Logic.GetEntityType(min)) * 100;
	
	local v1s = v1 + Vector2.new(math.cos(math.rad(angle)) * offset, math.sin(math.rad(angle)) * offset);
	
	local v1s2 = v1 - Vector2.new(math.cos(math.rad(angle)) * offset, math.sin(math.rad(angle)) * offset);
	
	local startPoint;
	if (v1s - v2).magnitude() < (v1s2 - v2).magnitude() then
		startPoint = v1s;
	else
		startPoint = v1s2;
	end;
	LuaDebugger.Log("START:");
	LuaDebugger.Log(startPoint);
	LuaDebugger.Log("V2");
	LuaDebugger.Log(v2);
	LuaDebugger.Log("ANGLE:");
	
	angle = Walls.Angle(startPoint.X, startPoint.Y, v2.X, v2.Y) + Walls.GetAngleOffsetByType(_eType);
	
	local normal = (v2 - startPoint).normalize();
	local n_new = startPoint + normal * Walls.GetHalfWallLengthByType(_eType) * 100;
	local corner = startPoint + normal * Walls.GetHalfWallLengthByType(_eType) * 2 * 100;
	
	local id = Logic.CreateEntity(_eType, n_new.X, n_new.Y, angle, _playerID);
	
	local cornerID = Logic.CreateEntity(Entities.XD_CoordinateEntity, corner.X, corner.Y, 0, 0);
	Logic.SetModelAndAnimSet(cornerID, Models.XD_WallCorner);
	Walls.LegacyWalls[id] = {cornerID};
end;

-- In Meters.
function Walls.PlaceWall(_playerID, _eType, _x, _y)
	local corner, dist, prev, next = Walls.FindNearestFreeCornerToPosition(_playerID, _x, _y);
	local wID, wDist = Walls.FindNearestFreeWallToPosition(_playerID, _x, _y)
	
	if not wID and not corner then
		--Message("PlaceWall failed. No place to build a wall.");
		Message("Using legacy walls");
		Walls.PlaceWallLegacy(_playerID, _eType, _x, _y);
		return;
	end;
	
	local id;
	if corner and (not wID or wDist > dist) then
		id = Walls.PlaceWallAtCorner(corner, prev, next, _x, _y, _eType, _playerID);
	else
		id = Walls.PlaceWallAtWall(wID, _x, _y, _eType, _playerID);
	end;
	
	if (id) then
		local angle = Logic.GetEntityOrientation(id) - Walls.GetAngleOffsetByType(_eType);
		local xO = math.cos(math.rad(angle)) * Walls.GetHalfWallLengthByType(_eType) * 100;
		local yO = math.sin(math.rad(angle)) * Walls.GetHalfWallLengthByType(_eType) * 100;
		local x,y = Logic.EntityGetPos(id);
		local ID = Logic.CreateEntity(Entities.XD_CoordinateEntity, x + xO, y + yO, 0, 0);
		Walls.CreatedWalls[id].model1 = ID;
		Logic.SetModelAndAnimSet(ID, Models.XD_WallCorner);
		LuaDebugger.Log(xO);
		LuaDebugger.Log(yO);
		ID = Logic.CreateEntity(Entities.XD_CoordinateEntity, x - xO, y - yO, 0, 0);
		Logic.SetModelAndAnimSet(ID, Models.XD_WallCorner);
		Walls.CreatedWalls[id].model2 = ID;
		
		--[[local wall = Walls.CreatedWalls[id];
		local v1 = Vector2.new(wall.corner1.X, wall.corner1.Y);
		local v2 = Vector2.new(wall.corner2.X, wall.corner2.Y);
		local posX, posY = Logic.EntityGetPos(id);
		posX,posY = Walls.CmToMeter(posX, posY);
		local v3 = Vector2.new(posX, posY);
		local n = (v1 - v2).normalize();
		local b = (v3-v2);
		local lotVektor = b - n * (n * b)
		LuaDebugger.Log(v1);
		LuaDebugger.Log(v2);
		LuaDebugger.Log(lotVektor);
		ID = Logic.CreateEntity(Entities.XD_CoordinateEntity, (v3 - lotVektor).X * 100, (v3 - lotVektor).Y * 100, Logic.GetEntityOrientation(id), 0);
		Logic.SetModelAndAnimSet(ID, Models.XD_WallDistorted);
		Logic.SetEntityScriptingValue( id, -30, 257)
		]]
	end;
end;

-- This function should only be used for walls with the same extent.
function Walls.ReplaceWall(_wID, _entityType)
	
	-- Disable the trigger system so the walls and corner tables are not altered.
	Trigger.DisableTriggerSystem(1);
	local newAngle = Logic.GetEntityOrientation(_wID) - Walls.GetAngleOffsetByType(Logic.GetEntityType(_wID)) + Walls.GetAngleOffsetByType(_entityType);
	local x,y = Logic.EntityGetPos(_wID);
	local id = Logic.CreateEntity(_entityType, x, y, newAngle, Logic.EntityGetPlayer(_wID));
	local t = Walls.CreatedWalls[_wID];
	
	Walls.CreatedWalls[_wID] = nil;
	Walls.CreatedWalls[id] = t;
	
	if t.wall1 then
		if t.wall1 == true then
			-- Wall is attached to corner 1.
			t.corner1.attachCorner2 = id;
		else
			-- Wall is attached to a wall.
			Walls.CreatedWalls[t.wall1].wall2 = id;
		end;
	end;
	
	if t.wall2 then
		if t.wall2 == true then
			-- Wall is attached to corner 1.
			t.corner2.attachCorner1 = id;
		else
			-- Wall is attached to a wall.
			Walls.CreatedWalls[t.wall2].wall1 = id;
		end;
	end;
	-- TODO set health ...
	Logic.DestroyEntity(_wID);
	-- Enable the trigger system again.
	Trigger.DisableTriggerSystem(0);
	
end;

function Walls.Test_PlaceWall(_eType)
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	x,y = Walls.CmToMeter(x,y);
	Sync.Call("Walls.PlaceWall", GUI.GetPlayerID(), _eType, x, y);
end;


function Walls.Test_ReplaceWall(_origType, _newType)
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	x,y = Walls.CmToMeter(x,y);
	local min;
	local mindist2;
	local distance2;
	local _x, _y;
	for eID in S5Hook.EntityIterator(
		Predicate.OfType(_origType)) do
		_x,_y = Walls.CmToMeter(Logic.EntityGetPos(eID));
		distance2 = Walls.Distance2(_x,_y, x,y);
		if (not min) or (mindist2 > distance2) then
			min = eID;
			mindist2 = distance2;
		end;	
	end
	
	if mindist2 and (mindist2 < 5^2) then
		Walls.Sync("Walls.ReplaceWall", min, _newType);
	end;
end;


function Walls.ConnectWallsIfNoGap (_id, _t)

	Walls.CornerWallTable_Update(_t);

	local nextID;
	local distance;
	local wID;
	local wallsWithFreeNeighbor = {};

	local prev = Walls.CreatedWalls[_id].wall1 == false;
	local check;
	for i = 1,table.getn(_t) do
		if prev then
			check = not Walls.CreatedWalls[_t[i]].wall2;
		else
			check = not Walls.CreatedWalls[_t[i]].wall1;
		end;
		if check then
			table.insert(wallsWithFreeNeighbor, _t[i]);
		end;
	end;

	local x,y = Logic.EntityGetPos(_id);
	x = math.floor(x/100+0.5);
	y = math.floor(y/100+0.5);
	local x2,y2;
	local found = 0;
	for i = table.getn(wallsWithFreeNeighbor),1,-1 do
		x2,y2 = Logic.EntityGetPos(wallsWithFreeNeighbor[i]);
		x2 = math.floor(x2/100+0.5);
		y2 = math.floor(y2/100+0.5);
		-- TODO plus 1?
		if Walls.Distance(x,y,x2,y2) <= (Walls.GetHalfWallLengthByType(Logic.GetEntityType(_id)) + Walls.GetHalfWallLengthByType(Logic.GetEntityType(wallsWithFreeNeighbor[i]))) then
			found = found + 1;
		end;
	end;

	if found == 0 then
		return;
	elseif found == 1 then
		if (prev) then
			Walls.CreatedWalls[wallsWithFreeNeighbor[1]].wall2 = _id;
			Walls.CreatedWalls[_id].wall1 = wallsWithFreeNeighbor[1];
		else
			Walls.CreatedWalls[wallsWithFreeNeighbor[1]].wall1 = _id;
			Walls.CreatedWalls[_id].wall2 = wallsWithFreeNeighbor[1];
		end;
	else
		assert(false, "Multiple walls found with free slots.");
	end;
end;

function Walls.DEBUG()
	--Tools.ExploreArea(-1,-1,900);
	--Camera.RotSetFlipBack(0);
	--Camera.RotSetAngle(0);
	--Input.KeyBindDown(Keys.E, "", 2);
	Input.KeyBindDown(Keys.A, "Walls.ToggleWallConstructionState()", 2)
	Input.KeyBindDown(Keys.NumPad1, "Walls.SetVirtualWallCorner()", 2);
	Input.KeyBindDown(Keys.NumPad2, "Walls.FindVirtualWallCornerAtPosition()", 2);
	Input.KeyBindDown(Keys.NumPad3, "Walls.RemoveLastVirtualWallCorner()", 2);
	
	Input.KeyBindDown(Keys.S, "Walls.Test_PlaceWall(Entities.XD_WallStraight)", 2);
	Input.KeyBindDown(Keys.D, "Walls.Test_PlaceWall(Entities.XD_WallDistorted)", 2);
	Input.KeyBindDown(Keys.F, "Walls.Test_PlaceWall(Entities.XD_WallStraightGate)", 2);
	Input.KeyBindDown(Keys.G, "Walls.Test_ReplaceWall(Entities.XD_WallStraightGate, Entities.XD_WallStraightGate_Closed)", 2);
	Input.KeyBindDown(Keys.H, "Walls.Test_ReplaceWall(Entities.XD_WallStraightGate_Closed, Entities.XD_WallStraightGate)", 2);
	
	Input.KeyBindDown(Keys.Y, "Walls.ShowConstructionPlans()", 2);
	Input.KeyBindDown(Keys.X, "Walls.HideConstructionPlans()", 2);

	
end

function Walls.Setup()
	-- ...2 means value already is a square

	Walls.DEBUG();
end


-- IN METER
function Walls.FindNearestFreeCornerToPosition(_playerID, _x, _y)
	local constructionPlans = Walls.GetConstructionPlansByPlayer(_playerID);
	
	local mindist2;
	local min;
	
	local distance2;
	
	local corners;
	local corner;
	local index;
	local index2;
	for i = 1,table.getn(constructionPlans) do
		corners = constructionPlans[i];
		for j = 1,table.getn(corners) do
			corner = corners[j];
			if Walls.Corner_HasFreeSlot(corner) then
				distance2 = Walls.Distance2(_x,_y, corner.X, corner.Y);
				if (not min) or (mindist2 > distance2) then
					min = corner;
					mindist2 = distance2;
					index = i;
					index2 = j;
				end;
			end;
		end;
	end;
	
	if min and mindist2 < Walls.MIN_WALL_RANGE_TO_ADJUSTMENT2 then
		return min, math.sqrt(mindist2), constructionPlans[index][index2 - 1], constructionPlans[index][index2+1];
	else
		return nil, nil, nil, nil;
	end;
end;

-- IN METER
function Walls.FindNearestFreeWallToPosition(_playerID, _x, _y)
	local min;
	local x,y;
	local mindist2;
	local distance2;
	for eID in S5Hook.EntityIterator(
		Predicate.OfCategory(EntityCategories.Wall),
		Predicate.OfPlayer(_playerID)) do
		if Walls.CreatedWalls[eID] and Walls.Wall_HasFreeSlot(eID) then
			x,y = Walls.CmToMeter(Logic.EntityGetPos(eID));
			distance2 = Walls.Distance2(_x,_y, x,y);
			if (not min) or (mindist2 > distance2) then
				min = eID;
				mindist2 = distance2;
			end;
		end
	end
	
	if min and mindist2 < Walls.MIN_WALL_RANGE_TO_ADJUSTMENT2 then
		return min, math.sqrt(mindist2);
	else
		return nil, nil;
	end;
end;

-- ###################################### --
-- ######## SECTION CONSTRUCTION ######## --
-- ###################################### --

function Walls.ToggleWallConstructionState()
	if (not Walls.isInWallConstructionState) then
		Walls.EnterWallConstructionState();
	else
		Walls.LeaveWallConstructionState();
	end
end

function Walls.SetVirtualWallCorner()
	if (not Walls.isInWallConstructionState) then
		return;
	end

	local x,y = GUI.Debug_GetMapPositionUnderMouse();

	x = math.floor(x / 100 + 0.5);
	y = math.floor(y / 100 + 0.5);

	Walls.InsertVirtualWallCorner({X=x,Y=y});
end

-- pos in METER
function Walls.InsertVirtualWallCorner(_position)
	_position = {X=_position.X, Y=_position.Y};
	if table.getn(Walls.currentConstructionPlan) == 0 then
		table.insert(Walls.currentConstructionPlan, _position);
	else
		local lastX,lastY = Walls.currentConstructionPlan[table.getn(Walls.currentConstructionPlan)].X, Walls.currentConstructionPlan[table.getn(Walls.currentConstructionPlan)].Y;
		if (lastX - _position.X)^2 + (lastY - _position.Y)^2 <= Walls.MIN_WALL_RANGE then
			-- TODO Message to inform user that the line is too short.
			Message("Wall too short.");
			return;
		else
			table.insert(Walls.currentConstructionPlan, _position);
		end
	end

	Walls.DrawCurrentConstructionPlan();
end

function Walls.FindVirtualWallCornerAtPosition()
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	x,y = Walls.CmToMeter(x,y);
	-- * tries to find a VirtualWallCorner(VWC) beneath the mouse in a certain range * --
	local constructionPlans = Walls.GetConstructionPlansByPlayer(GUI.GetPlayerID());
	local corners;
	local corner;
	for i = 1,table.getn(constructionPlans) do
		corners = constructionPlans[i];
		for j = 1,table.getn(corners) do
			corner = corners[j];
			if Walls.Distance2(corner.X, corner.Y, x, y) < Walls.FIND_VIRTUALCORNER_RANGE2 then
				Walls.InsertVirtualWallCorner(corner);
				return;
			end;
		end;
	end;
	
	for i = 1,table.getn(Walls.currentConstructionPlan) do
		corner = Walls.currentConstructionPlan[i];
		if Walls.Distance2(corner.X, corner.Y, x, y) < Walls.FIND_VIRTUALCORNER_RANGE2 then
			Walls.InsertVirtualWallCorner(corner);
			return;
		end;
	end;
	
	Message("No wall corner found MADAFAKA. :( os.exit(\"opfer\").");
end

function Walls.DrawCurrentConstructionPlan()
	local p;
	local p2 = Walls.currentConstructionPlan[1];
	for i = 2,table.getn(Walls.currentConstructionPlan) do
		p = Walls.currentConstructionPlan[i];
		Walls.Draw(p2.X, p2.Y, p.X, p.Y, 255, 0, 0);
		p2 = p;
	end;

	for i = 1, table.getn(Walls.currentConstructionPlan) do
		p = Walls.currentConstructionPlan[i];
		Walls.Draw(p.X, p.Y, p.X, p.Y, 0, 0, 0);
	end
end;

function Walls.HideCurrentConstructionPlan()
	
	local p;
	local p2 = Walls.currentConstructionPlan[1];
	for i = 2,table.getn(Walls.currentConstructionPlan) do
		p = Walls.currentConstructionPlan[i];
		Walls.Draw(p2.X, p2.Y, p.X, p.Y, 127, 127, 127);
		p2 = p;
	end;

	for i = 1, table.getn(Walls.currentConstructionPlan) do
		p = Walls.currentConstructionPlan[i];
		Walls.Draw(p.X, p.Y, p.X, p.Y, 127, 127, 127);
	end
	
	if Walls.areConstructionPlansShown then
		Walls.ShowConstructionPlans();
	end;
end;

function Walls.RemoveLastVirtualWallCorner()
	if table.getn(Walls.currentConstructionPlan) > 0 then
		
		Walls.HideCurrentConstructionPlan();
		
		table.remove(Walls.currentConstructionPlan, table.getn(Walls.currentConstructionPlan));
		
		Walls.DrawCurrentConstructionPlan();
		
	end;
end;

function Walls.Draw(x,y, x2,y2, r, g, b)
	
	local deltaX = x2 - x;
	local deltaY = y2 - y;
	for t = 0, 1, 0.02 do
		local x = x + deltaX * t
		local y = y + deltaY * t;
		x = math.floor(x + 0.5);
		y = math.floor(y + 0.5);
		Logic.SetTerrainVertexColor(x,y,r,g,b);
	end
end


-- TODO do something like "draw allied constructionPlans"
function Walls.ShowConstructionPlans()
	
	Walls.areConstructionPlansShown = true;

	local colors =
	{
		{ r = 255, g = 0, b = 255 };
		{ r = 128, g = 255, b = 255 };
	};
	local player = GUI.GetPlayerID();
	local constructionPlans = Walls.GetConstructionPlansByPlayer(player);
	
	local corners;
	local corner;
	local lastCorner;
	local color;
	for i = 1,table.getn(constructionPlans) do
		corners = constructionPlans[i];
		lastCorner = corners[1];
		color = colors[math.mod(i, table.getn(colors)) + 1];
		for j = 2,table.getn(corners) do
			corner = corners[j];
			Walls.Draw(lastCorner.X, lastCorner.Y, corner.X, corner.Y, color.r, color.g, color.b);
			lastCorner = corners[j];
		end;
	end;
	
	for i = 1,table.getn(constructionPlans) do
		corners = constructionPlans[i];
		for j = 1, table.getn(corners) do
			corner = corners[j];
			Logic.SetTerrainVertexColor(corner.X, corner.Y, 0, 0, 0);
		end;
	end;
end;

function G(_x)
	S5Hook.Eval(_x)()
end


-- MUST BE TRIGGERED WHEN A PLAN IS REMOVED TODO
function Walls.HideConstructionPlans()
	
	Walls.areConstructionPlansShown = false;
	
	local player = GUI.GetPlayerID();
	local constructionPlans = Walls.GetConstructionPlansByPlayer(player);
	
	local corners;
	local corner;
	local lastCorner;
	for i = 1,table.getn(constructionPlans) do
		corners = constructionPlans[i];
		lastCorner = corners[1];
		for j = 1,table.getn(corners) do
			corner = corners[j];
			Walls.Draw(lastCorner.X, lastCorner.Y, corner.X, corner.Y, 127, 127, 127);
			lastCorner = corners[j];
		end;
	end;
end;

function Walls.LeaveWallConstructionState()
	Walls.isInWallConstructionState = false;
	local t = Walls.currentConstructionPlan;
	local sharedWallsTable = {};
	for i = 1,table.getn(t) do
		t[i].attachCorner1 = false;
		t[i].attachCorner2 = false;
		t[i].wallsToPreviousCorner = sharedWallsTable;
		t[i].wallsToNextCorner = {};
		sharedWallsTable = t[i].wallsToNextCorner;
	end

	if (table.getn(t) > 0) then
		t[1].wallsToPreviousCorner = false;
		t[1].attachCorner1 = true;
		t[table.getn(t)].wallsToNextCorner = false;
		t[table.getn(t)].attachCorner2 = true;
		
		Walls.Local_AddConstructionPlan(t);
		Walls.HideCurrentConstructionPlan();
		Walls.currentConstructionPlan = {};
		
	end;
	
	GUI.ActivateSelectionState();
end

function Walls.Local_RemoveConstructionPlan()
	-- TODO
end;

function Walls.Local_AddConstructionPlan(_plan)
	-- TODO
	if Walls.areConstructionPlansShown then
		Walls.ShowConstructionPlans();
	end

	if Sync then
		Sync.Call("Walls.Synchronize_AddConstructionPlan", GUI.GetPlayerID(), _plan);
	else
		Walls.Synchronize_AddConstructionPlan(GUI.GetPlayerID(), _plan);
	end;
end;

function Walls.Synchronize_RemoveConstructionPlan()
	-- TOOD
end;

function Walls.Synchronize_AddConstructionPlan(_player, _plan)
	-- TODO
	Message("Construction Plan");
	table.insert(Walls.Players[_player].ConstructionPlans, _plan);
end;

function Walls.GetConstructionPlansByPlayer(_playerID)
	return Walls.Players[_playerID].ConstructionPlans;
end;

function Walls.GetWallLengthByType(type)
	if (type == Entities.XD_WallStraight) then
		return 4;
	elseif (type == Entities.XD_WallDistorted) then
		return 6;
	elseif (type == Entities.XD_WallStraightGate) then
		return 6;
	elseif (type == Entities.XD_WallStraightGate_Closed) then
		return 6;
	end;
	assert(false, "Walls.GetWallLengthByType: unknown type: " .. tostring(type));
end;

function Walls.CmToMeter(...)
	for i = 1,table.getn(arg) do
		arg[i] = math.floor(arg[i] / 100 + 0.5);
	end;
	return unpack(arg);
end;

function Walls.EnterWallConstructionState()
	-- TODO set cursor.
	Walls.isInWallConstructionState = true;
	
	GUI.ActivateSnipeCommandState();
	
	
end


-- ONLY SAME ANGLE.
function Walls.IsIntersectingWall(_wallID, _wallID2)
	local x,y = Logic.EntityGetPos(_wallID);
	local x2,y2 = Logic.EntityGetPos(_wallID2);
	x,y,x2,y2 = Walls.CmToMeter(x,y,x2,y2);
	return Walls.IsIntersectingByTypes(x,y, Logic.GetEntityType(_wallID), x2,y2, Logic.GetEntityType(_wallID2));
end;

-- METER, SAME ANGLE
function Walls.IsIntersectingByTypes(x,y,eType, x2,y2, eType2)
	return Walls.Distance(x,y,x2,y2) <= Walls.GetHalfWallLengthByType(eType) + Walls.GetHalfWallLengthByType(eType);
end;

-- _x,_y in METER
function Walls.IsIntersectingPoint(_wallID, _x, _y)
	local x,y = Logic.EntityGetPos(_wallID);
	x,y = Walls.CmToMeter(x,y);
	local offset = Walls.GetWallLengthByType(Logic.GetEntityType(_wallID));
	if Walls.Distance(x,y,_x,_y) <= offset / 2 then
		return true;
	else
		return false;
	end;
end;

function Walls.Corner_HasFreeSlot(_corner)
	return _corner.attachCorner1 == false or _corner.attachCorner2 == false;
end;

function Walls.Wall_HasFreeSlot(_wID)
	return Walls.CreatedWalls[_wID].wall1 == false or Walls.CreatedWalls[_wID].wall2 == false;
end;


SW.RegisterS5HookInitializedCallback(Walls.Setup);

-- BUGS:
--[[
	Wand zu lang -> überlappt mit corner, corner hat aber schon wand dann ... ? vielleicht....? ka.

]]
