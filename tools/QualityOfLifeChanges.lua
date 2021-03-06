-- QualityOfLifeChanges

-- Makes your life easier

--Done:
-- Refresh all troops in selection
-- Expel all entities in selection
-- Host is shown if player leaves
-- Pressing [Space] deselects all serfs tasked with constructing something
-- Holding [Alt] while pressing the serf button on the top of the screen selects all idle serfs
-- Holding [Strg] while pressing button in markets changes buy amount by 250
-- Holding [Alt] while pressing button in markets changes buy amount by 1 000
-- Holding [Strg] and [Alt] while pressing button in markets changes buy amount by 5 000

--Planned:
-- Upgrade all buildings of same type in range?


SW = SW or {}
SW.QoL = {}
SW.QoL.LeaderTypes = {}
function SW.QoL.Init()
	for k,v in pairs(Entities) do
		if string.find(k,"Leader") then
			SW.QoL.LeaderTypes[v] = true
		end
	end
	-- dont do QoL stuff if simis server is detected
	--if CNetwork then return end
	Input.KeyBindDown(Keys.Space, "SW.QoL.RemoveWorkingSerfsInSelection()", 2);
	SW.QoL.GameCallback_GUI_SelectionChanged = GameCallback_GUI_SelectionChanged
	GameCallback_GUI_SelectionChanged = function()
		SW.QoL.GameCallback_GUI_SelectionChanged()
		if SW.QoL.LeaderTypes[Logic.GetEntityType(GUI.GetSelectedEntity())] then
			XGUIEng.ShowWidget("Buy_Soldier",1)
			XGUIEng.ShowWidget("Buy_Soldier_Button",1)
		end
	end
	SW.QoL.GUIAction_BuySoldier = GUIAction_BuySoldier
	GUIAction_BuySoldier = function()
		if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
			SW.QoL.DoForAllEntitiesInSelection(SW.QoL.BuySoldier)
		else
			SW.QoL.GUIAction_BuySoldier()
		end
	end
	SW.QoL.GUIAction_ExpelSettler = GUIAction_ExpelSettler
	GUIAction_ExpelSettler = function()
		if XGUIEng.IsModifierPressed(Keys.ModifierControl) == 1 then
			SW.QoL.DoForAllEntitiesInSelection(SW.QoL.ExpelSettler)
		else
			SW.QoL.GUIAction_ExpelSettler()
		end
	end
	SW.QoL.InitSelectingIdleSerfs()
	
	SW.QoL.ShowHostOnPlayerDC()
	SW.QoL.MarketFixes()
	SW.QoL.ShowArea()
end
-- Calls the  given func for all entities in selection
-- During each call, only one entity is selected
-- While working, only one call of GUI.AddNote is allowed
function SW.QoL.DoForAllEntitiesInSelection(_func)
	SW.QoL.AddNote = GUI.AddNote
	GUI.AddNote = function(_s)
		SW.QoL.AddNote(_s)
		GUI.AddNote = function() end
	end
	local selection = {GUI.GetSelectedEntities()}
	GUI.ClearSelection()
	for i = 1, table.getn(selection),1 do
		GUI.SelectEntity(selection[i])
		_func()
		GUI.ClearSelection()
	end
	for i = 1,table.getn(selection) do
		GUI.SelectEntity(selection[i])
	end 
	GUI.AddNote = SW.QoL.AddNote
end
function SW.QoL.BuySoldier()
	local sel = GUI.GetSelectedEntity()
	if SW.QoL.LeaderTypes[Logic.GetEntityType(sel)] then
		local maxSol = Logic.LeaderGetMaxNumberOfSoldiers( sel)
		local curSol = Logic.GetSoldiersAttachedToLeader( sel)
		for i = 1, maxSol-curSol do
			SW.QoL.GUIAction_BuySoldier()
		end
	end
end
function SW.QoL.ExpelSettler()
	local sel = GUI.GetSelectedEntity()
	if SW.QoL.LeaderTypes[Logic.GetEntityType(sel)] then
		local curSol = Logic.GetSoldiersAttachedToLeader( sel)
		for i = 1, curSol do
			GUI.ExpelSettler( sel)
		end
	end
	GUI.ExpelSettler( sel)
end
function SW.QoL.ShowHostOnPlayerDC()
	if not SW.IsMultiplayer() then return end
	SW.QoL.MPGame_ApplicationCallback_PlayerLeftGame = MPGame_ApplicationCallback_PlayerLeftGame
	MPGame_ApplicationCallback_PlayerLeftGame = function( _pId, _misc)
		SW.QoL.MPGame_ApplicationCallback_PlayerLeftGame( _pId, _misc)
		StartSimpleJob("SW_QoL_OnPlayerLeft")
	end
	local hostNColor, hostN = SW.QoL.GetHostName()
	XGUIEng.SetText("MainMenuWindow_NetworkGame", "@center Host: "..hostN)
end
function SW_QoL_OnPlayerLeft()
	local hostAdress = XNetwork.Host_UserInSession_GetHostNetworkAddress()
	local hostId = 0
	for i = 1, 8 do
		if hostAdress == XNetwork.GameInformation_GetNetworkAddressByPlayerID( i) then
			hostId = i
			break
		end
	end
	local hostNColor, hostN = SW.QoL.GetHostName()
	Message("Aktueller Host: "..hostNColor)
	XGUIEng.SetText("MainMenuWindow_NetworkGame", "@center Host: "..hostN)
	return true
