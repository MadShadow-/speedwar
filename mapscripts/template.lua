-- ######################################################################################################################
-- #                                                                                                                    #
-- #                                                                                                                    #
-- #                                                                                                                    #
-- #                                                                                                                    #
-- #                                             Speedwar Configuration File                                            #
-- #                                                                                                                    #
-- #                                                                                                                    #
-- #                                                                                                                    #
-- #                                                                                                                    #
-- ######################################################################################################################
--[[	
	Here you can set:
		Spawn sectors
		Start ressources
		Other weather configuration

			SPAWN SECTORS
 		A map is divided into multiple sectors
		Two positions are in the same sector if and only if you can walk from one point to the other without winter
		In order to decide if a found start position is "good", the script has to know which sectors offer good spawn points.
		
		Now here´s your job:
			For each sector you think is good for spawning in, write one example position in this table
		E.g. for Wooden, we had 2 big sectors: Northern side and southern side, so the table had to contain a position in the northern half
			and one in the lower half

		Alternative way:
			Place in every sector you think is good for spawning a script entity named "SpawnSectorX", where X is a number running from 1 to whatever
			Note that the labeling has to be continous, so e.g. using the names
				SpawnSector1, SpawnSector2, SpawnSector4, SpawnSector5
			will result in SpawnSector1 & SpawnSector2 being considered and 4 & 5 ignored
			DONT GIVE 2 SCRIPT ENTITIES THE SAME NAME!
			DONT PLACE THESE SCRIPT ENTITIES INTO BLOCKED AREA 
]]
SW = SW or {};

SpeedwarConfig = {
	OnGameStartCallback = function()
		-- if there is anything you'd like to do ..
		-- this is called when serfs get spawned
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
