SW = SW or {}

-- Rank system
-- Every human player gets combat points for killing units, buildings and losing units
-- If enough combat points are reached, the rank of a player increases up to rank 4
-- With every rank new technologies might be unlocked
-- All players see the ranks of all players
-- Detailed information is available only for team mates

-- TODO: Use actual names instead of "Team x"

SW.RankSystem = {}
SW.RankSystem.RankThresholds = {
	50,
	200,
	1000
}
SW.RankSystem.KillPoints = 1		-- Points per settler killed
SW.RankSystem.LosePoints = 2		-- Points per settler lost
SW.RankSystem.BuildingPoints = 10	-- Points per building destroyed
SW.RankSystem.Points = {} --Key: PlayerId, Value: Current amount of points
SW.RankSystem.Rank = {} --Key: PlayerId, Value: Current rank, 1 to 4
SW.RankSystem.PlayerIds = {}
SW.RankSystem.PlayerNames = {}
SW.RankSystem.ListOfAllyIds = {}		-- ONLY LOCAL, DIFFERENT VALUES FOR DIFFERENT TEAMS!
SW.RankSystem.RankNames = {
	"Siedler",
	"@color:255,79,200: Krieger",
	"@color:0,140,2: Feldherr",
	"@color:115,209,65: Eroberer"
}
function SW.RankSystem.Init()
	for i = 1, 8 do
		SW.RankSystem.Points[i] = 0
		SW.RankSystem.Rank[i] = 1
	end
	SW.RankSystem.InitKillCount()
	SW.BuildingTooltips.GetRank = SW.RankSystem.GetRank		--Give BuildingTooltips a better rank system
	SW.RankSystem.InitGUI()
end
function SW.RankSystem.InitKillCount()
	SW.RankSystem.GameCallback_SettlerKilled = GameCallback_SettlerKilled
	GameCallback_SettlerKilled = function( _hurter, _hurt)
		SW.RankSystem.GameCallback_SettlerKilled( _hurter, _hurt)
		SW.RankSystem.Points[_hurter] = SW.RankSystem.Points[_hurter] + SW.RankSystem.KillPoints
		SW.RankSystem.Points[_hurt] = SW.RankSystem.Points[_hurt] + SW.RankSystem.LosePoints
		SW.RankSystem.UpdatePlayer(_hurter)
		SW.RankSystem.UpdatePlayer(_hurt)
	end
	SW.RankSystem.GameCallback_BuildingDestroyed = GameCallback_BuildingDestroyed
	GameCallback_BuildingDestroyed = function( _hurter, _hurt)
		SW.RankSystem.GameCallback_BuildingDestroyed( _hurter, _hurt)
		SW.RankSystem.Points[_hurter] = SW.RankSystem.Points[_hurter] + SW.RankSystem.BuildingPoints
		SW.RankSystem.UpdatePlayer( _hurter)
	end
end
function SW.RankSystem.UpdatePlayer( _pId)	--Gets called every time the score of a player changes
	if SW.RankSystem.Rank[_pId] == 4 then	--Max rank reached, set bar to full
		XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", 1, 1)
		return
	end
	XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", SW.RankSystem.Points[_pId], SW.RankSystem.RankThresholds[SW.RankSystem.Rank[_pId]])
	if SW.RankSystem.Points[_pId] >= SW.RankSystem.RankThresholds[SW.RankSystem.Rank[_pId]] then	--Player got enough points for next rank
		SW.RankSystem.Points[_pId] = SW.RankSystem.Points[_pId] - SW.RankSystem.RankThresholds[SW.RankSystem.Rank[_pId]]
		SW.RankSystem.Rank[_pId] = SW.RankSystem.Rank[_pId] + 1
		SW.RankSystem.OnRankUp( _pId)
	end
end
function SW.RankSystem.GetRank( _pId)
	return SW.RankSystem.Rank[_pId]
