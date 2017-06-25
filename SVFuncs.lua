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

	
	-- Init  global MP stuff
	--MultiplayerTools.InitResources("normal")
	MultiplayerTools.InitCameraPositionsForPlayers()	
	MultiplayerTools.SetUpGameLogicOnMPGameConfig()
	MultiplayerTools.GiveBuyableHerosToHumanPlayer( 0 )
	
	if XNetwork.Manager_DoesExist() == 0 then		
		for i=1,8,1 do
			MultiplayerTools.DeleteFastGameStuff(i)
		end
		local PlayerID = GUI.GetPlayerID()
		Logic.PlayerSetIsHumanFlag( PlayerID, 1 )
		Logic.PlayerSetGameStateToPlaying( PlayerID )
	end
	
	LocalMusic.UseSet = HIGHLANDMUSIC
	AddPeriodicSummer(10)
	SetupHighlandWeatherGfxSet()
	
	ActivateDebug()
	
	Script.LoadFolder("maps\\user\\scripts\\tools");
	local ret = InstallS5Hook();

	if (ret) then
		SW.OnS5HookLoaded();
	end;
	
        SW.Activate();
	Message("loaded SW");
	if InitAdressEntity ~= nil then
		--local adressEntityPos = GetPosition(67102)
		--local adressEntity = Logic.CreateEntity(Entities.PU_Serf, adressEntityPos.X, adressEntityPos.Y, 0, 1)
		--InitAdressEntity( 67102, onAdressEntityLoaded)
		--for i = 1, 5 do Game.GameTimeSpeedUp() end
	end
end


function onAdressEntityLoaded()
	--Message("SCV2 ready")
end
function ActivateDebug()
	Input.KeyBindDown(Keys.Q, "SpeedUpGame()",2);
	--Input.KeyBindDown(Keys.W, "GUI.ActivatePlaceBuildingState(UpgradeCategories.Outpost)", 2);
	Input.KeyBindDown(Keys.E, "Framework.RestartMap()", 2);
	local g = 10000;
	for i = 1,8 do
		Tools.GiveResouces(i, g,g,g,g,g,g);
		ResearchAllUniversityTechnologies(i);
	end
	Tools.ExploreArea(-1,-1,900);
	Camera.ZoomSetFactorMax( 2)
end
function CreateSonic()
	local _, id = Logic.GetPlayerEntities( 1, Entities.PU_Serf, 1) 
	S5Hook.GetEntityMem( id)[31][1][5]:SetFloat(5000)
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

function SW.Activate()
	
	SW.CallbackHacks();
	CreateSonic()
	
	-- leaders don't cost sold anymore
	for playerId = 1,8 do
		Logic.SetPlayerPaysLeaderFlag(playerId, 0);
	end

	-- village centers shall be removed and replaced by outposts
	SW.EnableOutpostVCs();
	-- outpostcosts increase with number of outposts
	SW.EnableIncreasingOutpostCosts();
	-- Increase exploration range of all player towers
	SW.TowerIncreaseExploration();
	-- Entities move faster
	SW.ApplyMovementspeedBuff();
	-- Buildings cost less & can be build faster | Example | Get-Functions rdy
	--local costTable = {			--Old method, needs full table
		--[ResourceType.Gold] = 0,	--Kept in as list of possible ResourceTypes
		--[ResourceType.Clay] = 0,
		--[ResourceType.Wood] = 0,
		--[ResourceType.Stone] = 0,
		--[ResourceType.Iron] = 0,
		--[ResourceType.Sulfur] = 100
	--};
	local costTable = {			--New method, doesnt need full table
		[ResourceType.Sulfur] = 100
	};
	SW.SetConstructionCosts( Entities.PB_Residence1, costTable)
	SW.SetConstructionTime( Entities.PB_Residence1, 5)
	-- Units cost less
	local costTable_ = {
		[ResourceType.Wood] = 15
	}
	SW.SetRecruitingCosts( Entities.PU_Serf, costTable_)
	-- BURN MF BURN
	--ExpandingFire:Init{ErrLvl = 0, AffectedPlayers = {1,2,3,4,5,6}}
	--local _, hqId = Logic.GetPlayerEntities( 1, Entities.PB_Headquarters1, 1)
	--ExpandingFire:IgniteBuilding(hqId)
	-- FICK LEIBIS
	local allSerfs = ExpandingFire:GetAllEntitiesOfPlayerOfType( 1, Entities.PU_Serf)
	for i = 5, table.getn(allSerfs) do
		DestroyEntity(allSerfs[i])
	end
	-- Genetische Dispositionen für alle! :D
	SW.EnableGeneticDisposition()
	-- Dying entities leaves remains
	SW.EnableMortalRemains()
	-- Recruiting costs for one weapon stay the same for all levels
	SW.UnifyRecruitingCosts()
	-- Jeder mag Plünderer :D
	SW.EnablePillage() --TODO
	-- Random StartPos
	SW.EnableRandomStart()]]
