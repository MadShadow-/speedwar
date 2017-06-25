SW = SW or {}
function SW.GetCostFactorByNumOfOutposts(x)
	if x == 0 then return 0; end
	return 25/(math.exp(-x+6) + 1)
end
SW.OutpostCosts = {
	[ResourceType.Gold] = 500,
	[ResourceType.Wood] = 400,
	[ResourceType.Clay] = 0,
	[ResourceType.Silver] = 0,
	[ResourceType.Stone] = 700,
	[ResourceType.Iron] = 0,
	[ResourceType.Sulfur] = 0
}
