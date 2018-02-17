
MemList = { __index = function(t,k) return MemList[k] or t:get(k) end }
function MemList:new(mem, len) --len in bytes
    local bp, cp, ep = mem[1], mem[2], mem[3]
    
    -- (+) and (-) is not affected by DX fpu precision settings
    -- and the difference should be small enough to fit 24Bit ;)
    local cnt = math.floor((ep:GetInt() - bp:GetInt())/len) 
    local cap = math.floor((ep:GetInt() - bp:GetInt())/len)
    
    local obj = { Length = cnt, Capacity = cap, list = mem, idxLen = len/4, listStart = bp }
    setmetatable(obj, self)
    return obj
end

function MemList:get(n) -- zero based
    if n < self.Length then
        return self.listStart:Offset(n * self.idxLen)
    end
end

function MemList:iterate()
    local i, count = -1, self.Length
    return function() 
        i = i + 1
        if i < count then 
            return self:get(i)
        end
    end
end

--- mcbEMan   0.2.3b
-- Gesammelte Funktionen zum Manipulieren von Entitys und Entitytypen.
-- Das Ganze wird erweitert, wenn ich neue Funktionen brauche ;)
-- 
-- Entity-Funktionen (müssen nicht zurückgesetzt werden/Savegamesicher):
-- 
-- mcbEMan.GetLeaderExperience(id)					Gibt die Erfahrungspunkte des Leaders zurück.
-- mcbEMan.SetLeaderExperience(id, exper)			Setzt die Erfahrungspunkte des Leaders.
-- 
-- mcbEMan.GetLeaderTroopHealth(id)					Gibt die Gesundheit der Truppe des Leaders zurück (aufsummiert, ohne Leader).
-- mcbEMan.SetLeaderTroopHealth(id, tHealth)		Setzt die Gesundheit der Truppe.
-- 
-- mcbEMan.SetLeaderMaxSoldiers(id, sol)			Setzt die Maximalzahl der Soldaten des Leaders. (Get über Logic)
-- 
-- mcbEMan.GetEntityMaxRange(id)					Gibt die Maximale Reichweite des Entitys zurück (sv 49, wenn nicht gesetzt über Behavior)
-- 
-- mcbEMan.GetScale(id)								Gibt die Skalierung eines Entitys zurück. (Float, Standard 1.0)
-- mcbEMan.SetScale(id, scale)						Setzt die Skalierung des Entitys.
-- 
-- mcbEMan.GetEntityOverheadWidget(id)				Gibt den Typ der Anzeige über dem Entity zurück.
-- 														(0->nur Name, 1->Name+Bar (auch für nicht Leader), 2->Worker,
-- 														3->Name+Bar (nur Leader), 4->Nix)
-- mcbEMan.SetEntityOverheadWidget(id, widNum)		Setzt den Typ der Anzeige.
-- 
-- mcbEMan.GetEntityTargetPos(id)					Gibt die Position zurück, zu der sich das Entity bewegt.
-- 
-- mcbEMan.GetThiefInvisibleData(id)				Gibt isInvisible, timeToInvisible eines Diebes zurück.
-- 
-- mcbEMan.SetThiefInvisibleData(id, time)			Setzt die Zeit, bis ein Dieb wieder unsichtbar wird.
-- 														(Aktuelle Unsichtbarkeit an <==> time==0) (max 15).
-- 
-- mcbEMan.GetAriInvisibleData(id)					Gibt isInvisible, remainingInvisible Aris zurück.
-- mcbEMan.SetAriInvisibleData(id, time)			Setzt die Zeit, die Ari unsichtbar ist (max 90).
-- 
-- mcbEMan.ReanimateHero(id)						Belebt einen toten Helden wieder.
-- 														(Igoriert normalerweise feindliche Truppen).
-- 
-- mcbEMan.GetHeroReanimateTimer(id)				Gibt den Timer zurück, wann ein Held wiederbelebt wird. -1, wenn nicht tot.
-- mcbEMan.SetHeroReanimateTimer(id, tim)			Setzt den Timer (Nur wenn Held auch tot ist).
-- 
-- mcbEMan.GetEntityHealingPoints(id)				Gibt die Regenerationspunkte, Regenerationsdauer des Entitys zurück.
-- 
-- mcbEMan.GetEntityLimitedLifespanRemainingSeconds(id)
-- 													Gibt die Zeit, die dieses Entity noch zu leben hat zurück (Sekunden).
-- mcbEMan.SetEntityLimitedLifespanRemainingSeconds(id, seconds)
-- 													Setzt die Zeit, die dieses Entity noch zu leben hat. (0->nächster Tick tot).
-- 
-- 
-- Entity-Funktionen (müssen nicht zurückgesetzt werden/nicht savegamesicher ohne s5HookLoader):
-- 
-- mcbEMan.SetEntityDamage(id, dmg)					Setzt den Schaden eines Entitys. Kann mehrere Sekunden brauchen.
-- 														Wenn verändert, keine Modifikation durch Techs mehr.
-- 														Änderungen rückgängig machen mit dmg<0.
-- 
-- mcbEMan.SetEntityArmor(id, def)					Setzt die Rüstung eines Entitys. Kann mehrere Sekunden brauchen.
-- 														Wenn verändert, keine Modifikation durch Techs mehr.
-- 														Änderungen rückgängig machen mit def<0.
-- 
-- mcbEMan.SetEntityExploration(id, explo)			Setzt die Sichtweite eines Entitys. Kann mehrere Sekunden brauchen.
-- 														Wenn verändert, keine Modifikation durch Techs mehr.
-- 														Änderungen rückgängig machen mit explo<0.
-- 
-- mcbEMan.SetEntityMaxRange(id, range)				Setzt die maximale Angriffsreichweite. Kann mehrere Sekunden brauchen.
-- 														Das Entity muss bereits angegriffen haben, oder einen feindlichen Player haben.
-- 														Wenn verändert keine Modifikation durch Techs mehr.
-- 														Änderungen Rückgängig machen mit range<0.
-- 
-- mcbEMan.SetEntityHealingPoints(id, hp)			Setzt die Regenerationspunkte des Entitys. Kann mehrere Sekunden brauchen.
-- 														Das Entity muss schon einmal regeneriert haben, sonst gibt es einen Lua-Error.
-- 														Wenn verändert keine Modifikation durch Techs mehr.
-- 														Änderungen Rückgängig machen mit hp<0.
-- 
-- EntityTyp-Funktionen (müssen vor beenden der Map zurückgesetzt werden):
-- 
-- mcbEMan.GetEntityTypeLimitedLifespanTime(typ)	Gibt die Zeit zurück, die ein Entity dieses Typs zu leben hat (Sekunden).
-- mcbEMan.SetEntityTypeLimitedLifespanTime(typ, sec)
-- 													Setzt die Zeit, die ein Entity dieses Typs zu leben hat.
-- 
-- mcbEMan.GetEntityTypeUpkeepCost(typ)				Gibt die Kosten für einen Leader dieses Typs zurück (Taler/Zahltag).
-- mcbEMan.SetEntityTypeUpkeepCost(typ, cost)		Setzt die Kosten für einen Leader dieses Typs.
-- 
-- mcbEMan.GetEntityTypeBuildBlock(typ)				Gibt ein table mit 2 Positionstables zurück, die die Ecken des BuildBlockings des Typs festlegen.
-- mcbEMan.SetEntityTypeBuildBlock(typ, pTab)		Setzt das BuildBlocking (Format von pTab wie Get). Nach Anwendung sollte das Blocking der Map aktualisiert werden.
-- 
-- mcbEMan.GetEntityTypeBlocking(typ)				Gibt ein table mit tables mit 2 Positionstables zurück, die 2 Positionstables in jedem Untertable ergeben ein Teil-Rechteck des Blockings.
-- mcbEMan.SetEntityTypeBlocking(typ, bTab)			Setzt das Blocking. (Format von bTab wie Get). Die Anzahl der Blockingrechtecke kann nicht geändert werden (allerdings können einige auf 0/0 gesetzt werden).
-- 														 Nach Anwendung sollte das Blocking der Map aktualisiert werden.
-- 
-- mcbEMan.SetEntityTypeMaxHealth(typ, health)		Setzt die maximale Gesundheit eines EntityTyps. Nur bei Typen mit Gesundheit anwenden.
-- 
-- mcbEMan.activateETypeFixes()						Fixt mir bekannte Fehler in den Entity-xmls. (Bauer als Arbeiter im Wirtshaus,
-- 														CU_BanditLeaderSwordX kann keine Soldaten kaufen).
-- 														Wenn framework2 und s5HookLoader vorhanden sind, wird diese Funktion automatisch ausgeführt.
-- 
-- mcbEMan.GetEntityTypeSuspendedAnim(typ)			Gibt die Animation zurück, die bei suspendeten Entitys genutzt wird. (normalerweise idle1).
-- 
-- mcbEMan.GetEntityTypeBuilderSlots(typ)			Gibt die Positionen (X,Y,r) zurück, an denen Serfs ein Gebäude bauen können.
-- mcbEMan.SetEntityTypeBuilderSlots(typ, t)		Setzt die Baupositionen, unbegrenzte Menge. UnHackMalloc muss aufgerufen werden.
-- 
-- mcbEMan.UnHackMalloc()							Muss beim beenden der Map aufgerufen werden, vor dem Rücksetzen der Entitytypen,
-- 														um Speicherleks zu verhindern. (Automatisch bei framework2).
-- 
-- mcbEMan.GetEntityTypeRegenValues(typ)			Gibt regenerierte HP, Dauer zwischen Regenerationen zurück.
-- mcbEMan.SetEntityTypeRegenValues(typ, hp, sec)	Setzt die Regenerationswerte.
-- 
-- mcbEMan.activateBuildingForCB()					Modifiziert die Entitytypen von einigen CB_-Gebäuden so, das per Logic.CreateConstructionSite
-- 														gesetzte Gebäude von Serfs gebaut (+repariert) werden können. UnHackMalloc muss aufgerufen werden.
-- 
-- Benötigt:
-- - S5Hook ab v1.4b
-- - MemList
-- - framework2 (optional, setzt Entitytypen automatisch zurück)
-- - s5HookLoader (optional, automatische entityTyp-Fixes + entity-funktionen automatisch neu ausgeführt)
-- 
-- TODO:
-- - ClassVTable vervollständigen
-- - checkEntityMoving
mcbEMan = {}