end

function SW.EnableOutpostVCs()
	-- load in archive while developing *-* --
	S5Hook.AddArchive("extra2/shr/maps/user/scripts/archive.bba");
	S5Hook.ReloadEntities();
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

function SW.TowerIncreaseExploration()
	local range = 75 --range in settler meters
	local towerTypes = {
		Entities.PB_Tower1,
		Entities.PB_Tower2,
		Entities.PB_Tower3
	}
	for k,v in pairs( towerTypes) do
		SW.SetExploration( v, range)
	end
end

--Update zu der Geschwindigkeitsgeschichte:   	Movementspeed einer Entity - Easy
--						Movementspeed für einen Typ - Noch nichts gefunden
--[[List of EntityCategories, useful for Speedbuff?Or Buff by Type?
Bow
Cannon
CavalryHeavy
CavalryLight
Hero
LongRange
Melee
Military
Rifle
Scout
Serf
Spear
Sword
Thief
Worker
]]
SW.MovementspeedTechInfluence = { --Balancechanges here!
		["T_BetterChassis"] = {
			Influenced = {EntityCategories.Cannon},
			SumPreFactor = 0,
			Factor = 1.0,
			SumPostFactor = 30
		},
		["T_BetterTrainingArchery"]= {
			Influenced = {EntityCategories.Bow, EntityCategories.Rifle},
			SumPreFactor = 0,
			Factor = 1.0,
			SumPostFactor = 40
		},
		["T_BetterTrainingBarracks"]= {
			Influenced = {EntityCategories.Melee},
			SumPreFactor = 0,
			Factor = 1.0,
			SumPostFactor = 30
		},
		["T_Shoeing"]= {
			Influenced = {EntityCategories.CavalryHeavy, EntityCategories.CavalryLight},
			SumPreFactor = 0,
			Factor = 1.0,
			SumPostFactor = 50
		},
		["T_Shoes"]= {
			Influenced = {EntityCategories.Serf, EntityCategories.Worker},
			SumPreFactor = 20,
			Factor = 1.0,
			SumPostFactor = 0
		},
		["T_SuperTechnology"]= {
			Influenced = {EntityCategories.Sword},
			SumPreFactor = 10,
			Factor = 5.0,
			SumPostFactor = 50
		}
	}
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
	local baseMS = { --Sets BaseMS by EntityCategory; Highest Value wins
		[EntityCategories.Bow] = 320,
		[EntityCategories.Cannon] = 180,  --Values for cannons: 240, 260, 220, 180
		[EntityCategories.CavalryHeavy] =  440,
		[EntityCategories.CavalryLight] = 480,
		[EntityCategories.Hero] = 400,
		[EntityCategories.Rifle] = 320,
		[EntityCategories.Scout] = 350,
		[EntityCategories.Serf]  = 400,
		[EntityCategories.Spear] = 360,
		[EntityCategories.Sword] = 360,
		[EntityCategories.Thief] = 400,
		[EntityCategories.Worker] = 320
	}
	local myBaseMS = 100
	for k,v in pairs( baseMS) do --Get highest possible baseMS
		if Logic.IsEntityTypeInCategory(_eType, k) == 1 then
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
				if Logic.IsEntityTypeInCategory( _eType, v2) == 1 then
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
	--[[local factors = { --Basic Factors		--Kept in as list of useful categories
		[EntityCategories.Bow] = 1.2,
		[EntityCategories.Cannon] = 2,
		[EntityCategories.CavalryHeavy] =  1.1,
		[EntityCategories.CavalryLight] = 2.5,
		[EntityCategories.Hero] = 1.5,
		[EntityCategories.LongRange] = 1.3,
		[EntityCategories.Melee] = 1.5,
		[EntityCategories.Military] = 1.05,
		[EntityCategories.Rifle] = 1.0,
		[EntityCategories.Scout] = 2,
		[EntityCategories.Serf]  = 3,
		[EntityCategories.Spear] = 1.5,
		[EntityCategories.Sword] = 1.0,
		[EntityCategories.Thief] = 1.6,
		[EntityCategories.Worker] = 4
	}
	local factor = 1
	for k,v in pairs(factors) do
		if Logic.IsEntityTypeInCategory(_eType, k) == 1 then
			factor = factor * v
		end
	end
	return factor]]
