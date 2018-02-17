-- ##############################################################################################
-- ##
-- ##
-- ##                                  Siedler SpeedWar Mod
-- ##
-- ##

function GameCallback_OnGameStart() 	
	
	-- Include global tool script functions	
	Script.Load(Folders.MapTools.."Ai\\Support.lua")
	Script.Load( "Data\\Script\\MapTools\\MultiPlayer\\MultiplayerTools.lua" )	
	Script.Load( "Data\\Script\\MapTools\\Tools.lua" )	
	Script.Load( "Data\\Script\\MapTools\\WeatherSets.lua" )
	IncludeGlobals("Comfort")

	if XNetwork.Manager_DoesExist() == 0 then		
		local PlayerID = GUI.GetPlayerID()
		Logic.PlayerSetIsHumanFlag( PlayerID, 1 )
		Logic.PlayerSetGameStateToPlaying( PlayerID )
	end
	
	LocalMusic.UseSet = HIGHLANDMUSIC
	Camera.ZoomSetFactorMax(2);
	
	Script.LoadFolder("maps\\user\\speedwar\\config");
	Script.LoadFolder("maps\\user\\speedwar\\tools");
	-- calculate check some after loading scripts
	SW.RessCheck.StartVersionCheck()
	
	SetupHighlandWeatherGfxSet()
	-- how about some vision?
	Display.GfxSetSetFogParams(3, 0.0, 1.0, 1, 152,172,182, 3000,19500)
	Display.GfxSetSetFogParams(2, 0.0, 1.0, 1, 102,132,132, 0,19500)
	
	-- extra für simi
	if LuaDebugger == nil or LuaDebugger.Log == nil then
		LuaDebugger = LuaDebugger or {};
		LuaDebugger.Log = function() end
		LuaDebugger.Break = function() end
		LuaDebugger.FakeDebugger = true
	end
	
	-- central debug property point
	-- to disable/enable debug options, only use this table
	log = function() end;
	debugging = {
		Debug = false,
		LevelUpToMaxRank = true,
		ErrorLogging = true,
		TroopSpawnKeys = false,
		ResearchAllUniversityTechnologies = true,
	};
	
	for i = 1, 8 do
		for k,v in pairs(SW.StartRessourceData) do
			Logic.AddToPlayersGlobalResource( i, k, v)
		end
		--Tools.GiveResouces(i, 0, 700, 500, 0, 0, 0);
	end
	
	SW.Players = {};
	SW.AttractedPlayerSlots = {};
	if SW.IsMultiplayer() then
		for playerId = 1,8 do
			if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(playerId) == 1 then
				table.insert(SW.Players, playerId);
				SW.AttractedPlayerSlots[playerId] = {GameStarted=false;};
			end
		end
	else
		SW.Players = {1};
	end
	SW.NrOfPlayers = table.getn(SW.Players);
	
	SW.Host = 1;
	SW.PlayerId = GUI.GetPlayerID();
	if SW.IsMultiplayer() then
		for playerId = 1,8 do
			if XNetwork.GameInformation_GetNetworkAddressByPlayerID(playerId)
			== XNetwork.Host_UserInSession_GetHostNetworkAddress() then
				SW.Host = playerId
				break;
			end
		end
	end
	SW.IsHost = (SW.Host == SW.PlayerId);
	
	SW.SetupMPLogic();
	Sync.Init();
	SW.Logging.Init();
	
	-- savegame compatability
	Mission_InitWeatherGfxSets = function()end
	
	Camera.RotSetFlipBack(0);

	local ret = InstallS5Hook();
	if (ret) then
		SW.OnS5HookLoaded();
	end;

	-- für alle custom names die wir brauchen - wird von WallGUI verwendet
	SW.CustomNames = {};
	S5Hook.SetCustomNames(SW.CustomNames);
	
	SW.IsActivated = false;
	if SW.NrOfPlayers == 1 then
		-- playing alone - no sync needed
		SW.Activate(XGUIEng.GetSystemTime());
	else
		if SW.IsHost then
			ActivateSpeedwar = function()
				if Counter.Tick2("ActivateSpeedwar", 3) then
					Sync.Call("SW.Activate", XGUIEng.GetSystemTime());
				end
				if SW.IsActivated then
					return true;
				end
			end
			StartSimpleJob("ActivateSpeedwar");
		end
	end
	
	SW.MPGame_ApplicationCallback_SyncChanged = MPGame_ApplicationCallback_SyncChanged;
	MPGame_ApplicationCallback_SyncChanged = function(_Message, _SyncMode)
		if _SyncMode == 0 then
			Game.GameTimeSetFactor(0);
		end
		SW.MPGame_ApplicationCallback_SyncChanged(_Message, _SyncMode);
	end
	
end

function ActivateDebug()
	Input.KeyBindDown(Keys.Q, "SpeedUpGame()",2);
	if debugging.ErrorLogging then
		log = function(_text) LuaDebugger.Log(_text) end
	end
	if debugging.TroopSpawnKeys then
		DebugTroops = {};
		CT = function()
			local x,y = GUI.Debug_GetMapPositionUnderMouse();
			table.insert(DebugTroops, Tools.CreateGroup(1, Entities.PU_LeaderCavalry2, 8, x, y, 100));
			SetHostile(1,2);
		end
		CT2 = function()
			local x,y = GUI.Debug_GetMapPositionUnderMouse();
			table.insert(DebugTroops, Tools.CreateGroup(2, Entities.PU_LeaderCavalry2, 8, x, y, 100));
		end
		DT = function()
			for i = table.getn(DebugTroops), 1, -1 do
				Tools.DestroyGroupByLeader(DebugTroops[i]);
				table.remove(DebugTroops, i);
			end
		end
		Input.KeyBindDown(Keys.W, "CT()",2);
		Input.KeyBindDown(Keys.E, "CT2()",2);
		Input.KeyBindDown(Keys.R, "DT()",2);
	end
	local g = 1000000;
	for i = 1,8 do
		Tools.GiveResouces(i, g,g,g,g,g,g);
		if debugging.ResearchAllUniversityTechnologies then
			ResearchAllUniversityTechnologies(i);
		end
		if debugging.LevelUpToMaxRank then
			SW.RankSystem.Points[i] = 100000
			SW.RankSystem.UpdatePlayer( i)
			SW.RankSystem.UpdatePlayer( i)
			SW.RankSystem.UpdatePlayer( i)
		end
	end
end
-- ##############################################################################################
-- ##
-- ##
-- ##                                  Siedler Speed War Mod
-- ##
-- ##


SW = SW or {};

-------------------------------------------------------
-- ################################################# --
-- Written & Tested 10.04.2017 ~ 01:30
SW.S5Hook_Callbacks = {};
function SW.RegisterS5HookInitializedCallback(_cb)

	if (S5Hook) then
		_cb();
		return;
	end
	
	table.insert(SW.S5Hook_Callbacks, _cb);
end;

function SW.OnS5HookLoaded()
	for i = 1,table.getn(SW.S5Hook_Callbacks) do
		SW.S5Hook_Callbacks[i]();
	end;
end;
-- ################################################# --
-------------------------------------------------------

