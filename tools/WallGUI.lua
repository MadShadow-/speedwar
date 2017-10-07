SW = SW or {};
SW.WallGUI = SW.WallGUI or {};
SW.WallGUI.WallType = "";
SW.WallGUI.LatestWallType = "";
SW.WallGUI.LatestEntity = 0;
SW.WallGUI.DummyPlaced = false;
SW.WallGUI.LatestGUIState = 0;
SW.WallGUI.ModelChanged = false;
SW.WallGUI.DummysInConstruction = {};
SW.WallGUI.Costs =
{
	["Wall"] = {
		[4] = 50,
	},
	["Gate"] = {
		[4] = 75,
	},
	["EndWall"] = {
		[3] = 100,
		[4] = 50,
	},
	["Windmill"] = {
		[1] = 200,
		[5] = 100,
	},
}

SW.WallGUI.ScriptNameCounter = 0;
SW.WallGUI.ScriptNames = {
	["Wall"] = "SWWall",
	["EndWall"] = "SWWall",
	["Gate"] = "SWGate",
	["Windmill"] = "SWWindmill"
}

SW.WallGUI.Models = {
	["Wall"] = Models.XD_WallStraight,
	["EndWall"] = Models.XD_WallDistorted,
	["Gate"] = Models.XD_WallStraightGate,
	["Windmill"] = Models.PB_Beautification12,
};

SW.WallGUI.ReplaceEntities = {
	["Wall"] = Entities.XD_WallStraight,
	["EndWall"] = Entities.XD_WallDistorted,
	["Gate"] = Entities.XD_WallStraightGate,
	["Windmill"] = Entities.PB_Beautification12,
};

SW.WallGUI.WallConstructionTooltips = {
	{
		"Mauer",
		"Wehrpflicht",
		"Erbauen eines einfachen Mauerfragments",
		"Ein Mauerstück mit dem ihr eine Basismauer errichten könnt. Die einzelnen Stücke verbinden sich automatisch."
	},
	{
		"Abschlussmauer",
		"Stehendes Heer",
		"Erbau einer Abschlussmauer",
		"Schließt Breschen in der Mauer und kann benutzt werden, um die Mauer in die selbe Richtung fortzusetzen."
	},
	{
		"Tor",
		"Taktiken",
		"Erbau von Toren",
		"Ein Tor das sich nach belieben öffnen und schließen lässt."
	},
};

SW.WallGUI.RequiredTechnologies = {
	["Wall"] = Technologies.GT_Mercenaries,
	["EndWall"] = Technologies.GT_StandingArmy,
	["Gate"] = Technologies.GT_Tactics,
	["Windmill"] = Technologies.GT_Strategies,
};

function SW.WallGUI.Init()
	SW.WallGUI.Tooltips = {
		["Wall"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[1])),
		["EndWall"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[2])),
		["Gate"] = SW.WallGUI.CreateTooltip(unpack(SW.WallGUI.WallConstructionTooltips[3])),
		["Windmill"] = {
				[2] = XGUIEng.GetStringTableText("MenuSerf/Beautification12_disabled"),
				[4] = XGUIEng.GetStringTableText("MenuSerf/Beautification12_normal")
			},
	};
	SW.WallGUI.GameCallback_GUI_StateChanged = GameCallback_GUI_StateChanged;
	function GameCallback_GUI_StateChanged( _StateNameID, _Armed )
		if SW.WallGUI.DummyPlaced then
			Sync.Call("SW.WallGUI.AddWallInConstructionToQueue", SW.WallGUI.LatestEntity, SW.WallGUI.LatestWallType);
			SW.WallGUI.DummyPlaced = false;
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

	SW.WallGUI.CancelState = GUI.CancelState;
	GUI.CancelState = function()
		if SW.WallGUI.LatestGUIState == gvGUI_StateID.PlaceBuilding then
			SW.WallGUI.LatestWallType = SW.WallGUI.WallType;
			SW.WallGUI.WallType = "";
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
		SW.WallGUI.GameCallback_GUI_SelectionChanged();
		if type == Entities.PU_Serf then
			XGUIEng.ShowWidget("SWBottomOverlay", 1);
			XGUIEng.ShowWidget("Build_Village",0);
		elseif XGUIEng.IsWidgetShown("SWBottomOverlay") == 1 or XGUIEng.IsWidgetShown("SWBottomOverlayBeautification") == 1 then
			XGUIEng.ShowWidget("SWBottomOverlay",0);
			XGUIEng.ShowWidget("SWBottomOverlayBeautification",0);
		end
	end
	
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, "", "SW_WallGUI_OnEntityDestroyed", 1);
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, "", "SW_WallGUI_OnEntityCreated", 1);
end

