-- Bug fixes

-- Fix sell building bug & overclocking/blessing bug
-- Fix invis leibi bug

SW = SW or {}

SW.Bugfixes = {}
SW.Bugfixes.BlessingCooldown = 90	--Cooldown for 90 seconds
SW.Bugfixes.ListOfSoldBuildings = {}
SW.Bugfixes.BlessingData = {}
SW.Bugfixes.OutpostList = {}
SW.Bugfixes.ToWipe = {}
function SW.Bugfixes.Init()
	local SellBuildingUpvalue = GUI.SellBuilding
	local ListOfSoldBuildingsUpvalue = {}
	SW.Bugfixes.OnAttackCDs = {}
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "SW_Bugfixes_IsBuilding", "SW_Bugfixes_OnHit", 1)
	GUI.SellBuilding = function( _eId)
		if _eId == nil then return end
		eId = math.mod( _eId, 65536)
		if (SW.Bugfixes.OnAttackCDs[eId] or 0) + 15000 > Logic.GetTimeMs() then
			Message("Das Gebäude wird angegriffen!")
			Sound.PlayGUISound( Sounds.VoicesMentor_MP_TauntFunny05, 0)
			return
		end
		if ListOfSoldBuildingsUpvalue[eId] == nil then
			ListOfSoldBuildingsUpvalue[eId] = Logic.GetTime()
			SellBuildingUpvalue( _eId)
		elseif  ListOfSoldBuildingsUpvalue[eId] + 60 < Logic.GetTime() then
			ListOfSoldBuildingsUpvalue[eId] = Logic.GetTime()
			SellBuildingUpvalue( _eId)
		end
	end
	for i = 1, SW.MaxPlayers do
		SW.Bugfixes.BlessingData[i] = {}
	end
	SW.Bugfixes.GUIAction_BlessSettlers = GUIAction_BlessSettlers
	GUIAction_BlessSettlers = function( _blessCategory)
		local player = GUI.GetPlayerID()
		if player == 17 then
			player = Logic.EntityGetPlayer(GUI.GetSelectedEntity())
			if player == 0 then return end
		end
		local currFaith = Logic.GetPlayersGlobalResource( player, ResourceType.Faith )	
		local costs = Logic.GetBlessCostByBlessCategory( _blessCategory)
		if currFaith < costs then
			SW.Bugfixes.GUIAction_BlessSettlers(_blessCategory)
			return
		end
		if SW.Bugfixes.BlessingData[player][_blessCategory] == nil then		--first blessing? ok.
			SW.Bugfixes.GUIAction_BlessSettlers(_blessCategory)
			SW.Bugfixes.BlessingData[player][_blessCategory] = Logic.GetTime()
			return
		end
		local timee = Logic.GetTime()
		if SW.Bugfixes.BlessingData[player][_blessCategory] + SW.Bugfixes.BlessingCooldown > timee then
			Message("Wartet noch @color:255,0,0 "..math.ceil(SW.Bugfixes.BlessingData[player][_blessCategory] + SW.Bugfixes.BlessingCooldown - timee).." @color:255,255,255 Sekunden!")
			return
		end
		SW.Bugfixes.GUIAction_BlessSettlers(_blessCategory)
		SW.Bugfixes.BlessingData[player][_blessCategory] = timee
		-- all nice and done? disable corresponding button
		for wId,bCat in pairs(SW.Bugfixes.BlessCategoriesByWidgetId) do
			if bCat == _blessCategory then
				XGUIEng.DisableButton(wId, 1)
			end
		end
		XGUIEng.DisableButton(XGUIEng.GetCurrentWidgetID(), 1)
	end
	SW.Bugfixes.BlessCategoriesByWidgetId = {
		[XGUIEng.GetWidgetID("BlessSettlers1")] = BlessCategories.Construction,
		[XGUIEng.GetWidgetID("BlessSettlers2")] = BlessCategories.Research,
		[XGUIEng.GetWidgetID("BlessSettlers3")] = BlessCategories.Weapons,
		[XGUIEng.GetWidgetID("BlessSettlers4")] = BlessCategories.Financial,
		[XGUIEng.GetWidgetID("BlessSettlers5")] = BlessCategories.Canonisation
	}
	SW.Bugfixes.BlessCategoriesByTechId = {
		[Technologies.T_BlessSettlers1] = BlessCategories.Construction,
		[Technologies.T_BlessSettlers2] = BlessCategories.Research,
		[Technologies.T_BlessSettlers3] = BlessCategories.Weapons,
		[Technologies.T_BlessSettlers4] = BlessCategories.Financial,
		[Technologies.T_BlessSettlers5] = BlessCategories.Canonisation
	}
	SW.Bugfixes.GUITooltip_BlessSettlers = GUITooltip_BlessSettlers
	GUITooltip_BlessSettlers = function(_a, _b, _c, _d)
		local CurrentWidgetID = XGUIEng.GetCurrentWidgetID()
		local ShortCutToolTip = " "
		if XGUIEng.IsButtonDisabled(CurrentWidgetID) == 1 then		
			TooltipText =  _a
		elseif XGUIEng.IsButtonDisabled(CurrentWidgetID) == 0 then		
			TooltipText = _b
		end
		if _d ~= nil then
			ShortCutToolTip = XGUIEng.GetStringTableText("MenuGeneric/Key_name") .. ": [" .. XGUIEng.GetStringTableText(_d) .. "]"
		end
		if TooltipText == "MenuMonastery/BlessSettlers_disabled" or TooltipText == "MenuMonastery/BlessSettlers_disabled" then
			TooltipText = _b
		end
		XGUIEng.SetTextKeyName(gvGUI_WidgetID.TooltipBottomText, TooltipText)
		XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomShortCut, ShortCutToolTip)
		local timeString = ""
		local bCat = SW.Bugfixes.BlessCategoriesByWidgetId[XGUIEng.GetCurrentWidgetID()]
		local pId = GUI.GetPlayerID()
		if pId == 17 then
			pId = Logic.EntityGetPlayer(GUI.GetSelectedEntity())
			if pId == 0 then return end
		end
		if SW.Bugfixes.BlessingData[pId][bCat] == nil then
			SW.Bugfixes.BlessingData[pId][bCat] = -10000
		end
		local timee = Logic.GetTime()
		local diff = SW.Bugfixes.BlessingData[pId][bCat] + SW.Bugfixes.BlessingCooldown - timee
		if  diff > 0 then
			timeString = "@color:255,0,0 "..math.ceil(diff).." @color:255,255,255 "
		end
		XGUIEng.SetText(gvGUI_WidgetID.TooltipBottomCosts, timeString)
	end
	SW.Bugfixes.GUIUpdate_BuildingButtons = GUIUpdate_BuildingButtons
	GUIUpdate_BuildingButtons = function( _s, _t, _x)
		SW.Bugfixes.GUIUpdate_BuildingButtons(_s, _t, _b)
		local bCat = SW.Bugfixes.BlessCategoriesByTechId[_t]
		if bCat == nil then return end
		local pId = GUI.GetPlayerID()
		if pId == 17 then
			pId = Logic.EntityGetPlayer(GUI.GetSelectedEntity())
			if pId == 0 then return end
		end
		if SW.Bugfixes.BlessingData[pId][bCat] == nil then
			SW.Bugfixes.BlessingData[pId][bCat] = -10000
		end
		local timee = Logic.GetTime()
		local diff = SW.Bugfixes.BlessingData[pId][bCat] + SW.Bugfixes.BlessingCooldown - timee
		if  diff > 0 then
			XGUIEng.DisableButton(_s, 1)
		end
	end
	
	--GUITooltip_BlessSettlers(_a,_b,_c,_d)
    --GUIUpdate_BuildingButtons
	SW.Bugfixes.FixBattleSerfBug()
	SW.Bugfixes.FixInvisSerfBug()
	SW.Bugfixes.FixSoldGUI()