function SW.Activate(_seed)
	if SW.IsActivated then
		Message("@color:255,0,0 Warning: Tried to activate speedwar 2 times! - cancelled");
		return;
	end
	SW.IsActivated = true;
	
	Message("SW activated");
	
	-- village centers shall be removed and replaced by outposts
	SW.EnableOutpostVCs();
	SW.RankSystem.ApplyGUIChanges();
	math.randomseed(_seed);
	SW.CallbackHacks();
	-- leaders don't cost sold anymore
	for playerId = 1,8 do
		Logic.SetPlayerPaysLeaderFlag(playerId, 0);
	end

	-- get number of max players for map
	SW.MaxPlayers = XNetwork.GameInformation_GetMapMaximumNumberOfHumanPlayer();
	if SW.MaxPlayers == 0 then
		SW.MaxPlayers = table.getn(SW.Players)
	end
	
	SW.RankSystem.Init();
	SW.TankyHQ.Init()
	SW.EnableStartingTechnologies();
	SW.EnableRandomWeather();
	-- outpostcosts increase with number of outposts
	SW.EnableIncreasingOutpostCosts();
	-- Increase exploration range of all player towers
	SW.TowerIncreaseExploration();
	-- Entities move faster
	SW.ApplyMovementspeedBuff();
	-- Use SW_BuildingCosts.lua for reduced buildings costs
	SW.EnableReducedConstructionCosts();
	-- same as for construction costs
	SW.EnableReducedUpgradeCosts();
	-- Change building max health
	SW.InitBuildingMaxHealth()
	-- Genetische Dispositionen für alle! :D
	SW.EnableGeneticDisposition()
	-- Dying entities leaves remains
	SW.EnableMortalRemains()
	-- Recruiting costs for one weapon stay the same for all levels
	SW.UnifyRecruitingCosts()
	-- Jeder mag Plünderer :D
	SW.EnablePillage()
	-- Random StartPos
	SW.EnableRandomStart()
	-- Defeatcondition - all entities of player destroyed
	SW.DefeatCondition_Create()
	-- Faster construction and upgrade for buildings
	SW.EnableFasterBuild()
	-- Activate Fire
	--SW.FireMod.Init()
	-- Enable tech tree
	SW.BuildingTooltipsInit()
	-- Fix blue byte exploits
	SW.Bugfixes.Init()
	-- Enable increased ressource gain
	SW.RefineryPush.Init()
	-- Activate the GUI for walls
	SW.WallGUI.Init()
	-- Activate Bastille Mod
	SW.Bastille.Activate()
	-- Just debug stuff
	SW.DebuggingStuff()		--DO NOT REMOVE NOW; REMOVE IN FINAL VERSION AFTER TALKING WITH NAPO
	-- Enable building walls
	SW.Walls.Init()
	-- Just for the lolz
	SW.RandomChest.Init()
	-- Make LKav great again
	SW.LKavBuff.Init()
	-- Window to display rank progress
	SW.ProgressWindow.Init()
	-- ActivateDebug()
	if debugging.Debug then
		ActivateDebug()
	end
	-- Allow ress checking
	SW.RessCheck.Init()
	-- Makes YOUR life easier with CTRL
	SW.QoL.Init()
	-- Block weather change for some time after manual change
	SW.WeatherBlock.Init()
	-- Let's have a key trigger!
	-- SW.KeyTrigger.Init();
	-- Now with better VCPlace distribution
	SW.VCChange.Init()
	-- We need HQ's! They are helpful
	SW.CreateHQsAndRedirectKeyBindung();
	-- More secure SoldierGetLeader
	-- SW.SoldierGetLeaderInit()
	-- Constant trade factors
	SW.FixMarketPrices()
	-- Check version
	SW.RessCheck.ShoutVersion()
end

function SW.EnableStartingTechnologies()
	local startTechs = {
		--"GT_Mercenaries", -- Wehrpflicht
		--"GT_Construction", -- Konstruktion
		"GT_Literacy", -- Bildung
	};
	
	for playerId = 1, SW.MaxPlayers do
		for i = 1, table.getn(startTechs) do
			ResearchTechnology(Technologies[startTechs[i]], playerId);
		end
	end
end

--			THE WEATHER
function SW.EnableRandomWeather()
	-- new weather states
	CreateDarkStorm(4);
	CreateSnowyRain(5);
	CreateIceTime(6);
	CreateLovelyEvening(7);
	WeatherSets_SourRain(8)
	WeatherSets_HotSummer(9)
	-- CONFIG PART
	local numOfWeatherStates = 9		--How many states are there?
	local baseChance = {}				--Doesnt need to add up to some number
	baseChance[1] = 80					--Chance summer
	baseChance[2] = 30					--Chance rain
	baseChance[3] = 30					--Chance winter
	baseChance[4] = 10					-- storm
	baseChance[5] = 20					-- snowy rain
	baseChance[6] = 20					-- ice time
	baseChance[7] = 20					-- evening
	baseChance[8] = 10					-- sour rain
	baseChance[9] = 10					-- hot summer
	local range = {}
	range[1] = {180, 300}				--Lower and upper limit for summer period
	range[2] = {60, 180}					--Lower and upper limit for rain period
	range[3] = {80, 240}					--Lower and upper limit for winter period
	range[4] = {60, 120}				--Lower and upper limit for summer2 period
	range[5] = {60, 180}					--Lower and upper limit for rain2 period
	range[6] = {80, 180}					--Lower and upper limit for winter2 period
	range[7] = {80, 120}					--Lower and upper limit for winter2 period
	range[8] = {40, 60}
	range[9] = {60, 120}
	local startSummerLength = 240 		-- minutes of starting summer
	local numOfPeriods = 50
	-- END OF CONFIG, DO NOT CHANGE
	if SW.WeatherData.UseCustomWeather then
		for k,v in pairs(baseChance) do
			baseChance[k] = SW.WeatherData.BaseChances[k] or baseChance[k]
		end
		for k,v in pairs(range) do
			range[k] = SW.WeatherData.Range[k] or range[k]
		end
	end
	local baseChanceSum = 0
	for i = 1, numOfWeatherStates do
		baseChanceSum = baseChanceSum + baseChance[i]
	end
	for i = 1, numOfWeatherStates do
		baseChance[i] = baseChance[i]/baseChanceSum
	end
	local total = {}
	for i = 1, numOfWeatherStates do
		total[i] = startSummerLength*baseChance[i]/baseChance[1]
	end
	local totalTimeSpent = startSummerLength
	local currentState = 1
	SW.RandomWeatherAddElement( 1, startSummerLength)
	local possStates = {}
	local representationFactors = {}
	local actualChances = {}
	local modifier = function(x)
		return 1/(x*x)
	end
	local sumChance = 0
	local rng, finalState, length
	for i = 2, numOfPeriods do
		-- IDEA: 
		-- We can calculate for each state a representation factor RF[i] = totalTimeInThisState(i)/totalTimeSpent/baseChance
		-- If weather state has high RF -> less likely to happen
		-- Script should try to balance things in a way that all RFs approach 1
		-- ActualChance[i] = baseChance[i]*modifier( RF[i])
		-- modifier should fulfill: modifier(1) = 1; lim_n->infinity modifier(n) = 0; lim_n->0 modifier(n) = infinity 
		-- modifier(x) = 1/x^2 should work for now
		
		-- calculate the RFs
		for j = 1, numOfWeatherStates do
			representationFactors[j] = total[j]/totalTimeSpent/baseChance[j]
		end
		-- calculate the actual chances
		for j = 1, numOfWeatherStates do
			actualChances[j] = baseChance[j] * modifier(representationFactors[j])
		end
		actualChances[currentState] = 0
		sumChance = 0
		for j = 1, numOfWeatherStates do
			sumChance = sumChance + actualChances[j]
		end
		-- now decide on state
		rng = math.random()*sumChance
		finalState = 0
		for j = 1, numOfWeatherStates do
			rng = rng - actualChances[j]
			if rng < 0 then
				finalState = j
				break
			end
		end
		-- if no final state was found cause of reasons unknown to mankind
		if finalState == 0 then finalState = math.mod(currentState,numOfWeatherStates)+1 end
		-- final state set -> GO!
		length = range[finalState][1]+math.floor(math.random()*(range[finalState][2]-range[finalState][1]))
		total[finalState] = total[finalState] + length
		totalTimeSpent = totalTimeSpent + length
		currentState = finalState
		SW.RandomWeatherAddElement( finalState, length)
	end
	if false then
		local s1, s2 = "", ""
		for i = 1, numOfWeatherStates do
			s1 = s1.." "..total[i]
			s2 = s2.." "..total[i]/totalTimeSpent
		end
		LuaDebugger.Log( s1)
		LuaDebugger.Log( s2)
	end
