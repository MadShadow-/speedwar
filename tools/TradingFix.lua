-- 			FIXED TRADING FACTORS
--		Other idea: All players share same prices?
function SW.FixMarketPrices()
	--Logic.SetCurrentInflation(_playerId, _resourceType, _value)
	--Logic.SetCurrentDeflation
	-- SW.GameCallback_OnTransactionCompleteTradeFix = GameCallback_OnTransactionComplete
	-- GameCallback_OnTransactionComplete = function( _eId, _e )
		-- local toBuyType, toBuyAmount = SW.GetMarketTransaction( _eId)
		-- LuaDebugger.Break()
		-- SW.GameCallback_OnTransactionCompleteTradeFix( _eId, _e)
	-- end
	local ressTypes = {
		"Wood",
		"Clay",
		"Sulfur",
		"Stone",
		"Iron"
	}
	for k,v in pairs(ressTypes) do
		local rType = ResourceType[v]
		-- for i = 1, SW.MaxPlayers do
			-- Logic.SetCurrentInflation( i, rType, 0)
			-- Logic.SetCurrentDeflation( i, rType, 0)
		-- end
		SW.SetMarketMinPrice( rType, 0.8)
		SW.SetMarketMaxPrice( rType, 1.2)
		for i = 1, SW.MaxPlayers do
			Logic.SetCurrentPrice( i, rType, 1)
		end
	end
	local goldVal = 2
	SW.SetMarketMinPrice( ResourceType.Gold, goldVal)
	SW.SetMarketMaxPrice( ResourceType.Gold, goldVal)
	for i = 1, SW.MaxPlayers do
		Logic.SetCurrentPrice( i, ResourceType.Gold, goldVal)
	end
end