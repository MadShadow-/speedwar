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
		for i=1,8,1 do
			MultiplayerTools.DeleteFastGameStuff(i)
		end
		local PlayerID = GUI.GetPlayerID()
		Logic.PlayerSetIsHumanFlag( PlayerID, 1 )
		Logic.PlayerSetGameStateToPlaying( PlayerID )
	end
	
	LocalMusic.UseSet = HIGHLANDMUSIC
	AddPeriodicSummer( 2 * 60);
	SetupHighlandWeatherGfxSet()
	-- how about some vision?
	Display.GfxSetSetFogParams(3, 0.0, 1.0, 1, 152,172,182, 3000,19500)
	Display.GfxSetSetFogParams(2, 0.0, 1.0, 1, 102,132,132, 0,19500)
	log = function() end;
	ActivateDebug();
	for i = 1, 4 do
		Tools.GiveResouces(i, 0, 700, 500, 0, 0, 0);
	end
	
	SW.Players = {};
	if SW.IsMultiplayer() then
		for playerId = 1,8 do
			if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(playerId) == 1 then
				table.insert(SW.Players, playerId);
			end
		end
	else
		SW.Players = {1};
	end
	SW.NrOfPlayers = table.getn(SW.Players);


	-- Create HQs and redirect keybindings
	SW.CreateHQsAndRedirectKeyBindung();
	
	Script.LoadFolder("maps\\user\\speedwar\\config");
	Script.LoadFolder("maps\\user\\speedwar\\tools");


	

	SW.SetupMPLogic();
	Sync.Init();


	local ret = InstallS5Hook();

	if (ret) then
		SW.OnS5HookLoaded();
	end;
	
	SW.IsActivated = false;
	
	if SW.NrOfPlayers == 1 then
		-- playing alone - no sync needed
		SW.Activate(XGUIEng.GetSystemTime());
	else
		-- try message sync
		-- every player notifies the other about his "arrival"
		-- first player ingame counts nr of "arrivals" and as soon
		SW.NotifiedPlayers = 0;
		-- NotifyingDone determines whether Activate call has been made
		SW.NotifyingDone = false;
		function SW.NotifyPlayer()
			SW.NotifiedPlayers = SW.NotifiedPlayers + 1;
			if SW.NotifiedPlayers == SW.NrOfPlayers and not SW.NotifyingDone then
				SW.NotifyingDone = true;
				Sync.Call("SW.Activate", XGUIEng.GetSystemTime());
			end
		end
		Sync.CallNoSync("SW.NotifyPlayer");
		
		-- fallbacksystem: if notify player messages fail - use this
		if GUI.GetPlayerID() == 1 then
			function SW_Iks()
				if Counter.Tick2("SW_Iks", 2) and not SW.NotifyingDone then
					SW.NotifyingDone = true;
					Message("used job for activating"); -- remove msg!
					Sync.Call("SW.Activate", XGUIEng.GetSystemTime());
					return true;
				end
			end
			StartSimpleJob("SW_Iks");
		end
	end
end

function ActivateDebug()
	log = function(_text) LuaDebugger.Log(_text) end
	DebugTroops = {};
	CT = function()
		local x,y = GUI.Debug_GetMapPositionUnderMouse();
		table.insert(DebugTroops, Tools.CreateGroup(2, Entities.PU_LeaderSword2, 8, x, y, 100));
		SetHostile(1,2);
	end
	DT = function()
		for i = table.getn(DebugTroops), 1, -1 do
			Tools.DestroyGroupByLeader(DebugTroops[i]);
			table.remove(DebugTroops, i);
		end
	end
	Input.KeyBindDown(Keys.W, "CT()",2);
	Input.KeyBindDown(Keys.E, "DT()",2);
	Input.KeyBindDown(Keys.Q, "SpeedUpGame()",2);
	--Input.KeyBindDown(Keys.W, "GUI.ActivatePlaceBuildingState(UpgradeCategories.Outpost)", 2);
	Input.KeyBindDown(Keys.R, "Framework.RestartMap()", 2);
	local g = 10000;
	for i = 1,8 do
		Tools.GiveResouces(i, g,g,g,g,g,g);
		--ResearchAllUniversityTechnologies(i);
	end
	Camera.ZoomSetFactorMax( 2)
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
	
	SW.EnableRankSystem();
	SW.TankyHQ.Init()
	SW.EnableStartingTechnologies();
	SW.EnableRandomWeather();
	-- village centers shall be removed and replaced by outposts
	SW.EnableOutpostVCs();
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
	--SW.SetConstructionTime( Entities.PB_Residence1, 5)
	-- Units cost less
	local costTable_ = {
		[ResourceType.Wood] = 15
	}
	SW.SetRecruitingCosts( Entities.PU_Serf, costTable_)
	-- BURN MF BURN
	--ExpandingFire:Init{ErrLvl = 0, AffectedPlayers = {1,2,3,4,5,6}}
	--local _, hqId = Logic.GetPlayerEntities( 1, Entities.PB_Headquarters1, 1)
	--ExpandingFire:IgniteBuilding(hqId)
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
	--SW.CreateDefeatCondition() -- deprecated
	SW.DefeatCondition_Create()
	-- Faster construction and upgrade for buildings
	SW.EnableFasterBuild()
	-- Fix sell building bug
	SW.EnableSellBuildingFix()
	--StartSimpleJob("WipeThemAll")
	-- Activate Fire
	SW.FireMod.Init()
	-- Enable tech tree
	SW.BuildingTooltipsInit()