end

function SW.RandomWeatherAddElement( _stateId, _length)
    if _stateId < 4 then 
        AddWeatherElement( _length, _stateId, 1) 
        return 
    end
    if _stateId == 4 then
        Logic.AddWeatherElement(2, _length, 1, 4, 5, 10)
    elseif _stateId == 5 then
        Logic.AddWeatherElement(2, _length, 1, 5, 5, 10)
	elseif _stateId == 6 then
		Logic.AddWeatherElement(3, _length, 1, 6, 5, 10)
    elseif _stateId == 7 then
        Logic.AddWeatherElement(1, _length, 1, 7, 5, 10)
    elseif _stateId == 8 then
		Logic.AddWeatherElement(2, _length, 1, 8, 5, 10)
	else
		Logic.AddWeatherElement(1, _length, 1, 9, 5, 10)
	end
end

function SW.EnableOutpostVCs()
	-- load in archive while developing *-* --
	S5Hook.AddArchive("extra2/shr/maps/user/speedwar/archive.bba");
	S5Hook.LoadGUI("maps\\user\\speedwar\\swgui.xml");
	S5Hook.ReloadEntities();
	S5Hook.RemoveArchive();
	--Message("EnableOutpostVCs");
	--Blende VC-Button bei Leibis aus, schiebe Outpost-Button rüber und zeige an
	--XGUIEng.ShowWidget("Build_Village", 0);
	XGUIEng.ShowWidget("SWBuildOutpost", 0);
	XGUIEng.ShowWidget("Build_Outpost", 1); -- handled now by WallGUI.lua
	
	--XGUIEng.SetWidgetPosition("Build_Outpost", 112, 4);
	XGUIEng.SetWidgetPosition("Build_Outpost", S5Hook.GetWidgetPosition(XGUIEng.GetWidgetID("Build_Village")));
	XGUIEng.TransferMaterials( "SWBuildOutpost", "Build_Outpost");

	--[[
		XGUIEng.DoManualButtonUpdate(gvGUI_WidgetID.InGame);

	]]
end

--			TOWER EXPLORATION RANGE
function SW.TowerIncreaseExploration()
	for k,v in pairs( SW.AfflictedTowerTypes) do
		SW.SetExploration( v, SW.NewTowerRange)
	end
end

--			MOVEMENTSPEED
function SW.GetRealMS( _eId)
	if SW.MovementspeedAltered == nil then
		SW.MovementspeedAltered = {}
		for k,v in pairs(Entities) do
			local eName = Logic.GetEntityTypeName( v)
			local start = string.find( eName, "PU")
			local start2 = string.find( eName, "CU")
			local start3 = string.find( eName, "PV")
			if start ~= nil or start2 ~= nil or start3 ~= nil then
				SW.MovementspeedAltered[v] = true
			else
				SW.MovementspeedAltered[v] = false
			end
		end
	end
	local eType = Logic.GetEntityType( _eId)
	if not SW.MovementspeedAltered[eType] then
		return 0
	end
	local pId = GetPlayer( _eId)
	return SW.GetMSByTypeAndPlayer( eType, pId)
end
function SW.GetMSByTypeAndPlayer( _eType, _player)
	local baseMS = SW.BaseMovementspeed
	local myBaseMS = 100
	for k,v in pairs( baseMS) do --Get highest possible baseMS
		if SW.IsEntityTypeInCategory(_eType, k) == 1 then
			if myBaseMS < v then
				myBaseMS = v
			end
		end
	end
	--Sum up influencing movementspeed alterations by technologies
	local preFactorAdd = 0
	local postFactorAdd = 0
	local factorVal = 1
	for k,v in pairs( SW.MovementspeedTechInfluence) do
		local myTech = Technologies[k]
		if  Logic.GetTechnologyState(_player, myTech) == 4 then --Player has technology researched
			local affected = false --not affected until proven otherwise
			for k2,v2 in pairs( v.Influenced) do --Go through all influenced E-Categories
				if SW.IsEntityTypeInCategory( _eType, v2) == 1 then
					affected = true
					break;
				end
			end
			if affected then
				preFactorAdd = preFactorAdd + v.SumPreFactor
				postFactorAdd = postFactorAdd + v.SumPostFactor
				factorVal = factorVal * v.Factor
			end
		end
	end
	return (myBaseMS + preFactorAdd)*factorVal + postFactorAdd
end
function SW.ApplyMovementspeedBuff()
	if SW.IsEntityTypeInCategory == nil then
		assert(false, "Bitte einmal config/SW_MovementSpeed speichern. -NAPO THE GREAT")
	end
	for k,v in pairs( Entities) do
		local typeName = Logic.GetEntityTypeName( v)
		local start = string.find( typeName, "PU")
		local start2 = string.find( typeName, "CU")
		local start3 = string.find( typeName, "PV")
		if start ~= nil or start2 ~= nil or start3 ~= nil then
			for i = 1, 8 do
				local myMS = SW.GetMSByTypeAndPlayer( v, i)
				local myEntities = SW.GetAllEntitiesOfTypeAndPlayer( v, i)
				for k2, v2 in pairs( myEntities) do
					SW.SetMovementspeed( v2, myMS)
				end
			end
		end
	end
	SW.MovementspeedBuffGameCallback_OnTechnologyResearched = GameCallback_OnTechnologyResearched
	GameCallback_OnTechnologyResearched = function( _pId, _tId, _eId)
		for k,v in pairs(SW.MovementspeedTechInfluence) do
			if Technologies[k] == _tId then --Relevant technology researched - Recalculate buffs
				for k2,v2 in Entities do
					local typeName = Logic.GetEntityTypeName( v2)
					local start = string.find( typeName, "PU")
					local start2 = string.find( typeName, "CU")
					local start3 = string.find( typeName, "PV")
					if start ~= nil or start2 ~= nil or start3 ~= nil then
						local myEntities = SW.GetAllEntitiesOfTypeAndPlayer( v2, _pId)
						local myMS = SW.GetMSByTypeAndPlayer( v2, _pId)
						if myMS ~= 100 then
							for k3,v3 in pairs(myEntities) do
								SW.SetMovementspeed( v3, myMS)
							end
						end
					end
				end
				break;
			end
		end
		SW.MovementspeedBuffGameCallback_OnTechnologyResearched( _pId, _tId, _eId)
	end
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_MSBuffIsInteresting", "SW_OnEntityCreatedMSBuff", 1);
end
function SW_MSBuffIsInteresting()
	local eId = Event.GetEntityID()
	local typeName = Logic.GetEntityTypeName( Logic.GetEntityType(eId))
	local start = string.find( typeName, "PU")
	local start2 = string.find( typeName, "CU")
	local start3 = string.find( typeName, "PV")
	if start ~= nil or start2 ~= nil or start3 ~= nil then
		return true
	end
	return false
