SW = SW or {};
SW.WallGUI = SW.WallGUI or {};
SW.WallGUI.WallType = "";
SW.WallGUI.StartNewWall = false;
SW.WallGUI.LatestWallType = "";
SW.WallGUI.LatestEntity = 0;
SW.WallGUI.DummyPlaced = false;
SW.WallGUI.LatestGUIState = 0;
SW.WallGUI.ModelChanged = false;
SW.WallGUI.DummysInConstruction = {};
SW.WallGUI.SelectedWallDestroyed = false;
SW.WallGUI.ScriptNameBuildingCounter = 0;
-- 
SW.WallGUI.PlayerLocal_WallQueue = {};
SW.WallGUI.Costs =
{
	["Wall"] = {
		[4] = 30,
	},
	["Gate"] = {
		[4] = 50,
	},
	["EndWall"] = {
		[4] = 30,
	},
	["NewWall"] = {
		[4] = 30,
	},
	["Windmill"] = {
		[1] = 200,
		[5] = 100,
	},
	["Blacksmith"] = {
		[2] = 200,
		[4] = 200,
	},
	["Bastille"] = {
		[2] = 400,
		[3] = 400,
		[4] = 500,
	},
}

SW.WallGUI.ScriptNameCounter = 0;
SW.WallGUI.ScriptNames = {
	["Wall"] = "XXSWWall",
	["EndWall"] = "XXSWWall",
	["Gate"] = "XXSWGate",
	["NewWall"] = "XXSWNewWall",
	["Windmill"] = "XXSWWindmill",
	["Blacksmith"] = "XXSWBlacksmith",
	["Bastille"] = "XXSWBastille",
}

SW.WallGUI.DummyEntities = {
	["Wall"] = Entities.PB_Beautification12,
	["EndWall"] = Entities.PB_Beautification12,
	["Gate"] = Entities.PB_Beautification12,
	["NewWall"] = Entities.PB_Beautification12,
	["Windmill"] = Entities.PB_Beautification12,
	["Blacksmith"] = Entities.PB_Blacksmith1,
	["Bastille"] = Entities.PB_Blacksmith1,
}

SW.WallGUI.DummyModels = {
	["Wall"] = Models.PB_Beautification12,
	["EndWall"] = Models.PB_Beautification12,
	["Gate"] = Models.PB_Beautification12,
	["NewWall"] = Models.PB_Beautification12,
	["Windmill"] = Models.PB_Beautification12,
	["Blacksmith"] = Models.PB_Blacksmith1,
	["Bastille"] = Models.PB_Blacksmith1,
}

SW.WallGUI.DummyUpgradeCategory = {
	["Wall"] = UpgradeCategories.Beautification12,
	["EndWall"] = UpgradeCategories.Beautification12,
	["Gate"] = UpgradeCategories.Beautification12,
	["NewWall"] = UpgradeCategories.Beautification12,
	["Windmill"] = UpgradeCategories.Beautification12,
	["Blacksmith"] = UpgradeCategories.Blacksmith,
	["Bastille"] = UpgradeCategories.Blacksmith,
}

SW.WallGUI.ShortCuts = { -- not enabled yet
	["Wall"] = "Q",
	["EndWall"] = "Ö",
	["Gate"] = "F",
	["Windmill"] = "",
	["Blacksmith"] = "C",
	["Bastille"] = "",
};

SW.WallGUI.SelectionNames =
{
	["Wall"] = "Mauer",
	["EndW"] = "Mauer",
	["Gate"] = "Tor",
	["NewW"] = "Mauer",
	["Wind"] = "Windrad",
	["Blac"] = "Schmiede",
	["Bast"] = "Standhafter Turm",
}

SW.WallGUI.CustomNames =
{
	["Wall"] = "Mauer",
	["EndWall"] = "Mauer",
	["Gate"] = "Tor",
	["NewWall"] = "Mauer",
	["Windmill"] = "Windrad",
	["Blacksmith"] = "Schmiede",
	["Bastille"] = "Standhafter Turm",
}