function mcbEMan.SetLeaderExperience(id, exper)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	exper = math.floor(exper)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][3][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLeaderBehavior)
	sv[31][3][32]:SetInt(exper)
end
function mcbEMan.GetLeaderExperience(id)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][3][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLeaderBehavior)
	return sv[31][3][32]:GetInt()
end

function mcbEMan.SetLeaderTroopHealth(id, tHealth)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	tHealth = math.floor(tHealth)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][3][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLeaderBehavior)
	sv[31][3][27]:SetInt(tHealth)
end
function mcbEMan.GetLeaderTroopHealth(id)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][3][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLeaderBehavior)
	return sv[31][3][27]:GetInt()
end

function mcbEMan.SetLeaderMaxSoldiers(id, sol)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	sol = math.floor(sol)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][4][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLimitedAttachmentBehavior)
	sv[31][4][6][0][4]:SetInt(sol)
end

function mcbEMan.SetLeaderTargetOrientation(id, rot)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	rot = math.rad(rot)
	local sv = S5Hook.GetEntityMem(id)
	sv[69]:SetFloat(rot)
	sv[68]:SetInt(1)
end

function mcbEMan.GetEntityMaxRange(id)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	local sv = S5Hook.GetEntityMem(id)
	local v1 = sv[107]:GetFloat()
	if v1 > 0 then
		return v1
	end
	local lbeh = mcbEMan.SearchETypeBehaviorClassPointer(Logic.GetEntityType(id), mcbEMan.ClassVTable.GGL_CLeaderBehaviorProps)
	if not lbeh then
		return 0
	end
	return lbeh[23]:GetFloat()
