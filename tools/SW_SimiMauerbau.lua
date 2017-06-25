
--[[

SW = SW or {};
SW.Mauerbau = {};


function SW.Mauerbau.Winkel(_x, _y, _x2, _y2)
	if (_x2 - _x == 0) then
		return 0;
	else
		return math.deg(math.atan((_y2 - _y) / (_x2 - _x)));
	end;
end;


function SW.Mauerbau.SetColorInRadius(_x, _y, _radius, _r, _g, _b)
	--local (x - _x)^2 + (y - _y)^2 = _r^2;
	
	local r2 = _radius*_radius;
	
	for x = _x - _radius, _x + _radius do
		for y = _y - _radius, _y + _radius do
			if (x - _x)^2 + (y - _y)^2 <= r2 then
				Logic.SetTerrainVertexColor(x,y,_r,_g,_b);
			end;
		end;
	end;
end;

function DrawLine(x,y, x2,y2, r, g, b)
	
	local deltaX = x2 - x;
	local deltaY = y2 - y;
	for t = 0, 1, 0.02 do
		local x = x + deltaX * t
		local y = y + deltaY * t;
		x = math.floor(x + 0.5);
		y = math.floor(y + 0.5);
		Logic.SetTerrainVertexColor(x,y,r,g,b);
	end;
end;

function Test3()
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	x = math.floor(x / 100 + 0.5);
	y = math.floor(y / 100 + 0.5);
	last = last or { x=x, y=y };
	Message(last.x .. " " .. last.y .. " : " .. x .. " " .. y);
	DrawLine(last.x, last.y, x, y);
	last.x = x;
	last.y = y;
end;

function Test4()
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	x = math.floor(x / 100 + 0.5);
	y = math.floor(y / 100 + 0.5);
	Message("POS: " .. x .. " " .. y);
end;

function Test5()
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	 SW.Mauerbau.CreateMauer(x,y);
end;

points = points or {};
function Test6()
	local x, y = GUI.Debug_GetMapPositionUnderMouse();
	x = math.floor(x / 100 + 0.5);
	y = math.floor(y / 100 + 0.5);
	table.insert(points, {X=x, Y = y});
end;

function Test7()
	for i = 1,table.getn(points) - 1 do
		DrawLine(points[i].X, points[i].Y, points[i+1].X, points[i+1].Y, math.random(0,255), math.random(0,255), math.random(0,255));
	end;
end;

function Test8()
	for i = 1,table.getn(points) - 1 do
		DrawLine(points[i].X, points[i].Y, points[i+1].X, points[i+1].Y, 127, 127, 127);
	end;
end;

function Test9()
	for i = 1,table.getn(points) - 1 do
		local x = points[i].X;
		local y = points[i].Y;
		local x2 = points[i+1].X;
		local y2 = points[i+1].Y;
		
		local winkel = SW.Mauerbau.Winkel(x,y,x2,y2);
		
		x = x * 100;
		y = y * 100;
		Logic.CreateEntity(Entities.XD_WallStraight, x, y, winkel + 90, 1);
		
		Message(x .. " " .. y .. " WINKEL: " .. winkel);
		
	end;
end;


Input.KeyBindDown(Keys.A, "Test6()", 2);
Input.KeyBindDown(Keys.S, "Test7()", 2);
Input.KeyBindDown(Keys.D, "Test8()", 2);

Tools.ExploreArea(-1,-1,900);
]]