end
function SW.ApplyMovementspeedBuff() --TODO: Problem mit erforschten Technologien?
	--SW.SetMovementspeed( _eId, _ms)
	--SW.GetMovementspeed( _eId)
	--SW.GetMSByTypeAndPlayer( _eType, _player)
	--SW.GetAllEntitiesOfType( _eType)
	--SW.GetAllEntitiesOfTypeAndPlayer( _eType, _player)
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

--HelperFunc: Get number of current outposts( finished & in construction)
function SW.GetNumberOfOutpostsOfPlayer( _player)
	local x = 0;
	for eID in S5Hook.EntityIterator(Predicate.OfPlayer(_player), Predicate.OfType(Entities.PB_Outpost1)) do
		x=x+1;
	end
	return x;
end
--HelperFunc: Get cost of next outpost for player
--optional: _modifier, reduces num of outposts used in calculation
function SW.GetCostOfNextOutpost( _player, _modifier)
	local baseCosts = {
		[ResourceType.Gold] = 500,
		[ResourceType.Wood] = 400,
		[ResourceType.Clay] = 0,
		[ResourceType.Silver] = 0,		
		[ResourceType.Stone] = 700,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	};
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
function SW.GetCostFactorByNumOfOutposts(x)
	if x == 0 then return 0; end
	return 25/(math.exp(-x+6) + 1)
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
SW.MortalRemainsTable = {
	-- EntityKey, offX, offY
	{"XD_Tomb5", 0, 0},
	{"XD_NephilimFlower", 0, -200},
	{"XD_PlantNorth7", 0, -100},
	{"XD_PlantDecal3", 0, -200},
	{"XD_PlantDecal3", 30, -120},
}
function SW_OnEntityDestroyedMR() --TODO: Füge ein, Rotation! Random! Jetzt!
	local eId = Event.GetEntityID()
	local pos = GetPosition( eId)
	if not SW.IsInCombatMR( eId) then --Kein Kampf? Kein GRAB!
		return
	end
	for k,v in pairs(SW.MortalRemainsTable) do
		local myEId = Logic.CreateEntity( Entities.XD_Rock1, pos.X + v[2], pos.Y + v[3], 0, 0)
		Logic.SetModelAndAnimSet( myEId, Models[v[1]])
		table.insert( SW.MortalRemainsRocks, myEId)
	end
	if table.getn(SW.MortalRemainsRocks) > 1000 then
		for i = 1, 50 do
			DestroyEntity( SW.MortalRemainsRocks[1])
			table.remove( SW.MortalRemainsRocks, 1)
		end
	end