end

function mcbEMan.GetEntityHealingPoints(id)
	id = GetID(id)
	assert(IsAlive(id))
	local sv = S5Hook.GetEntityMem(id)
	local r = sv[58+53]:GetFloat()
	local hp, sec = mcbEMan.GetEntityTypeRegenValues(Logic.GetEntityType(id))
	if r==-1 then
		return hp, sec
	end
	return r, sec
end

function mcbEMan.SetScale(id, scale)
	id = GetID(id)
	assert(IsAlive(id))
	assert(type(scale)=="number")
	local sv = S5Hook.GetEntityMem(id)
	sv[25]:SetFloat(scale)
end

function mcbEMan.GetScale(id)
	id = GetID(id)
	assert(IsAlive(id))
	local sv = S5Hook.GetEntityMem(id)
	return sv[25]:GetFloat()
end


function mcbEMan.SetEntityOverheadWidget(id, widNum)
	id = GetID(id)
	assert(IsAlive(id))
	assert(widNum==0 or widNum==1 or widNum==2 or widNum==3 or widNum==4)
	local sv = S5Hook.GetEntityMem(id)
	sv[130]:SetInt(widNum)
end

function mcbEMan.GetEntityOverheadWidget(id)
	id = GetID(id)
	assert(IsAlive(id))
	local sv = S5Hook.GetEntityMem(id)
	return sv[130]:GetInt()
end

function mcbEMan.GetThiefInvisibleData(id)
	id = GetID(id)
	assert(IsAlive(id))
	assert(IsEntityOfType(id, Entities.PU_Thief))
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][7][0]:GetInt()==mcbEMan.ClassVTable.GGL_CThiefCamouflageBehavior)
	--return sv[31][7][5]:GetInt(), sv[31][7][8]:GetInt(), sv[31][7][9]:GetInt()
	local isInvis = sv[31][7][8]:GetInt()==15
	local timeToInvis = sv[31][7][9]:GetInt()
	return isInvis, timeToInvis
end

function mcbEMan.SetThiefInvisibleData(id, timeToInvis)
	id = GetID(id)
	assert(IsAlive(id))
	assert(IsEntityOfType(id, Entities.PU_Thief))
	timeToInvis = math.floor(timeToInvis)
	assert(timeToInvis >= 0 and timeToInvis <= 15)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][7][0]:GetInt()==mcbEMan.ClassVTable.GGL_CThiefCamouflageBehavior)
	sv[31][7][8]:SetInt((timeToInvis==0) and 15 or 0)
	sv[31][7][9]:SetInt(timeToInvis)
end

function mcbEMan.GetAriInvisibleData(id)
	id = GetID(id)
	assert(IsAlive(id))
	assert(IsEntityOfType(id, Entities.PU_Hero5))
	local sv = S5Hook.GetEntityMem(id)[31][8]
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CCamouflageBehavior)
	local rem = sv[8]:GetInt()
	return rem>0, rem
end

function mcbEMan.SetAriInvisibleData(id, remInvis)
	id = GetID(id)
	assert(IsAlive(id))
	assert(IsEntityOfType(id, Entities.PU_Hero5))
	remInvis = math.floor(remInvis)
	assert(remInvis>=0 and remInvis<=90)
	local sv = S5Hook.GetEntityMem(id)[31][8]
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CCamouflageBehavior)
	sv[8]:SetInt(remInvis)
end