end
function SW.QoL.GetHostName()
	local hostAdress = XNetwork.Host_UserInSession_GetHostNetworkAddress()
	local hostId = 0
	for i = 1, 8 do
		if hostAdress == XNetwork.GameInformation_GetNetworkAddressByPlayerID( i) then
			hostId = i
			break
		end
	end
	if hostId == 0 then
		return "Unknown", "Unknown"
	else
		local r,g,b = GUI.GetPlayerColor(hostId)
		local hostName = XNetwork.GameInformation_GetLogicPlayerUserName(hostId) or ""
		return " @color:"..r..","..g..","..b.." "..hostName.." @color:255,255,255 ", hostName
	end
end
function SW.QoL.IsSerfInSelection()
	local selection = {GUI.GetSelectedEntities()}
	for k,v in pairs(selection) do
		if Logic.GetEntityType( v) == Entities.PU_Serf then return true end
	end
	return false
end
function SW.QoL.RemoveWorkingSerfsInSelection()
	if not SW.QoL.IsSerfInSelection() then
		-- original key bind of space
		KeyBindings_JumpToLastHotSpot();
		return;
	end
	local sel = {GUI.GetSelectedEntities()};
	local tl, e;
	for i = 1, table.getn(sel) do
		if Logic.GetEntityType(sel[i]) == Entities.PU_Serf then
			e = sel[i];
			tl = Logic.GetCurrentTaskList(e);
			if Logic.GetCurrentTaskList(e) == "TL_SERF_GO_TO_CONSTRUCTION_SITE"
			or Logic.GetCurrentTaskList(e) == "TL_SERF_BUILD" then
				GUI.DeselectEntity(e);
			end
		else
			GUI.DeselectEntity(sel[i])
		end
	end
end
function SW.QoL.InitSelectingIdleSerfs()
	SW.QoL.GUIAction_FindIdleSerf = GUIAction_FindIdleSerf
	GUIAction_FindIdleSerf = function(_arg)
		if XGUIEng.IsModifierPressed( Keys.ModifierAlt) == 1 then
			GUI.ClearSelection()
			local pId = GUI.GetPlayerID()
			local maxx = math.min( 20, Logic.GetNumberOfIdleSerfs( pId))
			local currId = 0
			for i = 1, maxx do
				currId = Logic.GetNextIdleSerf( 1, currId)
				GUI.SelectEntity( currId)
			end
		else
			SW.QoL.GUIAction_FindIdleSerf( _arg)
		end
	end
end
function SW.QoL.MarketFixes()
	GUIAction_MarketToggleResource = function(_value, _resource)
		if XGUIEng.IsModifierPressed( Keys.ModifierControl ) == 1 then
			_value = _value * 5
		end
		if XGUIEng.IsModifierPressed( Keys.ModifierAlt ) == 1 then
			_value = _value * 20
		end
		--calculate new amount of resource to buy
		_resource = _resource + _value
		--minus is forbidden
		if _resource <= 0 then
			_resource = 0
		end
		--Return new amount of resource to buy
		return _resource
	end
end
function SW.QoL.ShowArea()
	local playerT = {}
	local pId
	for eId in S5Hook.EntityIterator(Predicate.OfType(Entities.PU_Serf)) do
		pId = GetPlayer(eId)
		playerT[pId] = playerT[pId] or GetPosition(eId)
	end
	local distance = {}
	SW.QoL.VisionEntities = {}
	--[[local maxRange = 150
	for player1, pos1 in pairs(playerT) do
		distance[player1] = maxRange*maxRange*10000
		for player2, pos2 in pairs(playerT) do
			if player2 ~= player1 and Logic.GetDiplomacyState(player1, player2) ~= Diplomacy.Friendly then
				dis = (pos1.X-pos2.X)*(pos1.X-pos2.X)+(pos1.Y-pos2.Y)*(pos1.Y-pos2.Y)
				distance[player1] = math.min(distance[player1], dis)
			end
		end
		--LuaDebugger.Log(math.floor(math.sqrt(distance[player1])/100))
		local eId = Logic.CreateEntity( Entities.XD_ScriptEntity, pos1.X, pos1.Y, 0, player1)
		Logic.SetEntityExplorationRange( eId, math.floor(math.sqrt(distance[player1])/100))
		table.insert( SW.QoL.VisionEntities, eId)
	end
	--]]
	local t = {
		Entities.XD_StonePit1,
		Entities.XD_IronPit1,
		Entities.XD_ClayPit1,
		Entities.XD_SulfurPit1
	}
	local x,y,r, eID, pos;
	r = 15000;
	for playerId, position in pairs(playerT) do
		x = position.X;
		y = position.Y;
		for eId in S5Hook.EntityIterator(Predicate.OfAnyType(t[1],t[2],t[3],t[4]), Predicate.InCircle(x, y, r)) do
			pos = GetPosition(eId);
			eID = Logic.CreateEntity( Entities.XD_ScriptEntity, pos.X, pos.Y, 0, playerId);
			Logic.SetEntityExplorationRange( eID, 5);
			table.insert( SW.QoL.VisionEntities, eID);
		end
	end
	StartSimpleJob("SW_QoL_RemoveVision")
end
function SW_QoL_RemoveVision()
	if Counter.Tick2("SW_QoL_RemoveVision",5) then
		for k,v in pairs(SW.QoL.VisionEntities) do
			DestroyEntity(v)
		end
		return
	end
end
