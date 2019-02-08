SW = SW or {}

-- Rank system
-- Every human player gets combat points for killing units, buildings and losing units
-- If enough combat points are reached, the rank of a player increases up to rank 4
-- With every rank new technologies might be unlocked
-- All players see the ranks of all players
-- Detailed information is available only for team mates

-- TODO: Use actual names instead of "Team x"

SW.RankSystem = SW.RankSystem or {}

SW.RankSystem.Points = {} --Key: PlayerId, Value: Current amount of points
				-- if shared rank is active: Key: TeamId, Value: Current amount of points
SW.RankSystem.Rank = {} --Key: PlayerId, Value: Current rank, 1 to 4
SW.RankSystem.PlayerIds = {}
SW.RankSystem.PlayerNames = {}
SW.RankSystem.ListOfAllyIds = {}		-- ONLY LOCAL, DIFFERENT VALUES FOR DIFFERENT TEAMS!
SW.RankSystem.AvgRank = 1
SW.RankSystem.CallbackOnRankUp =
{
	-- reaching rank 2
	[2] = function()
		SW.Bastille.CallbackRankTwoReached();
		SW.ProgressWindow.RankUpGUIUpdate();
	end,
	-- reaching rank 3
	[3] = function()
		SW.ProgressWindow.RankUpGUIUpdate();
	end,
	-- reaching rank 4
	[4] = function()
		SW.ProgressWindow.RankUpGUIUpdate();
	end,
};
function SW.RankSystem.Init()
	for i = 1, 8 do
		SW.RankSystem.Points[i] = 0
		SW.RankSystem.Rank[i] = 1
	end
	if SW.GUI.Rules.SharedRank == 1 then
		SW.RankSystem.TeamSizes = {}
		local team = XNetwork.GameInformation_GetLogicPlayerTeam
		for i = 1, 8 do
			SW.RankSystem.TeamSizes[i] = 0
		end
		for i = 1, 8 do
			SW.RankSystem.TeamSizes[team(i)] = SW.RankSystem.TeamSizes[team(i)]+1
		end
	end
	SW.RankSystem.InitKillCount()
	SW.BuildingTooltips.GetRank = SW.RankSystem.GetRank		--Give BuildingTooltips a better rank system
	-- Create GUI with NaposUeberlegeneBalken
	SW.RankSystem.InitGUI()
	StartSimpleJob("SW_RankSystem_CalcAvgRankJob")
end
function SW.RankSystem.InitKillCount()
	SW.RankSystem.GameCallback_SettlerKilled = GameCallback_SettlerKilled
	GameCallback_SettlerKilled = function( _hurter, _hurt)
		SW.RankSystem.GameCallback_SettlerKilled( _hurter, _hurt)
		SW.RankSystem.GivePointsToPlayer( _hurter, SW.RankSystem.KillPoints)
		SW.RankSystem.GivePointsToPlayer( _hurt, SW.RankSystem.LosePoints)
		--SW.RankSystem.Points[_hurter] = SW.RankSystem.Points[_hurter] + SW.RankSystem.KillPoints
		--SW.RankSystem.Points[_hurt] = SW.RankSystem.Points[_hurt] + SW.RankSystem.LosePoints
		--SW.RankSystem.UpdatePlayer(_hurter)
		--SW.RankSystem.UpdatePlayer(_hurt)
	end
	SW.RankSystem.GameCallback_BuildingDestroyed = GameCallback_BuildingDestroyed
	GameCallback_BuildingDestroyed = function( _hurter, _hurt)
		SW.RankSystem.GameCallback_BuildingDestroyed( _hurter, _hurt)
		SW.RankSystem.GivePointsToPlayer( _hurter, SW.RankSystem.BuildingPoints)
		--SW.RankSystem.Points[_hurter] = SW.RankSystem.Points[_hurter] + SW.RankSystem.BuildingPoints
		--SW.RankSystem.UpdatePlayer( _hurter)
	end
end
function SW.RankSystem.UpdatePlayer( _pId)	--Gets called every time the score of a player changes
	if SW.RankSystem.Rank[_pId] == 4 then	--Max rank reached, set bar to full
		--XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", 1, 1)
		return
	end
	
	--XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", SW.RankSystem.Points[_pId], SW.RankSystem.RankThresholds[SW.RankSystem.Rank[_pId]])
	local threshold = SW.RankSystem.GetNextRankThreshold( _pId)
	if SW.RankSystem.Points[_pId] >= threshold then	--Player got enough points for next rank
		SW.RankSystem.Points[_pId] = SW.RankSystem.Points[_pId] - threshold
		SW.RankSystem.Rank[_pId] = SW.RankSystem.Rank[_pId] + 1
		SW.RankSystem.OnRankUp( _pId)
	end