SW.WallGUI.Models = {
	["Wall"] = Models.XD_WallStraight,
	["EndWall"] = Models.XD_WallDistorted,
	["Gate"] = Models.XD_WallStraightGate,
	["NewWall"] = Models.XD_WallStraight,
	["Windmill"] = Models.PB_Beautification12,
	["Blacksmith"] = Models.PB_Blacksmith1,
	["Bastille"] = Models.CB_Bastille1,
};

SW.WallGUI.ReplaceEntities = {
	["Wall"] = Entities.XD_WallStraight,
	["EndWall"] = Entities.XD_WallDistorted,
	["Gate"] = Entities.XD_WallStraightGate,
	["NewWall"] = Entities.XD_WallStraight,
	["Windmill"] = Entities.PB_Beautification12,
	["Blacksmith"] = Entities.PB_Blacksmith1,
	["Bastille"] = Entities.CB_Bastille1,
};

SW.WallGUI.WallConstructionTooltips = {
	{
		"Mauer",
		"Konstruktion",
		"Ein Mauerfragment zum Errichten einer Mauer.",
		"Baut eine Mauer indem ihr mehrere Mauerfragmente nebeneinander errichtet"
	},
	{
		"Abschlussmauer",
		"Konstruktion",
		"Erbau einer Abschlussmauer",
		"Schließt Breschen in der Mauer und kann benutzt werden, um die Mauer in die selbe Richtung fortzusetzen."
	},
	{
		"Tor",
		"Konstruktion",
		"Erbau von Toren",
		"Ein Tor das sich nach belieben öffnen und schließen lässt."
	},
	{
		"Standhafter Turm",
		"Rang: " .. SW.BuildingTooltips.RankNames[2],
		"Ermöglicht das Bauen standhafter Türme in denen sich Militäreinheiten stationieren lassen.",
		"In diesem Turm könnt ihr Einheiten stationieren."
	},
	{
		"Startmauer",
		"Konstruktion",
		"Verwendet dieses Mauerstück um eine neue Mauer zu starten.",
		"Diese Startmauer verbindet sich nicht automatisch mit einer in der Nähe befindlichen Mauer."
	},
};