end
function SW_OnEntityCreatedMSBuff()
	local eId = Event.GetEntityID()
	local typee = Logic.GetEntityType(eId)
	local pId = GetPlayer( eId)
	local myMS = SW.GetMSByTypeAndPlayer( typee, pId)
	SW.SetMovementspeed( eId, myMS)
end

function SW.GetAllEntitiesOfType( _eType)
	return S5Hook.EntityIteratorTableize(Predicate.OfType( _eType))
end
function SW.GetAllEntitiesOfTypeAndPlayer( _eType, _player)
	return S5Hook.EntityIteratorTableize(Predicate.OfType( _eType), Predicate.OfPlayer(_player))
end

--			OUTPOSTS
--HelperFunc: Get number of current outposts( finished & in construction)
function SW.GetNumberOfOutpostsOfPlayer( _player)
	--LuaDebugger.Log("".._player)
	return Logic.GetNumberOfEntitiesOfTypeOfPlayer( _player, Entities.PB_Outpost1)
	--Unstable cause of unknown reasons?
	--local x = 0;
	--for eID in S5Hook.EntityIterator(Predicate.OfPlayer(_player), Predicate.OfType(Entities.PB_Outpost1)) do
	--	x=x+1;
	--end
	--return x;
end
--HelperFunc: Get cost of next outpost for player
--optional: _modifier, reduces num of outposts used in calculation
function SW.GetCostOfNextOutpost( _player, _modifier)
	local baseCosts = SW.OutpostCosts
	local numOutposts = SW.GetNumberOfOutpostsOfPlayer(_player);
	if _modifier ~= nil then
		numOutposts = numOutposts + _modifier
	end
	local factor = SW.GetCostFactorByNumOfOutposts(numOutposts);
	local finalCosts = {};
	for k,v in pairs(baseCosts) do
		finalCosts[k] = math.floor(math.floor(v*factor + 0.5) / 50 + 0.5) * 50;
	end
	return finalCosts;
end

function SW.EnableIncreasingOutpostCosts()
	--GUIElements:
	--Calls: GUIAction_PlaceBuilding( UpgradeCategories.Outpost)
	SW.GUITooltip_ConstructBuilding = GUITooltip_ConstructBuilding;
	GUITooltip_ConstructBuilding = function( _a, _b, _c, _d, _e)
		if _a == UpgradeCategories.Outpost then
			local pId = GUI.GetPlayerID()
			local costString = InterfaceTool_CreateCostString( SW.GetCostOfNextOutpost( pId) )
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, costString)
			XGUIEng.SetTextKeyName(gvGUI_WidgetID.TooltipBottomText, "MenuSerf/outpost_normal")		
			XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, " ")
		else
			SW.GUITooltip_ConstructBuilding(  _a, _b, _c, _d, _e)
		end
	end
	SW.GUIAction_PlaceBuilding = GUIAction_PlaceBuilding;
	GUIAction_PlaceBuilding = function( _uc)
		if _uc == UpgradeCategories.Outpost then
			--check ressources
			local pId = GUI.GetPlayerID()
			local costTable = SW.GetCostOfNextOutpost( pId)
			local currWidget = XGUIEng.GetCurrentWidgetID()
			if InterfaceTool_HasPlayerEnoughResources_Feedback( costTable) == 1 then
				XGUIEng.HighLightButton( currWidget, 1)
				GUI.ActivatePlaceBuildingState( _uc)
				Sound.PlayGUISound( Sounds.klick_rnd_1, 0 )
			end
		else
			SW.GUIAction_PlaceBuilding( _uc)
		end
	end
	--Eigentliche Kosten
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_IsOutpost", "SW_OnEntityCreatedOutpost", 1);
	--XGUIEng.UnHighLightGroup(gvGUI_WidgetID.InGame, "BuildingGroup") Was macht das??? Ist in OrigPlacceBuilding
end
function SW_IsOutpost()
	local eId = Event.GetEntityID();
	if Logic.GetEntityType(eId) == Entities.PB_Outpost1 then
		return true
	end
	return false
end
function SW_OnEntityCreatedOutpost()
	local eId = Event.GetEntityID();
	local pId = GetPlayer(eId);
	
	local currCostTable = SW.GetCostOfNextOutpost( pId, -1);
	-- Has player enough ressources?
	local enoughRess = true --Yes until proven otherwise
	local playerRess = {
		[ResourceType.Gold] = Logic.GetPlayersGlobalResource( pId, ResourceType.Gold ) + Logic.GetPlayersGlobalResource( pId, ResourceType.GoldRaw),
		[ResourceType.Wood] = Logic.GetPlayersGlobalResource( pId, ResourceType.Wood ) + Logic.GetPlayersGlobalResource( pId, ResourceType.WoodRaw),
		[ResourceType.Clay] = Logic.GetPlayersGlobalResource( pId, ResourceType.Clay ) + Logic.GetPlayersGlobalResource( pId, ResourceType.ClayRaw),
		[ResourceType.Silver] = 0,		
		[ResourceType.Stone] = Logic.GetPlayersGlobalResource( pId, ResourceType.Stone ) + Logic.GetPlayersGlobalResource( pId, ResourceType.StoneRaw),
		[ResourceType.Iron] = Logic.GetPlayersGlobalResource( pId, ResourceType.Iron ) + Logic.GetPlayersGlobalResource( pId, ResourceType.IronRaw),
		[ResourceType.Sulfur] = Logic.GetPlayersGlobalResource( pId, ResourceType.Sulfur ) + Logic.GetPlayersGlobalResource( pId, ResourceType.SulfurRaw)
	}
	for k,v in pairs( playerRess) do
		if v < currCostTable[k] then --not enough ressources!
			enoughRess = false
		end
	end
	if not enoughRess then --Not enough ressources?
		--DEMOLISH!!!1!11cos(0)
		SW_DestroySafe( eId)
		--Play message for controlling players
		if GUI.GetPlayerID() == pId then
			InterfaceTool_HasPlayerEnoughResources_Feedback( currCostTable)
		end
	else --zur Kasse bitten
		for k,v in pairs(currCostTable) do
			Logic.SubFromPlayersGlobalResource( pId, k, v);
		end
	end
end

function SW_DestroySafe(_entityID)
	SW_ToDestroyEntities = SW_ToDestroyEntites or {};
	function SW_DestroyJob()
		for i = table.getn( SW_ToDestroyEntities), 1, -1 do
			DestroyEntity( SW_ToDestroyEntities[i])
			table.remove(SW_ToDestroyEntities, i);
		end
		return true;
	end;
	table.insert(SW_ToDestroyEntities, _entityID);
	if table.getn(SW_ToDestroyEntities) == 1 then
		StartSimpleHiResJob("SW_DestroyJob");
	end
