--[[
	Beschreibung der Bastille
	
	Ein sehr stabiles Gebäude(tanky).
	
	Vorschlag 1: Macht Gebäude in der Umgebung tanky bzw unverwundbar, so wie der Outpost??
	Vorschlag 2: Man kann Truppen einladen, für die man dann keinen DZ platz mehr benötigt!
	
	Teueres gebäude?
	
	TODO:
	Beim Tracking gucken ob soldaten sich weiterhin bewegen
]]
SW = SW or {};
SW.Bastille = {};
SW.Bastille.Tracking = {Pending = {}, Tracked = {}, PendingDuration = 10};
SW.Bastille.EnterRange = 1000;
SW.Bastille.MaxTroopsPerResort = 12; -- if you want to change this, GUI has to be changed as well
SW.Bastille.Resorts = {};
SW.Bastille.PlayerLocal_SpawnQueueAttractionLimit = 0; -- attraction limit place holder - local for every player to prevent abusing the attraction limit with the spawn delay

function SW.Bastille.Activate()
	SW.Bastille.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged;
	GameCallback_GUI_SelectionChanged = function()
		local entityId = GUI.GetSelectedEntity();
		local eType = Logic.GetEntityType(entityId);
		
		if XGUIEng.IsWidgetShown("SWBottomOverlayBastille") == 1 then
			XGUIEng.ShowWidget("SWBottomOverlayBastille", 0);
		end
		if XGUIEng.IsWidgetShown("SWBottomOverlayLeader") == 1 then
			XGUIEng.ShowWidget("SWBottomOverlayLeader", 0);
		end
		if eType == Entities.CB_Bastille1 then
			XGUIEng.ShowWidget("SWBottomOverlayBastille", 1);
		elseif Logic.IsLeader(entityId) == 1 then
			--XGUIEng.ShowWidget("SWBottomOverlayLeader", 1);
		end
		SW.Bastille.GameCallback_GUI_SelectionChanged();
	end
	
	SW.Bastille.LatestGUIState = 0;
	
	SW.Bastille.GameCallback_GUI_StateChanged = GameCallback_GUI_StateChanged;
	GameCallback_GUI_StateChanged = function( _StateNameID, _Armed )
		if _StateNameID == 8 then
			SW.Bastille.LatestGUIState = 8;
		elseif SW.Bastille.LatestGUIState == 8 then
			SW.Bastille.LatestGUIState = 0;
			-- GUI state changed back
			-- check selected units, are they guarding
			local x,y = GUI.Debug_GetMapPositionUnderMouse();
			x = math.floor(x);
			y = math.floor(y);
			local bastilles = {Logic.GetPlayerEntitiesInArea(GUI.GetPlayerID(), Entities.CB_Bastille1, x, y, 1000, 16)};
			if bastilles[1] > 0 then
				-- find bastille closest to mouse click
				local closestD, closestB, pos, currentD = 1000000000;
				for i = 2, bastilles[1]+1 do
					pos = GetPosition(bastilles[i])
					currentD = ((pos.X-x)^2 + (pos.Y-y)^2);
					if currentD < closestD then
						closestD = currentD;
						currentB = bastilles[i];
					end
				end
				
				local selected = {GUI.GetSelectedEntities()};
				local leaders = {};
				for i = 1,table.getn(selected) do
					if Logic.IsLeader(selected[i]) == 1 then 
						table.insert(leaders,selected[i]);
					end
				end
				Sync.Call("SW.Bastille.TrackGroup", leaders, currentB);
			end
		end
		SW.Bastille.GameCallback_GUI_StateChanged( _StateNameID, _Armed )
	end
	
	SW.Bastille.KeepWindowDisplayedDelay = 25;
	
	SW_Bastille_UpdateProgressWindow = function()
		if XGUIEng.IsModifierPressed(Keys.ModifierAlt) == 0 then
			if XGUIEng.IsWidgetShown("SWGameProgress") == 0 then
				return;
			end
			if SW.Bastille.KeepWindowDisplayedDelay > 0 then
				SW.Bastille.KeepWindowDisplayedDelay = SW.Bastille.KeepWindowDisplayedDelay - 1;
				return;
			end
			XGUIEng.ShowWidget("SWGameProgress", 0);
			SW.Bastille.KeepWindowDisplayedDelay = 25;
			return;
		end
		XGUIEng.ShowWidget("SWGameProgress", 1);
		
	end
	--SW.Bastille.UpdateWindowJobId = StartSimpleHiResJob("SW_Bastille_UpdateProgressWindow");