function SW.WallGUI.Init()

	-- prepare GUI
	XGUIEng.DisableButton("SWBuildWall",1);
	XGUIEng.DisableButton("SWBuildEndWall",1);
	XGUIEng.DisableButton("SWBuildGate",1);
	XGUIEng.DisableButton("SWBuildBlacksmith",1);
	XGUIEng.DisableButton("SWBuildBastille",1);
	XGUIEng.ShowWidget("SWBuildNewWall", 0);
	
	SW.WallGUI.Tooltips = {
		["Wall"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[1])),
		["EndWall"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[2])),
		["Gate"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[3])),
		["NewWall"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[5])),
		["Windmill"] = {
				[2] = XGUIEng.GetStringTableText("MenuSerf/Beautification12_disabled"),
				[4] = XGUIEng.GetStringTableText("MenuSerf/Beautification12_normal")
			},
		["Blacksmith"] = {
				[2] = XGUIEng.GetStringTableText("MenuSerf/Blacksmith_disabled"),
				[4] = XGUIEng.GetStringTableText("MenuSerf/Blacksmith_normal")
			},
		["Bastille"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[4])),
	};
	SW.WallGUI.GameCallback_GUI_StateChanged = GameCallback_GUI_StateChanged;
	GameCallback_GUI_StateChanged = function( _StateNameID, _Armed )
		if SW.WallGUI.DummyPlaced then
			-- now with a list
			--Sync.Call("SW.WallGUI.PayCosts", GUI.GetPlayerID(), SW.WallGUI.Costs[SW.WallGUI.LatestWallType]);
			--Sync.Call("SW.WallGUI.AddWallInConstructionToQueue", SW.WallGUI.LatestEntity, SW.WallGUI.LatestWallType, SW.WallGUI.LatestWallNewWall);
			local wallInfo;
			for i = 1, table.getn(SW.WallGUI.PlayerLocal_WallQueue) do
				wallInfo = SW.WallGUI.PlayerLocal_WallQueue[i];
				--Sync.Call("SW.WallGUI.PayCosts", GUI.GetPlayerID(), wallInfo[2]);
				-- call PayCosts in AddWallInConstructionToQueue
				Sync.Call("SW.WallGUI.AddWallInConstructionToQueue", wallInfo[1], wallInfo[2], wallInfo[3]);
			end
			SW.PreciseLog.Log("Sending "..SW.WallGUI.LatestWallType.." with "..tostring(SW.WallGUI.LatestWallNewWall), "WallGUI")
			SW.WallGUI.DummyPlaced = false;
			SW.WallGUI.PlayerLocal_WallQueue = {};
		end
		if _StateNameID ~= 1 and _StateNameID ~= 2 then
			SW.WallGUI.LatestGUIState = _StateNameID;
		end
		SW.WallGUI.GameCallback_GUI_StateChanged( _StateNameID, _Armed )
		if _StateNameID == gvGUI_StateID.PlaceBuilding then
			if SW.WallGUI.WallType == "" then
				return;
			end
			if not SW.WallGUI.HasPlayerEnoughResources( SW.WallGUI.Costs[SW.WallGUI.WallType] ) then
				GUI.CancelState();
			end
		end
	end
	
	-- TODO: Currently hardcoded, should somehow end up in a config table
	SW.WallGUI.GameCallback_OnTechnologyResearched = GameCallback_OnTechnologyResearched;
	GameCallback_OnTechnologyResearched = function( _playerId , _technologyType)
		SW.WallGUI.GameCallback_OnTechnologyResearched(_playerId, _technologyType)
		if _playerId ~= GUI.GetPlayerID() then
			return;
		end
		if _technologyType == Technologies.GT_Construction then
			XGUIEng.DisableButton("SWBuildWall", 0);
			XGUIEng.DisableButton("SWBuildEndWall", 0);
			XGUIEng.DisableButton("SWBuildGate", 0);
			XGUIEng.DisableButton("SWBuildNewWall", 0);
		elseif _technologyType == Technologies.GT_Alchemy then
			XGUIEng.DisableButton("SWBuildBlacksmith", 0);
		end
	end

	SW.WallGUI.CancelState = GUI.CancelState;
	GUI.CancelState = function()
		if SW.WallGUI.LatestGUIState == gvGUI_StateID.PlaceBuilding then
			SW.WallGUI.LatestWallType = SW.WallGUI.WallType;
			SW.WallGUI.LatestWallNewWall = SW.WallGUI.StartNewWall;
			SW.WallGUI.WallType = "";
			SW.WallGUI.StartNewWall = false;
			if SW.WallGUI.ModelChanged and SW.WallGUI.LatestWallType ~= "" then
				SW.WallGUI.EntityType_SetDisplayModel(SW.WallGUI.DummyEntities[SW.WallGUI.LatestWallType], SW.WallGUI.DummyModels[SW.WallGUI.LatestWallType]);
			end
		end
		SW.WallGUI.CancelState();
	end

	SW.WallGUI.GUIAction_ToggleSerfMenu = GUIAction_ToggleSerfMenu
	GUIAction_ToggleSerfMenu = function( _widgetId, _x)
		SW.WallGUI.GUIAction_ToggleSerfMenu(_widgetId, _x);
		if _widgetId == gvGUI_WidgetID.SerfBeautificationMenu then
			XGUIEng.ShowWidget("SWBottomOverlay",0);
			XGUIEng.ShowWidget("SWBottomOverlayBeautification",1);
			XGUIEng.ShowWidget("Build_Beautification12",0);
		elseif _widgetId == gvGUI_WidgetID.SerfConstructionMenu then
			XGUIEng.ShowWidget("SWBottomOverlay",1);
			XGUIEng.ShowWidget("SWBottomOverlayBeautification",0);
			XGUIEng.ShowWidget("Build_Village",0);
		end
	end
	
	SW.WallGUI.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged;
	GameCallback_GUI_SelectionChanged = function()
		local entityId = GUI.GetSelectedEntity();
		local type = Logic.GetEntityType(entityId);
		local ename = Logic.GetEntityName(entityId) or "";
		if string.find(ename, "XXSW", 1, true) then
			SW.WallGUI.NameOfCurrentlySelectedBuilding = SW.WallGUI.SelectionNames[string.sub(ename,5,8)];
		else
			SW.WallGUI.NameOfCurrentlySelectedBuilding = nil;
		end
		SW.WallGUI.GameCallback_GUI_SelectionChanged();
		if type == Entities.PU_Serf then
			XGUIEng.ShowWidget("SWBottomOverlayBeautification",0);
			XGUIEng.ShowWidget("SWBottomOverlay", 1);
			XGUIEng.ShowWidget("Build_Village",0);
			XGUIEng.ShowWidget("Build_Blacksmith",0);
		elseif XGUIEng.IsWidgetShown("SWBottomOverlay") == 1 or XGUIEng.IsWidgetShown("SWBottomOverlayBeautification") == 1 then
			XGUIEng.ShowWidget("SWBottomOverlay",0);
			XGUIEng.ShowWidget("SWBottomOverlayBeautification",0);
		end
	end
	
	SW.WallGUI.GUIUpdate_SelectionName = GUIUpdate_SelectionName;
	GUIUpdate_SelectionName = function()
		if SW.WallGUI.NameOfCurrentlySelectedBuilding ~= nil then
			XGUIEng.SetText("Selection_Name", SW.WallGUI.NameOfCurrentlySelectedBuilding);
			return;
		end
		SW.WallGUI.GUIUpdate_SelectionName();
	end
	
	SW.WallGUI.PostStartEntityCostAndBlockingChanges();
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, "", "SW_WallGUI_OnEntityDestroyed", 1);
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, "", "SW_WallGUI_OnEntityCreated", 1);
end