function SW.WallGUI.GUIAction_PlaceBuilding(_wall)
	local widgetId = XGUIEng.GetCurrentWidgetID();
	XGUIEng.UnHighLightGroup( gvGUI_WidgetID.InGame, "BuildingGroup" );
	if SW.WallGUI.HasPlayerEnoughResources_Feedback( SW.WallGUI.Costs[_wall] ) then
		SW.WallGUI.WallType = _wall;
		XGUIEng.HighLightButton( widgetId, 1 );
		SW.WallGUI.EntityType_SetDisplayModel(Entities.PB_Beautification12, SW.WallGUI.Models[_wall]);
		SW.WallGUI.ModelChanged = true;
		GUI.ActivatePlaceBuildingState( UpgradeCategories.Beautification12 );
	end
end

function SW.WallGUI.UpdateTooltip(_wall)
	local widgetId = XGUIEng.GetCurrentWidgetID();
	local playerId = GUI.GetPlayerID();
	local costs = " ";
	local tooltip = " ";
	
	if XGUIEng.IsButtonDisabled(widgetId) == 1 then
		tooltip = SW.WallGUI.Tooltips[_wall][2];
	else
		tooltip = SW.WallGUI.Tooltips[_wall][4];
	end
	
	if Logic.GetTechnologyState( playerId, SW.WallGUI.RequiredTechnologies[_wall] ) == 0 then
		tooltip =  "MenuGeneric/BuildingNotAvailable";
		XGUIEng.SetTextKeyName(gvGUI_WidgetID.TooltipBottomText, tooltip);
		return;
	else
		costs = SW.WallGUI.CreateCostString( SW.WallGUI.Costs[_wall] );
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
		if Logic.GetEntityType(entityId) ~= Entities.PB_Beautification12 then
			return;
		end
		
		-- placed by player?
		if Logic.IsConstructionComplete(entityId) == 1 then
			-- instantly created -> build by script?
			return;
		end
		
		-- yeah it was - reset the model in case it was changed
		if SW.WallGUI.ModelChanged then
			SW.WallGUI.EntityType_SetDisplayModel(Entities.PB_Beautification12, SW.WallGUI.Models["Windmill"]);
		end
		
		SW.WallGUI.DummysInConstruction[entityId] = 0;

		-- determine the building type
		if SW.WallGUI.LatestWallType == "" then 
			Message("Walls: no type found!");
			return; 
		end
		SW.WallGUI.LatestEntity = entityId;
		SW.WallGUI.DummyPlaced = true;
end

function SW.WallGUI.AddWallInConstructionToQueue( _entityId, _wall)
	if not IsAlive(_entityId) then
		return;
	end
	local pos = GetPosition(_entityId);
	SW.WallGUI.DummysInConstruction[tostring(pos.X)..tostring(pos.Y)] = {_entityId, _wall};
	Logic.SetModelAndAnimSet(_entityId, SW.WallGUI.Models[_wall]);
	SW.WallGUI.ScriptNameCounter = SW.WallGUI.ScriptNameCounter + 1;
	SetEntityName(_entityId, SW.WallGUI.ScriptNames[_wall] .. SW.WallGUI.ScriptNameCounter);
end

function SW_WallGUI_OnEntityDestroyed()
		local entityId = Event.GetEntityID();
		-- wurde ein baugerüst für unseren dummy zerstört?
		if Logic.GetEntityType(entityId) ~= 583 then
			return;
		end
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
		local player = GetPlayer(relatedBuilding[1]);
		if SW.WallGUI.ReplaceEntities[ relatedBuilding[2] ] == Entities.PB_Beautification12 then
			--> a simple windwall
			return;
		else
			--> a wall part, so destroy our dummy
			DestroyEntity( relatedBuilding[1] );
		end
		SW.WallGUI.CreateWall(SW.WallGUI.ReplaceEntities[ relatedBuilding[2] ], pos, player);
end

function SW.WallGUI.CreateWall(_entityType, _position, _playerId)
	-- not part of the GUI anymore
	-- this is the logic part
	-- to be continued by napo
	
	--NOW IS NAPO TIME
	--FEAR ME
	local dummyId = Logic.CreateEntity( Entities.XD_ScriptEntity, _position.X, _position.Y, 0, _playerId)
	if _entityType == Entities.XD_WallStraight then
		SW.Walls.PlaceNormalWall( dummyId)
	elseif _entityType == Entities.XD_WallStraightGate then
		SW.Walls.PlaceGate( dummyId)
	elseif _entityType == Entities.XD_WallDistorted then
		SW.Walls.PlaceClosingWall( dummyId)
	elseif _entityType == Entities.PB_Beautification10 then
		SW.Walls.PlaceRepairElement( dummyId)
	end
	--Logic.CreateEntity(_entityType, _position.X, _position.Y, 0, _playerId);
end

function SW.WallGUI.EntityType_SetDisplayModel(_entityType, _model)
	S5Hook.GetRawMem(9002416)[0][16][_entityType * 8 + 3][2]:SetInt(_model)
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