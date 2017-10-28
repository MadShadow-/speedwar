-- QualityOfLifeChanges

-- Makes your life easier

--Done:
-- Refresh all troops in selection
-- Expel all entities in selection

--Planned:
-- Upgrade all buildings of same type in range?
-- Toggle all nearby gates of same type?
-- Use  [Ctrl] to use effect

SW = SW or {}
SW.QoL = {}
SW.QoL.LeaderTypes = {}
function SW.QoL.Init()
	for k,v in pairs(Entities) do
		if string.find(k,"Leader") then
			SW.QoL.LeaderTypes[v] = true
		end
	end
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