end

-- llllIIIIlIlIIl
function SW.EnableRankSystem()
	SW.RankSystem.Init()
	if true then return end
	SW.RankSystem = {};
	
	-- 1 Kill = 2 points
	-- 1 Building = 20 Points
	-- to be balanced
	SW.RankSystem.PointsToNextRank = {
		[2] = 400, -- 20 buildings or 200 kills
		[3] = 1200, -- 60 buildings or 600 kills
		[4] = 2000,  -- 100 buildings or 1000 kills
	};
	SW.RankSystem.RankOfPlayer = {}
	SW.RankSystem.PointsOfPlayer = {}
	for i = 1, SW.NrOfPlayers do
		SW.RankSystem.RankOfPlayer[SW.Players[i]] = 1;
		SW.RankSystem.PointsOfPlayer[SW.Players[i]] = 0;
	end
	
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


function SW.EnableRandomWeather() --Dont use completely random weather, use pseudo random distribution; Event didnt kick in->Increase chances of kicking in
	--chance: 50% summer, 25% rain, 25% snow
	local baseChanceSummer = 50
	local baseChanceRain = 25
	local baseChanceWinter = 25
	local penaltyFactor = 1.4	--Factor by which chances increases if event didnt hit}
	local rangeSummer = {45, 180}
	local rangeRain = {45, 120}
	local rangeWinter = {75, 90}
	local currSummer = baseChanceSummer
	local currRain = baseChanceRain
	local currWinter = baseChanceWinter
	local summerCount = 0
	local rainCount = 0
	local winterCount = 0
	-- 30 weather periods
	for i = 1, 30 do
		local rng = math.random(1,currSummer + currRain + currWinter);
		if rng <= currSummer then
			local length = math.random(rangeSummer[1],rangeSummer[2])
			AddPeriodicSummer( length);
			LuaDebugger.Log("Summer: "..length)
			--Summer added, increase chance of rain and snow, reset summer chance
			currSummer = baseChanceSummer
			currRain = math.floor(currRain * penaltyFactor)
			currWinter = math.floor(currWinter * penaltyFactor)
			summerCount = summerCount + 1
		elseif rng <= currSummer + currRain then
			local length = math.random(rangeRain[1],rangeRain[2])
			AddPeriodicRain( length);
			LuaDebugger.Log("Rain: "..length)
			--Rain added, increase chance of summer and snow, reset rain chance
			currRain = baseChanceRain
			currSummer = math.floor(currSummer * penaltyFactor)
			currWinter = math.floor(currWinter * penaltyFactor)
			rainCount = rainCount + 1
		else
			local length = math.random(rangeWinter[1],rangeWinter[2])
			AddPeriodicWinter( length);
			LuaDebugger.Log("Winter: "..length)
			--Winter added, increase chance of rain and summer, reset winter chance
			currWinter = baseChanceWinter
			currRain = math.floor(currRain * penaltyFactor)
			currSummer = math.floor(currSummer * penaltyFactor)
			winterCount = winterCount + 1
		end
	end
	LuaDebugger.Log("Summer: "..summerCount)
	LuaDebugger.Log("Rain: "..rainCount)
	LuaDebugger.Log("Winter: "..winterCount)