function mcbEMan.GetEntityLimitedLifespanRemainingSeconds(id)
	id = GetID(id)
	assert(IsAlive(id))
	local sv, index = mcbEMan.SearchETypeBehaviorClassPointer(Logic.GetEntityType(id), mcbEMan.ClassVTable.GGL_CLimitedLifespanBehaviorProps)
	assert(sv)
	sv = S5Hook.GetEntityMem(id)[31]
	assert(sv:GetInt(index/2)>0)
	assert(sv[index/2][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLimitedLifespanBehavior)
	return sv[index/2][5]:GetInt()
end

function mcbEMan.SetEntityLimitedLifespanRemainingSeconds(id, seconds)
	id = GetID(id)
	assert(IsAlive(id))
	seconds = math.floor(seconds)
	assert(seconds>=0)
	local sv, index = mcbEMan.SearchETypeBehaviorClassPointer(Logic.GetEntityType(id), mcbEMan.ClassVTable.GGL_CLimitedLifespanBehaviorProps)
	assert(sv)
	sv = S5Hook.GetEntityMem(id)[31]
	assert(sv:GetInt(index/2)>0)
	assert(sv[index/2][0]:GetInt()==mcbEMan.ClassVTable.GGL_CLimitedLifespanBehavior)
	return sv[index/2][5]:SetInt(seconds)
end

mcbEMan.HeroBehaviorOffset = {
	[Entities.PU_Hero1] = 3,
	[Entities.PU_Hero1a] = 3,
	[Entities.PU_Hero1b] = 3,
	[Entities.PU_Hero1c] = 3,
	[Entities.PU_Hero2] = 5,
	[Entities.PU_Hero3] = 5,
	[Entities.PU_Hero4] = 5,
	[Entities.PU_Hero5] = 5,
	[Entities.PU_Hero6] = 5,
	[Entities.PU_Hero10] = 5,
	[Entities.PU_Hero11] = 3,
	[Entities.CU_Barbarian_Hero] = 6,
	[Entities.CU_BlackKnight] = 5,
	[Entities.CU_Mary_de_Mortfichet] = 3,
	[Entities.CU_Evil_Queen] = 5,
}

function mcbEMan.ReanimateHero(id)
	id = GetID(id)
	assert(IsValid(id) and IsDead(id) and Logic.IsHero(id)==1)
	local sv = S5Hook.GetEntityMem(id)
	sv = sv[31][mcbEMan.HeroBehaviorOffset[Logic.GetEntityType(id)]]
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CHeroBehavior)
	sv[7]:SetInt(1)
	sv[5]:SetInt(10000)
end

function mcbEMan.GetHeroReanimateTimer(id)
	id = GetID(id)
	assert(IsValid(id) and Logic.IsHero(id)==1)
	if IsAlive(id) then
		return -1
	end
	local sv = S5Hook.GetEntityMem(id)
	sv = sv[31][mcbEMan.HeroBehaviorOffset[Logic.GetEntityType(id)]]
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CHeroBehavior)
	return sv[5]:GetInt()
end

function mcbEMan.SetHeroReanimateTimer(id, tim)
	id = GetID(id)
	assert(IsValid(id) and IsDead(id) and Logic.IsHero(id)==1)
	tim = math.floor(tim)
	assert(tim>=0 and tim<=10000)
	local sv = S5Hook.GetEntityMem(id)
	sv = sv[31][mcbEMan.HeroBehaviorOffset[Logic.GetEntityType(id)]]
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CHeroBehavior)
	sv[5]:SetInt(tim)
end

function mcbEMan.Inter_QuickFakeAttack(id)
	local p = GetPlayer(id)
	for i=1,8 do
		if Logic.GetDiplomacyState(p, i)==Diplomacy.Hostile then
			p = i
			break
		end
	end
	assert(p~=GetPlayer(id))
	local p = GetPosition(id)
	local tid = Logic.CreateEntity(Entities.PU_Serf, p.X, p.Y, 0, p)
	Logic.GroupAttack(id, tid)
	DestroyEntity(tid)
end

function mcbEMan.SetEntityDamage(id, dmg)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	dmg = round(dmg)
	if dmg < 0 then
		mcbEMan.Inter_RemoveBattleValue(id, 33)
		return
	end
	mcbEMan.Inter_AddBattleValue(id, 33, dmg, 12)
end

function mcbEMan.SetEntityMaxRange(id, range)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	assert(type(range)=="number")
	if S5Hook.GetEntityMem(id)[58+49]:GetFloat()==-1 then
		mcbEMan.Inter_QuickFakeAttack(id)
	end
	if range < 0 then
		mcbEMan.Inter_RemoveBattleValue(id, 49)
		return
	end
	mcbEMan.Inter_AddBattleValue(id, 49, range, 44)
end

function mcbEMan.SetEntityExploration(id, explor)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	assert(type(explor)=="number")
	if explor < 0 then
		mcbEMan.Inter_RemoveBattleValue(id, 47)
		return
	end
	mcbEMan.Inter_AddBattleValue(id, 47, explor, 40)
end

function mcbEMan.SetEntityArmor(id, def)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	def = round(def)
	if def < 0 then
		mcbEMan.Inter_RemoveBattleValue(id, 39)
		return
	end
	mcbEMan.Inter_AddBattleValue(id, 39, def, 24)
end