end

function SW.Bastille.TrackGroup(_leaders, _bastille)
	table.insert(SW.Bastille.Tracking.Pending, {Count=0, Leaders = _leaders, Bastille = _bastille});
	if JobIsRunning(SW.Bastille.Tracking.ControlPendingJobId) == 0 then
		SW.Bastille.Tracking.ControlPendingJobId = StartSimpleJob("SW_Bastille_Tracking_ControlPending");
	end
end

function SW_Bastille_Tracking_ControlPending()
	LuaDebugger.Log("Pending...");
	local t;
	local pendingGroups = table.getn(SW.Bastille.Tracking.Pending);
	if pendingGroups == 0 then
		LuaDebugger.Log("end pending job");
		return true;
	end
	for i = pendingGroups, 1, -1 do
		t = SW.Bastille.Tracking.Pending[i];
		for j = 1, table.getn(t.Leaders) do
			if IsAlive(t.Leaders[j]) then
				if Logic.LeaderGetCurrentCommand(t.Leaders[j]) == 6 then
					table.insert(SW.Bastille.Tracking.Tracked, t);
					table.remove(SW.Bastille.Tracking.Pending, i);
					if JobIsRunning(SW.Bastille.Tracking.ControlTrackingJobId) == 0 then
						SW.Bastille.Tracking.ControlTrackingJobId = StartSimpleJob("SW_Bastille_Tracking_ControlTracking");
					end
					break;
				end
			end
		end
		if t.Count < SW.Bastille.Tracking.PendingDuration then
			t.Count = t.Count + 1;
		else
			table.remove(SW.Bastille.Tracking.Pending, i);
		end
	end
end

function SW_Bastille_Tracking_ControlTracking()
	LuaDebugger.Log("Tracking...");
	local t;
	local trackingGroups = table.getn(SW.Bastille.Tracking.Tracked);
	if trackingGroups == 0 then
		LuaDebugger.Log("end tracking job");
		return true;
	end
	local pos;
	for i = trackingGroups, 1, -1 do
		t = SW.Bastille.Tracking.Tracked[i];
		for j = table.getn(t.Leaders), 1, -1 do
			if IsAlive(t.Leaders[j]) and IsNear(t.Leaders[j], t.Bastille, SW.Bastille.EnterRange) then
				SW.Bastille.LeaderEnterBastille(t.Leaders[j], t.Bastille);
				table.remove(t.Leaders, j);
			end
		end
		if table.getn(t.Leaders) == 0 then
			table.remove(SW.Bastille.Tracking.Tracked, i);
		end
	end
end

function SW.Bastille.LeaderEnterBastille(_leader, _bastille)
	LuaDebugger.Log("Leader ".._leader.." enters bastille");
	if SW.Bastille.Resorts[_bastille] == nil then
		SW.Bastille.Resorts[_bastille] = {};
	end
	if SW.Bastille.Resorts[_bastille][SW.Bastille.MaxTroopsPerResort] then
		Message("Euer Standhafter Turm ist voll!");
		return;
	end
	
	local t = {};
	t.Type = Logic.GetEntityType(_leader);
	t.Health = Logic.GetEntityHealth(_leader);
	t.MaxHealth = Logic.GetEntityMaxHealth(_leader);
	t.IsHero = Logic.IsHero(_leader);
	t.ScriptName = Logic.GetEntityName(_leader);
	t.AttractionLimitValue = Logic.GetLeadersGroupAttractionLimitValue(_leader);
	if t.IsHero == 0 then
		t.Soldiers = Logic.LeaderGetNumberOfSoldiers(_leader);
		t.MaxSoldiers = Logic.LeaderGetMaxNumberOfSoldiers(_leader);
		t.ExperienceLevel = Logic.GetLeaderExperienceLevel(_leader);
	end
	table.insert(SW.Bastille.Resorts[_bastille], t);
	DestroyEntity(_leader);
	
	if GUI.GetSelectedEntity() == _bastille then
		SW.Bastille.UpdateCompleteGUI()
	end