end
SW.Bugfixes.FormationETypes = {
	[Entities.PU_LeaderBow1] = true,
	[Entities.PU_LeaderBow2] = true,
	[Entities.PU_LeaderBow3] = true,
	[Entities.PU_LeaderBow4] = true,
	[Entities.PU_LeaderPoleArm1] = true,
	[Entities.PU_LeaderPoleArm2] = true,
	[Entities.PU_LeaderPoleArm3] = true,
	[Entities.PU_LeaderPoleArm4] = true,
	[Entities.PU_LeaderRifle1] = true,
	[Entities.PU_LeaderRifle2] = true,
	[Entities.PU_LeaderSword1] = true,
	[Entities.PU_LeaderSword2] = true,
	[Entities.PU_LeaderSword3] = true,
	[Entities.PU_LeaderSword4] = true,
	[Entities.PU_LeaderCavalry1] = true,
	[Entities.PU_LeaderCavalry2] = true,
	[Entities.PU_LeaderHeavyCavalry1] = true,
	[Entities.PU_LeaderHeavyCavalry2] = true,
	[Entities.PV_Cannon1] = true,
	[Entities.PV_Cannon2] = true,
	[Entities.PV_Cannon3] = true,
	[Entities.PV_Cannon4] = true
}
function SW.Bugfixes.FixBattleSerfBug()
	SW.Bugfixes.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()
		-- call the real thing first
		SW.Bugfixes.GameCallback_GUI_SelectionChanged()
		local sel = GUI.GetSelectedEntity()
		-- only work if an entity is selected
		if sel == nil then return end
		if SW.Bugfixes.FormationETypes[Logic.GetEntityType(sel)] then
			XGUIEng.ShowWidget("Commands_Leader",1)
		end
	end
