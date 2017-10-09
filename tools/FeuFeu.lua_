--	Comfort: ExpandingFire
--		ExpandingFire:Init{}:
--			Initialisiert ExpandingFire, muss manuell aufgerufen werden!
--			Parameter:
--				Ein Table mit folgenden möglichen/optionalen Einträgen:
--				LeapRange: Bis wie weit das Feuer überspringen kann, in Siedlercm
--				FireDamage: Wie viel Schaden das Feuer pro Sekunde anrichtet, in Promille der maximalen HP
--				LeapChance: Wie hoch ist die Chance, dass das Feuer bei maximaler Reichweite überspringt?
--				LeapChanceOnCollaps: Wie hoch ist die Chance, dass sich das Feuer bei maximaler Reichweite ausbreitet, wenn das Gebäude abbrennt?
--				ErrLvl: Gibt an, wie Statusmeldungen herausgegeben werden:
--					1: Ausgabe mit Message
--					2: Ausgabe mit Fehlermeldung/debugscript	Würde ich nicht verwenden ;)	
--					3: Ausgabe mit LuaDebugger.Log 
--					sonst: Keine Ausgabe	
--				BurnableBuildings: Table, welches Entitytypes enthält, die neben den PB-Gebäuden brennen soll		
--		
--		ExpandingFire:IgniteBuilding( _eId):
--			Zündet ein Gebäude an
--			Parameter:
--				_eId: EntityId des anzuzündenden Gebäudes
--
--		ExpandingFire:SetTypeBurnable( _eType):
--			Der übergebene EntityTyp kann angezündet werden. PB-Gebäude sind durch die Standardeinstellung schon brennbar
--			Parameter:
--				_eType: EntityTyp 
--		
--		ExpandingFire:SetTypeUnBurnable( _eType):
--			Gebäude dieser EntityType können nicht mehr angezündet werden, brennende Gebäude brennen trotzdem weiter
--			Parameter:
--				_eType: EntityTyp
--		
--		ExpandingFire:IsBurning( _eId):
--			Fragt ab, ob ein Gebäude gerade brennt. Falls ja, wird true zurückgegeben, sonst false
--			Parameter:
--				_eId: EntityID des Gebäudes
--
--		ExpandingFire:GetNumberOBurningBuildings():	
--			Gibt zurück, wie viele Gebäude gerade brennen
--		
--		ExpandingFire:Shutdown():
--			Deaktiviert das Feuersystem. Brennende Gebäude verlieren nicht weiter HP und das Feuer springt auch nicht mehr über.
--			Dieser Befehl sollte nur einmal verwendet werden, ein erneuter Start ist momentan nicht möglich.
ExpandingFire = {}
ExpandingFire.LeapRange = 5000
--Leapchance in Promille pro Sekunde
ExpandingFire.LeapChance = 10
--Schaden, der pro Sekunde gegen brennende Gebäude angerichtet wird, in Promille des maximalen Lebens
ExpandingFire.FireDamage = 4
--Chance, dass das Feuer bei maximaler Reichweite überspringt, sobald das Gebäude einstürzt
ExpandingFire.LeapChanceOnCollaps = 50
--Enthält die IDs aller brennenden Gebäude
ExpandingFire.Burning = {}
ExpandingFire.AffectedPlayers = {1}
ExpandingFire.ErrLvl = 0
--Bei Init werden alle PB-Gebäude auf Burnable gesetzt
ExpandingFire.Burnable = {}
ExpandingFire.ListOfBuildings = {}
ExpandingFire.Metrik = {}
function ExpandingFire:Init(_paramTable)
	if self.Initialized then
		self:DbgMsg("ExpandingFire wurde schon initialisiert!")
	end
	self.Initialized =  true
	for k, v in pairs(Entities) do
		local eName = Logic.GetEntityTypeName(v)
		local found = string.find(eName, "PB")
		if found ~= nil then
			if eName ~= "PB_Tower2_Ballista" and eName ~= "PB_Tower3_Cannon" and eName ~= "PB_DarkTower2_Ballista" and eName ~= "PB_DarkTower3_Cannon" then --BlackList
				table.insert(self.Burnable, v)
			end
		end
	end
	--Füge EntityTypes von außen hinzu
	if _paramTable.BurnableBuildings ~= nil then
		if type(_paramTable.BurnableBuildings) == "table" then
			for k,v in pairs(_paramTable.BurnableBuildings) do
				table.insert(self.Burnable, v)
			end
		end
	end
	--Übernehme Parameter von außen, falls vorhanden
	local params = {"FireDamage", "LeapRange", "LeapChance", "LeapChanceOnCollaps", "ErrLvl", "AffectedPlayers"}
	for k,v in pairs(params) do
		if _paramTable[v] ~= nil then
			self[v] = _paramTable[v]
		end
	end
	--Update Gebäudeliste
	for k, v in pairs(self.Burnable) do
		for k3, v3 in pairs(self.AffectedPlayers) do
			local myEntities = self:GetAllEntitiesOfPlayerOfType( v3, v)
			--local myEntities = {}
			if table.getn(myEntities) ~= 0 then
				self:DbgMsg("Found "..table.getn(myEntities).." Entities for Type "..Logic.GetEntityTypeName(v).." for player "..v3)
			end
			for k2, v2 in pairs(myEntities) do
				table.insert(self.ListOfBuildings, v2)
			end
		end
	end
	--Update Metrik
	self:RecreateMetrik()
	self.SJobId = StartSimpleJob("ExpandingFire_Job")
	self.OECTrigger = Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, "ExpandingFire_IsEventInteresting", "ExpandingFire_OnEntityCreated", 1)
	self.OEDTrigger = Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, "ExpandingFire_IsEventInteresting", "ExpandingFire_OnEntityDestroyed", 1)
	--Anti-Abriss-Hack
	self.GUI_SellBuilding = GUI.SellBuilding
	GUI.SellBuilding = function(_eId)
		if ExpandingFire:IsBurning( _eId) then
			Message("Ihr könnt das Gebäude nicht abreissen, es brennt!")
			Sound.PlayGUISound(Sounds.VoicesLeader_LEADER_NO_rnd_01)
		else
			ExpandingFire.GUI_SellBuilding(_eId)
		end
	end
	self.GameCallback_OnBuildingConstructionComplete = GameCallback_OnBuildingConstructionComplete
	GameCallback_OnBuildingConstructionComplete  = function( _eId, _pId)
		ExpandingFire.GameCallback_OnBuildingConstructionComplete( _eId, _pId)
		--self:DbgMsg("Gebaude ".._eId.." von Spieler ".._pId.." ist fertig!")
		if ExpandingFire:IsBurning(_eId) then
			local maxHealth = Logic.GetEntityMaxHealth( _eId)
			local targetHealth = math.floor(maxHealth/4)
			local currentHealth = Logic.GetEntityHealth( _eId)
			Logic.HurtEntity( _eId, currentHealth - targetHealth)
		end
	end
	--Klinke dich in Upgrades rein
	self.GameCallback_OnBuildingUpgradeComplete = GameCallback_OnBuildingUpgradeComplete
	GameCallback_OnBuildingUpgradeComplete = function( _oldId, _newId)
		ExpandingFire_OnEntityCreated( _newId)
		self:DbgMsg("Upgrade found! ".._oldId.." to ".._newId)
		if self:IsBurning( _oldId) then --erhalten bleibt actualHP / maxHP bei Upgrade
			self:Ignite( _newId)
		end
		ExpandingFire_OnEntityDestroyed( _oldId)
		self.GameCallback_OnBuildingUpgradeComplete( _oldId, _newId)
	end