end

function SW_CreateEntitySafe( _eType, _x, _y, _rot, _player, _callback)
	SW_ToCreateEntities = SW_ToCreateEntities or {};
	function SW_CreateJob()
		for i = table.getn( SW_ToCreateEntities), 1, -1 do
			local entry = SW_ToCreateEntities[i]
			entry.callback(Logic.CreateEntity( entry.eType, entry.x, entry.y, entry.rot, entry.player))
		end
		SW_ToCreateEntities = {}
		return true
	end
	table.insert(SW_ToCreateEntities, { eType = _eType, x = _x, y = _y, rot = _rot, player = _player, callback = _callback});
	if table.getn(SW_ToCreateEntities) == 1 then
		StartSimpleHiResJob("SW_CreateJob");
	end
end

-- REDUCE BUILDING CONSTRUCTION COSTS
function SW.EnableReducedConstructionCosts()
	for buildingType, costTable in pairs(SW.BuildingConstructionCosts) do
		SW.SetConstructionCosts( Entities[buildingType], costTable);
	end
end

-- REDUCE BUILDING UPGRADE COSTS
function SW.EnableReducedUpgradeCosts()
	for buildingType, costTable in pairs(SW.BuildingUpgradeCosts) do
		SW.SetUpgradeCosts( Entities[buildingType], costTable);
	end
end

function SW.CallbackHacks()
	SW.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged;
	GameCallback_GUI_SelectionChanged = function()
		local entityId = GUI.GetSelectedEntity();
		local entityType = Logic.GetEntityType(entityId);
		SW.GameCallback_GUI_SelectionChanged();
		if entityType == Entities.PU_Serf then
			XGUIEng.ShowWidget("Build_Village", 0);
		end
	end


	-- Fix for finished buildings/technologies while serf is selected (VillageCenter was shown again.
	SW.DoManualButtonUpdate = XGUIEng.DoManualButtonUpdate;
	XGUIEng.DoManualButtonUpdate = function(_widgetID)
		SW.DoManualButtonUpdate(_widgetID);
		if (GUI.GetSelectedEntity() ~= nil and Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.PU_Serf) then
			XGUIEng.ShowWidget("Build_Village", 0);
		end;
	end;
end

--		DEBUG STUFF; REMOVE IN FINAL VERSION
SW_GoodNumber = 519
SW_BetterNumber = 1514
function SW.DebuggingStuff()
	-- Stuff worth protecting:
	--		Functions in SW-table
	--		Functions in GUI-table
	--		Functions in _G with "GUI" in it
	--		GameCallback_OnGameStart
	-- Creates check sums of SW.Activate and GUI.SellBuilding
	-- Used to call out bad people in multiplayer games
	GenerateChecksum = function(_f)
		local str = "";
		xpcall(function() str = string.dump( _f) end, function(_s) end)
		local checkSum = 0
		for i = 1, string.len(str) do
			checkSum = math.mod(checkSum + i*i*string.byte( str, i), 2017)
		end
		return checkSum
	end
	GenerateTableChecksum = function(_t)
		local checksum = 0
		for k,v in pairs(_t) do
			if type(v) == "function" then
				checksum = math.mod(checksum + GenerateChecksum(v), 2017)
			elseif type(v) == "table" then
				checksum = math.mod(checksum + GenerateTableChecksum(v), 2017)
			end
		end
		return checksum
	end
	local debugggg = false
	if GenerateTableChecksum(GUI) ~= SW_BetterNumber then
		SW_BetterNumber = GenerateTableChecksum(GUI)
		debugggg = true
	end
	if GenerateTableChecksum(SW) ~= SW_GoodNumber then
		SW_GoodNumber = GenerateTableChecksum(SW)
		debugggg = true
	end
	debugggg = false
	if debugggg and XNetwork.Manager_DoesExist() == 1 then
	--if debugggg then
		local pId = GUI.GetPlayerID()
		local name = XNetwork.GameInformation_GetLogicPlayerUserName( pId )
		local r,g,b = GUI.GetPlayerColor( pId )
    	local Message = "@color:"..r..","..g..","..b.." "..name.." @color:255,255,255 > Ich habe das Skript manipuliert!"
		XNetwork.Chat_SendMessageToAll( Message)
	end
end

--			GENETIC DISPOSITION
function SW.EnableGeneticDisposition()
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_IsSettlerGD", "SW_OnEntityCreatedGD", 1);
end
function SW_IsSettlerGD()
	local eId = Event.GetEntityID()
	if Logic.IsSettler( eId) == 1 then
		return true
	end
	return false
end
function SW_OnEntityCreatedGD()
	local eId = Event.GetEntityID()
	local rng = 0.75+0.5*math.random()
	S5Hook.GetEntityMem( eId)[25]:SetFloat(rng)
end

--			MORTAL REMAINS
function SW.EnableMortalRemains()
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_IsSettlerMR", "SW_OnEntityDestroyedMR", 1);
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "SW_IsSettlerMROH", "SW_OnEntityHurtMR", 1);
	for k,v in pairs(Entities) do
		local start = string.find( k, "Soldier")
		if start ~= nil then
			SW.MortalRemainsSoldierTypes[v] = true
		end
	end
	StartSimpleJob("SW_JobMR")
end
function SW_IsSettlerMR()
	local eId = Event.GetEntityID()
	if Logic.IsSettler( eId) == 1 then
		return true
	end
	return false
end
function SW_IsSettlerMROH()
	local eId = Event.GetEntityID2()
	if Logic.IsSettler( eId) == 1 then
		return true
	end
	return false
end
SW.MortalRemainsSoldierTypes = {}
SW.MortalRemainsRocks = {}
SW.MortalRemainsRocks_CurrIndex = 1
SW.MortalRemainsRecentlyHurt = {} --Entries: key = eId, value = timeStamp
SW.MortalRemainsEntitiesToPlace = {} --Entries: {[1] = ModelType, [2] = X, [3] = Y, [4] = rot}
function SW_OnEntityDestroyedMR()
	local eId = Event.GetEntityID()
	local pos = GetPosition( eId)
	if not SW.IsInCombatMR( eId) then --Kein Kampf? Kein GRAB!
		return
	end
	--SW.PreciseLog.Log("CreateGrave at "..pos.X.." "..pos.Y.." for eId "..eId)
	local myDegRng = math.mod(math.mod(eId,360)*47,360);
	local myRng = math.rad( myDegRng)
	local mySin = math.sin( myRng)
	local myCos = math.cos(myRng)
	local offsetX = math.random(-3,3) * 100;
	local offsetY = math.random(-3,3) * 100;
	local bones = math.random(1,3);
	--for i = 1, bones do
	--	table.insert( SW.MortalRemainsEntitiesToPlace, {"XD_BoneHuman"..math.random(1,8), pos.X + offsetX, pos.Y + offsetY, myDegRng})
	--end
	-- Gräber by mordred
	for i = 1, table.getn(SW.MortalRemainsTable) do
		local v = SW.MortalRemainsTable[i]
		--Transform offsetX, offsetY into new offsets with rotation
		local offsetX = myCos*v[2] - mySin*v[3]
		local offsetY = mySin*v[2] + myCos*v[3]
		table.insert( SW.MortalRemainsEntitiesToPlace, {v[1], pos.X + offsetX, pos.Y + offsetY, myDegRng+v[4]})
	end