function SW.WallGUI.GUIAction_PlaceBuilding(_wall)
	local widgetId = XGUIEng.GetCurrentWidgetID();
	XGUIEng.UnHighLightGroup( gvGUI_WidgetID.InGame, "BuildingGroup" );
	if SW.WallGUI.HasPlayerEnoughResources_Feedback( SW.WallGUI.Costs[_wall] ) then
		if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
			SW.WallGUI.StartNewWall = true;
		end
		SW.WallGUI.WallType = _wall;
		XGUIEng.HighLightButton( widgetId, 1 );
		SW.WallGUI.EntityType_SetDisplayModel(SW.WallGUI.DummyEntities[_wall], SW.WallGUI.Models[_wall]);
		SW.WallGUI.ModelChanged = true;
		GUI.ActivatePlaceBuildingState( SW.WallGUI.DummyUpgradeCategory[_wall] );
	end
end

function SW.WallGUI.UpdateTooltip(_wall)
	local widgetId = XGUIEng.GetCurrentWidgetID();
	local playerId = GUI.GetPlayerID();
	local costs = SW.WallGUI.CreateCostString( SW.WallGUI.Costs[_wall] );
	local tooltip = " ";
	
	if XGUIEng.IsButtonDisabled(widgetId) == 1 then
		tooltip = SW.WallGUI.Tooltips[_wall][2];
	else
		tooltip = SW.WallGUI.Tooltips[_wall][4];
	end
	
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, costs);
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, tooltip);
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, " ");
end

function SW_WallGUI_OnEntityCreated()
		local entityId = Event.GetEntityID();
		local playerId = GUI.GetPlayerID();
		-- is this our buisness?
		if playerId ~= GetPlayer(entityId) then
			return;
		end
		
		-- was our dummy placed?
		if Logic.GetEntityType(entityId) ~= SW.WallGUI.DummyEntities[SW.WallGUI.LatestWallType] then
			return;
		end
		
		-- placed by player?
		if Logic.IsConstructionComplete(entityId) == 1 then
			-- instantly created -> build by script?
			return;
		end
		
		-- yeah it was - reset the model in case it was changed
		--if SW.WallGUI.ModelChanged then
		--	SW.WallGUI.EntityType_SetDisplayModel(SW.WallGUI.DummyEntities[SW.WallGUI.LatestWallType], SW.WallGUI.DummyModels[SW.WallGUI.LatestWallType]);
		--end
		
		SW.WallGUI.DummysInConstruction[entityId] = 0;

		-- determine the building type
		if SW.WallGUI.LatestWallType == "" then 
			Message("Walls: no type found!");
			return; 
		end
		--SW.WallGUI.LatestEntity = entityId;
		-- Now we have a list
		SW.WallGUI.PlayerLocal_AddEntityToQueue(entityId)
		SW.WallGUI.DummyPlaced = true;
