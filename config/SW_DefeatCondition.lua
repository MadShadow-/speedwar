
SW = SW or {}

SW.DefeatConditionPlayerEntities = {}
for playerId = 1,8 do
	SW.DefeatConditionPlayerEntities[playerId] = 0
end
SW.DefeatConditionEntityList = {}
--Entries: [eId] = playerId

SW.DefeatConditionTypes = {
	[Entities.PB_Outpost1] = true,
	[Entities.PU_Serf] = true
}
for k,v in pairs(Entities) do
	if string.find( k, "Leader") then
		SW.DefeatConditionTypes[v] = true
	end
end