end

function SW.Bastille.GUIAction_ReleaseAllUnits()
	local sel = GUI.GetSelectedEntity();
	if SW.Bastille.Resorts[sel] == nil then
		return;
	end
	local pos, info;
	while(SW.Bastille.Resorts[sel][1]) do
		if not SW.Bastille.ReleaseUnit(sel, 1) then
			-- can't remove all leaders due to attraction limit
			break;
		end
	end
	SW.Bastille.UpdateCompleteGUI();
end

function SW.Bastille.GUIUpate_HealthBar(_id)
	local CurrentWidgetID = XGUIEng.GetWidgetID("SWBOBEntity".._id.."_health");
	local sel = GUI.GetSelectedEntity();
	
	if SW.Bastille.Resorts[sel] == nil 
	or SW.Bastille.Resorts[sel][_id] == nil then
		XGUIEng.SetProgressBarValues(CurrentWidgetID,0,1);
	else
		local PlayerID = GUI.GetPlayerID()
		local ColorR, ColorG, ColorB = GUI.GetPlayerColor( PlayerID )
		
		local CurrentHealth = SW.Bastille.Resorts[sel][_id].Health;
		local Maxhealth = SW.Bastille.Resorts[sel][_id].MaxHealth
		
		if SW.Bastille.Resorts[sel][_id].IsHero == 0 then
			
			local AmountOfSoldiers = SW.Bastille.Resorts[sel][_id].Soldiers
			local MaxAmountOfSoldiers = SW.Bastille.Resorts[sel][_id].MaxSoldiers
					
			CurrentHealth = CurrentHealth + (AmountOfSoldiers * 200)
			Maxhealth = Maxhealth + (MaxAmountOfSoldiers * 200)
			
		end
		
		XGUIEng.SetMaterialColor(CurrentWidgetID,0,ColorR, ColorG, ColorB,255)
		
		XGUIEng.SetProgressBarValues(CurrentWidgetID,CurrentHealth, Maxhealth)
	end

end

SW.Bastille.Tooltips = {
	["EnterBastille"] = "",
};

function SW.Bastille.UpdateTooltip(_tooltip)
end

function SW.Bastille.GUIAction_ReleaseUnit(_id)
	local sel = GUI.GetSelectedEntity();
	if SW.Bastille.Resorts[GUI.GetSelectedEntity()] == nil
	or SW.Bastille.Resorts[GUI.GetSelectedEntity()][_id] == nil then
		-- no units in this resort
		return;
	end	
	if not SW.Bastille.ReleaseUnit(sel, _id) then
		return;
	end
	SW.Bastille.UpdateCompleteGUI()
end

function SW.Bastille.ReleaseUnit(_bastille, _id)
	local pos = GetPosition(_bastille);
	local info = SW.Bastille.Resorts[GUI.GetSelectedEntity()][_id];
	local attractionLimit = Logic.GetPlayerAttractionLimit(GUI.GetPlayerID());
	local attractionUsage = Logic.GetPlayerAttractionUsage(GUI.GetPlayerID());
	local troopAtrUsage = info.AttractionLimitValue;
	
	if (attractionUsage + troopAtrUsage + SW.Bastille.PlayerLocal_SpawnQueueAttractionLimit) > attractionLimit then
		GUI.SendPopulationLimitReachedFeedbackEvent(GUI.GetPlayerID());
		return false;
	end
	SW.Bastille.PlayerLocal_SpawnQueueAttractionLimit = SW.Bastille.PlayerLocal_SpawnQueueAttractionLimit + troopAtrUsage;
	Sync.Call("SW.Bastille.SpawnReleasedUnit",
		GUI.GetPlayerID(),
		_bastille,
		_id,
		info.Type,
		info.Soldiers or 0,
		pos.X,
		pos.Y,
		info.Experience or 0,
		info.Health,
		info.ScriptName,
		troopAtrUsage
	);
	-- local remove from table to prevent spawning the same unit two times
	table.remove(SW.Bastille.Resorts[_bastille], _id);
	return true;
