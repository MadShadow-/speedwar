-- Napos GFXStuff
--[[
function WeatherSets_SetupHighland(_ID)
	Display.GfxSetSetSkyBox(_ID, 0.0, 1.0, "YSkyBox05")
	Display.GfxSetSetSnowStatus(_ID, 0, 1.0, 0)
	Display.GfxSetSetSnowEffectStatus(_ID, 0.0, 0.8, 0)
	Display.GfxSetSetFogParams(_ID, 0.0, 1.0, 1, 152,172,182, 5000,28000)
	Display.GfxSetSetLightParams(_ID,  0.0, 1.0, 40, -15, -50,  120,110,110,  255,254,230)
end
function WeatherSets_SetupHighlandSnow(_ID)
	Display.GfxSetSetSkyBox(_ID, 0.0, 1.0, "YSkyBox01")
	Display.GfxSetSetSnowStatus(_ID, 0, 1.0, 1)
	Display.GfxSetSetSnowEffectStatus(_ID, 0.0, 0.8, 1)
	Display.GfxSetSetFogParams(_ID, 0.0, 1.0, 1, 152,172,182, 4000,12000)
	Display.GfxSetSetLightParams(_ID,  0.0, 1.0,  40, -15, -75,  100,110,110, 250,250,250)
end

function WeatherSets_SetupHighlandRain(_ID)
	Display.GfxSetSetSkyBox(_ID, 0.0, 1.0, "YSkyBox04")
	Display.GfxSetSetRainEffectStatus(_ID, 0.0, 1.0, 1)
	Display.GfxSetSetSnowStatus(_ID, 0, 1.0, 0)
	Display.GfxSetSetSnowEffectStatus(_ID, 0.0, 0.8, 0)
	Display.GfxSetSetFogParams(_ID, 0.0, 1.0, 1, 102,132,142, 3000,8000)
	Display.GfxSetSetLightParams(_ID,  0.0, 1.0, 40, -15, -50,  120,110,110,  255,254,230)
end]]

function WeatherSets_SourRain(_ID)
	Display.GfxSetSetSkyBox(_ID, 0.0, 1.0, "YSkyBox04")
	Display.GfxSetSetRainEffectStatus(_ID, 0.0, 1.0, 1)
	Display.GfxSetSetSnowStatus(_ID, 0, 1.0, 0)
	Display.GfxSetSetSnowEffectStatus(_ID, 0.0, 0.8, 0)
	Display.GfxSetSetFogParams( _ID, 0.0, 1.0, 1, 0, 150, 50, 3000,30000)
	Display.GfxSetSetLightParams( _ID,  0.0, 1.0, 40, -15, -50, 23, 104, 9,  0,0,0)
end

function WeatherSets_HotSummer( _ID)
	Display.GfxSetSetLightParams( _ID,  0.0, 1.0, 0, -10, -20,  220,220,170,  255,255,255)
	Display.GfxSetSetSkyBox(_ID, 0.0, 1.0, "YSkyBox04")
	Display.GfxSetSetFogParams( _ID, 0.0, 1.0, 1, 150, 150, 50, 20000,30000)
	Display.GfxSetSetRainEffectStatus(_ID, 0.0, 1.0, 0)
	Display.GfxSetSetSnowStatus(_ID, 0, 1.0, 0)
	Display.GfxSetSetSnowEffectStatus(_ID, 0.0, 0.8, 0)
end
-- Make changeable:
--  Sunposition, Suncolor, ambientcolor
--[[Display.GfxSetSetLightParams(WeatherID, TransitionStart, TransitionEnd,
                             PositionX, PositionY, PositionZ,
                             AmbientR, AmbientG, AmbientB,
                             DiffuseR, DiffuseG, DiffuseB)
]]
--  FogColor
--[[Display.GfxSetSetFogParams(WeatherID, TransitionStart, TransitionEnd, Flag,
                           ColorR, ColorG, ColorB,
                           FogStart, FogEnd)
]]
GFXHelper = {}
GFXHelper.Focus = "SunPos"
GFXHelper.Coord = 1
GFXHelper.Data = {
	SunPos = {40, -15, -50},
	SunCol = {255, 254, 230},
	AmbCol = {120, 110, 110},
	FogCol = {152,172,182}
}
GFXHelper.FogStart = 2000
GFXHelper.FogEnd = 32000
function GFXHelper.Init()
	Input.KeyBindDown(Keys.Add, "GFXHelper.Increase()", 2)
	Input.KeyBindDown(Keys.Subtract, "GFXHelper.Decrease()", 2)
	GroupSelection_SelectTroops = function(_k)
		if _k == 1 then
			GFXHelper.Focus = "SunPos"
		elseif _k == 2 then
			GFXHelper.Focus = "SunCol"
		elseif _k == 3 then
			GFXHelper.Focus = "AmbCol"
		elseif _k == 4 then
			GFXHelper.Focus = "FogCol"
		elseif _k == 7 then
			GFXHelper.Coord = 1
		elseif _k == 8 then
			GFXHelper.Coord = 2
		elseif _k == 9 then
			GFXHelper.Coord = 3
		end
		GFXHelper.UpdateMsg()
	end
end
function GFXHelper.UpdateMsg()
	Message("Now selected: "..GFXHelper.Focus.." with coordinate "..GFXHelper.Coord)
end
function GFXHelper.Increase()
	if GFXHelper.Focus == "SunPos" then
		GFXHelper.Data.SunPos[GFXHelper.Coord] = GFXHelper.Data.SunPos[GFXHelper.Coord] + 1
		Message("Now: "..GFXHelper.Data.SunPos[GFXHelper.Coord])
	else
		local val = GFXHelper.Data[GFXHelper.Focus][GFXHelper.Coord]
		if val < 255 then
			GFXHelper.Data[GFXHelper.Focus][GFXHelper.Coord] = val + 1
			Message("Now: "..GFXHelper.Data[GFXHelper.Focus][GFXHelper.Coord])
		end
	end
	GFXHelper.UpdateGFX()
end
function GFXHelper.Decrease()
	if GFXHelper.Focus == "SunPos" then
		GFXHelper.Data.SunPos[GFXHelper.Coord] = GFXHelper.Data.SunPos[GFXHelper.Coord] - 1
		Message("Now: "..GFXHelper.Data.SunPos[GFXHelper.Coord])
	else
		local val = GFXHelper.Data[GFXHelper.Focus][GFXHelper.Coord]
		if val > 0 then
			GFXHelper.Data[GFXHelper.Focus][GFXHelper.Coord] = val - 1
			Message("Now: "..GFXHelper.Data[GFXHelper.Focus][GFXHelper.Coord])
		end
	end
	GFXHelper.UpdateGFX()
end
function GFXHelper.UpdateGFX()
	Display.GfxSetSetLightParams( 1, 0, 1, unpack(GFXHelper.Data.SunPos), unpack(GFXHelper.Data.AmbCol), unpack(GFXHelper.Data.SunCol))
	Display.GfxSetSetFogParams( 1, 0.0, 1.0, 1, 
	GFXHelper.Data.FogCol[1], GFXHelper.Data.FogCol[2],GFXHelper.Data.FogCol[3], GFXHelper.FogStart, GFXHelper.FogEnd)
end
