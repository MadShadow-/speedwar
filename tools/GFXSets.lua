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
	Display.GfxSetSetLightParams( _ID,  0.0, 1.0, 0, 25, 40,  220,220,170,  255,255,255)
	Display.GfxSetSetSkyBox(_ID, 0.0, 1.0, "YSkyBox04")
	Display.GfxSetSetFogParams( _ID, 0.0, 1.0, 1, 150, 150, 50, 20000,30000)
	Display.GfxSetSetRainEffectStatus(_ID, 0.0, 1.0, 0)
	Display.GfxSetSetSnowStatus(_ID, 0, 1.0, 0)
	Display.GfxSetSetSnowEffectStatus(_ID, 0.0, 0.8, 0)
end
if false then
	Ambient = {
		R = 143,
		G = 254,
		B = 9
	}
	Source = {
		R = 55,
		G = 55,
		B = 55
	}
	GroupSelection_SelectTroops = function(_k)
		LuaDebugger.Log(_k)
		if _k == 1 then
			Source.R = Source.R + 1
		elseif _k == 2 then
			Source.R = Source.R - 1
		elseif _k == 3 then
			Source.G = Source.G + 1
		elseif _k == 4 then
			Source.G = Source.G - 1
		elseif _k == 5 then
			Source.B = Source.B + 1
		else
			Source.B = Source.B - 1
		end
		Display.GfxSetSetLightParams(1,  0.0, 1.0, 40, -15, -50, 143, 254, 9, Source.R, Source.G, Source.B)
	end
end