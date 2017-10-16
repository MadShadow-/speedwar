SW = SW or {}
SW.LKavBuff = {}
SW.LKavBuff.FirstStrikeBonus = 30
SW.LKavBuff.FirstStrikeRecharge = 30
SW.LKavBuff.GoldPerKill = 30
SW.LKavBuff.MaxTimeDiff = 2
SW.LKavBuff.Looted = {}
for i = 1, 8 do
	SW.LKavBuff.Looted[i] = 0
end
SW.LKavBuff.GoodTypes = {
	[Entities.PU_LeaderCavalry1] = true,
	[Entities.PU_LeaderCavalry2] = true,
	[Entities.PU_SoldierCavalry1] = true,
	[Entities.PU_SoldierCavalry2] = true,
}
SW.LKavBuff.SoldierTypes = {}
function SW.LKavBuff.Init()
	for k,v in pairs(Entities) do
		if string.find(k, "Soldier") then
			SW.LKavBuff.SoldierTypes[v] = true
		end
	end
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
	local def = Event.GetEntityID2()
	--LuaDebugger.Log(att.." of type "..Logic.GetEntityTypeName(Logic.GetEntityType(att)).." attacking "..def.." of type "..Logic.GetEntityTypeName(Logic.GetEntityType(def)))
	if SW.LKavBuff.SoldierGetLeader(def) ~= 0 then
		local leader = SW.LKavBuff.SoldierGetLeader(def)
		local data = {Logic.GetSoldiersAttachedToLeader( leader)}
		for i = 2, data[1]+1 do
			SW.LKavBuff.LastAttacker[data[i]] = { att, time}
		end
		SW.LKavBuff.LastAttacker[leader] = { att, time}
	elseif Logic.IsLeader( def) == 1 then
		local data = {Logic.GetSoldiersAttachedToLeader( def)}
		for i = 2, data[1]+1 do
			SW.LKavBuff.LastAttacker[data[i]] = { att, time}
		end
		SW.LKavBuff.LastAttacker[def] = { att, time}
	else
		SW.LKavBuff.LastAttacker[def] = { att, time}
	end
	-- Now check for timer if attacker is LKav
	if SW.LKavBuff.GoodTypes[Logic.GetEntityType(att)] == nil then	--attacker is good type?
		return
	end
	if SW.LKavBuff.LastAttack[att] == nil then											--never attacked a settler?
		SW.LKavBuff.ApplyDamage( def, SW.LKavBuff.FirstStrikeBonus)
		SW.LKavBuff.LastAttack[att] = time
		return
	end
	if SW.LKavBuff.LastAttack[att] + SW.LKavBuff.FirstStrikeRecharge < time then     	--enough time went by?
		SW.LKavBuff.ApplyDamage( def, SW.LKavBuff.FirstStrikeBonus)
	end
	SW.LKavBuff.LastAttack[att] = time
end
function SW.LKavBuff.SoldierGetLeader(_eId)
	if SW.LKavBuff.SoldierTypes[Logic.GetEntityType(_eId)] then
		-- Index 127 via S5Hook.GetEntityMem
		return Logic.GetEntityScriptingValue( _eId, 69)
	else 
		return 0 
	end
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
	SW.PreciseLog.Log("LKav: Gold to "..attPId)
	AddGold( attPId, SW.LKavBuff.GoldPerKill)
	SW.LKavBuff.Looted[attPId] = SW.LKavBuff.Looted[attPId] + SW.LKavBuff.GoldPerKill
end
function SW.LKavBuff.ApplyDamage( _eId, _dmg)
	SW.PreciseLog.Log("LKav: Damaging ".._eId.." of type "..(Logic.GetEntityTypeName(Logic.GetEntityType(_eId)) or "unknown").." of player "..Logic.EntityGetPlayer(_eId))
	if SW.LKavBuff.SoldierGetLeader(_eId) ~= 0 then
		_eId = SW.LKavBuff.SoldierGetLeader(_eId)
		SW.LKavBuff.ApplyDamageToLeader( _eId, _dmg)
		return
	end
	if IsDead( _eId) then return end
	if Logic.IsLeader(_eId) == 1 then
		SW.LKavBuff.ApplyDamageToLeader( _eId, _dmg)
		return
	end
	SW.PreciseLog.Log("LKav: DirectHit")
	Logic.HurtEntity( _eId, _dmg)
end
function SW.LKavBuff.ApplyDamageToLeader( _eId, _dmg)
	if IsDead( _eId) then return end
	SW.PreciseLog.Log("LKav: Hurting ".._eId.." of type "..Logic.GetEntityTypeName(Logic.GetEntityType(_eId)).." like leader.")
	local typee = S5Hook.GetEntityMem( _eId)[31][3][0]:GetInt()
	if typee ~= 7823840 then
		SW.PreciseLog.Log("LKav: Tried to hurt nonleader like leader.")
		return
	end
	local solHP = S5Hook.GetEntityMem( _eId)[31][3][27]:GetInt()
	SW.PreciseLog.Log("LKav: SolHP"..solHP)
	if solHP >= _dmg then
		S5Hook.GetEntityMem( _eId)[31][3][27]:SetInt( solHP - _dmg)
	else
		S5Hook.GetEntityMem( _eId)[31][3][27]:SetInt(0)
		Logic.HurtEntity( _eId, math.min(_dmg - solHP, Logic.GetEntityHealth( _eId)-1))
	end
end
function SW.LKavBuff.Test(_s)
	local pos = GetPosition(GUI.GetSelectedEntity())
	if _s == "LKav" then
		for i = 1, 5 do
			Tools.CreateGroup( 1, Entities.PU_LeaderCavalry1, 3, pos.X, pos.Y, 0)
		end
	else
		for i = 1, 5 do
			Tools.CreateGroup( 2, Entities.PU_LeaderSword1, 4, pos.X, pos.Y, 0)
		end
	end
	SetHostile(1,2)
end
function SW.LKavBuff.GenerateArmies()
	local spawnA = { X = 32300, Y = 59200}
	local spawnB = { X = 26900, Y = 52300}
	for i = 1, 15 do
		Attack( Tools.CreateGroup( 1, Entities.PU_LeaderCavalry1, 3, spawnA.X, spawnA.Y, 0), spawnB)
		Attack( Tools.CreateGroup( 2, Entities.PU_LeaderCavalry1, 3, spawnB.X, spawnB.Y, 0), spawnB)
	end
	SetHostile( 1, 2)
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