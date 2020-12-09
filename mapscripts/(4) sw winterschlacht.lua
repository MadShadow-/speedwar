Script.Load("maps\\user\\speedwar\\SpeedWar.lua");

-- Configfile, entnommen aus
-- https://raw.githubusercontent.com/MadShadow-/speedwar/master/mapscripts/template.lua
SW = SW or {};

SpeedwarConfig = {
	OnGameStartCallback = function()
		-- Entferne unfaire Kiste
		-- toRemove = {"Sonic", "NobleMan", "WildMan"}
		-- for k,v in pairs(toRemove) do
			-- local vCopy = v
			-- SW.RandomChest.Action[v] = function( _pId, _x, _y)
				-- if GUI.GetPlayerID() == _pId then
					-- Message("Hier sollte eigentlich "..vCopy.." drin sein. Ist wohl verloren gegangen.")
				-- end
			-- end
		-- end
	end,
	EverySecond = function()
		-- stuff that is called every second, return true does not end job
	end,
	
	PlayerStartSectors = {
		--{ X = 32323, Y = 30976 },
		--{ X = 19461, Y = 21278 },
		-- ...
	},
	StartRessources = {
		[ResourceType.Gold]   = 0, 
		[ResourceType.Wood]   = 700, 
		[ResourceType.Clay]   = 500,
		[ResourceType.Stone]  = 0,
		[ResourceType.Iron]   = 0, 
		[ResourceType.Sulfur] = 0
	},
	
	-- Muss auf true gesetzt werden, falls fixe Startpositionen verwendet werden sollen
	PlayerFixedStart = true,
	PlayerStartPos = {		-- accepts position table, entity name or entity id
		[1] = {X = 14300, Y = 14300}, 
		[2] = {X = 42900, Y = 42900}, 
		[3] = {X = 42900, Y = 14300}, 
		[4] = {X = 14300, Y = 42900},
		[5] = "Start_P5", --Spieler 5 spawnt auf Skriptentity mit Namen Start_P5
		[6] = "Start_P6", --Spieler 6 spawnt auf Skriptentity mit Namen Start_P6
		[7] = "Start_P7", --Spieler 7 spawnt auf Skriptentity mit Namen Start_P7
		[8] = "Start_P8", --Spieler 8 spawnt auf Skriptentity mit Namen Start_P8
	},
	
	-- If an entry here is true the corresponding rule cannot be changed in the rule selection
	FixedRules = {
		ChangeTime = true,
		ChangeHQLimit = false,
		TeamSpawn = true,
		TeamRank = true
	},
	
	-- Default rules for the map
	InitialRules = {
		Teamspawn = 0, -- no team spawn
		Teamrank = 0, -- no team rank
		Suddendeath = 90, -- 90 min play time
		MaxHQ = 0, -- no limit for HQs
	},
	
	--[[
	-- WeatherConfiguration
	-- If enable this tables, they overwrite the original values
	
	WeatherBaseChances = { --sets likelyness of weather states; there is no need to add up to some special number
		[1] = 50,		-- Summer
		[2] = 25,		-- Rain
		[3] = 25,		-- Winter
		[4] = 10,		-- Storm
		[5] = 15,		-- No iced lakes, snow & rain falling
		[6] = 15,		-- Snowy terrain without falling snow or rain
		[7] = 10,		-- "Lovely evening", also now has volcanic eruption
		[8] = 20,		-- SourRain
		[9] = 10		-- Hot summer
	},
	WeatherDuration = {	--sets min & max duration for each weather period, ids are same as before
		[1] = {180, 300},
		[2] = {60, 180},
		[3] = {80, 240},
		[4] = {60, 120},
		[5] = {60, 180},
		[6] = {80, 180},
		[7] = {80, 120},
		[8] = {40, 60},
		[9] = {60, 120}
	},
	--]]
};