end
function SW.RankSystem.InitGUI()
	GUIUpdate_VCTechRaceColor = function() end
	GUIUpdate_VCTechRaceProgress = function() end --use this function wisely!
	GUIUpdate_GetTeamPoints = function() end
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
		listPlayer = {1,3,5,8}
		SW.RankSystem.PlayerNames[1] = "@color:255,0,0: Napo @color:255,255,255: "
		SW.RankSystem.PlayerNames[3] = "Dieter"
		SW.RankSystem.PlayerNames[5] = "Fritzl"
		SW.RankSystem.PlayerNames[8] = "Peter Enis"
		numPlayer = 4
		SetFriendly(1,8)
		--StartSimpleJob("SW_RankSystem_DEBUGHandOutPoints")
	end
	--DEBUG END
	SW.RankSystem.PlayerIds = listPlayer
	SW.RankSystem.NumPlayers = numPlayer
	XGUIEng.ShowWidget("VCMP_Window", 1)
	XGUIEng.ShowAllSubWidgets("VCMP_Window", 1)
	for i = 1, numPlayer do			--Prep everything
		for j = 1, 8 do
			XGUIEng.ShowWidget("VCMP_Team"..i.."Player"..j, 0)
		end
		XGUIEng.SetText("VCMP_Team"..i.."Name", "Team "..i)
		XGUIEng.ShowWidget("VCMP_Team"..i.."TechRace", 1)
		XGUIEng.ShowWidget("VCMP_Team"..i.."Progress", 1)
		XGUIEng.ShowWidget("VCMP_Team"..i.."_Shade", 0)
		XGUIEng.SetProgressBarValues("VCMP_Team"..i.."Progress", 0, 8)
	end
	for i = 1, 8 do
		XGUIEng.ShowWidget("VCMP_Team"..i, 0)
		XGUIEng.ShowWidget("VCMP_Team"..i.."_Shade", 0)
	end
	-- Basics done, now start refining
	-- Only show progress of allies
	local currPlayer = GUI.GetPlayerID()
	--Find all allies
	for i = 1, numPlayer do
		if listPlayer[i] == currPlayer or Logic.GetDiplomacyState( currPlayer, listPlayer[i]) == Diplomacy.Friendly then
			table.insert( SW.RankSystem.ListOfAllyIds, listPlayer[i])
		end
	end
	for i = 1, table.getn(SW.RankSystem.ListOfAllyIds) do
		XGUIEng.ShowWidget("VCMP_Team"..i, 1)
		XGUIEng.ShowWidget("VCMP_Team"..i.."_Shade", 0)
		local ColorR, ColorG, ColorB = GUI.GetPlayerColor( SW.RankSystem.ListOfAllyIds[i] )
		XGUIEng.SetMaterialColor("VCMP_Team"..i.."Progress",0,ColorR, ColorG, ColorB,200)
		XGUIEng.SetText("VCMP_Team"..i.."Name", SW.RankSystem.PlayerNames[SW.RankSystem.ListOfAllyIds[i]])
	end
	--[[
	   VCMP_Window
         VCMP_Team1
           VCMP_Team1Name
           VCMP_Team1Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team1Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team1Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team1Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team1Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team1Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team1Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team1Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team1TechRace
             VCMP_Team1Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team1ProgressBG
           VCMP_Team1PointGame
             VCMP_Team1Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team1PointBG
         VCMP_Team1_Shade
	]]
end
function SW.RankSystem.OnRankUp( _pId)	--Gets called every time a player reaches a new rank; Currently empty
	Message("Spieler "..SW.RankSystem.PlayerNames[_pId].." hat den Rang "..SW.RankSystem.RankNames[SW.RankSystem.Rank[_pId]].." @color:255,255,255 erreicht!")
	if SW.RankSystem.Rank[_pId] == 4 then
		XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", 1, 1)
	else
		XGUIEng.SetProgressBarValues("VCMP_Team"..SW.RankSystem.GetGUIIdByPlayerId(_pId).."Progress", 0, 1)
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
function SW_RankSystem_DEBUGHandOutPoints()
	for i = 1, 8 do
		SW.RankSystem.Points[i] = SW.RankSystem.Points[i] + i
		SW.RankSystem.UpdatePlayer( i)
	end
end