end
function ExpandingFire:IsPlayerAffected(_pId)
	local affected = false
	for k,v in pairs(ExpandingFire.AffectedPlayers) do
		if v == _pId then
			affected = true
			break
		end
	end
	return affected
end
function ExpandingFire:IgniteBuilding(_eID)
	if type(_eID) == "string" then
		_eID = GetEntityId( _eID)
	end
	if type(_eID) ~= "number" then
		self:DbgMsg("ExpandingFire:IgniteBuilding hat einen falschen Parameter erhalten!")
		return
	end
	if Logic.IsBuilding(_eID) == 0 then
		self:DbgMsg("ExpandingFire:IgniteBuilding hat einen Parameter erhalten, der kein Gebäude ist!")
		return
	end
	if not self:IsPlayerAffected(GetPlayer(_eID)) then
		self:DbgMsg("ExpandingFire:IgniteBuilding hat einen Parameter erhalten, der nicht zu einem betroffenen Spieler gehört!")
		return
	end
	--Alles gecheckt! Burn the thing down!
	self:Ignite(_eID)
end
function ExpandingFire:Ignite(_eID) --intern
	--Verringere Health des Ziels
	local maxHealth = Logic.GetEntityMaxHealth( _eID)
	if Logic.IsConstructionComplete( _eID) == 0 then
		maxHealth = math.floor(maxHealth / 4)
	end
	local targetHealth = math.floor(maxHealth/2)
	local currentHealth = Logic.GetEntityHealth( _eID)
	if currentHealth - targetHealth > 0 then
		Logic.HurtEntity( _eID, currentHealth - targetHealth)
	end
	--Nehme EntityId in Table aller brennenden Entities auf
	table.insert(self.Burning, _eID)
	if Logic.GetEntityTypeName(Logic.GetEntityType(_eID)) == nil then
		self:DbgMsg("Gebaeude ".._eID.." vom Typ UBEKANNT brennt jetzt!")
	else
		self:DbgMsg("Gebaeude ".._eID.." vom Typ "..Logic.GetEntityTypeName(Logic.GetEntityType(_eID)).." brennt jetzt!")
	end
