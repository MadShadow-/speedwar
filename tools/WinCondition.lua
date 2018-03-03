SW = SW or {}
SW.WinCondition = {}
SW.WinCondition.CellSize = 3200		-- 32 sm
SW.WinCondition.Time = 90*60
SW.WinCondition.Delays = 15*60
-- WIN CONDITION
-- SW.WinCondition.GetWinner will give winning team

-- TODO: Players that have already lost are unable to score!
function SW.WinCondition.Init()
	SW.WinCondition.TeamByPlayer = {}
	--XNetwork.GameInformation_GetLogicPlayerTeam
	for i = 0, 8 do
		SW.WinCondition.TeamByPlayer[i] = 0
	end
	for i = 1, table.getn(SW.Players) do
		SW.WinCondition.TeamByPlayer[SW.Players[i]] = XNetwork.GameInformation_GetLogicPlayerTeam(SW.Players[i])
	end
	SW.WinCondition.WorldSize = Logic.WorldGetSize()
	SW.WinCondition.RelevantEntities = {}
end
function SW.WinCondition.StartCountdown()
	StartSimpleJob("SW_WinConditionJob")
	SW.WinCondition.DelayVar = SW.WinCondition.Delays
	SW.WinCondition.TimeVar = SW.WinCondition.Time
end
function SW_WinConditionJob()
	if SW.WinCondition.DelayVar < 0 then
		SW.WinCondition.GetWinner()
		SW.WinCondition.DelayVar = SW.WinCondition.Delays
	end
	if SW.WinCondition.TimeVar < 0 then
		SW.WinCondition.GetWinner()
		Message("Das Spiel sei beendet!")
		return true
	end
	SW.WinCondition.DelayVar = SW.WinCondition.DelayVar - 1
	SW.WinCondition.TimeVar = SW.WinCondition.TimeVar - 1
end
function SW.WinCondition.UpdateRelevantEntities()
	-- Entities that qualify for rule over area:
	-- Completed buildings
	-- Leaders
	SW.WinCondition.RelevantEntities = S5Hook.EntityIteratorTableize( Predicate.OfCategory(EntityCategories.Leader))
	for eId in S5Hook.EntityIterator( Predicate.IsBuilding()) do
		if Logic.IsConstructionComplete(eId) == 1 then
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

--[[
Logic.SetPlayerRawName( playerId, XNetwork.GameInformation_GetLogicPlayerUserName( playerId ) );
			Logic.PlayerSetGameStateToPlaying(playerId);	
			Logic.PlayerSetIsHumanFlag(playerId, 1);
			
			local r,g,b = GUI.GetPlayerColor( playerId );
]]