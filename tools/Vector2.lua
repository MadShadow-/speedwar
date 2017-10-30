-- functionality Vector2 should do:
--		scalar product
--		addition of vectors
--		normalize vector
--		scale vector up
--		dot product


Vector2 = {};
Vector2.__mt = {
	__add = function(_v1, _v2)
		return Vector2.add(_v1,_v2);
	end;
	
	__mul = function(_v1, _v2)
		if type(_v1) == "number" then
			return Vector2.scale(_v1, _v2);
		elseif type(_v2) == "number" then
			return Vector2.scale(_v2, _v1);
		else
			return Vector2.dotProduct(_v1, _v2);
		end;
	end;
	
	__sub = function(_v1, _v2)
		return Vector2.sub(_v1, _v2);
	end;

	__index = function(_v, _key)
		if _key == "normalize" then
			return function() return Vector2[_key]( _v) end;
		elseif _key == "scale" then
			return function( _scale) return Vector2[_key]( _scale, _v) end
		elseif _key == "magnitude" then
			return function() return math.sqrt(_v.X ^ 2 + _v.Y ^ 2); end;
		elseif _key == "rotate" then
			return function( _alpha) Vector2[_key]( _v, _alpha) end
		end
		return nil;
	end;
	
	--__index = function(_v, _key)
	--	return Vector2.__mt[_key];
	--end;
};
--function Vector2.__mt:normalize(_v1)
--	LuaDebugger.Log(self);
--	LuaDebugger.Log(_v1);
--	return Vector2.normalize(_v1);
--end


function Vector2.new(x,y) --https://www.lua.org/pil/13.4.1.html
	x = x or 0;
	y = y or 0;
	local v = {X=x,Y=y};
	setmetatable(v, Vector2.__mt);
	return v;
end;

function Vector2.normalize(_v1)
	if _v1.X == 0 and _v1.Y == 0 then
		LuaDebugger.Log("normalize not possible, _v1 = 0")
	end
	return Vector2.scale( 1/math.sqrt( _v1.X*_v1.X + _v1.Y*_v1.Y), _v1)
end;

function Vector2.add(_v1, _v2)
	local v = Vector2.new();
	v.X = _v1.X + _v2.X;
	v.Y = _v1.Y + _v2.Y;
	return v;
end;

function Vector2.sub(_v1, _v2)
	local v = Vector2.new();
	v.X = _v1.X - _v2.X;
	v.Y = _v1.Y - _v2.Y;
	return v;
end;

function Vector2.scale(_scale, _v1)
	local v = Vector2.new();
	v.X = _v1.X * _scale;
	v.Y = _v1.Y * _scale;
	return v;
end;

function Vector2.dotProduct(_v1, _v2)
	return _v1.X * _v2.X + _v1.Y * _v2.Y;
end;

function Vector2.rotate( _v, _alpha)
	_alpha = math.rad(_alpha)
	local cos, sin = math.cos(_alpha), math.sin(_alpha)
	return Vector2.new( _v.X*cos + _v.Y*sin, _v.Y*cos - _v.X*sin)
end