--[[
SW = SW or {};
SW.Mauerbau = {};

SW.Mauerbau.newMauer = {};

function SW.Mauerbau.SetColorInRadius(_x, _y, _radius, _r, _g, _b)
	--local (x - _x)^2 + (y - _y)^2 = _r^2;
	
	local r2 = _radius*_radius;
	
	for x = _x - _radius, _x + _radius do
		for y = _y - _radius, _y + _radius do
			if (x - _x)^2 + (y - _y)^2 <= r2 then				
				Logic.SetTerrainVertexColor(x,y,_r,_g,_b);
				local x2,y2 = GUI.Debug_GetMapPositionUnderMouse();
				--Message(x2 .. " " .. y2);
			end;
		end;
	end;
	
end;

function DrawLine(x,y, x2,y2, r, g, b)
	
	local deltaX = x2 - x;
	local deltaY = y2 - y;
	--Message("POS: " .. x .. " " .. y .. " : " .. x2 .. " " .. y2);
	--Message("DELTAX " .. deltaX .. " DELTAY " .. deltaY);
	for t = 0, 1, 0.02 do
		local x = x + deltaX * t
		local y = y + deltaY * t;
		x = math.floor(x + 0.5);
		y = math.floor(y + 0.5);
		SW.Mauerbau.SetColorInRadius(x,y, 0, r, g, b);
		--Message(x .. " " .. y);
		--Message(x .. " " .. y);
	end;
end;

function SW.Mauerbau.Winkel(_x, _y, _x2, _y2)
	if (_x2 - _x == 0) then
		return 0;
	else
		return math.deg(math.atan((_y2 - _y) / (_x2 - _x)));
	end;
end;


function SW.Mauerbau.CleanupDisplay()
	-- TODO
end;

function SW.Mauerbau.Set()
	-- Trigged by key.
	if not SW.Mauerbau.setActivated then
		return;
	end;
	
	
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	
	
	
end;

function SW.Mauerbau.Draw(_entityID)
	local x,y,x2,y2;
	
	local mX,mY = Logic.EntityGetPos(_entityID);
	
	local angle = Logic.GetEntityOrientation(_entityID);
	
	Message("Winkel: " .. angle);

	local angleRad = math.rad(angle + 90);

	local length = 500;
	
	local x = math.cos(angleRad) * length /2 + mX;
	local y = math.sin(angleRad) * length /2 + mY;
	
	local x2 = mX - math.cos(angleRad) * length /2;
	local y2 = mY - math.sin(angleRad) * length /2;

	local xoff = math.cos(angleRad) * length /2;
	local yoff = math.sin(angleRad) * length /2;

	Message("OFF: " .. xoff .. " " .. yoff .. " combined: " .. (xoff + yoff));

	x = math.floor(x / 100 + 0.5);
	y = math.floor(y / 100 + 0.5);

	x2 = math.floor(x2 / 100 + 0.5);
	y2 = math.floor(y2 / 100 + 0.5);

	Message(x .. " " .. y .. " : " .. x2 .. " " .. y2);

	SW.Mauerbau.SetColorInRadius(x,y,0, 255,0,0);
	SW.Mauerbau.SetColorInRadius(x2,y2,0, 0,255,0);
	
	SW.Mauerbau.anchor[1] = { X = x, Y = y };
	SW.Mauerbau.anchor[2] = { X = x2, Y = y2 };
	
end;

-- TODO
local GameCallback_GUI_SelectionChanged_SW_Orig = GameCallback_GUI_SelectionChanged;

SW.Mauerbau.displayed = false;
SW.Mauerbau.anchor = {};


function GameCallback_GUI_SelectionChanged ()
	if (SW.Mauerbau.displayed) then
		SW.Mauerbau.CleanupDisplay();
		SW.Mauerbau.setActivated = false;
	end;
		
	if (GUI.GetSelectedEntity() and Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.XD_WallStraight) then
		
		SW.Mauerbau.displayed = true;
		SW.Mauerbau.Draw(GUI.GetSelectedEntity());
		SW.Mauerbau.setActivated = true;
	else
	
	end;
	return GameCallback_GUI_SelectionChanged_SW_Orig();
end


Logic.CreateEntity(Entities.XD_WallStraight, 60000, 60000, 30, 1);

Tools.ExploreArea(-1,-1,900);




Input.KeyBindDown(Keys.A, "SW.Mauerbau.Set()", 2);




function dbg()
	local x,y = GUI.Debug_GetMapPositionUnderMouse();
	    GUI.MiniMapDebug_SetText("Maus-Position: ".."X= "..math.floor(x).. " ".." Y= "..math.floor(y) .. "\r\n" .. "Maus-Position: ".."X= "..math.floor(x/100+0.5).. " ".." Y= "..math.floor(y/100+0.5))
end;

StartSimpleJob("dbg");
]]
