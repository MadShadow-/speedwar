-- Bug fixes

-- Fix sell building bug & overclocking/blessing bug
-- Fix invis leibi bug

SW = SW or {}

SW.Bugfixes = {}
SW.Bugfixes.BlessingCooldown = 90	--Cooldown for 90 seconds
SW.Bugfixes.ListOfSoldBuildings = {}
SW.Bugfixes.BlessingData = {}
SW.Bugfixes.ToWipe = {}
function SW.Bugfixes.Init()
	local SellBuildingUpvalue = GUI.SellBuilding
	local ListOfSoldBuildingsUpvalue = {}
	GUI.SellBuilding = function( _eId)
		if _eId == nil then return end
		eId = math.mod( _eId, 65536)
		LuaDebugger.Log(eId)
		if ListOfSoldBuildingsUpvalue[eId] == nil then
			ListOfSoldBuildingsUpvalue[eId] = Logic.GetTime()
			SellBuildingUpvalue( _eId)
		elseif  ListOfSoldBuildingsUpvalue[eId] + 60 < Logic.GetTime() then
			ListOfSoldBuildingsUpvalue[eId] = Logic.GetTime()
			SellBuildingUpvalue( _eId)
		else
			Message("Dieses Gebäude wird schon abgerissen!")
		end
	end
	for i = 1, 8 do
		SW.Bugfixes.BlessingData[i] = {}
	end
	SW.Bugfixes.GUIAction_BlessSettlers = GUIAction_BlessSettlers
	GUIAction_BlessSettlers = function( _blessCategory)
		local player = GUI.GetPlayerID()
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
	end
	SW.Bugfixes.FixBattleSerfBug()
	SW.Bugfixes.FixInvisSerfBug()
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
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_BugfixesIsOutpost", "SW_BugfixesOnOutpostDestroyed", 1)
end
function SW_BugfixesIsOutpost()
	if Logic.GetEntityType(Event.GetEntityID()) == Entities.PB_Outpost1 then
		return true
	end
	return false
end
function SW_BugfixesOnOutpostDestroyed()
	local hqId = Event.GetEntityID()
	local pos = GetPosition( hqId)
	for eId in S5Hook.EntityIterator(Predicate.OfType(Entities.PU_Serf), Predicate.InCircle( pos.X, pos.Y, 500)) do
		LuaDebugger.Log(eId)
		table.insert( SW.Bugfixes.ToWipe, eId)
	end
	StartSimpleJob("SW_BugfixesDestroyJob")
end
function SW_BugfixesDestroyJob()
	for i = table.getn(SW.Bugfixes.ToWipe), 1, -1 do
		DestroyEntity(SW.Bugfixes.ToWipe[i])
	end
	return true
end

--[[
	SW.Bugfixes.SellBuilding_Orig = SW.Bugfixes.SellBuilding
	SW.Bugfixes.SellBuilding = function( _eId, _para)
		SW.Bugfixes.SellBuilding_Orig( _eId)
		if _para ~= 1 and XNetwork.Manager_DoesExist() == 1 then
			local pId = GUI.GetPlayerID()
			local name = XNetwork.GameInformation_GetLogicPlayerUserName( pId )
			local r,g,b = GUI.GetPlayerColor( pId )
			local Message = "@color:"..r..","..g..","..b.." "..name.." @color:255,255,255 > Ich benutze den Abreissbug und bin stolz."
			XNetwork.Chat_SendMessageToAll( Message)
		end
	end
]]