end
function SW.Bugfixes.FixInvisSerfBug()
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, "SW_BugfixesIsOutpost", "SW_BugfixesOnOutpostCreated", 1)
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_BugfixesIsOutpost", "SW_BugfixesOnOutpostDestroyed", 1)
end
function SW_BugfixesIsOutpost()
	if Logic.GetEntityType(Event.GetEntityID()) == Entities.PB_Outpost1 then
		return true
	end
	return false
end
function SW_BugfixesOnOutpostCreated()
	local hqId = Event.GetEntityID()
	SW.Bugfixes.OutpostList[hqId] = GetPosition(hqId)
end
function SW_BugfixesOnOutpostDestroyed()
	local hqId = Event.GetEntityID()
	--local pos = GetPosition( hqId)
	local pos = SW.Bugfixes.OutpostList[hqId]
	--Message("Clearing serfs at X = "..pos.X..", Y = "..pos.Y)
	for eId in S5Hook.EntityIterator( Predicate.OfType(Entities.PU_Serf), Predicate.InCircle( pos.X, pos.Y, 800)) do
		table.insert( SW.Bugfixes.ToWipe, eId)
	end
	--Message("Entities found: "..table.getn(SW.Bugfixes.ToWipe))
	StartSimpleJob("SW_BugfixesDestroyJob")
end
function SW_BugfixesDestroyJob()
	for i = 1, table.getn(SW.Bugfixes.ToWipe) do
		DestroyEntity(SW.Bugfixes.ToWipe[i])
	end
	SW.Bugfixes.ToWipe = {}
	return true
end
function SW.Bugfixes.FixSoldGUI()
	GUIUpdate_TaxLeaderCosts = function()
		local currWidget = XGUIEng.GetCurrentWidgetID()
		XGUIEng.SetText( currWidget, 0)
	end
end
function SW_Bugfixes_IsBuilding()
	return Logic.IsBuilding(Event.GetEntityID2()) == 1
end
function SW_Bugfixes_OnHit()
	SW.Bugfixes.OnAttackCDs[math.mod( Event.GetEntityID2(), 65536)] = Logic.GetTimeMs()
end