end

function SW.WallGUI.PlayerLocal_AddEntityToQueue(_entityId)
	table.insert(SW.WallGUI.PlayerLocal_WallQueue, {_entityId, SW.WallGUI.LatestWallType, SW.WallGUI.LatestWallNewWall});
end

function SW.WallGUI.AddWallInConstructionToQueue( _entityId, _wall, _isNewWall)
	SW.PreciseLog.Log("Receiving ".._wall.." with "..tostring(_isNewWall), "WallGUI")
	if not IsAlive(_entityId) then
		return;
	end
	SW.WallGUI.PayCosts( Logic.EntityGetPlayer( _entityId), _wall)
	local pos = GetPosition(_entityId);
	SW.WallGUI.DummysInConstruction[tostring(pos.X)..tostring(pos.Y)] = {_entityId, _wall, _isNewWall};
	Logic.SetModelAndAnimSet(_entityId, SW.WallGUI.Models[_wall]);
	SW.WallGUI.ScriptNameCounter = SW.WallGUI.ScriptNameCounter + 1;
	local scriptname = SW.WallGUI.ScriptNames[_wall] .. SW.WallGUI.ScriptNameCounter;
	SW.CustomNames[scriptname] = SW.WallGUI.CustomNames[_wall];
	SetEntityName(_entityId, scriptname);
end

function SW_WallGUI_OnEntityDestroyed()
		local entityId = Event.GetEntityID();
		-- wurde ein baugerüst für unseren dummy zerstört?
		if Logic.GetEntityType(entityId) ~= 583 and Logic.GetEntityType(entityId) ~= 564 then
			return;
		end
		--LuaDebugger.Break();
		-- handelt es sich um eins unserer gebäude?
		local pos = GetPosition(entityId);
		local relatedBuilding = SW.WallGUI.DummysInConstruction[tostring(pos.X)..tostring(pos.Y)];
		if relatedBuilding == nil then
			return;
		end
		
		if Logic.IsConstructionComplete( relatedBuilding[1] ) == 0 then
			SW.WallGUI.DummysInConstruction[tostring(pos.X)..tostring(pos.Y)] = nil;
			return;
		end
		-- what entity should our dummy be replaced with?
		local player = Logic.EntityGetPlayer(relatedBuilding[1]);
		if player == 0 then
			-- kp was da abgeht, aber hier isch ende
			return;
		end
		if SW.WallGUI.ReplaceEntities[ relatedBuilding[2] ] == Entities.PB_Beautification12
		or SW.WallGUI.ReplaceEntities[ relatedBuilding[2] ] == Entities.PB_Blacksmith1 then
			--> a simple windmill
			return;
		else
			--> a wall part, so destroy our dummy
			-- and remove custom name
			if GUI.GetSelectedEntity() == relatedBuilding[1] then
				SW.WallGUI.SelectedWallDestroyed = true;
			end
			SW.CustomNames[Logic.GetEntityName(relatedBuilding[1])] = nil;
			SW_DestroySafe( relatedBuilding[1] );
		end
		SW.WallGUI.CreateEntity(SW.WallGUI.ReplaceEntities[ relatedBuilding[2] ], pos, player, relatedBuilding[2], relatedBuilding[3]);
end