end
function SW_JobMR()
	for i = table.getn(SW.MortalRemainsRecentlyHurt), 1, -1 do
		SW.MortalRemainsRecentlyHurt[i].time = SW.MortalRemainsRecentlyHurt[i].time - 1
		if SW.MortalRemainsRecentlyHurt[i].time < 0 then
			table.remove( SW.MortalRemainsRecentlyHurt, i)
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
	local newCostsA = { --New costs for first half of tech tree
		["PU_LeaderBow"] = {
			[ResourceType.Gold] = 150,
			[ResourceType.Wood] = 60,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderCavalry"] = {
			[ResourceType.Gold] = 200,
			[ResourceType.Wood] = 60,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderHeavyCavalry"] = {
			[ResourceType.Gold] = 250,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 80,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderPoleArm"] = {
			[ResourceType.Gold] = 80,
			[ResourceType.Wood] = 50,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderRifle"] = {
			[ResourceType.Gold] = 250,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 70
		},
		["PU_LeaderSword"] = {
			[ResourceType.Gold] = 100,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 50,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierBow"] = {
			[ResourceType.Gold] = 30,
			[ResourceType.Wood] = 30,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierCavalry"] = {
			[ResourceType.Gold] = 80,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 30,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierHeavyCavalry"] = {
			[ResourceType.Gold] = 120,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 40,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierPoleArm"] = {
			[ResourceType.Gold] = 30,
			[ResourceType.Wood] = 20,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierRifle"] = {
			[ResourceType.Gold] = 50,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 40
		},
		["PU_SoldierSword"] = {
			[ResourceType.Gold] = 30,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 20,
			[ResourceType.Sulfur] = 0
		}
	}
	local newCostsB = { --New costs for second half of tech tree
		["PU_LeaderBow"] = {
			[ResourceType.Gold] = 250,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 70,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderCavalry"] = {
			[ResourceType.Gold] = 250,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 70,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderHeavyCavalry"] = {
			[ResourceType.Gold] = 350,
			[ResourceType.Wood] = 90,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderPoleArm"] = {
			[ResourceType.Gold] = 160,
			[ResourceType.Wood] = 70,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_LeaderRifle"] = {
			[ResourceType.Gold] = 300,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 80
		},
		["PU_LeaderSword"] = {
			[ResourceType.Gold] = 200,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 70,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierBow"] = {
			[ResourceType.Gold] = 50,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 40,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierCavalry"] = {
			[ResourceType.Gold] = 100,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 40,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierHeavyCavalry"] = {
			[ResourceType.Gold] = 150,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 50,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierPoleArm"] = {
			[ResourceType.Gold] = 50,
			[ResourceType.Wood] = 40,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0
		},
		["PU_SoldierRifle"] = {
			[ResourceType.Gold] = 60,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 50
		},
		["PU_SoldierSword"] = {
			[ResourceType.Gold] = 50,
			[ResourceType.Wood] = 0,
			[ResourceType.Iron] = 40,
			[ResourceType.Sulfur] = 0
		}
	}
	local techTreeSize = {}
	for k1,v1 in pairs(newCostsB) do
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
			SW.SetRecruitingCosts( Entities[k1..i], newCostsA[k1])
		end
		for i = math.floor(v1/2+1), v1 do
			SW.SetRecruitingCosts( Entities[k1..i], newCostsB[k1])
		end
	end
end

function SW.EnablePillage() --TODO: Sollte jemand skripten

end

function SW.EnableRandomStart() --TODO
	for i = 1, 4 do
		SW.RandomPosForPlayer( i)
	end
end
function SW.RandomPosForPlayer( _player)
	local success = false
	--[[
	local positions = {
		{ X = 4000, Y = 18000 };
		{ Y = 22000, Y = 6000 };
	};
	local _, _, sec1 = S5Hook.GetTerrainInfo( 4000, 18000);
	local _, _, sec2 = S5Hook.GetTerrainInfo( 22000, 6000);
	while not success do
		local worldSize = Logic.WorldGetSize()
		local ranX = math.random()*worldSize
		local ranY = math.random()*worldSize
		local _, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY);
		local valid = fa
		for j = 1, table.getn(positions) do
			if positions[i]
		end
		if sectorID == sec1 or sectorID == sec2 then
			success = true
			for i = 1, 8 do
				Logic.CreateEntity( Entities.PU_Serf, ranX, ranY, 0, _player)
			end
		end 
	end]]
end
