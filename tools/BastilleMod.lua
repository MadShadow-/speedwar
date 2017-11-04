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
SW.Bastille.Tracking = {};
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
	
	-- for napos pillage script
	if SW.PillageEntityTypeCost then
		SW.PillageEntityTypeCost[Entities.CB_Bastille1] = {
			[ResourceType.Wood]= 400,
			[ResourceType.Clay]= 400,
			[ResourceType.Stone]= 500,
		}; 
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
				local closestD, currentB, pos, currentD = 1000000000;
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
				SW.PreciseLog.Log("Startup tracking groups", "Bastille")
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
	for i = 1, table.getn(_leaders) do
		SW.Bastille.Tracking[_leaders[i]] = {Bastille = _bastille};
	end
	if JobIsRunning(SW.Bastille.ControlTrackingJobId) == 0 then
		SW.Bastille.ControlTrackingJobId = StartSimpleJob("SW_Bastille_ControlTracking");
	end
end

function SW_Bastille_ControlTracking()
	local numberOfLeaders = 0;
	for leaderId, t in pairs(SW.Bastille.Tracking) do
		if IsAlive(leaderId) then
			if Logic.LeaderGetCurrentCommand(leaderId) == 6 then
				if IsNear(leaderId, t.Bastille, SW.Bastille.EnterRange) then
					SW.Bastille.LeaderEnterBastille(leaderId, t.Bastille);
					SW.Bastille.Tracking[leaderId] = nil;
				end
			else
				SW.Bastille.Tracking[leaderId] = nil;
			end
		else
			SW.Bastille.Tracking[leaderId] = nil;
		end
		numberOfLeaders = numberOfLeaders + 1;
	end
	
	if numberOfLeaders == 0 then
		return true;
	end
end

function SW.Bastille.LeaderEnterBastille(_leader, _bastille)
	if SW.Bastille.Resorts[_bastille] == nil then
		SW.Bastille.Resorts[_bastille] = {};
	end
	if SW.Bastille.Resorts[_bastille][SW.Bastille.MaxTroopsPerResort] then
		if GetPlayer(_bastille) == GUI.GetPlayerID() then
			Message("Euer Standhafter Turm ist voll!");
		end
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

--	is called on all computers, synced
--	return false if spawn fails
function SW.Bastille.ReleaseUnit(_bastille, _id)
	if IsDead(_bastille) then return false end
	if SW.Bastille.Resorts[_bastille][_id] == nil then return false end
	SW.Bastille.UpdateCompleteGUI()
	local pId = GetPlayer( _bastille)
	local pos = GetPosition( _bastille);
	local info = SW.Bastille.Resorts[_bastille][_id];
	local attractionLimit = Logic.GetPlayerAttractionLimit( pId);
	local attractionUsage = Logic.GetPlayerAttractionUsage( pId);
	local troopAtrUsage = info.AttractionLimitValue;
	if (attractionUsage + troopAtrUsage) > attractionLimit then
		GUI.SendPopulationLimitReachedFeedbackEvent(GUI.GetPlayerID());
		return false;
	end
	--Everything ready to spawn now!
	local offsetX, offsetY
	offsetX = 20*math.random(-5,5)
	offsetY = 50*math.random(1,10)
	local newEntity = AI.Entity_CreateFormation( pId, info.Type, 0, info.Soldiers or 0, pos.X+offsetX, pos.Y-600-offsetY, 0, 0, info.ExperienceLevel, 0)
	Logic.HurtEntity(newEntity, Logic.GetEntityMaxHealth(newEntity) - info.Health)
	if info.ScriptName then
		SetEntityName(newEntity, info.ScriptName)
	end
	table.remove(SW.Bastille.Resorts[_bastille], _id)
	return true
end
function SW.Bastille.SyncedReleaseAllUnits( _bastilleId)
	if SW.Bastille.Resorts[_bastilleId] == nil then return end
	while(SW.Bastille.Resorts[_bastilleId][1]) do
		if not SW.Bastille.ReleaseUnit(_bastilleId, 1) then
			--can't remove all leaders due to attraction limit
			break;
		end
	end
	SW.Bastille.UpdateCompleteGUI()
end
function SW.Bastille.GUIAction_ReleaseAllUnits()
	local sel = GUI.GetSelectedEntity();
	if SW.Bastille.Resorts[sel] == nil then
		return;
	end
	Sync.Call("SW.Bastille.SyncedReleaseAllUnits", sel)
end

function SW.Bastille.GUIAction_ReleaseUnit(_id)
	local sel = GUI.GetSelectedEntity();
	Sync.Call("SW.Bastille.ReleaseOneUnitSynced", sel, _id)
end
function SW.Bastille.ReleaseOneUnitSynced( _bastilleId, _slotId)
	if SW.Bastille.Resorts[_bastilleId] == nil
	or SW.Bastille.Resorts[_bastilleId][_slotId] == nil then
		-- no units in this resort
		return;
	end	
	if not SW.Bastille.ReleaseUnit(_bastilleId, _slotId) then
		return;
	end
	SW.Bastille.UpdateCompleteGUI()
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

function SW.Bastille.GUIUpdate_HealthBar(_id)
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

SW.Bastille.TooltipTexts = {
	["releaseAll"] = "@color:255,165,0 Zu den Waffen! @cr @color:220,220,220 Alle Einheiten verlassen den Turm sofort."
};

function SW.Bastille.GUIUpdate_Tooltip(_id)
	-- overwrite with empty strings
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, "");
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, "");
	
	local tooltipDescr = "";
	if SW.Bastille.TooltipTexts[_id] then
		tooltipDescr =  SW.Bastille.TooltipTexts[_id];
	else
		local sel = GUI.GetSelectedEntity()
		if SW.Bastille.Resorts[sel] == nil 
		or SW.Bastille.Resorts[sel][_id] == nil then
			tooltipDescr = "@color:152,251,152 Freier Platz @cr @color:220,220,220 Hier hat noch eine Einheit Platz im Turm." ..
						   " Sendet einen Trupp mit dem 'Bewachen'-Befehl auf einen standhaften Turm um die Einheit dort unterzubringen."
		else
			local t = SW.Bastille.Resorts[sel][_id];
			local soldiers = "";
			if t.Soldiers > 0 then
				soldiers = "(" .. t.Soldiers .. "/" .. t.MaxSoldiers .. ")";
			end
				
			tooltipDescr = "@color:152,251,152 " .. XGUIEng.GetStringTableText("names/" .. Logic.GetEntityTypeName(t.Type)) ..
				" " .. soldiers .. " @cr @color:220,220,220 Mit einem Klick auf diesen Button muss die stationierte Einheit ihren warmen Platz im Turm verlassen.";
		end
	end
	
	XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomText, tooltipDescr);
end

function SW.Bastille.UpdateCompleteGUI()
	for i = 1, 12 do
		SW.Bastille.GUIUpdate_UnitButton(i);
		SW.Bastille.GUIUpdate_HealthBar(i);
		SW.Bastille.GUIUpdate_Tooltip(i);
	end
end

function SW.Bastille.CallbackRankTwoReached()
	XGUIEng.DisableButton("SWBuildBastille", 0);
end