function SW.WallGUI.CreateEntity(_entityType, _position, _playerId, _wallTypeString, _isNewWall)
	-- not part of the GUI anymore
	-- this is the logic part
	-- to be continued by napo
	-- LuaDebugger.Log(_wallTypeString);
	--NOW IS NAPO TIME
	--FEAR ME
	local newEntityId;
	if _entityType == Entities.CB_Bastille1 then
		newEntityId = Logic.CreateEntity(Entities.CB_Bastille1, _position.X, _position.Y, 0, _playerId);
		SW.WallGUI.ScriptNameBuildingCounter = SW.WallGUI.ScriptNameBuildingCounter + 1;
		local scriptname = "XXSWBastille" .. SW.WallGUI.ScriptNameBuildingCounter; 
		SetEntityName(newEntityId, scriptname);
		SW.CustomNames[scriptname] = SW.WallGUI.CustomNames["Bastille"];
	else
		-- walls
		--local dummyId = Logic.CreateEntity(Entities.XD_ScriptEntity, _position.X, _position.Y, 0, _playerId);
		if _entityType == Entities.XD_WallStraight then
			if not _isNewWall then
				newEntityId = SW.Walls.PlaceNormalWall( _position, _playerId);
			else -- NewWall
				newEntityId = SW.Walls.PlaceStartWall(_position, _playerId);
			end
		elseif _entityType == Entities.XD_WallStraightGate then
			if not _isNewWall then
				newEntityId = SW.Walls.PlaceGate(_position, _playerId);
			else -- New Gate
				newEntityId = SW.Walls.PlaceStartGate(_position, _playerId);
			end
		elseif _entityType == Entities.XD_WallDistorted then
			newEntityId = SW.Walls.PlaceClosingWall(_position, _playerId);
		end
		-- replace surfs
		local newPos = GetPosition(newEntityId);
		local serfs = {Logic.GetPlayerEntitiesInArea(_playerId, Entities.PU_Serf, newPos.X, newPos.Y, 700, 16)};
		local pos, player, serf, selectedUnits;
		if GUI.GetPlayerID() == _playerId then
			selectedUnits = {GUI.GetSelectedEntities()};
			for i = 1, table.getn(selectedUnits) do
				selectedUnits[ selectedUnits[i] ] = true;
			end
		end
		local toSelect = {};
		for i = 1, serfs[1] do
			pos = GetPosition(serfs[i+1]);
			player = GetPlayer(serfs[i+1]);
			if Logic.GetSector(serfs[i+1]) == 0 then
				serf = AI.Entity_CreateFormation(player, Entities.PU_Serf, 0, 0, pos.X, pos.Y, 0, 0, 0, 0)
				if GUI.GetPlayerID() == _playerId then
					if selectedUnits[serfs[i+1] ] then
						table.insert(toSelect, serf);
					end
				end
				DestroyEntity(serfs[i+1]);
			end
		end
		if GUI.GetPlayerID() == _playerId then
			for i = 1, table.getn(toSelect) do
				GUI.SelectEntity(toSelect[i]);
			end
		end
	end
	if newEntityId == nil then return end
	if SW.WallGUI.SelectedWallDestroyed then
		GUI.SelectEntity(newEntityId);
		SW.WallGUI.SelectedWallDestroyed = false;
	end
end

function SW.WallGUI.WallHotKey(_keyIsUp)
	if _keyIsUp then
		return;
	end
	if XGUIEng.IsButtonDisabled("SWBuildWall") == 1 then
		return;
	end
	if Logic.GetEntityType(GUI.GetSelectedEntity()) == Entities.PU_Serf then
		SW.WallGUI.GUIAction_PlaceBuilding("Wall")
	end
end

function SW.WallGUI.EntityType_SetDisplayModel(_entityType, _model)
	--LuaDebugger.Break();
	S5Hook.GetRawMem(9002416)[0][16][_entityType * 8 + 3][2]:SetInt(_model)
end

function SW.WallGUI.EntityType_SetResourceCost(_resourceType, _entityType, _amount)
	local resourceTypes = {
		[1] = 57,
		[2] = 67,
		[3] = 69,
		[4] = 61,
		[5] = 63,
		[6] = 65,
	};
	S5Hook.GetRawMem(9002416)[0][16][_entityType * 8 + 2][resourceTypes[_resourceType]]:SetFloat(_amount);
end

