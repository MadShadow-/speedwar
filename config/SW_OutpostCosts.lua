SW = SW or {}
function SW.GetCostFactorByNumOfOutposts(x)
	if x == 0 then return 0; end
	return 100/(math.exp(-x+6) + 1)
end
SW.FLAG_USE_FIXED_OUTPOST_COSTS = true
function SW.GetOutpostCosts(_index)
	if SW.FLAG_USE_FIXED_OUTPOST_COSTS then
		return SW.OutpostCosts[_index] or SW.OutpostCosts[8]
	end

	local base
	if _index <= 2 then
		base = {
			[ResourceType.Gold] = 350,
			[ResourceType.Clay] = 0,
			[ResourceType.Wood] = 300,
			[ResourceType.Stone] = 450,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0,
			[ResourceType.Silver] = 0
		}
	else
		base = {
			[ResourceType.Gold] = 350,
			[ResourceType.Clay] = 400,
			[ResourceType.Wood] = 0,
			[ResourceType.Stone] = 450,
			[ResourceType.Iron] = 0,
			[ResourceType.Sulfur] = 0,
			[ResourceType.Silver] = 0
		}
	end
	local factor = 1
	if _index == 0 then
		factor = 0
	elseif _index <= 6 then
		-- math.exp(x*0.694) = 2^x; 0.694 = ln(2)
		factor = math.floor(math.exp( (_index-1)*0.694))
	else
		-- index = 6 => factor = 32
		factor = 2*(_index-2)*(_index-2)
	end
	local retTable = {}
	for k,v in pairs(base) do
		retTable[k] = v*factor
	end
	return retTable
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
		[ResourceType.Gold] = 350,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 450,
		[ResourceType.Stone] = 450,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[2] = {
		[ResourceType.Gold] = 900,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 700,
		[ResourceType.Stone] = 700,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[3] = {
		[ResourceType.Gold] = 2000,
		[ResourceType.Clay] = 1000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 2000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[4] = {
		[ResourceType.Gold] = 3500,
		[ResourceType.Clay] = 1500,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 2000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[5] = {
		[ResourceType.Gold] = 5000,
		[ResourceType.Clay] = 2000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 3000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[6] = {
		[ResourceType.Gold] = 8000,
		[ResourceType.Clay] = 3000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 5000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[7] = {
		[ResourceType.Gold] = 12000,
		[ResourceType.Clay] = 4000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 7000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
	[8] = {
		[ResourceType.Gold] = 24000,
		[ResourceType.Clay] = 8000,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 14000,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0,
	},
}

function GetTotalCostsOld( _count)
	GetTotalCosts( _count, function(_i)  return SW.OutpostCosts[math.min(_i,8)] end)
end
function GetTotalCostsNew( _count)
	GetTotalCosts( _count, SW.GetOutpostCosts)
end
function GetTotalCosts( _c, _f)
	local base = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0,
		[ResourceType.Silver] = 0
	}
	for i = 0, _c do 
		local cost = _f(i)
		for k,v in pairs(cost) do
			base[k] = base[k] + v
		end
	end
	local names = {
		[ResourceType.Gold] = "Gold",
		[ResourceType.Clay] = "Lehm",
		[ResourceType.Wood] = "Holz",
		[ResourceType.Stone] = "Stein",
		[ResourceType.Iron] = "Eisen",
		[ResourceType.Sulfur] = "Schwefel",
		[ResourceType.Silver] = ""
	}
	for k,v in pairs(base) do
		if v ~= 0 then
			LuaDebugger.Log(names[k].." "..v)
		end
	end
end