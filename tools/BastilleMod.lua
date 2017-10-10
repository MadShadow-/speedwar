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
SW.Bastille.Resorts = {};

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
			LuaDebugger.Log("Mouse at "..x.." "..y.." E: "..Logic.LeaderGetCurrentCommand(GUI.GetSelectedEntity()) .. "bastille: "..bastilles[1]);
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
	SW.Bastille.UpdateWindowJobId = StartSimpleHiResJob("SW_Bastille_UpdateProgressWindow");
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
			if Logic.LeaderGetCurrentCommand(t.Leaders[j]) == 6 then
				table.insert(SW.Bastille.Tracking.Tracked, t);
				table.remove(SW.Bastille.Tracking.Pending, i);
				if JobIsRunning(SW.Bastille.Tracking.ControlTrackingJobId) == 0 then
					SW.Bastille.Tracking.ControlTrackingJobId = StartSimpleJob("SW_Bastille_Tracking_ControlTracking");
				end
				break;
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
			if IsNear(t.Leaders[j], t.Bastille, SW.Bastille.EnterRange) then
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
		SW.Bastille.Resorts[_bastille] = {TroupCounter = 0};
	end
	
end

function SW.Bastille.GUIAction_ReleaseAllUnits()
end

function SW.Bastille.GUIUpate_HealthBar()
end

SW.Bastille.Tooltips = {
	["EnterBastille"] = "",
};

function SW.Bastille.UpdateTooltip(_tooltip)
end

function SW.Bastille.GUIAction_ReleaseUnit()
end

function SW.Bastille.GUITooltip_Update()
end

function SW.Bastille.GUIUpdate_UnitButton()
	local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
	LuaDebugger.Log("ID:"..CurrentWidgetID);
	local MotherContainer= XGUIEng.GetWidgetsMotherID(CurrentWidgetID)	
	local EntityID = XGUIEng.GetBaseWidgetUserVariable(MotherContainer, 0)			
	local SelectedHeroID = HeroSelection_GetCurrentSelectedHeroID()
	
	local SourceButton
	
	if Logic.IsEntityInCategory(EntityID,EntityCategories.Hero1) == 1 then	
		SourceButton = "MultiSelectionSource_Hero1"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Hero2) == 1 then
		SourceButton = "MultiSelectionSource_Hero2"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Hero3) == 1 then
		SourceButton = "MultiSelectionSource_Hero3"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Hero4) == 1 then
		SourceButton = "MultiSelectionSource_Hero4"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Hero5) == 1 then
		SourceButton = "MultiSelectionSource_Hero5"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Hero6) == 1 then
		SourceButton = "MultiSelectionSource_Hero6"
	elseif Logic.GetEntityType( EntityID )	== Entities.CU_BlackKnight then
		SourceButton = "MultiSelectionSource_Hero7"
	elseif Logic.GetEntityType( EntityID )	== Entities.CU_Mary_de_Mortfichet then
		SourceButton = "MultiSelectionSource_Hero8"
	elseif Logic.GetEntityType( EntityID )	== Entities.CU_Barbarian_Hero then
		SourceButton = "MultiSelectionSource_Hero9"
	elseif Logic.GetEntityType( EntityID ) == Entities.PU_Serf then
		SourceButton = "MultiSelectionSource_Serf"	
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Sword) == 1 then
		SourceButton = "MultiSelectionSource_Sword"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Bow) == 1 then
		SourceButton = "MultiSelectionSource_Bow"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Spear) == 1 then
		SourceButton = "MultiSelectionSource_Spear"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.Cannon) == 1 then
		SourceButton = "MultiSelectionSource_Cannon"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.CavalryHeavy) == 1 then
		SourceButton = "MultiSelectionSource_HeavyCav"
	elseif Logic.IsEntityInCategory(EntityID,EntityCategories.CavalryLight) == 1 then
		SourceButton = "MultiSelectionSource_LightCav"	
	else
		SourceButton = "MultiSelectionSource_Sword"
	end
	
	
	XGUIEng.TransferMaterials(SourceButton, CurrentWidgetID)
	
	-- set color when hero is selected
	if SelectedHeroID == EntityID then		
		for i=0, 4,1
		do
			XGUIEng.SetMaterialColor(SourceButton,i, 255,177,0,255)
		end		
	else	
		for i=0, 4,1
		do
			XGUIEng.SetMaterialColor(SourceButton,i, 255,255,255,255)
		end	
	end
end


function SW.Bastille.GUIAction_EnterBastille()
	GUIAction_Command(5)
end