end

function SW.Bastille.SpawnReleasedUnit(_playerId, _bastille, _id, _leaderType, _soldiers, _posX, _posY, _experience, _health, _scriptName, _troopAtrUsage)
	if GUI.GetPlayerID() ~= _playerId then
		table.remove(SW.Bastille.Resorts[_bastille], _id);
	else
		-- now that troop is spawned, real attraction limit can be obtained
		-- reset place holder
		SW.Bastille.PlayerLocal_SpawnQueueAttractionLimit = SW.Bastille.PlayerLocal_SpawnQueueAttractionLimit - _troopAtrUsage;
	end
	local offsetX, offsetY;
	offsetX = 20*math.random(-5,5);
	offsetY = 50*math.random(1,10);
	local newEntity = AI.Entity_CreateFormation(_playerId, _leaderType, 0, _soldiers or 0, _posX+offsetX, _posY-600-offsetY, 0, 0, _experience, 0)
	Logic.HurtEntity(newEntity, Logic.GetEntityMaxHealth(newEntity) - _health); 
	if _scriptName then
		SetEntityName(newEntity, _scriptName);
	end
end

function SW.Bastille.GUITooltip_Update(_id)
end

function SW.Bastille.GUIUpdate_UnitButton(_id)
	local CurrentWidgetID = XGUIEng.GetWidgetID("SWBOBEntity".._id.."_button");
	
	local SourceButton;
	if SW.Bastille.Resorts[GUI.GetSelectedEntity()] == nil 
	or SW.Bastille.Resorts[GUI.GetSelectedEntity()][_id] == nil then
		SourceButton = "SWBOBEmptySlot"
	else	
		local entityType = SW.Bastille.Resorts[GUI.GetSelectedEntity()][_id].Type;
		if Logic.IsEntityTypeInCategory(entityType,EntityCategories.Hero1) == 1 then	
			SourceButton = "MultiSelectionSource_Hero1"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Hero2) == 1 then
			SourceButton = "MultiSelectionSource_Hero2"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Hero3) == 1 then
			SourceButton = "MultiSelectionSource_Hero3"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Hero4) == 1 then
			SourceButton = "MultiSelectionSource_Hero4"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Hero5) == 1 then
			SourceButton = "MultiSelectionSource_Hero5"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Hero6) == 1 then
			SourceButton = "MultiSelectionSource_Hero6"
		elseif entityType	== Entities.CU_BlackKnight then
			SourceButton = "MultiSelectionSource_Hero7"
		elseif entityType	== Entities.CU_Mary_de_Mortfichet then
			SourceButton = "MultiSelectionSource_Hero8"
		elseif entityType	== Entities.CU_Barbarian_Hero then
			SourceButton = "MultiSelectionSource_Hero9"
		elseif entityType == Entities.PU_Serf then
			SourceButton = "MultiSelectionSource_Serf"	
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Sword) == 1 then
			SourceButton = "MultiSelectionSource_Sword"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Bow) == 1 then
			SourceButton = "MultiSelectionSource_Bow"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Spear) == 1 then
			SourceButton = "MultiSelectionSource_Spear"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.Cannon) == 1 then
			SourceButton = "MultiSelectionSource_Cannon"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.CavalryHeavy) == 1 then
			SourceButton = "MultiSelectionSource_HeavyCav"
		elseif Logic.IsEntityTypeInCategory(entityType,EntityCategories.CavalryLight) == 1 then
			SourceButton = "MultiSelectionSource_LightCav"	
		else
			SourceButton = "MultiSelectionSource_Sword"
		end
	end
	
	XGUIEng.TransferMaterials(SourceButton, CurrentWidgetID)
end

function SW.Bastille.GUIAction_EnterBastille()
	GUIAction_Command(5)
end

function SW.Bastille.UpdateCompleteGUI()
	for i = 1, 12 do
		SW.Bastille.GUIUpate_HealthBar(i);
		SW.Bastille.GUIUpdate_UnitButton(i);
	end
end