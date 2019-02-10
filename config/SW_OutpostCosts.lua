SW = SW or {}
function SW.GetCostFactorByNumOfOutposts(x)
	if x == 0 then return 0; end
	return 100/(math.exp(-x+6) + 1)
end
function SW.GetOutpostCosts(_index)
	return SW.OutpostCosts[_index] or SW.OutpostCosts[8];
end
SW.OutpostCosts = {
	[0] = {
		[ResourceType.Gold] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[1] = {
		[ResourceType.Gold] = 500,
		[ResourceType.Clay] = 450,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 450,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[2] = {
		[ResourceType.Gold] = 1500,
		[ResourceType.Clay] = 1000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 1000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[3] = {
		[ResourceType.Gold] = 2350,
		[ResourceType.Clay] = 2000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 2000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[4] = {
		[ResourceType.Gold] = 6000,
		[ResourceType.Clay] = 3000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 5500,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[5] = {
		[ResourceType.Gold] = 12000,
		[ResourceType.Clay] = 5000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 8500,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[6] = {
		[ResourceType.Gold] = 24000,
		[ResourceType.Clay] = 10000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 12000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[7] = {
		[ResourceType.Gold] = 30000,
		[ResourceType.Clay] = 12000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 15000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[8] = {
		[ResourceType.Gold] = 50000,
		[ResourceType.Clay] = 15000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 22000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
}