function SW.WallGUI.HasPlayerEnoughResources( _costs )
	local resourcetypes = {
		ResourceType.Gold,
		ResourceType.Clay,
		ResourceType.Wood,
		ResourceType.Stone,
		ResourceType.Iron,
		ResourceType.Sulfur,
	};
	local playerId = GUI.GetPlayerID();
	local res;
	
	for i = 1,6 do
		res = Logic.GetPlayersGlobalResource( playerId, resourcetypes[i] ) + Logic.GetPlayersGlobalResource( playerId, resourcetypes[i] + 1 );
		if _costs[ i ] ~= nil and res < _costs[ i ] then		
			return false;
		end
	end
	
	return true;
end

function SW.WallGUI.HasPlayerEnoughResources_Feedback( _costs )
	
	local resourcetypes = {
		{ ResourceType.Gold, "InGameMessages/GUI_NotEnoughMoney" },
		{ ResourceType.Clay, "InGameMessages/GUI_NotEnoughClay" },
		{ ResourceType.Wood, "InGameMessages/GUI_NotEnoughWood" },
		{ ResourceType.Stone, "InGameMessages/GUI_NotEnoughStone" },
		{ ResourceType.Iron, "InGameMessages/GUI_NotEnoughIron" },
		{ ResourceType.Sulfur, "InGameMessages/GUI_NotEnoughSulfur" },
	};
	local playerId = GUI.GetPlayerID();
	local res;
	local msg = "";
	
	for i = 1,6 do
		res = Logic.GetPlayersGlobalResource( playerId, resourcetypes[i][1] ) + Logic.GetPlayersGlobalResource( playerId, resourcetypes[i][1] + 1 );
		if _costs[ i ] ~= nil and res < _costs[ i ] then		
			msg = string.format(XGUIEng.GetStringTableText( resourcetypes[i][2] ), _costs[ i ] - res );
			GUI.AddNote( msg );
			GUI.SendNotEnoughResourcesFeedbackEvent( resourcetypes[i][1], _costs[ i ] - res );
		end
	end
	
	if msg ~= "" then
		return false;
	else
		return true;
	end

end

function SW.WallGUI.CreateTooltip(_title, _needs, _allows, _content)
		return {
			"Eine neue Technologie wurde erforscht! @cr @cr " .. _title,
			"@color:180,180,180,255 ".._title.." @cr @color:255,204,51,255 benötigt: @color:255,255,255,255 "
			.. _needs .. " @cr @color:255,204,51,255 ermöglicht: @color:255,255,255,255 " .. _allows,
			"@color:180,180,180,255 ".._title.." @cr @color:255,204,51,255 ermöglicht: @color:255,255,255,255 " .. _allows,
			"@color:180,180,180,255 ".._title.." @cr @color:255,255,255,255 " .. _content,	
		};
end

function SW.WallGUI.CreateCostString( _costs )

	local resourcetypes = {
		{ ResourceType.Gold, "InGameMessages/GUI_NameMoney" },
		{ ResourceType.Clay, "InGameMessages/GUI_NameClay" },
		{ ResourceType.Wood, "InGameMessages/GUI_NameWood" },
		{ ResourceType.Stone, "InGameMessages/GUI_NameStone" },
		{ ResourceType.Iron, "InGameMessages/GUI_NameIron" },
		{ ResourceType.Sulfur, "InGameMessages/GUI_NameSulfur" },
	};
	local playerId = GUI.GetPlayerID();
	local costString = "";
	local res;
	for i = 1,6 do
		if _costs[ i ] ~= nil then
			costString = costString .. XGUIEng.GetStringTableText( resourcetypes[i][2] ) .. ": ";
			res = Logic.GetPlayersGlobalResource( playerId, resourcetypes[i][1] ) + Logic.GetPlayersGlobalResource( playerId, resourcetypes[i][1] + 1 );
			if res >= _costs[ i ] then
				costString = costString .. " @color:255,255,255,255 "
			else
				costString = costString .. " @color:220,64,16,255 "
			end
			costString = costString .. _costs[ i ] .. " @color:255,255,255,255 @cr "
		end
	end
	return costString;

end