function mcbEMan.SetEntityHealingPoints(id, hp)
	id = GetID(id)
	assert(IsAlive(id) and Logic.IsLeader(id)==1)
	assert(S5Hook.GetEntityMem(id)[58+53]:GetFloat()~=-1)
	hp = round(hp)
	if hp < 0 then
		mcbEMan.Inter_RemoveBattleValue(id, 53)
		return
	end
	mcbEMan.Inter_AddBattleValue(id, 53, hp, 52)
end

mcbEMan.Inter_BattleValuesTab = {} -- {id, ind, val, orig, bp, orig2}
function mcbEMan.Inter_AddBattleValue(id, ind, val, bp)
	for _,t in ipairs(mcbEMan.Inter_BattleValuesTab) do
		if t.id==id and t.ind==ind then
			t.val = val
			return
		end
	end
	local orig = mcbEMan.Inter_RedirectBattlePointer(id, bp)
	local orig2 = S5Hook.GetEntityMem(id)[58+ind]:GetFloat()
	table.insert(mcbEMan.Inter_BattleValuesTab, {id=id, ind=ind, val=val, orig=orig, bp=bp, orig2=orig2})
	if not mcbEMan.Inter_JobBattleValueId then
		mcbEMan.Inter_JobBattleValueId = StartSimpleJob(mcbEMan.Inter_JobResetBattleValues)
	end
end

function mcbEMan.Inter_RemoveBattleValue(id, ind)
	for i=table.getn(mcbEMan.Inter_BattleValuesTab), 1, -1 do
		local t = mcbEMan.Inter_BattleValuesTab[i]
		if t.id == id and t.ind == ind then
			table.remove(mcbEMan.Inter_BattleValuesTab, i)
			mcbEMan.Inter_RedirectBattlePointer(id, ind, t.orig)
			S5Hook.GetEntityMem(t.id)[58+t.ind]:SetFloat(t.orig2)
		end
	end
end

function mcbEMan.Inter_ReloadBattleValues()
	local tab = mcbEMan.Inter_BattleValuesTab
	mcbEMan.Inter_BattleValuesTab = {}
	for _, t in ipairs(tab) do
		mcbEMan.Inter_AddBattleValue(t.id, t.ind, t.val, t.bp)
	end
end

function mcbEMan.Inter_JobResetBattleValues()
	for i=table.getn(mcbEMan.Inter_BattleValuesTab), 1, -1 do
		local t = mcbEMan.Inter_BattleValuesTab[i]
		if IsValid(t.id) then
			S5Hook.GetEntityMem(t.id)[58+t.ind]:SetFloat(t.val)
		else
			table.remove(mcbEMan.Inter_BattleValuesTab, i)
		end
	end
	if table.getn(mcbEMan.Inter_BattleValuesTab) == 0 then
		mcbEMan.Inter_JobBattleValueId = nil
		return true
	end
end

function mcbEMan.Inter_RedirectBattlePointer(id, ind, override)
	id = GetID(id)
	assert(IsAlive(id))
	local sv = S5Hook.GetEntityMem(id)
	local svbn = sv[58+22]
	local adr1 = svbn:Offset(ind/4)
	local ad22 = svbn[0]:GetInt()
	S5Hook.SetPreciseFPU()
	local val = override or ad22-100
	local r = adr1[0]:GetInt()
	adr1[0]:SetInt(val)
	return r
end

function mcbEMan.GetETypePointer()
	return S5Hook.GetRawMem(9002416)[0][16]
end

function mcbEMan.GetETypeLogicPointer(typ)
	assert(Logic.GetEntityTypeName(typ))
	return mcbEMan.GetETypePointer()[typ * 8 + 2]
end

function mcbEMan.GetETypeDisplayPointer(typ)
	assert(Logic.GetEntityTypeName(typ))
	return mcbEMan.GetETypePointer()[typ * 8 + 3]
end

function mcbEMan.GetETypeBehaviorPointer(typ)
	assert(Logic.GetEntityTypeName(typ))
	return mcbEMan.GetETypePointer()[typ * 8 + 5]
end

function mcbEMan.SetEntityTypeMaxHealth(typ, health)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	health = math.floor(health)
	sv[13]:SetInt(health)
end

function mcbEMan.GetEntityTypeRegenValues(typ)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CLeaderBehaviorProps)
	assert(sv)
	return sv[28]:GetInt(), sv[29]:GetInt()
end

function mcbEMan.SetEntityTypeRegenValues(typ, hp, sec)
	hp = math.floor(hp)
	sec = math.floor(sec)
	assert(hp >= 0 and sec > 0)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CLeaderBehaviorProps)
	assert(sv)
	sv[28]:SetInt(hp)
	sv[29]:SetInt(sec)
end

function mcbEMan.GetEntityTypeBuildBlock(typ)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	local t = {}
	t[1] = mcbEMan.ReadPos(sv:Offset(38))
	t[2] = mcbEMan.ReadPos(sv:Offset(40))
	return t
end

function mcbEMan.GetEntityTypeBlocking(typ)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	local t = {}
	local list = MemList:new(sv:Offset(34), 16)
	for bl in list:iterate() do
		table.insert(t, {mcbEMan.ReadPos(bl), mcbEMan.ReadPos(bl:Offset(2))})
	end
	return t
end