end
function SW.RankSystem.UpdateTeam( _team)
	local team = XNetwork.GameInformation_GetLogicPlayerTeam
	local repr = 0
	for i = 1, 8 do
		if team(i) == _team then
			repr = i
			break
		end
	end
	if SW.RankSystem.Rank[repr] == 4 then return end
	if SW.RankSystem.Points[_team] >= SW.RankSystem.GetNextRankThreshold( _team) then
		SW.RankSystem.Points[_team] = SW.RankSystem.Points[_team] - SW.RankSystem.GetNextRankThreshold( _team)
		for i = 1, 8 do
			if team(i) == _team then
				SW.RankSystem.Rank[i] = SW.RankSystem.Rank[i] + 1
				SW.RankSystem.OnRankUp( i)
			end
		end
	end
end 
function SW.RankSystem.GetNextRankThreshold( _pId)
	if SW.GUI.Rules.SharedRank == 0 then
		return SW.RankSystem.RankThresholds[SW.RankSystem.Rank[_pId]]
	end
	local team = XNetwork.GameInformation_GetLogicPlayerTeam
	return SW.RankSystem.RankThresholds[SW.RankSystem.Rank[_pId]]*SW.RankSystem.TeamSizes[team(_pId)]
end
function SW.RankSystem.GetRank( _pId)
	return SW.RankSystem.Rank[_pId]
end
function SW.RankSystem.InitGUI()
	-- GUIUpdate_VCTechRaceColor = function() end
	-- GUIUpdate_VCTechRaceProgress = function() end --use this function wisely!
	-- GUIUpdate_GetTeamPoints = function() end
	local numPlayer = SW.NrOfPlayers
	local listPlayer = SW.Players
	for i = 1, 8 do
		SW.RankSystem.PlayerNames[i] = "Spieler "..i
	end
	for k,v in pairs(listPlayer) do
		local r,g,b = GUI.GetPlayerColor( v )
		SW.RankSystem.PlayerNames[v] = "@color:"..r..","..g..","..b..": "..XNetwork.GameInformation_GetLogicPlayerUserName( v).." @color:255,255,255 "
	end
	--DEBUG
	if not SW.IsMultiplayer() then
	--if false then
		listPlayer = {1,3,5,8}
		local r,g,b = GUI.GetPlayerColor(1)
		SW.RankSystem.PlayerNames[1] = "@color:"..r..","..g..","..b..": "..UserTool_GetPlayerName(1).." @color:255,255,255 "
		for i = 2, 8 do
			r,g,b = GUI.GetPlayerColor(i)
			SW.RankSystem.PlayerNames[i] = "@color:"..r..","..g..","..b..": Peter Enis @color:255,255,255 "
			numPlayer = 8
			SetFriendly(1,i)
			SW.NrOfPlayers = SW.NrOfPlayers+1
			table.insert( SW.Players, i)
			SW.RankSystem.Points[i] = (i-1)*71
		end
		--StartSimpleJob("SW_RankSystem_DEBUGHandOutPoints")
	end
	--DEBUG END
	SW.RankSystem.PlayerIds = listPlayer
	SW.RankSystem.NumPlayers = numPlayer
	SW.RankSystem.ApplyGUIChanges()
end
function SW.RankSystem.ApplyGUIChanges()
	local numPlayer = SW.NrOfPlayers
	local listPlayer = SW.Players
	-- Now uses NaposUeberlegeneBalken
	-- XGUIEng.ShowWidget("VCMP_Window", 1)
	-- XGUIEng.ShowAllSubWidgets("VCMP_Window", 1)
	-- for i = 1, numPlayer do			--Prep everything
		-- for j = 1, 8 do
			-- XGUIEng.ShowWidget("VCMP_Team"..i.."Player"..j, 0)
		-- end
		-- XGUIEng.SetText("VCMP_Team"..i.."Name", "Team "..i)
		-- XGUIEng.ShowWidget("VCMP_Team"..i.."TechRace", 1)
		-- XGUIEng.ShowWidget("VCMP_Team"..i.."Progress", 1)
		-- XGUIEng.ShowWidget("VCMP_Team"..i.."_Shade", 0)
		-- XGUIEng.SetProgressBarValues("VCMP_Team"..i.."Progress", 0, 8)
	-- end
	-- for i = 1, 8 do
		-- XGUIEng.ShowWidget("VCMP_Team"..i, 0)
		-- XGUIEng.ShowWidget("VCMP_Team"..i.."_Shade", 0)
	-- end
	-- Basics done, now start refining
	-- Only show progress of allies
	local currPlayer = GUI.GetPlayerID()
	--Find all allies
	SW.RankSystem.ListOfAllyIds = {}
	if GUI.GetPlayerID() ~= 17 then
		for i = 1, numPlayer do
			if listPlayer[i] == currPlayer or Logic.GetDiplomacyState( currPlayer, listPlayer[i]) == Diplomacy.Friendly then
				table.insert( SW.RankSystem.ListOfAllyIds, listPlayer[i])
			end
		end
	else
		for i = 1, numPlayer do
			table.insert( SW.RankSystem.ListOfAllyIds, listPlayer[i])
		end
	end
	SW.RankSystem.CountFuncs = {}
	SW.RankSystem.GeneralCountFunc = function( j)
		if SW.RankSystem.Rank[j] < 4 then
			return math.floor(100*SW.RankSystem.Points[j]/SW.RankSystem.GetNextRankThreshold( j));
		else
			return 100
		end
	end
	for i = 1, 8 do
		local j = i
		SW.RankSystem.CountFuncs[j] = function()
			return SW.RankSystem.GeneralCountFunc(j)
		end
	end
	QuestController.Init()
	for i = 1, table.getn(SW.RankSystem.ListOfAllyIds) do
		QuestController.Add( "percent", SW.RankSystem.CountFuncs[SW.RankSystem.ListOfAllyIds[i]], 
			SW.RankSystem.PlayerNames[SW.RankSystem.ListOfAllyIds[i]].." @color:255,255,255", 100)
		--XGUIEng.ShowWidget("VCMP_Team"..i, 1)
		--XGUIEng.ShowWidget("VCMP_Team"..i.."_Shade", 0)
		--local ColorR, ColorG, ColorB = GUI.GetPlayerColor( SW.RankSystem.ListOfAllyIds[i] )
		--XGUIEng.SetMaterialColor("VCMP_Team"..i.."Progress",0,ColorR, ColorG, ColorB,200)
		--XGUIEng.SetText("VCMP_Team"..i.."Name", SW.RankSystem.PlayerNames[SW.RankSystem.ListOfAllyIds[i]])
	end
