SW = SW or {}

-- Rank system
-- Every human player gets combat points for killing units, buildings and losing units
-- If enough combat points are reached, the rank of a player increases up to rank 4
-- With every rank new technologies might be unlocked
-- All players see the ranks of all players
-- Detailed information is available only for team mates

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
	if SW.RankSystem.Rank[_pId] == 4 then	--Max rank reached, no need to do things
		return
	end
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
         VCMP_Team2
           VCMP_Team2TechRace
             VCMP_Team2Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team2ProgressBG
           VCMP_Team2Name
           VCMP_Team2Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team2Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team2Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team2Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team2Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team2Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team2Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team2Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team2PointGame
             VCMP_Team2Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team2PointBG
         VCMP_Team3
           VCMP_Team3Name
           VCMP_Team3Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team3Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team3Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team3Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team3Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team3Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team3Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team3Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team3TechRace
             VCMP_Team3Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team3ProgressBG
           VCMP_Team3PointGame
             VCMP_Team3Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team3PointBG
         VCMP_Team4
           VCMP_Team4TechRace
             VCMP_Team4Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team4ProgressBG
           VCMP_Team4Name
           VCMP_Team4Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team4Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team4Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team4Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team4Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team4Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team4Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team4Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team4PointGame
             VCMP_Team4Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team4PointBG
         VCMP_Team5
           VCMP_Team5TechRace
             VCMP_Team5Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team5ProgressBG
           VCMP_Team5Name
           VCMP_Team5Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team5Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team5Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team5Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team5Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team5Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team5Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team5Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team5PointGame
             VCMP_Team5Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team5PointBG
         VCMP_Team6
           VCMP_Team6TechRace
             VCMP_Team6Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team6ProgressBG
           VCMP_Team6Name
           VCMP_Team6Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team6Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team6Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team6Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team6Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team6Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team6Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team6Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team6PointGame
             VCMP_Team6Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team6PointBG
         VCMP_Team7
           VCMP_Team7TechRace
             VCMP_Team7Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team7ProgressBG
           VCMP_Team7Name
           VCMP_Team7Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team7Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team7Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team7Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team7Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team7Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team7Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team7Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team7PointGame
             VCMP_Team7Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team7PointBG
         VCMP_Team8
           VCMP_Team8TechRace
             VCMP_Team8Progress
              Calls: GUIUpdate_VCTechRaceProgress()
             VCMP_Team8ProgressBG
           VCMP_Team8Name
           VCMP_Team8Player1
            Calls: GUIUpdate_VCTechRaceColor(1)
           VCMP_Team8Player2
            Calls: GUIUpdate_VCTechRaceColor(2)
           VCMP_Team8Player3
            Calls: GUIUpdate_VCTechRaceColor(3)
           VCMP_Team8Player4
            Calls: GUIUpdate_VCTechRaceColor(4)
           VCMP_Team8Player5
            Calls: GUIUpdate_VCTechRaceColor(5)
           VCMP_Team8Player6
            Calls: GUIUpdate_VCTechRaceColor(6)
           VCMP_Team8Player7
            Calls: GUIUpdate_VCTechRaceColor(7)
           VCMP_Team8Player8
            Calls: GUIUpdate_VCTechRaceColor(8)
           VCMP_Team8PointGame
             VCMP_Team8Points
              Calls: GUIUpdate_GetTeamPoints()
             VCMP_Team8PointBG
         VCMP_Team3_Shade
         VCMP_Team2_Shade
         VCMP_Team4_Shade
         VCMP_Team5_Shade
         VCMP_Team6_Shade
         VCMP_Team7_Shade
         VCMP_Team8_Shade
	]]
end
function SW.RankSystem.OnRankUp( _pId)	--Gets called every time a player reaches a new rank; Currently empty
	
end