end
function SW.MortalRemainsAddToRockTable( _eId)
	if SW.MortalRemainsRocks[SW.MortalRemainsRocks_CurrIndex] == nil then	--fresh index? write eId down
		SW.MortalRemainsRocks[SW.MortalRemainsRocks_CurrIndex] = _eId
	elseif IsExisting(SW.MortalRemainsRocks[SW.MortalRemainsRocks_CurrIndex]) then
		DestroyEntity(SW.MortalRemainsRocks[SW.MortalRemainsRocks_CurrIndex])
		SW.MortalRemainsRocks[SW.MortalRemainsRocks_CurrIndex] = _eId
	else
		SW.MortalRemainsRocks[SW.MortalRemainsRocks_CurrIndex] = _eId
	end
	--increase index
	--mapping:
	-- 1 -> 2
	-- 999 -> 1000
	-- 1000 -> 1
	SW.MortalRemainsRocks_CurrIndex = math.mod(SW.MortalRemainsRocks_CurrIndex, 1000)+1
end
function SW_JobMR()
	for i = table.getn(SW.MortalRemainsEntitiesToPlace), 1, -1 do
		local v = SW.MortalRemainsEntitiesToPlace[i]
		local myEId = Logic.CreateEntity( Entities.XD_Rock1, v[2], v[3], v[4], 0)
		Logic.SetModelAndAnimSet( myEId, Models[v[1]])
		SW.MortalRemainsAddToRockTable( myEId)
	end
	SW.MortalRemainsEntitiesToPlace = {}		--All entities placed
	--for i = table.getn(SW.MortalRemainsRecentlyHurt), 1, -1 do
	--	SW.MortalRemainsRecentlyHurt[i].time = SW.MortalRemainsRecentlyHurt[i].time - 1
	--	if SW.MortalRemainsRecentlyHurt[i].time < 0 then
	--		table.remove( SW.MortalRemainsRecentlyHurt, i)
	--	end
	--end
end
function SW.IsInCombatMR( _eId)
    local eType = Logic.GetEntityType( _eId)
	--SW.PreciseLog.Log("InCombatParam: ".._eId)
    if SW.MortalRemainsSoldierTypes[eType] then
        --_eId = SW.SoldierGetLeader(_eId)
		_eId = Logic.GetEntityScriptingValue( _eId, 69)
		if IsDead(_eId) then
			return false
		end
    end
    local condition = Logic.GetTimeMs() < (SW.MortalRemainsRecentlyHurt[_eId] or 0) + 3000;
    local x,y = Logic.EntityGetPos(_eId);
    --SW.PreciseLog.Log("Comb: " .. tostring(_eId) .. " " .. tostring(Logic.GetEntityType(_eId)) .. " " .. x .. " " .. y .. " " .. tostring(condition) .. " " .. Logic.GetTimeMs() .. " " .. ((SW.MortalRemainsRecentlyHurt[_eId] or 0) + 3000));
    if condition then
        return true
    end
    return false
end

function SW_OnEntityHurtMR()
	local opfer = Event.GetEntityID2()
	local eType = Logic.GetEntityType( opfer)
	if SW.MortalRemainsSoldierTypes[eType] then
		opfer = Logic.GetEntityScriptingValue( opfer, 69)
	end
	SW.MortalRemainsRecentlyHurt[opfer] = Logic.GetTimeMs()
end

--SW SoldierGetLeader
SW.SoldierGetLeaderData = {}
SW.SoldierGetLeaderSoldierTypes = {}
function SW.SoldierGetLeaderInit()
	for k,v in pairs(Entities) do
		local start = string.find( k, "Soldier")
		if start ~= nil then
			SW.SoldierGetLeaderSoldierTypes[v] = true
		end
	end
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_IsSoldier", "SW_OnEntityCreatedSoldierGetLeader", 1);
end
function SW_IsSoldier()
	if SW.SoldierGetLeaderSoldierTypes[Logic.GetEntityType(Event.GetEntityID())] then
		return true
	end
	return false
end
function SW_OnEntityCreatedSoldierGetLeader()
	local eId = Event.GetEntityID()
	SW.SoldierGetLeaderData[eId] = Logic.GetEntityScriptingValue( eId, 69)
end
function SW.SoldierGetLeader( _eId)	
	return SW.SoldierGetLeaderData[_eId] or 0
end

function SW.UnifyRecruitingCosts()
	for entityType, costTable in pairs(SW.RecruitingCosts.Extra) do
		SW.SetRecruitingCosts( Entities[entityType], costTable);
	end
	local techTreeSize = {}
	for k1,v1 in pairs(SW.RecruitingCosts.Level1And2) do
		local techTreeNum = 0
		for k2,v2 in pairs(Entities) do
			local start = string.find( k2, k1)
			if start ~= nil then
				techTreeNum = techTreeNum+1
			end
		end
		techTreeSize[k1] = techTreeNum
	end
	for k1,v1 in pairs(techTreeSize) do
		--SW.SetRecruitingCosts( _eType, _costTable)
		for i = 1, v1/2 do
			SW.SetRecruitingCosts( Entities[k1..i], SW.RecruitingCosts.Level1And2[k1])
		end
		for i = math.floor(v1/2+1), v1 do
			SW.SetRecruitingCosts( Entities[k1..i], SW.RecruitingCosts.Level3And4[k1])
		end
	end
end

function SW.EnablePillage()
	SW.PillageLastAttacker = {}
	SW.PillageCreateCostTable()
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "SW_IsBuildingPILLAGE", "SW_OnEntityHurtPILLAGE", 1)
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_IsBuildingDPILLAGE", "SW_OnEntityDestroyedPILLAGE", 1)
end
function SW_IsBuildingPILLAGE()
	local eId = Event.GetEntityID2()
	if Logic.IsBuilding(eId) == 1 then
		return true
	end
	return false
end
function SW_IsBuildingDPILLAGE()
	local eId = Event.GetEntityID()
	if Logic.IsBuilding(eId) == 1 then
		return true
	end
	return false
end
function SW_OnEntityHurtPILLAGE()
	local player = GetPlayer( Event.GetEntityID1())
	SW.PillageLastAttacker[Event.GetEntityID2()] = player
end
function SW_OnEntityDestroyedPILLAGE()
	local destroyId = Event.GetEntityID()
	if SW.PillageLastAttacker[destroyId] ~= nil then
		SW.PillageRewardPlayer( Logic.GetEntityType( destroyId), SW.PillageLastAttacker[destroyId])
	end
