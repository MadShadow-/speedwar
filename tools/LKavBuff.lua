SW = SW or {}
SW.LKavBuff = {}
SW.LKavBuff.FirstStrikeBonus = 50
SW.LKavBuff.FirstStrikeRecharge = 30
SW.LKavBuff.GoldPerKill = 10
SW.LKavBuff.MaxTimeDiff = 2
SW.LKavBuff.GoodTypes = {
	[Entities.PU_LeaderCavalry1] = true,
	[Entities.PU_LeaderCavalry2] = true,
	[Entities.PU_SoldierCavalry1] = true,
	[Entities.PU_SoldierCavalry2] = true,
}
function SW.LKavBuff.Init()
	SW.LKavBuff.LastAttacker = {}
	SW.LKavBuff.LastAttack = {} --key = eId, value = timestamp
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_HURT_ENTITY, "SW_LKavBuff_IsSettlerA", "SW_LKavBuff_OnEntityHurtEntity", 1)
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_LKavBuff_IsSettler", "SW_LKavBuff_OnEntityDestroyed", 1)
end
function SW_LKavBuff_IsSettlerA() --Is settler attacked?
	if Logic.IsSettler(Event.GetEntityID2()) == 1 then
		return true
	end
	return false
end
function SW_LKavBuff_OnEntityHurtEntity()
	local time = Logic.GetTime()
	local att = Event.GetEntityID1()
	SW.LKavBuff.LastAttacker[Event.GetEntityID2()] = { att, time}
	-- Now check for timer if attacker is LKav
	if SW.LKavBuff.GoodTypes[Logic.GetEntityType(att)] == nil then	--attacker is good type?
		return
	end
	if SW.LKavBuff.LastAttack[att] == nil then											--never attacked a settler?
		SW.LKavBuff.ApplyDamage( Event.GetEntityID2(), SW.LKavBuff.FirstStrikeBonus)
		SW.LKavBuff.LastAttack[att] = time
		return
	end
	if SW.LKavBuff.LastAttack[att] + SW.LKavBuff.FirstStrikeRecharge < time then     	--enough time went by?
		SW.LKavBuff.ApplyDamage( Event.GetEntityID2(), SW.LKavBuff.FirstStrikeBonus)
	end
	SW.LKavBuff.LastAttack[att] = time
end
function SW_LKavBuff_IsSettler() --Is settler dying?
	if Logic.IsSettler(Event.GetEntityID()) == 1 then
		return true
	end
	return false
end
function SW_LKavBuff_OnEntityDestroyed()
	local lastHitter = SW.LKavBuff.LastAttacker[Event.GetEntityID()]
	if lastHitter == nil then													-- No data for this settler -> cancel
		return
	end
	if lastHitter[2] + SW.LKavBuff.MaxTimeDiff < Logic.GetTime() then			-- There was no real last hit -> cancel
		return
	end
	if IsDead(lastHitter[1]) then												-- The attacker died -> cancel to avoid errors
		return
	end
	if SW.LKavBuff.GoodTypes[Logic.GetEntityType(lastHitter[1])] == nil then	-- Attacker isnt LKav -> cancel
		return
	end
	--Everything ok? Give gold to attacker
	local attPId = GetPlayer(lastHitter[1])
	AddGold( attPId, SW.LKavBuff.GoldPerKill)
	if attPId == GUI.GetPlayerID() then
		Message("Eure leichte Kavallerie hat "..SW.LKavBuff.GoldPerKill.." Gold gefunden!")
	end
end
function SW.LKavBuff.ApplyDamage( _eId, _dmg)
	-- Zugriff auf SoldatenHP:
	-- S5Hook.GetEntityMem( _eId)[31][3][27]:GetInt()
	if Logic.IsLeader(_eId) == 1 or (string.find(Logic.GetEntityTypeName(Logic.GetEntityType(_eId)),"Soldier") ~= nil)then
		if true then return end
		local solHP = S5Hook.GetEntityMem( _eId)[31][3][27]:GetInt()
		if solHP >= _dmg then
			S5Hook.GetEntityMem( _eId)[31][3][27]:SetInt( solHP - _dmg)
		else
			S5Hook.GetEntityMem( _eId)[31][3][27]:SetInt(0)
			Logic.HurtEntity( _eId, math.min(_dmg - solHP, Logic.GetEntityHealth( _eId)-1))
		end
	else
		Logic.HurtEntity( _eId, _dmg)
	end
end

--TODO:
-- Fix crash
-- Make soldiers drop money too
-- Are serfs settlers?




--					OUTDATED
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