end

function SW.EnableOutpostVCs()
	-- load in archive while developing *-* --
	S5Hook.AddArchive("extra2/shr/maps/user/speedwar/archive.bba");
	S5Hook.ReloadEntities();
	S5Hook.RemoveArchive();
	--Message("EnableOutpostVCs");
	--Blende VC-Button bei Leibis aus, schiebe Outpost-Button rüber und zeige an
	XGUIEng.ShowWidget("Build_Village", 0);
	XGUIEng.ShowWidget("Build_Outpost", 1);
	--XGUIEng.SetWidgetPosition("Build_Outpost", 112, 4);
	XGUIEng.SetWidgetPosition("Build_Outpost", S5Hook.GetWidgetPosition(XGUIEng.GetWidgetID("Build_Village")));

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
				SW.MovementspeedAltered[v] = true
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
						for k3,v3 in pairs(myEntities) do
							SW.SetMovementspeed( v3, myMS)
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
		finalCosts[k] = math.floor(math.floor(v*factor + 0.5) / 100 + 0.5) * 100;
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
end;

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
		--Show HQ Menu in Outposts
		if entityType == Entities.PB_Outpost1 then
			if Logic.IsConstructionComplete( entityId) == 1 then
				XGUIEng.ShowWidget("Headquarter", 1)
				--XGUIEng.DoManualButtonUpdate(XGUIEng.GetWidgetID("Headquarter"));
				XGUIEng.ShowWidget("Buy_Hero", 0);
				XGUIEng.ShowWidget("Upgrade_Headquarter1", 0)
				XGUIEng.ShowWidget("Upgrade_Headquarter2", 0)
				-- Show tax menu if adjustable taxes are researched
				if Logic.GetTechnologyState( GUI.GetPlayerID(), Technologies.GT_Literacy) == 4 then
					XGUIEng.ShowWidget( "HQTaxes", 1)
				end
			end
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
SW.MortalRemainsRecentlyHurt = {} --Entries: {id, time}
SW.MortalRemainsEntitiesToPlace = {} --Entries: {[1] = ModelType, [2] = X, [3] = Y, [4] = rot}
function SW_OnEntityDestroyedMR()
	local eId = Event.GetEntityID()
	local pos = GetPosition( eId)
	if not SW.IsInCombatMR( eId) then --Kein Kampf? Kein GRAB!
		return
	end
	local myDegRng = math.random(1,360);
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
	for k,v in pairs(SW.MortalRemainsTable) do
		--Transform offsetX, offsetY into new offsets with rotation
		local offsetX = myCos*v[2] - mySin*v[3]
		local offsetY = mySin*v[2] + myCos*v[3]
		table.insert( SW.MortalRemainsEntitiesToPlace, {v[1], pos.X + offsetX, pos.Y + offsetY, myDegRng+v[4]})
	end --
	
end
function SW_JobMR()
	for i = table.getn(SW.MortalRemainsEntitiesToPlace), 1, -1 do
		local v = SW.MortalRemainsEntitiesToPlace[i]
		local myEId = Logic.CreateEntity( Entities.XD_Rock1, v[2], v[3], v[4], 0)
		Logic.SetModelAndAnimSet( myEId, Models[v[1]])
		table.insert( SW.MortalRemainsRocks, myEId)
		table.remove( SW.MortalRemainsEntitiesToPlace, i)
	end
	for i = table.getn(SW.MortalRemainsRecentlyHurt), 1, -1 do
		SW.MortalRemainsRecentlyHurt[i].time = SW.MortalRemainsRecentlyHurt[i].time - 1
		if SW.MortalRemainsRecentlyHurt[i].time < 0 then
			table.remove( SW.MortalRemainsRecentlyHurt, i)
		end
	end
	if table.getn(SW.MortalRemainsRocks) > 1000 then
		for i = 1, 50 do
			DestroyEntity( SW.MortalRemainsRocks[1])
			table.remove( SW.MortalRemainsRocks, 1)
		end
	end
end
function SW.IsInCombatMR( _eId)
	local eType = Logic.GetEntityType( _eId)
	if SW.MortalRemainsSoldierTypes[eType] then
		_eId = S5Hook.GetEntityMem( _eId)[127]:GetInt()
	end
	for k,v in SW.MortalRemainsRecentlyHurt do
		if _eId == v.id then
			return true
		end
	end
	return false
