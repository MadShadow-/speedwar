-- 			FIXED TRADING FACTORS
--		Other idea: All players share same prices?
function SW.FixMarketPrices()
	--Logic.SetCurrentInflation(_playerId, _resourceType, _value)
	--Logic.SetCurrentDeflation
	local ressTypes = {
		"Gold",
		"Wood",
		"Clay",
		"Sulfur",
		"Stone",
		"Iron"
	}
	for k,v in pairs(ressTypes) do
		local rType = ResourceType[v]
		for i = 1, 8 do
			Logic.SetCurrentInflation( i, rType, 0)
			Logic.SetCurrentDeflation( i, rType, 0)
		end
	end
end