end
function ExpandingFire:SetTypeBurnable(_eType)
	--Überprüfe, ob EntityType gültig ist
	if not self:IsValidEntityType( _eType) then
		self:DbgMsg("ExpandingFire:SetTypeBurnable hat einen ungültigen Parameter erhalten.")
		return
	end
	for k,v in pairs(self.Burnable) do
		if v == _eType then
			self:DbgMsg("ExpandingFire:SetTypeBurnable: Der EntityType "..Logic.GetEntityTypeName(v).." ist schon brennbar!")
			return
		end
	end
	--Füge zum Table hinzu
	table.insert(self.Burnable, _eType)
	--Update Gebäudeliste + Metrik
	for k2, v2 in pairs(self.AffectedPlayers) do
		local myEntities = self:GetAllEntitiesOfPlayerOfType( v2, _eType)
		for k,v in myEntities do
			self:AddToListOfBuildings( v)
		end
	end
end
function ExpandingFire:SetTypeUnBurnable(_eType)
	if not self:IsValidEntityType( _eType) then
		self:DbgMsg("ExpandingFire:SetTypeUnBurnable hat Parameter erhalten, der kein EntityType ist.")
		return
	end
	--Lösche eType aus Burnable-Table
	--for k,v in pairs(self.Burnable) do
	--	if v == _eType then
	--		table.remove(self.Burnable, k)
	--		break
	--	end
	--end
	--Update Gebäudeliste + Metrik
	local loopVar = 1
	while loopVar <= table.getn(self.ListOfBuildings) do
		if Logic.GetEntityType(self.ListOfBuildings[loopVar]) == _eType then
			local entityID = self.ListOfBuildings[loopVar]
			for k,v in pairs(self.ListOfBuildings) do
				self.Metrik[v][entityID] = nil 
			end
			self.Metrik[entityID] = nil
			table.remove(self.ListOfBuildings, loopVar)
		else
			loopVar = loopVar + 1
		end
	end
end
function ExpandingFire:DbgMsg(_errString) --intern
	if self.ErrLvl == 1 then
		Message("ExpandingFire: ".._errString)
	elseif self.ErrLvl == 2 then
		assert(false, "ExpandingFire: ".._errString)
	elseif self.ErrLvl == 3 then
		LuaDebugger.Log("ExpandingFire: ".._errString)
	end
end
function ExpandingFire:AddToListOfBuildings(_eID) --intern
	table.insert(self.ListOfBuildings, _eID)
	self.Metrik[_eID] = {}
	for k,v in pairs(self.ListOfBuildings) do
		if v ~= _eID then
			local distance = self:GetDistance(v, _eID)
			if distance < self.LeapRange then
				self.Metrik[_eID][v] = distance
				self.Metrik[v][_eID] = distance
			end
		end
	end
	--Gebäude eingereiht, Metrik angepasst, fertig
end
function ExpandingFire:RecreateMetrik() --intern
	self.Metrik = {}
	for k,v in pairs(self.ListOfBuildings) do
		self.Metrik[v] = {}
	end
	for k,v in pairs(self.ListOfBuildings) do
		for k2, v2 in pairs(self.ListOfBuildings) do
			local distance = self:GetDistance(v, v2)
			if distance > 0 and distance < self.LeapRange then
				self.Metrik[v][v2] = distance
				self.Metrik[v2][v] = distance
			end
		end
	end
end
function ExpandingFire:GetDistance(_eId1, _eId2) --intern
	local pos1 = GetPosition(_eId1)
	local pos2 = GetPosition(_eId2)
	local delX = pos1.X - pos2.X
	local delY = pos1.Y - pos2.Y
	return math.sqrt(delX*delX + delY*delY) --Nutze l2-Norm
end
function ExpandingFire:IsValidEntityType( _eType) --intern
	local valid = false
	for k,v in pairs(Entities) do
		if v == _eType then
			valid = true
		end
	end
	return valid
end
function ExpandingFire:GetAllEntitiesOfPlayerOfType(_player, _eType) --intern
	local returnTable = {}
	local n, eID = Logic.GetPlayerEntities( _player, _eType, 1)
	if n == 0 then
		return {}
	end
	local firstID = eID
	eID = Logic.GetNextEntityOfPlayerOfType( eID)
	table.insert( returnTable, firstID)
	while eID ~= firstID do
		table.insert( returnTable, eID)
		eID = Logic.GetNextEntityOfPlayerOfType( eID)
	end
	return returnTable
end
function ExpandingFire_Job() --intern, ruft den eigentlichen Job auf
	ExpandingFire:Job()