function mcbEMan.SetEntityTypeBuildBlock(typ, t)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	mcbEMan.WritePos(sv:Offset(38), t[1])
	mcbEMan.WritePos(sv:Offset(40), t[2])
end

function mcbEMan.SetEntityTypeBlocking(typ, t)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	local list = MemList:new(sv:Offset(34), 16)
	local i=1
	for bl in list:iterate() do
		mcbEMan.WritePos(bl, t[i][1])
		mcbEMan.WritePos(bl:Offset(2), t[i][2])
		i = i+1
	end
end

function mcbEMan.GetEntityTypeBuilderSlots(typ)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CGLBuildingProps)
	local t = {}
	local ml = MemList:new(sv:Offset(51), 12)
	for p in ml:iterate() do
		local i = mcbEMan.ReadPos(p)
		i.r = math.deg(p[2]:GetFloat())
		table.insert(t, i)
	end
	return t
end

function mcbEMan.SetEntityTypeBuilderSlots(typ, t)
	local sv = mcbEMan.GetETypeLogicPointer(typ)
	assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CGLBuildingProps)
	sv = sv:Offset(51)
	mcbEMan.HackMalloc(sv, 12, table.getn(t))
	local list = MemList:new(sv, 12)
	local i=1
	for bl in list:iterate() do
		mcbEMan.WritePos(bl, t[i])
		bl[2]:SetFloat(math.rad(t[i].r))
		i = i+1
	end
end

function mcbEMan.GetEntityTypeSuspendedAnim(typ)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CGLAnimationBehaviorExProps)
	assert(sv)
	return sv[4]:GetInt()
end

function mcbEMan.GetEntityTypeLimitedLifespanTime(typ)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CLimitedLifespanBehaviorProps)
	assert(sv)
	return sv[4]:GetInt()
end

function mcbEMan.SetEntityTypeLimitedLifespanTime(typ, lifespan)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CLimitedLifespanBehaviorProps)
	assert(sv)
	lifespan = math.floor(lifespan)
	assert(lifespan > 0)
	sv[4]:SetInt(lifespan)
end

function mcbEMan.GetEntityTypeUpkeepCost(typ)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CLeaderBehaviorProps)
	assert(sv)
	return sv[31]:GetFloat()
end

function mcbEMan.SetEntityTypeUpkeepCost(typ, cost)
	local sv = mcbEMan.SearchETypeBehaviorClassPointer(typ, mcbEMan.ClassVTable.GGL_CLeaderBehaviorProps)
	assert(sv)
	cost = math.floor(cost)
	assert(cost >= 0)
	return sv[31]:SetFloat(cost)
end

mcbEMan.ETypeMallocReset = {} -- pointer = {curr, start, end, end}

function mcbEMan.HackMalloc(sv, size, num)
	if mcbEMan.ETypeMallocReset[sv:GetInt()] then
		S5Hook.FreeMem(sv[1]:GetInt())
	else
		local mlrs = {}
		for i=0,3 do
			mlrs[i+1] = sv[i]:GetInt()
		end
		mcbEMan.ETypeMallocReset[sv:GetInt()] = mlrs
	end
	local p = S5Hook.ReAllocMem(0, size*num)
	local ep = size*num
	S5Hook.SetPreciseFPU()
	ep = ep + p
	sv[0]:SetInt(p)
	sv[1]:SetInt(p)
	sv[2]:SetInt(ep)
	sv[3]:SetInt(ep)
end

function mcbEMan.UnHackMalloc()
	for point, itab in pairs(mcbEMan.ETypeMallocReset) do
		local sv = S5Hook.GetRawMem(point)
		for i=0,3 do
			sv[i]:SetInt(itab[i+1])
		end
	end
end

function mcbEMan.ReadPos(sv)
	return {X=sv[0]:GetFloat(), Y=sv[1]:GetFloat()}
end

function mcbEMan.WritePos(sv, p)
	assert(type(p.X)=="number" and type(p.Y)=="number")
	sv[0]:SetFloat(p.X)
	sv[1]:SetFloat(p.Y)
end

function mcbEMan.SearchETypeBehaviorClassPointer(typ, class)
	assert(Logic.GetEntityTypeName(typ))
	local sv = mcbEMan.GetETypePointer()
	local ind = typ * 8 + 5
	local number = (sv[ind+2]:GetInt() - sv[ind]:GetInt()) / 4
	for i=0,number-1 do
		if sv[ind][i]:GetInt()>0 and sv[ind][i][0]:GetInt()==class then
			return sv[ind][i], i
		end
	end
end

function mcbEMan.SearchEntityBehaviorClassPointer(id, class)
	id = GetID(id)
	assert(IsAlive(id))
	local sv = S5Hook.GetEntityMem(id)
	local number = (sv[32]:GetInt() - sv[31]:GetInt()) / 4
	for i=0,number-1 do
		if sv[31][i]:GetInt()>0 and sv[31][i][0]:GetInt()==class then
			return sv[31][i], i
		end
	end
end

