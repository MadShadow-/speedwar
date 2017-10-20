-- VC Changes

SW = SW or {}
SW.VCChange = {}
SW.VCChange.ToChange = {
	["PU_LeaderCavalry1"] = 1,
	["PU_LeaderCavalry2"] = 1,
	["PU_SoldierCavalry1"] = 1,
	["PU_SoldierCavalry2"] = 1,
	["PV_Cannon1"] = 2,
	["PV_Cannon2"] = 2,
	["PV_Cannon3"] = 5,
	["PV_Cannon4"] = 5,
}
function SW.VCChange.Init()
	for k,v in pairs(SW.VCChange.ToChange) do
		SW.SetAttractionPlaceNeeded( Entities[k], v)
	end
end