end
function SW.RankSystem.OnRankUp( _pId)	--Gets called every time a player reaches a new rank; Currently empty
	Message("Spieler "..SW.RankSystem.PlayerNames[_pId].." hat den Rang "..SW.RankSystem.RankNames[SW.RankSystem.Rank[_pId]].." @color:255,255,255 erreicht!")
	-- calling callbacks
	if SW.RankSystem.CallbackOnRankUp[SW.RankSystem.Rank[_pId]] then
		SW.RankSystem.CallbackOnRankUp[SW.RankSystem.Rank[_pId]]();
	end
	if SW.RankSystem.Rank[_pId] == 4 then
		XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", 1, 1)
	else
		XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", 0, 1)
	end
	if GUI.GetPlayerID() == 17 then
		local key = 0
		for i = 1, table.getn(SW.RankSystem.ListOfAllyIds) do
			if SW.RankSystem.ListOfAllyIds[i] == _pId then
				key = i
				break
			end
		end
		if key ~= 0 then
			local rank = SW.RankSystem.Rank[_pId]
			QuestController.Data[key].desc = SW.RankSystem.RankNames[rank].." "..SW.RankSystem.PlayerNames[_pId].." @color:255,255,255"
		end
	end
end
function SW.RankSystem.GetGUIIdByPlayerId(_pId)
	for k,v in pairs(SW.RankSystem.ListOfAllyIds) do
		if v == _pId then
			return k
		end
	end
	return 8
end
function SW_RankSystem_DEBUGHandOutPoints( _sender, _amount)
	Message(_sender.." is giving away rank points for free: ".._amount)
	for i = 1, 8 do
		SW.RankSystem.GivePointsToPlayer( i, _amount)
	end
end
function SW.RankSystem.GetRankWithProgress( _pId)
	local r1 = SW.RankSystem.Rank[_pId]
	if r1 == 4 then return 4 end
	local r2 = SW.RankSystem.Points[_pId]/SW.RankSystem.RankThresholds[r1]
	return r1+r2
end
function SW.RankSystem.CalculateAvgRank()
	local vals = {}
	for i = 1, 8 do
		if SW.DefeatConditionPlayerStates[i] then	--player has not lost yet
			table.insert( vals, SW.RankSystem.GetRankWithProgress(i))
		end
	end
	local val = 0
	--use l2-norm for creating average
	for i = 1, table.getn(vals) do
		val = val + vals[i]^2
	end
	val = math.sqrt(val/table.getn(vals))
	return val
end
function SW.RankSystem.GivePointsToPlayer( _pId, _amount)
	if SW.GUI.Rules.SharedRank == 1 then
		local team = XNetwork.GameInformation_GetLogicPlayerTeam( _pId)
		SW.RankSystem.Points[team] = SW.RankSystem.Points[team] + _amount
		SW.RankSystem.UpdateTeam(team)
	else
		SW.RankSystem.Points[_pId] = SW.RankSystem.Points[_pId] + math.floor(_amount*SW.RankSystem.Modifier( _pId))
		SW.RankSystem.UpdatePlayer( _pId)
	end
end
function SW_RankSystem_CalcAvgRankJob()
	SW.RankSystem.AvgRank = SW.RankSystem.CalculateAvgRank()
end
function SW.RankSystem.Modifier( _pId)	--Might be used to give players that fell behind more points per action
	if not SW.RankSystem.UseCatchUp then return 1 end
	local weight = SW.RankSystem.AvgRank - SW.RankSystem.GetRankWithProgress(_pId)
	if weight <= 1 then
		return 1
	end
	--return math.exp(math.ln(A)*(weight-1)/2)
	--currently A = 25
	return math.exp(3.21887582487*(weight-1)/2)
end



