SW = SW or {}
SW.LKavBuff = {}
SW.LKavBuff.DropRate = 5
SW.LKavBuff.VisionRange= 30
SW.LKavBuff.VisionDuration = 60
function SW.LKavBuff.Init()

end

--Use bank buttons for LKav active
--[[Bank
             Commands_Bank
               Upgrade_Bank1
                 Calls: GUIAction_UpgradeSelectedBuilding()
                 Calls: GUITooltip_UpgradeBuilding(Logic.GetEntityType(GUI.GetSelectedEntity()),"MenuBank/Upgradebank1_disabled","MenuBank/UpgradeBank1_normal", Technologies.UP1_Bank)
                Calls: GUIUpdate_UpgradeButtons("Upgrade_Bank1", Technologies.UP1_Bank)
               Research_Debenture
                 Calls: GUIAction_ReserachTechnology(Technologies.T_Debenture)
                 Calls: GUITooltip_ResearchTechnologies(Technologies.T_Debenture,"MenuBank/Debenture")
               Research_BookKeeping
                 Calls: GUIAction_ReserachTechnology(Technologies.T_BookKeeping)
                 Calls: GUITooltip_ResearchTechnologies(Technologies.T_BookKeeping,"MenuBank/BookKeeping")
               Research_Scale
                 Calls: GUIAction_ReserachTechnology(Technologies.T_Scale)
                 Calls: GUITooltip_ResearchTechnologies(Technologies.T_Scale,"MenuBank/Scale")
               Research_Coinage
                 Calls: GUIAction_ReserachTechnology(Technologies.T_Coinage)
                 Calls: GUITooltip_ResearchTechnologies(Technologies.T_Coinage,"MenuBank/Coinage")]]