function SW.WallGUI.PayCosts( _playerId, _costKey)
	local _costs = SW.WallGUI.Costs[_costKey]
	AddGold  ( _playerId, - math.min(GetGold(_playerId),   _costs[1] or 0) );
	AddClay  ( _playerId, - math.min(GetClay(_playerId),   _costs[2] or 0) );
	AddWood  ( _playerId, - math.min(GetWood(_playerId),   _costs[3] or 0) );
	AddStone ( _playerId, - math.min(GetStone(_playerId),  _costs[4] or 0) );
	AddIron  ( _playerId, - math.min(GetIron(_playerId),   _costs[5] or 0) );
	AddSulfur( _playerId, - math.min(GetSulfur(_playerId), _costs[6] or 0) );
end

function SW.WallGUI.PostStartEntityCostAndBlockingChanges()

	function GetXY(mem)
		return { X = mem[0]:GetFloat(), Y = mem[1]:GetFloat() }
	end

	function SetXY(mem, x, y)
		mem[0]:SetFloat(x)
		mem[1]:SetFloat(y)
	end

	function ReadX2O(base)
		local n = 0
		local lst = {}
		
		while true do
			local typ = base[n]:GetInt() --2: direct value, 3: embedded/linked object
			if typ == 0 then break end
			
			local namefield, name = base[n+1]
			if namefield:GetInt() == 0 then
				name = n --unnamed field
			else
				name = namefield:GetString()
			end
			
			local pos = base[n+2]:GetInt()
			local len = base[n+3]:GetInt()
			local subElmDef = base[n+5]
			local listOps = base[n+7]
			
			local entry = { Length = len, RelativePos = pos }
			
			if subElmDef:GetInt() ~= 0 then
				entry.SubData9999 = ReadX2O(subElmDef)
			end
			
			if listOps:GetInt() ~= 0 then
				name = "ListOf__" .. name
			end
			
			lst[name] = entry
			n = n + 9
		end
		
		return lst
	end

	MemList = { __index = function(t,k) return MemList[k] or t:get(k) end }
	function MemList:new(mem, len) --len in bytes
		bp, cp, ep = mem[1], mem[2], mem[3]
		
		-- (+) and (-) is not affected by DX fpu precision settings
		-- and the difference should be small enough to fit 24Bit ;)
		local cnt = math.floor((ep:GetInt() - bp:GetInt())/len) 
		local cap = math.floor((ep:GetInt() - bp:GetInt())/len)
		
		local obj = { Length = cnt, Capacity = cap, list = mem, idxLen = len/4, listStart = bp }
		setmetatable(obj, self)
		return obj
	end

	function MemList:get(n) -- zero based
		if n < self.Length then
			return self.listStart:Offset(n * self.idxLen)
		end
	end

	function MemList:iterate()
		local i, count = -1, self.Length
		return function() 
			i = i + 1
			if i < count then 
				return self:get(i)
			end
		end
	end

	function GetLogicDef(e)
		return S5Hook.GetRawMem(9002416)[0][16][e*8+2]
	end
	
	-- now use all the functions above and do the actual blocking exchange
	local def = GetLogicDef(Entities.PB_Beautification12)
	local baList = MemList:new(def:Offset(136/4), 16)
	for subElm in baList:iterate() do
		local pt1, pt2 = subElm, subElm:Offset(2)
		SetXY(pt2, 1, 1)
		SetXY(pt1, 0, 0)
	end
	
	def = GetLogicDef(Entities.PB_Beautification12)
	local tp1 = def:Offset(152/4)
	local tp2 = def:Offset(160/4)
	SetXY(tp1, 0, 0)
	SetXY(tp2, 10, 10)
	
	local s = Logic.WorldGetSize() / 100 - 1;
	Logic.UpdateBlocking(0, 0, s, s);
	-- update ressource costs
	-- now done with config/SW_BuildingCosts.lua, resets if game is left
	--SW.WallGUI.EntityType_SetResourceCost(1, Entities.PB_Beautification12, 0);
	--SW.WallGUI.EntityType_SetResourceCost(5, Entities.PB_Beautification12, 0);
end