end
function SW.PillageRewardPlayer( _eType, _pId)
	SW.PreciseLog.Log("Pillage: Rewarding ".._pId.." for "..(Logic.GetEntityTypeName(_eType) or "unknown"))
	local costTable = SW.PillageEntityTypeCost[_eType]
	if costTable == nil then return; end
	local stringg = "Ihr habt ein Gebäude zerstört! Ihr erhaltet "
	local nameTable = {
		[ResourceType.Gold] = "Gold",
		[ResourceType.Clay] = "Lehm",
		[ResourceType.Wood] = "Holz",
		[ResourceType.Stone] = "Stein",
		[ResourceType.Iron] = "Eisen",
		[ResourceType.Sulfur] = "Schwefel",
	}
	local resColor = {
		[ResourceType.Gold] = "@color:255,215,0",
		[ResourceType.Clay] = "@color:167,107,41",
		[ResourceType.Wood] = "@color:86,47,14",
		[ResourceType.Stone] = "@color:139,141,122",
		[ResourceType.Iron] = "@color:203,205,205",
		[ResourceType.Sulfur] = "@color:237,255,33",
	}
	local stringElements = {}
	for k,v in pairs( costTable) do
		local toGive = math.floor(v*SW.PillagingRate/100)
		if toGive > 0 then
			Logic.AddToPlayersGlobalResource( _pId, k, toGive)
			local resName = nameTable[k] or "Unknown"
			local resColorr = resColor[k] or ""
			table.insert(stringElements, resColorr.." "..toGive.." "..resName.." @color:255,255,255 ")
		end
	end
	stringg = stringg..(stringElements[1] or "")
	for i = 2, table.getn(stringElements) do
		stringg = stringg..", "..stringElements[i]
	end
	if _pId == GUI.GetPlayerID() then
		Message( stringg..".")
	end
end

--		DEFEAT CONDITION
SW.DefeatConditionPlayerStates = {}
function SW.DefeatCondition_Create()
	SW.DefeatCondition_GetExistingEntities()
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, "SW_DefeatConditionCondition","SW_Defeat_On_Entity_Created",1 );
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, nil,"SW_Defeat_On_Entity_Destroyed",1 );
	StartSimpleJob("SW_DefeatConditionControl")
	for playerId = 1, SW.MaxPlayers do
		SW.DefeatConditionPlayerStates[playerId] = true
	end
end
function SW.DefeatConditionOnPlayerDefeated( _pId)	--Gets called once player destroyed - one time call
	if GUI.GetPlayerID() == _pId then		--show defeated player he has lost FOREVER
		GUI.AddStaticNote("@color:255,0,0: " .. XGUIEng.GetStringTableText( "InGameMessages/Note_PlayerLostGame" ))
	else						--show other players defeat of player _pId
		if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID( _pId) == 1 then
			local r,g,b = GUI.GetPlayerColor( _pId );
			local PlayerColor = " @color:" .. r .. "," .. g .. "," .. b .. ": ";
			GUI.AddNote( PlayerColor..UserTool_GetPlayerName( _pId).." @color:255,255,255: "..XGUIEng.GetStringTableText( "InGameMessages/Note_PlayerXLostGame" ), 10);
		end
	end
	--Make player name red
	if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID( _pId) == 1 then
		Logic.SetPlayerRawName( _pId, "@color:255,0,0,140 "..XNetwork.GameInformation_GetLogicPlayerUserName( _pId ).." @color:255,255,255 " )
	end
	--Has team of _pId lost?
	local lost = true
	local team = XNetwork.GameInformation_GetLogicPlayerTeam
	for i = 1, SW.MaxPlayers do
		if team(i) == team(_pId) then
			if SW.DefeatConditionPlayerStates[i] then --one player still fighting? not lost
				lost = false
				break
			end
		end
	end
	--Apply new sticky note & show map for defeated team
	if lost then
		if team(GUI.GetPlayerID()) == team( _pId) then
			GUI.ClearNotes()
			GUI.AddStaticNote("@color:255,0,0: " .. XGUIEng.GetStringTableText( "InGameMessages/Note_PlayerTeamLost" ));
		end
		for i = 1, SW.MaxPlayers do
			if team( _pId) == team(i) then
				local viewCenter = Logic.CreateEntity(Entities.XD_ScriptEntity, -1, -1, 90, i)
				Logic.SetEntityExplorationRange( viewCenter, 2000) --2000 > 768 * sqrt(2)
			end
		end
	end
	--Check for victorious team
	local vicTeam = nil
	local soleTeam = true
	for i = 1, SW.MaxPlayers do
		if SW.DefeatConditionPlayerStates[i] then  --one player still standing
			if vicTeam == nil then		--if no possibly victorious team found -> new victorious team
				vicTeam = team(i)
			else				--check if same team
				if vicTeam ~= team(i) then --Different teams - no victorious player
					soleTeam = false
					break
				end
			end
		end
	end
	--Show map & message
	if soleTeam and vicTeam ~= nil then
		if team(GUI.GetPlayerID()) == vicTeam then
			GUI.AddStaticNote("@color:0,255,0: "..XGUIEng.GetStringTableText("InGameMessages/Note_TeamWonGame"));
		end
		for i = 1, SW.MaxPlayers do
			if team(i) == vicTeam then
				local viewCenter = Logic.CreateEntity(Entities.XD_ScriptEntity, -1, -1, 90, i)
				Logic.SetEntityExplorationRange( viewCenter, 2000) --2000 > 768 * sqrt(2)
			end
		end
		return true
	end
end
function SW_DefeatConditionCondition()
	return SW.DefeatConditionTypes[Logic.GetEntityType(Event.GetEntityID())];
end
function SW_DefeatConditionControl()
	for i = 1, SW.MaxPlayers do
		if SW.DefeatConditionPlayerStates[i] then
			if SW.DefeatConditionPlayerEntities[i] == 0 then
				SW.DefeatConditionPlayerStates[i] = false
				SW.DefeatConditionOnPlayerDefeated( i)
			end
		end
	end
end
function SW_Defeat_On_Entity_Created()
	local eId = Event.GetEntityID()
	local player = Logic.EntityGetPlayer(eId);
	if player < 1 then
		return;
	end
	SW.DefeatConditionPlayerEntities[player] = SW.DefeatConditionPlayerEntities[player] + 1;
	SW.DefeatConditionEntityList[eId] = player
end
function SW_Defeat_On_Entity_Destroyed()
	if SW.GameClosed then
		return true
	end
	local eId = Event.GetEntityID()
	local player = SW.DefeatConditionEntityList[eId]
	if player == nil then
		return;
	end
	--LuaDebugger.Log("Entity destroyed: "..eId.." of player "..(player or "unknown"))
	SW.DefeatConditionEntityList[eId] = nil
	SW.DefeatConditionPlayerEntities[player] = SW.DefeatConditionPlayerEntities[player] - 1;
	--LuaDebugger.Log("Player "..player.." has "..SW.DefeatConditionPlayerEntities[player].." entities.")
end
function SW.DefeatCondition_GetExistingEntities()
	for playerId = 1, SW.MaxPlayers do
		for k,v in pairs( SW.DefeatConditionTypes) do
			local n, eID = Logic.GetPlayerEntities(playerId, k, 1);
			if (n > 0) then
				local firstEntity = eID;
				repeat
					SW.DefeatConditionPlayerEntities[playerId] = SW.DefeatConditionPlayerEntities[playerId] + 1;
					SW.DefeatConditionEntityList[eID] = playerId
					eID = Logic.GetNextEntityOfPlayerOfType(eID);
				until (firstEntity == eID);
			end
		end
	end
end

