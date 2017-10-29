SW = SW or {}

SW.HeadquarterUpgrade = {}
SW.HeadquarterUpgrade.CostUp1 = {
	[ResourceType.Gold] = 500,
	[ResourceType.Wood] = 400,
	[ResourceType.Clay] = 0,
	[ResourceType.Silver] = 0,
	[ResourceType.Stone] = 700,
	[ResourceType.Iron] = 0,
	[ResourceType.Sulfur] = 0
}
SW.HeadquarterUpgrade.CostUp2 = {
	[ResourceType.Gold] = 500,
	[ResourceType.Wood] = 400,
	[ResourceType.Clay] = 0,
	[ResourceType.Silver] = 0,
	[ResourceType.Stone] = 700,
	[ResourceType.Iron] = 0,
	[ResourceType.Sulfur] = 0
}
SW.HeadquarterUpgrade.WallBuildDuration = 30
SW.HeadquarterUpgrade.Up1Data = {}	--Entry: ListOfWalls, TimeSpent, Max, eId
function SW.HeadquarterUpgrade.UpgradeButtonHandler()
	if Logic.IsConstructionComplete( entityId) == 1 then
		XGUIEng.ShowWidget("Headquarter", 1)
		--XGUIEng.DoManualButtonUpdate(XGUIEng.GetWidgetID("Headquarter"));
		XGUIEng.ShowWidget("Buy_Hero", 0);
		XGUIEng.ShowWidget("Upgrade_Headquarter1", 0)
		XGUIEng.ShowWidget("Upgrade_Headquarter2", 0)
		-- Show tax menu if adjustable taxes are researched
		if Logic.GetTechnologyState( GUI.GetPlayerID(), Technologies.GT_Literacy) == 4 then
			XGUIEng.ShowWidget( "HQTaxes", 1)
		end
		XGUIEng.SetText("TaxLeaderSumOfPay", 0)		--Correct sum.
	end
end
function SW.HeadquarterUpgrade.StartBuildingWalls()
	
end


--Offsets for walls:
--		HQX +i*400, HQY +- 600
--		HQX +- 600, HQY +i*400

--[[
Headquarter
	Commands_Headquarter
		Upgrade_Headquarter1
			Calls: GUIAction_UpgradeSelectedBuilding()
			Calls: GUITooltip_UpgradeBuilding(Logic.GetEntityType(GUI.GetSelectedEntity()),"MenuHeadquarter/upgradeHeadquarter1_disabled","MenuHeadquarter/upgradeHeadquarter1_normal", Technologies.UP1_Headquarter)
			Calls: GUIUpdate_UpgradeButtons("Upgrade_Headquarter1", Technologies.UP1_Headquarter)
		Upgrade_Headquarter2
			Calls: GUIAction_UpgradeSelectedBuilding()
			Calls: GUITooltip_UpgradeBuilding(Logic.GetEntityType(GUI.GetSelectedEntity()),"MenuHeadquarter/upgradeHeadquarter2_disabled","MenuHeadquarter/upgradeHeadquarter2_normal", Technologies.UP2_Headquarter)
			Calls: GUIUpdate_UpgradeButtons("Upgrade_Headquarter2", Technologies.UP2_Headquarter)
		Research_Tracking
			Calls: GUIAction_ReserachTechnology(Technologies.T_Tracking)
			Calls: GUITooltip_ResearchTechnologies(Technologies.T_Tracking,"MenuHeadquarter/Tracking","KeyBindings/ReserachTechnologies1")
			Calls: GUIUpdate_GlobalTechnologiesButtons("Research_Tracking", Technologies.T_Tracking,Entities.PB_Headquarters1)
		Buy_Hero
			Calls: GUIAction_ToggleMenu( gvGUI_WidgetID.BuyHeroWindow,-1)
			Calls: GUITooltip_Generic("MenuHeadquarter/buy_hero")
			Calls: GUIUpdate_BuyHeroButton()
		ActivateAlarm
			Calls: GUIAction_ActivateAlarm()
			Calls: GUITooltip_Generic("MenuHeadquarter/ActivateAlarm")
			Calls: GUIUpdate_AlarmButton()
		Buy_Serf
			Calls: GUIAction_BuySerf()
			Calls: GUITooltip_BuySerf()
			Calls: GUIUpdate_BuildingButtons("Buy_Serf", Technologies.MU_Serf)
		HQ_Militia
			HQ_CallMilitia
				Calls: GUIAction_CallMilitia()
				Calls: GUITooltip_Generic("MenuHeadquarter/CallMilitia")
			HQ_BackToWork
				Calls: GUIAction_BackToWork()
				Calls: GUITooltip_Generic("MenuHeadquarter/BackToWork")
		HQTaxes
			SetLowTaxes
				Calls: GUIAction_SetTaxes(1)
				Calls: GUITooltip_Generic("MenuHeadquarter/SetLowTaxes")
				Calls: GUIUpdate_TaxesButtons()
			SetVeryLowTaxes
				Calls: GUIAction_SetTaxes(0)
				Calls: GUITooltip_Generic("MenuHeadquarter/SetVeryLowTaxes")
				Calls: GUIUpdate_TaxesButtons()
			SetNormalTaxes
				Calls: GUIAction_SetTaxes(2)
				Calls: GUITooltip_Generic("MenuHeadquarter/SetNormalTaxes")
				Calls: GUIUpdate_TaxesButtons()
			SetHighTaxes
				Calls: GUIAction_SetTaxes(3)
				Calls: GUITooltip_Generic("MenuHeadquarter/SetHighTaxes")
				Calls: GUIUpdate_TaxesButtons()
			SetVeryHighTaxes
				Calls: GUIAction_SetTaxes(4)
				Calls: GUITooltip_Generic("MenuHeadquarter/SetVeryHighTaxes")
				Calls: GUIUpdate_TaxesButtons()
		Levy_Duties
			Calls: GUIAction_LevyTaxes()
			Calls: GUITooltip_LevyTaxes()
		MilitiaUpdateButtonController
		QuitAlarm
			Calls: GUIAction_QuitAlarm()
			Calls: GUITooltip_Generic("MenuHeadquarter/QuitAlarm")
			Calls: GUIUpdate_AlarmButton()
		TaxesUpdateButtonController
			Calls: GUIUpdate_FeatureButtons("HQTaxes", Technologies.T_AdjustTaxes)
		TaxesAndPayStatistics
			TaxWorkerTooltip
				Calls: GUITooltip_Generic("MenuHeadquarter/TaxWorker")
			TaxLeaderTooltip
				Calls: GUITooltip_Generic("MenuHeadquarter/TaxLeader")
			TaxSumOfPaydayTooltip
				Calls: GUITooltip_Generic("MenuHeadquarter/TaxSumOfPayday")
			TaxWorkerAmount
				Calls: GUIUpdate_TaxWorkerAmount()
			TaxWorkerIcon
			TaxWorkerTaxes
				Calls: GUIUpdate_TaxTaxAmountOfWorker()
			TaxWorkerSumOfTaxes
				Calls: GUIUpdate_TaxSumOfTaxes()
			TaxLeaderIcon
			TaxLeaderSumOfPay
				Calls: GUIUpdate_TaxLeaderCosts()
			TaxLeaderPay
			TaxLeaderMultiply
			TaxLeaderAmount
				Calls: GUIUpdate_TaxLeaderAmount()
			TaxWorkerMultiply
			TaxWorkerEqual
			TaxLeaderEqual
			TaxSumOfPayday
				Calls: GUIUpdate_TaxPaydayIncome()
			TaxBar
]]