function SW.SetupMPLogic()
	if SW.IsMultiplayer() == false then
		return
	end
	--gvMission = gvMission or {};
	--gvMission.PlayerID = GUI.GetPlayerID();
	local playerId;
	for i = 1, table.getn(SW.Players) do
		playerId = SW.Players[i];
		if XNetwork.GameInformation_IsHumanPlayerAttachedToPlayerID(playerId) == 1 then
			Logic.SetPlayerRawName( playerId, XNetwork.GameInformation_GetLogicPlayerUserName( playerId ) );
			Logic.PlayerSetGameStateToPlaying(playerId);	
			Logic.PlayerSetIsHumanFlag(playerId, 1);
			
			local r,g,b = GUI.GetPlayerColor( playerId );
			Logic.PlayerSetPlayerColor( playerId, r, g, b);
		else
			MultiplayerTools.RemoveAllPlayerEntities( playerId );
		end
	end
	local players = table.getn(SW.Players);
	local team = XNetwork.GameInformation_GetLogicPlayerTeam;
	local player1, player2;
	for i = 1, players do
		for j = i+1, players do
			player1 = SW.Players[i];
			player2 = SW.Players[j];
			if team(player1) == team(player2) then
				Logic.SetShareExplorationWithPlayerFlag( player1, player2, 1 );
				Logic.SetShareExplorationWithPlayerFlag( player2, player1, 1 );
				Logic.SetDiplomacyState( player1, player2, Diplomacy.Friendly );
			else
				Logic.SetDiplomacyState( player1, player2, Diplomacy.Hostile );
			end
		end
	end
	
	XGUIEng.ShowWidget(gvGUI_WidgetID.NetworkWindowInfoCustomWidget,1)	
	
	--Extra keybings only in MP 
	Input.KeyBindDown(Keys.NumPad0, "KeyBindings_MPTaunt(1,1)", 2)  --Yes
	Input.KeyBindDown(Keys.NumPad1, "KeyBindings_MPTaunt(2,1)", 2)  --No
	Input.KeyBindDown(Keys.NumPad2, "KeyBindings_MPTaunt(3,1)", 2)  --Now	
	Input.KeyBindDown(Keys.NumPad3, "KeyBindings_MPTaunt(7,1)", 2)  --help
	Input.KeyBindDown(Keys.NumPad4, "KeyBindings_MPTaunt(8,1)", 2)  --clay
	Input.KeyBindDown(Keys.NumPad5, "KeyBindings_MPTaunt(9,1)", 2)  --gold
	Input.KeyBindDown(Keys.NumPad6, "KeyBindings_MPTaunt(10,1)", 2) --iron	
	Input.KeyBindDown(Keys.NumPad7, "KeyBindings_MPTaunt(11,1)", 2) --stone
	Input.KeyBindDown(Keys.NumPad8, "KeyBindings_MPTaunt(12,1)", 2) --sulfur
	Input.KeyBindDown(Keys.NumPad9, "KeyBindings_MPTaunt(13,1)", 2) --wood
	
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad0, "KeyBindings_MPTaunt(5,1)", 2)  --attack here
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad1, "KeyBindings_MPTaunt(6,1)", 2)  --defend here
	
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad2, "KeyBindings_MPTaunt(4,0)", 2)  --attack you
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad3, "KeyBindings_MPTaunt(14,0)", 2) --VeryGood
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad4, "KeyBindings_MPTaunt(15,0)", 2) --Lame
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad5, "KeyBindings_MPTaunt(16,0)", 2) --funny comments 
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad6, "KeyBindings_MPTaunt(17,0)", 2) --funny comments 
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad7, "KeyBindings_MPTaunt(18,0)", 2) --funny comments 
	Input.KeyBindDown(Keys.ModifierControl + Keys.NumPad8, "KeyBindings_MPTaunt(19,0)", 2) --funny comments 

	
	SW.MPGame_ApplicationCallback_PlayerLeftGame = MPGame_ApplicationCallback_PlayerLeftGame;
	MPGame_ApplicationCallback_PlayerLeftGame = function ( _PlayerID, _Misc )
		for i = 1, table.getn(SW.Players) do
			if SW.Players[i] == _PlayerID then
				table.remove(SW.Players, i);
			end
		end
		if SW.DefeatConditionPlayerStates[_PlayerID] then
			SW.DefeatConditionPlayerStates[_PlayerID] = false
			SW.DefeatConditionOnPlayerDefeated( _PlayerID)
		end
		SW.MPGame_ApplicationCallback_PlayerLeftGame(_PlayerID, _Misc);
	end

	-- No nil-error on game call VC_Deathmatch()
	function VC_Deathmatch()
	end

	MultiplayerTools.RemoveAllPlayerEntities = function( _pId)
		if GUI.GetPlayerID() == _pId then
			Message("Weichei. Geh da raus und MACH DIE KAPUTT!")
		end
	end
end