function mcbEMan.activateETypeFixes()
	-- PB_Tavern2 worker to PU_TavernBarkeeper
	mcbEMan.GetETypeLogicPointer(Entities.PB_Tavern2)[45]:SetInt(Entities.PU_TavernBarkeeper)
	
	-- adding entries for buying soldiers to CU_BanditLeaderSwordX
	local svo = mcbEMan.GetETypeBehaviorPointer(Entities.PU_LeaderSword1)[6]
	for _,ety in {Entities.CU_BanditLeaderSword1, Entities.CU_BanditLeaderSword2} do
		local sv = mcbEMan.GetETypeBehaviorPointer(ety)[6]
		sv[26]:SetInt(svo[26]:GetInt()) -- building type
		sv[27]:SetInt(svo[27]:GetInt()) -- homeRadius
	end
	svo = mcbEMan.GetETypeLogicPointer(Entities.PU_SoldierSword1)
	for _,ety in {Entities.CU_BanditSoldierSword1, Entities.CU_BanditSoldierSword2} do
		local sv = mcbEMan.GetETypeLogicPointer(ety)
		sv[41]:SetInt(svo[41]:GetInt()) -- cost gold
		sv[47]:SetInt(svo[47]:GetInt()) -- cost iron
	end
end

mcbEMan.buildingForCB = {
	[Entities.CB_Mint1] = {
		time = 110,
		site = Entities.ZB_ConstructionSiteMint1,
		bsl = {
			{X=100,Y=-700,r=90},
			{X=-100,Y=-700,r=90},
			{X=-600,Y=-300,r=0},
			{X=-600,Y=300,r=0},
		},
	},
	[Entities.CB_SteamMashine] = {
		time = 10,
		site = Entities.ZB_ConstructionSiteTower1,
		bsl = {
			{X=-200,Y=200,r=10},
		},
	},
	[Entities.CB_Bastille1] = {
		time = 40,
		site = Entities.ZB_ConstructionSiteTower1,
		bsl = {
			{X=-200,Y=-400,r=90},
			{X=-100,Y=-400,r=90},
			{X=-400,Y=-100,r=0},
			{X=-400,Y=100,r=0},
		},
	},
	[Entities.CB_BarmeciaCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
	[Entities.CB_CleycourtCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
	[Entities.CB_CrawfordCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
	[Entities.CB_DarkCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
	[Entities.CB_FolklungCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
	[Entities.CB_KaloixCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
	[Entities.CB_OldKingsCastle] = {
		time = 110,
		site = Entities.ZB_ConstructionSite4,
		bsl = {
			{X=200,Y=-800,r=90},
			{X=-500,Y=-800,r=90},
			{X=-800,Y=-300,r=0},
			{X=-800,Y=300,r=0},
			{X=-500,Y=800,r=290},
			{X=300,Y=800,r=290},
		},
	},
}

function mcbEMan.activateBuildingForCB()
	for ety, t in pairs(mcbEMan.buildingForCB) do
		local sv = mcbEMan.GetETypeLogicPointer(ety)
		assert(sv[0]:GetInt()==mcbEMan.ClassVTable.GGL_CGLBuildingProps)
		sv[55]:SetInt(t.time)
		sv[74]:SetInt(t.site)
		mcbEMan.SetEntityTypeBuilderSlots(ety, t.bsl)
	end
end

function mcbEMan.getEntityTargetPos(id)
	assert(IsAlive(id))
	return mcbEMan.ReadPos(S5Hook.GetEntityMem(GetID(id)):Offset(66))
end

function mcbEMan.checkEntityMoving()
	EntityFind.GetEntities(1, function(id)
		if Logic.IsSettler(id)==0 then
			return
		end
		if Logic.GetSector(id)==0 then
			return
		end
		local sv = S5Hook.GetEntityMem(id)
		local z, bl, sec = S5Hook.GetTerrainInfo(sv[66]:GetFloat(), sv[67]:GetFloat()) -- TODO position of target id
		if sec~=Logic.GetSector(id) then
			Message("Found: "..id)
			Logic.GroupDefend(id) --4E745B
		end
	end)
end

mcbEMan.ClassVTable = {
	GGL_CLeaderBehaviorProps = tonumber("775FA4", 16),
	GGL_CLeaderBehavior = tonumber("7761E0", 16),
	
	GGL_CLimitedAttachmentBehavior = tonumber("775E84", 16),
	
	GGL_CGLBehaviorAnimationEx = tonumber("776B64", 16),
	GGL_CGLAnimationBehaviorExProps = tonumber("776C48", 16),
	
	GGL_CThiefCamouflageBehavior = tonumber("00773934", 16),
	
	GGL_CHeroBehavior = tonumber("0077677C", 16),
	
	GGL_CCamouflageBehavior = tonumber("007738F4", 16),
	
	GGL_CGLBuildingProps = tonumber("76EC78", 16),
	
	GGL_CLimitedLifespanBehaviorProps = tonumber("775DE4", 16),
	GGL_CLimitedLifespanBehavior = tonumber("775D9C", 16),
}

if framework2 and s5HookLoader then
	table.insert(framework2.map.endCallback, function()
		mcbEMan.UnHackMalloc()
		S5Hook.ReloadEntities()
	end)
	table.insert(s5HookLoader.cb, function()
		mcbEMan.activateETypeFixes()
		mcbEMan.Inter_ReloadBattleValues()
	end)
elseif LuaDebugger.Log then
	LuaDebugger.Log("mcbEMan: framework2 or s5HookLoader not found, no automatic eType fix/reset!")
end

--- mcbAnim    1.0
-- Ermöglicht es eine Animation eines Entitys gezielt per Script abzuspielen.
-- Dabei wird TaskLists.TL_MILITARY_IDLE jeden Tick gesetzt.
-- Am ersten Tick nach dem Aufruf wird die Animation zurückgesetzt, beim nächsten Tick startet die gesetzte Animation.
-- 
-- Parameter:
-- - id: EntityId des zu animierenden Ziels
-- - anim: Animation, animTable.EntityTypeString.Anim (nicht geprüft)
-- - speed: Animationsgeschwindigkeit als Float, 1.0 normal
-- - back: Rückwärtsabspielen der Animation true/false
-- - funcs: table mit "Animationspunkten" t[x] wird x Ticks nach dem Start der Animation aufgerufen (id, tick, unpack(arg)).
-- 				Gibt t[x] true zurück, wird die Animation beendet. (jedes x optional)
-- - dead: Wird aufgerufen, wenn id vor Animationsende stirbt (id, unpack(arg)). Animation wird danach beendet.
-- - escape: Jeden Tick vor dem Setzen der Animation aufgerufen (id, tick, unpack(arg)).
-- 				Wird true zurückgegeben, wird die Animation beendet. (Optional)
-- 
-- Benötigt:
-- - S5Hook ab v1.2
-- - Trigger-Fix
-- - mcbEMan (ClassVTable)
-- - animTable (empfohlen)
function mcbAnim(id, anim, speed, back, funcs, dead, escape, ...)
	assert(IsValid(id))
	local id = GetID(id)
	local sv = S5Hook.GetEntityMem(id)
	assert(sv[31][0][0]:GetInt() == mcbEMan.ClassVTable.GGL_CGLBehaviorAnimationEx)
	assert(type(anim)=="number")
	assert(type(speed)=="number")
	Logic.SetTaskList(id, TaskLists.TL_MILITARY_IDLE)
	local t = {id=id,anim=anim,speed=speed,back=back,funcs=funcs,t=-1,arg=arg,dead=dead,escape=escape}
	StartSimpleHiResJob(function(t)
		t.t = t.t + 1
		if IsDead(t.id) then
			t.dead(t.id, unpack(t.arg))
			return true
		end
		if t.escape then
			local r, r2 = t.escape(t.id, t.t, unpack(t.arg))
			if r then
				if not r2 then
					Logic.SetTaskList(t.id, TaskLists.TL_MILITARY_IDLE)
					Logic.GroupDefend(t.id)
				end
				return true
			end
		end
		if t.funcs[t.t] then
			if t.funcs[t.t](t.id, t.t, unpack(t.arg)) then
				Logic.SetTaskList(t.id, TaskLists.TL_MILITARY_IDLE)
				Logic.GroupDefend(t.id)
				return true
			end
		end
		local sv = S5Hook.GetEntityMem(id)
		Logic.SetTaskList(t.id, TaskLists.TL_MILITARY_IDLE)
		if t.t==0 then
			return
		end
		if not t.sTur then
			t.sTur = Logic.GetCurrentTurn()
		end
		sv[31][0][4]:SetInt(t.anim)
		sv[31][0][7]:SetInt(t.sTur)
		sv[31][0][9]:SetInt(t.back and 1 or 0)
		sv[31][0][11]:SetFloat(t.speed)
	end, t)
	return t
end

function test1()
    --[[
            VTable  Class                           X2O Def     Derived from   
            76E47C  EGL::CGLEEntityProps            85DDC8      BB::IObject
            776FEC  GGL::CEntityProperties          875DA8      EGL::CGLEEntityProps        //used for ressourcetree
            76E498  GGL::CGLSettlerProps            85E260      EGL::CGLEEntityProps    
            779074  GGL::CGLAnimalProps             87C5F8      EGL::CGLEEntityProps
            76EB38  GGL::CBuildBlockProperties      85F4F0      EGL::CGLEEntityProps
            76FF68  GGL::CResourceDoodadProperties  8635E0      GGL::CBuildBlockProperties
            76EC78  GGL::CGLBuildingProps           85F640      GGL::CBuildBlockProperties
            778148  GGL::CBridgeProperties          878908      GGL::CGLBuildingProps
    ]]--
    return ReadX2O(S5Hook.GetRawMem(tonumber("85E260", 16)))
end

function ReadX2O(base)
    local n = 0
    local lst = {}
    
    while true do
        local typ = base[n]:GetInt() --2: direct value, 3: embedded/linked object
        if typ == 0 then break end
        
        local namefield, name = base[n+1]
        if namefield:GetInt() == 0 then
            name = n --unnamed field
        else
            name = namefield:GetString()
        end
        
        local pos = base[n+2]:GetInt()
        local len = base[n+3]:GetInt()
        local subElmDef = base[n+5]
        local listOps = base[n+7]
        
        local entry = { Length = len, RelativePos = pos }
        
        if subElmDef:GetInt() ~= 0 then
            entry.SubData9999 = ReadX2O(subElmDef)
        end
        
        if listOps:GetInt() ~= 0 then
            name = "ListOf__" .. name
        end
        
        lst[name] = entry
        n = n + 9
    end
    
    return lst
end