end
function SW_OnEntityHurtMR()
	local opfer = Event.GetEntityID2()
	local eType = Logic.GetEntityType( opfer)
	if SW.MortalRemainsSoldierTypes[eType] then
		opfer = S5Hook.GetEntityMem( opfer)[127]:GetInt()
	end
	table.insert( SW.MortalRemainsRecentlyHurt, { id = opfer, time = 3})
end

function SW.UnifyRecruitingCosts()
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
	local costTable = SW.PillageEntityTypeCost[_eType]
	if costTable == nil then return; end
	for k,v in pairs( costTable) do
		Logic.AddToPlayersGlobalResource( _pId, k, math.floor(v*SW.PillagingRate/100)) 	
	end
end

--		DEFEAT CONDITION
function SW.DefeatCondition_Create()
	SW.DefeatCondition_GetExistingEntities()
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, "SW_DefeatConditionCondition","SW_Defeat_On_Entity_Created",1 );
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, nil,"SW_Defeat_On_Entity_Destroyed",1 );
	StartSimpleJob("SW_DefeatConditionControl")
	SW.DefeatConditionPlayerStates = {}
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

function SW.EnableSellBuildingFix()
	--GameCallback_GainedResources
	--Is not triggered by trades & sold buildings
	SW.SellBuildingFixGainedResourcesOrig = GameCallback_GainedResources
	GameCallback_GainedResources = function(_playerId, _type, _amount)
		--Message( _playerId)
		--Message( _type)
		--Message( _amount)
		SW.SellBuildingFixGainedResourcesOrig( _playerId, _type, _amount)
	end
end



function SW.IsMultiplayer()
	return XNetworkUbiCom.Manager_DoesExist() == 1 or XNetwork.Manager_DoesExist() == 1;
end

function SW.EnableRandomStart()
	if SW.IsMultiplayer() then
		local isHuman;
		for i = 1, 8 do
			isHuman = XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i);
			if isHuman == 1 then
				-- TODO remove spectators.
				SW.RandomPosForPlayer(i);
			end;
		end;
	else
		SW.RandomPosForPlayer(1);
	end;
end
function SW.RandomPosForPlayer(_player)
	local success = false
	local positions = {
		{ X = 4000, Y = 18000 };
		{ X = 22000, Y = 6000 };
	};
	local sectors = {};
	local _, _, sector;
	for i = 1,table.getn(positions) do
		_, _, sector = S5Hook.GetTerrainInfo(positions[i].X, positions[i].Y);
		table.insert(sectors, sector)
	end;
	local worldSize = Logic.WorldGetSize()
	local ranX, ranY, sectorID
	local valid;
	while not success do
		ranX = math.random()*worldSize
		ranY = math.random()*worldSize
		_, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY);
		valid = false --invalid until proven otherwise
		for j = 1, table.getn(sectors) do
			if sectors[j] == sectorID then
				valid = true
				break;
			end
		end
		if valid then
			success = true
			for i = 1, 8 do
				Logic.CreateEntity( Entities.PU_Serf, ranX, ranY, 0, _player)
				if GUI.GetPlayerID() == _player then
					Camera.ScrollSetLookAt(ranX,ranY);
				end
			end
		end 
	end
	
end

function SW.CreateHQsAndRedirectKeyBindung()
	
	local player;
	local hqId;
	for i = 1, table.getn(SW.Players) do
		player = SW.Players[i];
		hqId = Logic.CreateEntity( Entities.PB_Headquarters3, 1000, 1000, 0, player)
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


function SW.SetRandomSeed(_seed)
	--[[if true then return end;
	if SW.IsMultiplayer() then 
		local currSeed = 0
		local FatNum = 312431
		for i = 1, 8 do
			if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(i) == 1 then
				local currName = XNetwork.GameInformation_GetLogicPlayerUserName(i)
				local length = string.len( currName)
				local entry = math.mod( i*FatNum, length)+1
				local myNum = string.byte(currName, entry)
				currSeed = currSeed * 256 + myNum
			end	
		end
		--Message( currSeed)
		math.randomseed( currSeed)
	end]]
end

--[[
	Mad[01.07.17 12:31]: causes crashes at restart, seems to happen if troops attacked a building -> disabled
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
		Trigger.DisableTriggerSystem( 1)
		Framework.CloseGame_Orig();
	end
end]]

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