end
function ExpandingFire:Job() --intern, macht das Verwaltungszeug
	--Überprüfe zuerst, ob ein Gebäude erfolgreich gelöscht wurde
	local loopVar = 1
	while loopVar <= table.getn(self.Burning) do
		local maxHealth = Logic.GetEntityMaxHealth( self.Burning[loopVar])
		local curHealth = Logic.GetEntityHealth( self.Burning[loopVar])
		if curHealth * 2 > maxHealth then
			table.remove(self.Burning, loopVar)
		else
			loopVar =  loopVar + 1
		end
	end
	--Sortiere kaputte Entities aus
	for i = table.getn(self.Burning), 1, -1 do
		if not IsAlive(self.Burning[i]) then
			table.remove( self.Burning, i)
		end
	end
	for k,v in pairs(self.Burning) do
		local damageToDeal = math.ceil(self.FireDamage * Logic.GetEntityMaxHealth( v) / 1000)
		if damageToDeal >= Logic.GetEntityHealth(v) then --Gebäude stürzt ein
			self:DoLeapTick( v, self.LeapChanceOnCollaps)
			if Logic.GetEntityTypeName(Logic.GetEntityType(v)) == nil then
				self:DbgMsg("Gebaeude "..v.." vom Typ UNBEKANNT ist abgebrandt!")
			else
				self:DbgMsg("Gebaeude "..v.." vom Typ "..Logic.GetEntityTypeName(Logic.GetEntityType(v)).." ist abgebrandt!")
			end
		else --Verwende ansonsten normalen LeapTick
			self:DoLeapTick( v, self.LeapChance)
		end
		Logic.HurtEntity( v, damageToDeal)
	end
end
function ExpandingFire:DoLeapTick( _eId, _chance) --intern
	for k,v in pairs(self.Metrik[_eId]) do --Gehe alle nahen Gebäude durch
		if not self:IsBurning(k) then --Das Gebäude brennt noch nicht
			local actualChance = _chance * v / self.LeapRange
			if math.random()*1000 < actualChance then
				self:Ignite(k)
			end
		end
	end
end
function ExpandingFire:IsBurning( _eId)
	local isBurning = false
	for k,v in pairs(self.Burning) do
		if v == _eId then
			isBurning = true
			break;
		end
	end
	return isBurning
end
function ExpandingFire_IsEventInteresting() --intern
	local eId = Event.GetEntityID()
	local eType = Logic.GetEntityType( eId)
	local pId = GetPlayer( eId)
	if ExpandingFire.IsPlayerAffected( pId) and Logic.IsBuilding(eId) == 1 then
		if ExpandingFire:IsBurnable(eType) then
			return true
		end
	end
	return false
end
function ExpandingFire:IsBurnable( _eType)
	for k,v in self.Burnable do
		if v == _eType then
			return true
		end
	end
	return false
end
function ExpandingFire_OnEntityCreated( _eId) --intern
	local eId = Event.GetEntityID()
	if _eId ~= nil then
		eId = _eId
	end
	--Alle Voraussetzungen erfüllt, füge das Gebäude der Liste hinzu
	ExpandingFire:AddToListOfBuildings(eId)
	ExpandingFire:DbgMsg("Entity "..eId.." vom Typ "..Logic.GetEntityTypeName(Logic.GetEntityType(eId)).." wurde erstellt!")
end
function ExpandingFire_OnEntityDestroyed( _eId) --intern
	local eId = Event.GetEntityID()
	if _eId ~= nil then
		eId = _eId
	end
	--Lösche das Gebäude, falls es brennt
	for k,v in pairs(ExpandingFire.Burning) do
		if v == eId then
			table.remove( ExpandingFire.Burning, k)
		end
	end
	--Entferne das Gebäude aus der ListOfBuildings
	for k,v in pairs(ExpandingFire.ListOfBuildings) do
		if v == eId then
			table.remove(ExpandingFire.ListOfBuildings, k)
		end
	end
	--Räume die Metrik auf
	ExpandingFire.Metrik[eId] = nil
	for k,v in pairs(ExpandingFire.ListOfBuildings) do
		ExpandingFire.Metrik[v][eId] = nil 
	end
	--ExpandingFire:DbgMsg("Entity "..eId.." vom Typ "..Logic.GetEntityTypeName(Logic.GetEntityType(eId)).." wurde zerstoert!")
end
function ExpandingFire:Shutdown()
	EndJob(self.SJobId)
	Trigger.UnrequestTrigger(self.OECTrigger)
	Trigger.UnrequestTrigger(self.OEDTrigger)
	self.Burning = {}
	self.Metrik = {}
	self.Burnable = {}
	self.ListOfBuildings = {}
end
function ExpandingFire:GetNumberOBurningBuildings()
	return table.getn(self.Burning)
end
