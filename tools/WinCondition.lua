SW = SW or {}
SW.WinCondition = {}
SW.WinCondition.CellSize = 3200		-- 32 sm
SW.WinCondition.Time = 90*60 -- this will be overwritten in SWGUI by startmenu callback
-- WIN CONDITION
-- SW.WinCondition.GetWinner will give winning team
SW.WinCondition.TeamByPlayer = {}
SW.WinCondition.ConstructionSiteTypes = {}
--XNetwork.GameInformation_GetLogicPlayerTeam
for i = 0, 8 do
	SW.WinCondition.TeamByPlayer[i] = 0
end

-- TODO: Players that have already lost are unable to score!
function SW.WinCondition.Init()
	if not SW.IsMultiplayer() then	--SP
		for i = 1, 8 do
			SW.WinCondition.TeamByPlayer[i] = i
		end
	else	--MP
		for i = 1, table.getn(SW.Players) do
			SW.WinCondition.TeamByPlayer[SW.Players[i]] = XNetwork.GameInformation_GetLogicPlayerTeam(SW.Players[i])
		end
	end
	for k,v in pairs(Entities) do
		if string.find( k, "ZB") then
			SW.WinCondition.ConstructionSiteTypes[v] = true
		end
	end
	SW.WinCondition.WorldSize = Logic.WorldGetSize()
	SW.WinCondition.RelevantEntities = {}
end
function SW.WinCondition.StartCountdown()
	StartSimpleJob("SW_WinConditionJob")
	SW.WinCondition.TimeVar = SW.WinCondition.Time
end
function SW_WinConditionJob()
	if SW.WinCondition.TimeVar < 0 then
		SW.WinCondition.EndGame()
		Message("Das Spiel sei beendet!")
		return true
	end
	SW.WinCondition.TimeVar = SW.WinCondition.TimeVar - 1
end
function SW.WinCondition.UpdateRelevantEntities()
	-- Entities that qualify for rule over area:
	-- Completed buildings
	-- Leaders
	SW.WinCondition.RelevantEntities = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Leader))
	for eId in S5Hook.EntityIterator( Predicate.IsBuilding()) do
		if Logic.IsConstructionComplete(eId) == 1 and SW.WinCondition.ConstructionSiteTypes[Logic.GetEntityType(eId)] == nil then
			table.insert( SW.WinCondition.RelevantEntities, eId)
		end
	end
end
function SW.WinCondition.GetCell( _x, _y)
	return math.floor(_x/SW.WinCondition.CellSize+1), math.floor(_y/SW.WinCondition.CellSize+1)
end
function SW.WinCondition.SortByCells()
	SW.WinCondition.CellGrid = {}
	for x = 1, SW.WinCondition.WorldSize/SW.WinCondition.CellSize+1 do
		SW.WinCondition.CellGrid[x] = {}
		for y = 1, SW.WinCondition.WorldSize/SW.WinCondition.CellSize+1 do
			SW.WinCondition.CellGrid[x][y] = {}
			for i = 0, 8 do
				SW.WinCondition.CellGrid[x][y][i] = 0;
			end
		end
	end
	local team, pos, x, y
	for k,v in pairs(SW.WinCondition.RelevantEntities) do
		pos = GetPosition(v)
		team = SW.WinCondition.TeamByPlayer[GetPlayer(v)]
		x, y = SW.WinCondition.GetCell( pos.X, pos.Y)
		SW.WinCondition.CellGrid[x][y][team] = SW.WinCondition.CellGrid[x][y][team]+1
	end
end
function SW.WinCondition.EvaluateCells()
	SW.WinCondition.TeamScores = {}
	for i = 0, 8 do
		SW.WinCondition.TeamScores[i] = 0
	end
	local winner
	for x = 1, SW.WinCondition.WorldSize/SW.WinCondition.CellSize+1 do
		for y = 1, SW.WinCondition.WorldSize/SW.WinCondition.CellSize+1 do
			winner = SW.WinCondition.GetCellWinner( x, y)
			SW.WinCondition.TeamScores[winner] = SW.WinCondition.TeamScores[winner] + 1
		end
	end 
end
function SW.WinCondition.GetCellWinner( _x, _y)
	local winner = 0
	local score = 0
	for i = 1, 8 do
		if SW.WinCondition.CellGrid[_x][_y][i] > score then
			winner = i
			score = SW.WinCondition.CellGrid[_x][_y][i]
		end
	end
	return winner
end
function SW.WinCondition.PrintScores()
	for i = 1, 8 do
		if SW.WinCondition.TeamScores[i] > 0 then
			Message("Das Team "..SW.WinCondition.GetTeamMembers(i).." hat "..SW.WinCondition.TeamScores[i].." Punkte!")
		end
	end
end
function SW.WinCondition.GetTeamMembers( _teamId)
	local s = ""
	for k,v in pairs(SW.Players) do
		if SW.WinCondition.TeamByPlayer[v] == _teamId then
			local r,g,b = GUI.GetPlayerColor(v)
			s = s.." @color:"..r..","..g..","..b.." "..XNetwork.GameInformation_GetLogicPlayerUserName(v).." @color:255,255,255 "
		end
	end
	return s
end
function SW.WinCondition.GetWinner()
	if SW.WinCondition.WorldSize == nil then
		SW.WinCondition.Init()
	end
	SW.WinCondition.UpdateRelevantEntities()
	SW.WinCondition.SortByCells()
	SW.WinCondition.EvaluateCells()
	SW.WinCondition.PrintScores()
	local winner = 0
	local score = 0
	for i = 1, 8 do
		if SW.WinCondition.TeamScores[i] > score then
			winner = i
			score = SW.WinCondition.TeamScores[i]
		end
	end
	return winner
end
function SW.WinCondition.ForcePointUpdate()
	if SW.WinCondition.WorldSize == nil then
		SW.WinCondition.Init()
	end
	SW.WinCondition.UpdateRelevantEntities()
	SW.WinCondition.SortByCells()
	SW.WinCondition.EvaluateCells()
end
function SW.WinCondition.GetPlayerPoints( _pId)
	local teamId = SW.WinCondition.TeamByPlayer[_pId]
	if teamId == 0 then return 0 end
	return SW.WinCondition.TeamScores[teamId]
end
function SW.WinCondition.EndGame()
	local winnerTeam = SW.WinCondition.GetWinner()
	Logic.SuspendAllEntities()
	for i = 1, 8 do
		if SW.DefeatConditionPlayerStates[i] then
			if SW.WinCondition.TeamByPlayer[i] ~= winnerTeam then
				SW.DefeatConditionPlayerStates[i] = false
				SW.DefeatConditionOnPlayerDefeated( i)
				SW.WinCondition.GameOver = true
			end
		end
	end
end


--[[
Logic.SetPlayerRawName( playerId, XNetwork.GameInformation_GetLogicPlayerUserName( playerId ) );
			Logic.PlayerSetGameStateToPlaying(playerId);	
			Logic.PlayerSetIsHumanFlag(playerId, 1);
			
			local r,g,b = GUI.GetPlayerColor( playerId );
]]