--			FASTER BUILDING
function SW.EnableFasterBuild()
	--if true then return end
	-- First change construction time
	for k,v in Entities do
		if SW.FasterBuildConstructionTimeChange[v] then		--construction speed of eType should be changed
			local time = SW.FasterBuildConstruction[v]
			if time == nil then
				time = SW.FasterBuildFactor * SW.GetConstructionTime( v)
			end
			SW.SetConstructionTime( v, time)
		end
	end
	-- Now change upgrade time
	for k,v in Entities do
		if SW.FasterBuildUpgradeTimeChange[v] then		--construction speed of eType should be changed
			local time = SW.FasterBuildUpgrade[v]
			if time == nil then
				time = SW.FasterBuildFactor * SW.GetUpgradeTime( v)
			end
			SW.SetUpgradeTime( v, time)
		end
	end
end


function SW.IsMultiplayer()
	return XNetworkUbiCom.Manager_DoesExist() == 1 or XNetwork.Manager_DoesExist() == 1;
end

function SW.CreateHQsAndRedirectKeyBindung()
	local player;
	local hqId;
	SW.SetAttractionPlaceProvided(Entities.PB_Headquarters3, 30);
	for i = 1, table.getn(SW.Players) do
		player = SW.Players[i];
		hqId = Logic.CreateEntity(Entities.PB_Headquarters3, 1000, 1000, 0, player);
		Logic.SetEntitySelectableFlag( hqId, 0)
		Logic.SetEntityScriptingValue( hqId, -30, 257)
	end;
	SW.KeyBindings_SelectUnit = KeyBindings_SelectUnit
	KeyBindings_SelectUnit = function( _uc, _pId)
		if _uc == UpgradeCategories.Headquarters then
			SW.KeyBindings_SelectUnit( UpgradeCategories.Outpost, _pId)
		else
			SW.KeyBindings_SelectUnit( _uc, _pId)
		end
	end
end

xXPussySlayer69Xx = LuaDebugger;

--[[
	Mad[01.07.17 12:31]: causes crashes at restart, seems to happen if troops attacked a building -> disabled
	Napo[21.10.17]: reenabled to test stuff

if not Framework.RestartMap_Orig then
	Framework.RestartMap_Orig = Framework.RestartMap;
	Framework.RestartMap = function()
		--S5Hook.RemoveArchive();
		S5Hook.ReloadEntities();
		SW.ResetScriptingValueChanges();
		Trigger.DisableTriggerSystem( 1)
		Framework.RestartMap_Orig();
	end
end
if not SW.QuitGame then
	SW.QuitGame = QuitGame
	QuitGame = function()	
		SW.GameClosed = true;
		SW.QuitGame()
	end
end

if not Framework.CloseGame_Orig then
	Framework.CloseGame_Orig = Framework.CloseGame;
	Framework.CloseGame = function()
		--S5Hook.RemoveArchive(); --Archive already removed in SW.EnableOutpostVCs()
		SW.GameClosed = true;
		S5Hook.ReloadEntities();
		SW.ResetScriptingValueChanges();
		--LuaDebugger.Break();
		--
		S5Hook.AddArchive("extra2/shr/maps/user/speedwar/backtotheroots.bba");
		Trigger.DisableTriggerSystem( 1)
		Framework.CloseGame_Orig();
	end
end
 -- ]]
 
 if not Framework.CloseGame_Orig then
	Framework.CloseGame_Orig = Framework.CloseGame;
	Framework.CloseGame = function()
		SW.ResetScriptingValueChanges();
		SW.RefineryPush.Reset();
		SW.ResetBuildingMaxHealth();
		S5Hook.AddArchive("extra2/shr/maps/user/speedwar/backtotheroots.bba");
		S5Hook.ReloadEntities();
		S5Hook.RemoveArchive();
		Trigger.DisableTriggerSystem( 1)
		Framework.CloseGame_Orig();
	end
end
function AddTribute( _tribute )
		assert( type( _tribute ) == "table", "Tribut muß ein Table sein" );
		assert( type( _tribute.text ) == "string", "Tribut.text muß ein String sein" );
		assert( type( _tribute.cost ) == "table", "Tribut.cost muß ein Table sein" );
		assert( type( _tribute.pId ) == "number", "Tribut.pId muß eine Nummer sein" );
		assert( not _tribute.Tribute , "Tribut.Tribute darf nicht vorbelegt sein");
 
		uniqueTributeCounter = uniqueTributeCounter or 1;
		_tribute.Tribute = uniqueTributeCounter;
		uniqueTributeCounter = uniqueTributeCounter + 1;
 
		local tResCost = {};
		for k, v in pairs( _tribute.cost ) do
			assert( ResourceType[k] );
			assert( type( v ) == "number" );
			table.insert( tResCost, ResourceType[k] );
			table.insert( tResCost, v );
		end
 
		Logic.AddTribute( _tribute.pId, _tribute.Tribute, 0, 0, _tribute.text, unpack( tResCost ) );
		SetupTributePaid( _tribute );
		return _tribute.Tribute;
end

function CreateDarkStorm(_id)
	local start = 0.0;
	local endt = 1.0;
	Display.GfxSetSetSkyBox(_id, start, endt, "YSkyBox04")
	Display.GfxSetSetSnowStatus(_id, start, endt, 0)
	Display.GfxSetSetSnowEffectStatus(_id, start, endt, 0)
	Display.GfxSetSetRainEffectStatus(_id, 0.5, 4.0, 1)
	Display.GfxSetSetFogParams(_id, start, endt, 1, 10,10,40, 0,30000)
	Display.GfxSetSetLightParams(_id,  start, endt, 20, -15, -50,  20,20,35,  155,155,255)
end

function CreateSnowyRain(_id)
	Display.GfxSetSetSkyBox(_id, 0.0, 1.0, "YSkyBox04")
	Display.GfxSetSetSnowStatus(_id, 0, 6.0, 0)
	Display.GfxSetSetSnowEffectStatus(_id, 0.0, 2.0, 1)
	Display.GfxSetSetRainEffectStatus(_id, 0.0, 7.0, 1)
	Display.GfxSetSetFogParams(_id, 0.0, 1.0, 1, 102,142,162, 0,30000);
    Display.GfxSetSetLightParams(_id,  0.0, 1.0, 40, -15, -50,  120,110,110,  255,254,230)
end

function CreateIceTime(_id)
    Display.GfxSetSetSkyBox(_id, 0.0, 1.0, "YSkyBox01")
    Display.GfxSetSetSnowStatus(_id, 0, 1.0, 1)
    Display.GfxSetSetSnowEffectStatus(_id, 0.0, 0.8, 0)
    Display.GfxSetSetFogParams(_id, 0.0, 1.0, 1, 152,172,182, 0,30000)
    Display.GfxSetSetLightParams(_id,  0.0, 1.0,  40, -15, -75,  180,180,190, 250,250,250)
end

function CreateLovelyEvening(_id)
	Display.GfxSetSetSkyBox(_id, 0.0, 1.0, "YSkyBox05")
	Display.GfxSetSetSnowStatus(_id, 0, 1.0, 0)
	Display.GfxSetSetSnowEffectStatus(_id, 0.0, 1.0, 0)
	Display.GfxSetSetRainEffectStatus(_id, 0.0, 1.0, 0)
	Display.GfxSetSetFogParams(_id, 0.0, 1.0, 1, 255,205,155, 6000,30000)
	Display.GfxSetSetLightParams(_id,  0.0, 1.0, 90, -15, -95,  225,100,80,  230,85,100)
end

