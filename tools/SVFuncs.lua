SW = SW or {}


SW.ScriptingValueBackup = SW.ScriptingValueBackup or {};
SW.ScriptingValueBackup.ConstructionCosts = SW.ScriptingValueBackup.ConstructionCosts or {};
SW.ScriptingValueBackup.RecruitingCosts = SW.ScriptingValueBackup.RecruitingCosts or {};
SW.ScriptingValueBackup.UpgradeCosts = SW.ScriptingValueBackup.UpgradeCosts or {};
SW.ScriptingValueBackup.TechCosts = SW.ScriptingValueBackup.TechCosts or {};
SW.ScriptingValueBackup.TechBuildReq = SW.ScriptingValueBackup.TechBuildReq or {}
SW.ScriptingValueBackup.TechTime = SW.ScriptingValueBackup.TechTime or {}
SW.ScriptingValueBackup.SerfExtrAmount = SW.ScriptingValueBackup.SerfExtrAmount or {}
SW.ScriptingValueBackup.SerfExtrDelay = SW.ScriptingValueBackup.SerfExtrDelay or {}
SW.ScriptingValueBackup.DamageClass = SW.ScriptingValueBackup.DamageClass or {}
SW.ScriptingValueBackup.MarketData = SW.ScriptingValueBackup.MarketData or {}

function SW.ResetScriptingValueChanges()
	for k,v in pairs(SW.ScriptingValueBackup.ConstructionCosts) do
		SW.SetConstructionCosts(k, v);
	end;

	for k,v in pairs(SW.ScriptingValueBackup.RecruitingCosts) do
		SW.SetRecruitingCosts(k,v);
	end;
	
	for k, v in pairs(SW.ScriptingValueBackup.UpgradeCosts) do
		SW.SetUpgradeCosts(k,v);
	end;
	for k, v in pairs(SW.ScriptingValueBackup.TechCosts) do
		SW.SetTechnologyCosts(k,v);
	end;
	for k, v in pairs(SW.ScriptingValueBackup.TechBuildReq) do
		SW.TechnologyRestoreBuildingReqs(k,v);
	end;
	
	for k,v in pairs(SW.ScriptingValueBackup.SerfExtrAmount) do
		SW.SetSerfExtractionAmount( k, v)
	end
	for k,v in pairs(SW.ScriptingValueBackup.SerfExtrDelay) do
		SW.SetSerfExtractionDelay( k, v)
	end
	for dmgClass,dmgTable in pairs(SW.ScriptingValueBackup.DamageClass) do
		for armClass, val in pairs(dmgTable) do
			SW.SetDamageArmorCoeff( dmgClass, armClass, val)
		end
	end
	if SW.ScriptingValueBackup.MarketSpeed then
		SW.SetGlobalMarketSpeed( SW.ScriptingValueBackup.MarketSpeed)
	end
	for k,v in pairs(SW.ScriptingValueBackup.MarketData) do
		if v.MaxPrice then
			SW.SetMarketMaxPrice( k, v.MaxPrice)
		end
		if v.MinPrice then
			SW.SetMarketMinPrice( k, v.MinPrice)
		end
		if v.WorkAmount then
			SW.SetMarketWorkAmount( k, v.WorkAmount)
		end
	end
	SW.SV.GreatReset()
end;

--HelperFunc: Set Movement speed of given entity
function SW.SetMovementspeed( _eId, _ms)
	S5Hook.GetEntityMem( _eId)[31][1][5]:SetFloat( _ms)
end
--HelperFunc: Get Movement speed of given entity
function SW.GetMovementspeed( _eId)
	return S5Hook.GetEntityMem( _eId)[31][1][5]:GetFloat()
end
--sets remaining time until explosion in ticks
function SW.SetKegTimer( _eId, _time)
	if S5Hook.GetEntityMem( _eId)[31]:GetInt() == 0 then
		return
	end
	if S5Hook.GetEntityMem( _eId)[31][0]:GetInt() == 0 then
		return
	end
	if S5Hook.GetEntityMem( _eId)[31][0][0]:GetInt() ~= 7824600 then
		return
	end
	S5Hook.GetEntityMem( _eId)[31][0][5]:SetInt( _time) 
end
function SW.GetKegTimer( _eId)
	if S5Hook.GetEntityMem( _eId)[31]:GetInt() == 0 then
		return
	end
	if S5Hook.GetEntityMem( _eId)[31][0]:GetInt() == 0 then
		return
	end
	if S5Hook.GetEntityMem( _eId)[31][0][0]:GetInt() ~= 7824600 then
		return
	end
	return S5Hook.GetEntityMem( _eId)[31][0][5]:GetInt() 
end

--some stuff regarding markets
-- returns type and amount of ressource to buy, type and amount to sell
function SW.GetMarketTransaction( _eId)
	local p = S5Hook.GetEntityMem( _eId)[31][1]
	return p[6]:GetInt(), p[7]:GetFloat(), p[5]:GetInt(), p[8]:GetFloat()
end
function SW.SetMarketTransaction( _eId, _toBuyType, _toBuyAmount)
	local p = S5Hook.GetEntityMem( _eId)[31][1]
	local maxProgress = (p[8]:GetFloat() + p[7]:GetFloat())/10;
	p[6]:SetInt( _toBuyType)
	p[7]:SetFloat( _toBuyAmount)
	p[9]:SetFloat( math.min(p[9]:GetFloat(), maxProgress-1))
end
-- number ranging from 0 to 1
function SW.SetMarketProgress( _eId, _progress)
	local p = S5Hook.GetEntityMem( _eId)[31][1]
	local maxProgress = (p[8]:GetFloat() + p[7]:GetFloat())/10;
	p[9]:SetFloat(math.floor(maxProgress*_progress))
end
-- _speed is some factor; Vanilla: 4.5
function SW.SetGlobalMarketSpeed( _speed)
	local p = S5Hook.GetRawMem(9002416)[0][16][Entities.PB_Market2*8+5][2][4]
	SW.ScriptingValueBackup.MarketSpeed = SW.ScriptingValueBackup.MarketSpeed or p:GetFloat()
	p:SetFloat(_speed)
end

--HelperFunc: Set construction cost of given entity type, developed by mcb
function SW.SetConstructionCosts( _eType, _costTable)
	SW.ScriptingValueBackup.ConstructionCosts[_eType] = SW.ScriptingValueBackup.ConstructionCosts[_eType] or SW.GetConstructionCosts(_eType);
	local blankCostTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	local resourceTypes = {
		[ResourceType.Gold] = 57,
		[ResourceType.Silver] = 59,
		[ResourceType.Clay] = 67,
		[ResourceType.Wood] = 69,
		[ResourceType.Stone] = 61,
		[ResourceType.Iron] = 63,
		[ResourceType.Sulfur] = 65,
	};
	for k,v in pairs( blankCostTable) do --Allows incomplete cost tables
		_costTable[k] = _costTable[k] or blankCostTable[k]
	end
	for k,v in pairs( _costTable) do
		S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][resourceTypes[k]]:SetFloat( v);
	end
end
--HelperFunc: Get construction cost of given entity type, developed by mcb
function SW.GetConstructionCosts( _eType)
	local resourceTypes = {
		[ResourceType.Gold] = 57,
		[ResourceType.Clay] = 67,
		[ResourceType.Wood] = 69,
		[ResourceType.Stone] = 61,
		[ResourceType.Iron] = 63,
		[ResourceType.Sulfur] = 65,
	};
	local _costTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	for k,v in pairs( _costTable) do
		_costTable[k] = S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][resourceTypes[k]]:GetFloat();
	end
	_costTable[ResourceType.Silver] = 0
	return _costTable
end
--HelperFunc: Set recruiting costs for given entity type
function SW.SetRecruitingCosts( _eType, _costTable)
	SW.ScriptingValueBackup.RecruitingCosts[_eType] = SW.ScriptingValueBackup.RecruitingCosts[_eType] or SW.GetRecruitingCosts(_eType);
	local blankCostTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	local resourceTypes = {
		[ResourceType.Gold] = 41,
		[ResourceType.Clay] = 51,
		[ResourceType.Wood] = 53,
		[ResourceType.Stone] = 45,
		[ResourceType.Iron] = 47,
		[ResourceType.Sulfur] = 49,
	};
	for k,v in pairs( blankCostTable) do --Allows incomplete cost tables
		_costTable[k] = _costTable[k] or blankCostTable[k]
	end
	for k,v in pairs( resourceTypes) do
		S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][v]:SetFloat( _costTable[k]);
	end
end
--HelperFunc: Get recruiting cost of given entity type
function SW.GetRecruitingCosts( _eType)
	local resourceTypes = {
		[ResourceType.Gold] = 41,
		[ResourceType.Clay] = 51,
		[ResourceType.Wood] = 53,
		[ResourceType.Stone] = 45,
		[ResourceType.Iron] = 47,
		[ResourceType.Sulfur] = 49,
	};
	local _costTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	for k,v in pairs( _costTable) do
		_costTable[k] = S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][resourceTypes[k]]:GetFloat();
	end
	_costTable[ResourceType.Silver] = 0
	return _costTable
end
--HelperFunc: Increases experience of given entity
function SW.AddExperiencePoints( _eId, _exp)
	if Logic.IsLeader(_eId) == 0 then
		return
	end
	--Exp stored in S5Hook.GetEntityMem( _eId)[31][3][32]:GetInt()
	local currExp = S5Hook.GetEntityMem( _eId)[31][3][32]:GetInt()
	if (currExp + _exp) > 1000 then --upper border for reasons beyond human understanding
		S5Hook.GetEntityMem( _eId)[31][3][32]:SetInt( 1000)
		return
	end
	S5Hook.GetEntityMem( _eId)[31][3][32]:SetInt( currExp + _exp)
end
--HelperFunc: Get upgrade costs of building
function SW.GetUpgradeCosts( _eType)
	local resourceTypes = {
		[ResourceType.Gold] = 82,
		[ResourceType.Clay] = 92,
		[ResourceType.Wood] = 94,
		[ResourceType.Stone] = 86,
		[ResourceType.Iron] = 88,
		[ResourceType.Sulfur] = 90,
	};
	local _costTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	for k,v in pairs( _costTable) do
		_costTable[k] = S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][resourceTypes[k]]:GetFloat();
	end
	_costTable[ResourceType.Silver] = 0
	return _costTable
end
--HelperFunc: Set upgrade costs for building
function SW.SetUpgradeCosts( _eType, _costTable)
	SW.ScriptingValueBackup.UpgradeCosts[_eType] = SW.ScriptingValueBackup.UpgradeCosts[_eType] or SW.GetUpgradeCosts(_eType);
	local blankCostTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	local resourceTypes = {
		[ResourceType.Gold] = 82,
		[ResourceType.Clay] = 92,
		[ResourceType.Wood] = 94,
		[ResourceType.Stone] = 86,
		[ResourceType.Iron] = 88,
		[ResourceType.Sulfur] = 90,
	};
	for k,v in pairs( blankCostTable) do --Allows incomplete cost tables
		_costTable[k] = _costTable[k] or blankCostTable[k]
	end
	for k,v in pairs( resourceTypes) do
		S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][v]:SetFloat( _costTable[k]);
	end
end

function SW.GetDamageArmorCoeff( _dmgClass, _armorClass)
	local p = SVTests.GetDamageClassPointer()
	return p[_dmgClass][_armorClass]:GetFloat()
end
function SW.SetDamageArmorCoeff( _dmgClass, _armorClass, _val)
	local p = SVTests.GetDamageClassPointer()
	if SW.ScriptingValueBackup.DamageClass[_dmgClass] == nil then
		SW.ScriptingValueBackup.DamageClass[_dmgClass] = {}
	end
	SW.ScriptingValueBackup.DamageClass[_dmgClass][_armorClass] = SW.ScriptingValueBackup.DamageClass[_dmgClass][_armorClass] or SW.GetDamageArmorCoeff( _dmgClass, _armorClass)
	return p[_dmgClass][_armorClass]:SetFloat(_val)
end
--SerfExtractionStuff
-- allowed _ressSource:
--	Entities.XD_Iron1
--	Entities.XD_Clay1
--	Entities.XD_Stone1
--	Entities.XD_Stone_BlockPath
--	Entities.XD_Sulfur1
--	Entities.XD_ClayPit1
--	Entities.XD_IronPit1
--	Entities.XD_StonePit1
--	Entities.XD_SulfurPit1
--	Entities.XD_ResourceTree
function SW.GetSerfExtractionAmount( _ressSource)
	local p = S5Hook.GetRawMem(9002416)[0][16][Entities.PU_Serf*8+5][6]
	--local num = ( p[9]:GetInt() - p[8]:GetInt())/12
	local num = 10
	local extractionDataP = p[8]
	for i = 0, num-1 do
		if extractionDataP[3*i]:GetInt() == _ressSource then
			return extractionDataP[3*i+2]:GetInt()
		end
	end
end
function SW.SetSerfExtractionAmount( _ressSource, _amount)
	local p = S5Hook.GetRawMem(9002416)[0][16][Entities.PU_Serf*8+5][6]
	--local num = ( p[9]:GetInt() - p[8]:GetInt())/12
	local num = 10
	local extractionDataP = p[8]
	for i = 0, num-1 do
		if extractionDataP[3*i]:GetInt() == _ressSource then
			if SW.ScriptingValueBackup.SerfExtrAmount[_ressSource] == nil then
				SW.ScriptingValueBackup.SerfExtrAmount[_ressSource] = SW.GetSerfExtractionAmount( _ressSource)
			end
			extractionDataP[3*i+2]:SetInt(_amount)
			return
		end
	end
end
function SW.GetSerfExtractionDelay( _ressSource)
	local p = S5Hook.GetRawMem(9002416)[0][16][Entities.PU_Serf*8+5][6]
	--local num = ( p[9]:GetInt() - p[8]:GetInt())/12
	local num = 10
	local extractionDataP = p[8]
	for i = 0, num-1 do
		if extractionDataP[3*i]:GetInt() == _ressSource then
			return extractionDataP[3*i+1]:GetFloat()
		end
	end
end
function SW.SetSerfExtractionDelay( _ressSource, _amount)
	local p = S5Hook.GetRawMem(9002416)[0][16][Entities.PU_Serf*8+5][6]
	--local num = ( p[9]:GetInt() - p[8]:GetInt())/12
	local num = 10
	local extractionDataP = p[8]
	for i = 0, num-1 do
		if extractionDataP[3*i]:GetInt() == _ressSource then
			if SW.ScriptingValueBackup.SerfExtrDelay[_ressSource] == nil then
				SW.ScriptingValueBackup.SerfExtrDelay[_ressSource] = SW.GetSerfExtractionDelay( _ressSource)
			end
			extractionDataP[3*i+1]:SetFloat(_amount)
			return
		end
	end
end
--Technology stuff
function SW.GetTechnologyCosts( _tId)
	local resourceTypes = {
		[ResourceType.Gold] = 4,
		[ResourceType.Clay] = 14,
		[ResourceType.Wood] = 16,
		[ResourceType.Stone] = 8,
		[ResourceType.Iron] = 10,
		[ResourceType.Sulfur] = 12,
	};
	local _costTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	for k,v in pairs( _costTable) do
		_costTable[k] = S5Hook.GetRawMem(8758176)[0][13][1][ _tId-1][resourceTypes[k]]:GetFloat();
	end
	_costTable[ResourceType.Silver] = 0
	return _costTable
end
function SW.SetTechnologyCosts( _tId, _costTable)
	SW.ScriptingValueBackup.TechCosts[_tId] = SW.ScriptingValueBackup.TechCosts[_tId] or SW.GetTechnologyCosts( _tId);
	local blankCostTable = {
		[ResourceType.Gold] = 0,
		[ResourceType.Clay] = 0,
		[ResourceType.Wood] = 0,
		[ResourceType.Stone] = 0,
		[ResourceType.Iron] = 0,
		[ResourceType.Sulfur] = 0
	}
	local resourceTypes = {
		[ResourceType.Gold] = 4,
		[ResourceType.Clay] = 14,
		[ResourceType.Wood] = 16,
		[ResourceType.Stone] = 8,
		[ResourceType.Iron] = 10,
		[ResourceType.Sulfur] = 12,
	};
	for k,v in pairs( blankCostTable) do --Allows incomplete cost tables
		_costTable[k] = _costTable[k] or blankCostTable[k]
	end
	for k,v in pairs( _costTable) do
		S5Hook.GetRawMem(8758176)[0][13][1][ _tId-1][resourceTypes[k]]:SetFloat( v);
	end
end

function SW.TechnologyVoidBuidingReqs( _tId)
	local memObj = SW.SV.GetTechData( _tId)
	if SW.ScriptingValueBackup.TechBuildReq[_tId] == nil then	-- first change of buildReqs for this tech?
		SW.ScriptingValueBackup.TechBuildReq[_tId] = {
			count = memObj[26]:GetInt(),
			reqStart = memObj[28]:GetInt(),
			reqEnd = memObj[29]:GetInt()
		}
	end
	memObj[26]:SetInt(0)	--set # of req to meet to 0
	memObj[28]:SetInt(0)	--destroy pointer
	memObj[29]:SetInt(0)
	memObj[30]:SetInt(0)
end
-- _count is # of requirements that have to be fulfilled, requirements are encoded as 
-- _data = {{1, Entities.PB_Tower3}, {4, Entities.PB_Tower2}}
-- so 1 Tower3 and 4 Tower2 are needed if _count == 2 or one of the conditions if _count == 1
function SW.TechnologyAlterBuildingReqs( _tId, _count, _data)
	local memObj = SW.SV.GetTechData( _tId)
	if SW.ScriptingValueBackup.TechBuildReq[_tId] == nil then	-- first change of buildReqs for this tech?
		SW.ScriptingValueBackup.TechBuildReq[_tId] = {
			count = memObj[26]:GetInt(),
			reqStart = memObj[28]:GetInt(),
			reqEnd = memObj[29]:GetInt()
		}
	end
	local n = table.getn(_data)
	--if n == _count then _count = 0 end
	memObj[26]:SetInt( _count)
	local ptr = S5Hook.ReAllocMem( 0, n*8)
	memObj[28]:SetInt( ptr)
	memObj[29]:SetInt( ptr+n*8)
	memObj[30]:SetInt( ptr+n*8)
	ptr = S5Hook.GetRawMem( ptr)
	for i = 1, n do
		ptr[2*i-2]:SetInt(_data[i][2])
		ptr[2*i-1]:SetInt(_data[i][1])
	end
end
function SW.TechnologyRestoreBuildingReqs( _tId, _data)
	local memObj = SW.SV.GetTechData( _tId)
	memObj[26]:SetInt(_data.count)
	memObj[28]:SetInt(_data.reqStart)
	memObj[29]:SetInt(_data.reqEnd)
	memObj[30]:SetInt(_data.reqEnd)
end

function SW.SetTechnologyTimeToResearch( _tId, _time)
	local p = SW.SV.GetTechData( _tId)
	SW.ScriptingValueBackup.TechTime[_tId] = SW.ScriptingValueBackup.TechTime[_tId] or SW.GetTechnologyTimeToResearch( _tId)
	p[1]:SetFloat( _time)
end
function SW.GetTechnologyTimeToResearch( _tId)
	return SW.SV.GetTechData( _tId)[1]:GetFloat()
end

function SW.SetMarketMaxPrice( _ressType, _price)
	SW.ScriptingValueBackup.MarketData[_ressType] = SW.ScriptingValueBackup.MarketData[_ressType] or {}
	SW.ScriptingValueBackup.MarketData[_ressType].MaxPrice = SW.ScriptingValueBackup.MarketData[_ressType].MaxPrice or SW.GetMarketMaxPrice( _ressType)
	local mp = SW.SV.GetLogicXMLPointer()[15]
	local i = SW.SV.GetMarketIndex( mp, _ressType)
	mp[8*i+4]:SetFloat( _price)
end
function SW.GetMarketMaxPrice( _ressType)
	local mp = SW.SV.GetLogicXMLPointer()[15]
	local i = SW.SV.GetMarketIndex( mp, _ressType)
	return mp[8*i+4]:GetFloat()
end
function SW.SetMarketMinPrice( _ressType, _price)
	SW.ScriptingValueBackup.MarketData[_ressType] = SW.ScriptingValueBackup.MarketData[_ressType] or {}
	SW.ScriptingValueBackup.MarketData[_ressType].MinPrice = SW.ScriptingValueBackup.MarketData[_ressType].MinPrice or SW.GetMarketMinPrice( _ressType)
	local mp = SW.SV.GetLogicXMLPointer()[15]
	local i = SW.SV.GetMarketIndex( mp, _ressType)
	mp[8*i+3]:SetFloat( _price)
end
function SW.GetMarketMinPrice( _ressType)
	local mp = SW.SV.GetLogicXMLPointer()[15]
	local i = SW.SV.GetMarketIndex( mp, _ressType)
	return mp[8*i+3]:GetFloat()
end
function SW.SetMarketWorkAmount( _ressType, _workAmount)
	SW.ScriptingValueBackup.MarketData[_ressType] = SW.ScriptingValueBackup.MarketData[_ressType] or {}
	SW.ScriptingValueBackup.MarketData[_ressType].WorkAmount = SW.ScriptingValueBackup.MarketData[_ressType].WorkAmount or SW.GetMarketWorkAmount( _ressType)
	local mp = SW.SV.GetLogicXMLPointer()[15]
	local i = SW.SV.GetMarketIndex( mp, _ressType)
	mp[8*i+7]:SetFloat( _workAmount)
end
function SW.GetMarketWorkAmount( _ressType)
	local mp = SW.SV.GetLogicXMLPointer()[15]
	local i = SW.SV.GetMarketIndex( mp, _ressType)
	return mp[8*i+7]:GetFloat()
end

SW.SV = {}
-- Entries { type, vtable, index, float/int}
--	false == float, true == int for float/int
--  type:
--  2 == Beh
--	1 == Logic
--  index can be a table, only implemented for behTables atm

-- for each entry, 2 functions are created:
--	SV["Set"..key]( _eType, val), sets key for the entity type
--	SV["Get"..key]( _eType), gets key for the entity
SW.SV.Data = {
	-- some worker logic
	["WorkTimeChangeWork"] = {2, 7809936, 17, true},
	["WorkTimeChangeFarm"] = {2, 7809936, 18, false},
	["WorkTimeChangeResidence"] = {2, 7809936, 19, false},
	["WorkTimeChangeCamp"] = {2, 7809936, 20, false},
	["WorkTimeMaxChangeFarm"] = {2, 7809936, 21, true},
	["WorkTimeMaxChangeResidence"] = {2, 7809936, 22, true},
	["ExhaustedWorkMotivationMalus"] = {2, 7809936, 23, false},
	["WorkerTransportAmount"] = {2, 7809936, 24, true},
	-- some other stuff
	["RecruitingTime"] = {2, 7834420, 9, false},
	["RefinedPerTick"] = {2, 7818276, 5, false},
	["AmountToMine"] = {2, 7821340, 4, true},
	-- Logic for buildings, GGL::CGLBuildingProps == 7793784
	["KegFactor"] = {1, 7793784, 124, false},
	["AttractionPlaceProvided"] = {1, 7793784, 44, true},
	["UpgradeTime"] = {1, 7793784, 80, false},
	["Exploration"] = {1, 7793784, 19, false},
	["ConstructionTime"] = {1, 7793784, 55, true},
	["BuildingMaxHealth"] = {1, 7793784, 13, true},
	-- Logic for entities, GGL::CGLSettlerProps == 7791768
	["AttractionPlaceNeeded"] = {1, 7791768, 136, true},
	["SettlerExploration"] = {1, 7791768, 19, false},
	["SettlerArmorClass"] = {1, 7791768, 60, true},
	-- BehTable for motivation, 7836116 == GGL::CAffectMotivationBehaviorProps
	["MotivationProvided"] = {2, 7836116, 4, false},
	-- BehTable for residences / farms, 7823028 == GGL::CLimitedAttachmentBehaviorProperties
	["PlacesProvided"] = {2, 7823028, {5,7}, true},
	-- Stuff for thief bombs, use type XD_Keg1
	["ThiefKegDamage"] = {2, 7824728, 5, true},			-- damage against settlers, default 50
	["ThiefKegDmgPercentage"] = {2, 7824728, 7, true},	-- damage against buildings, default 70
	["ThiefKegRange"] = {2, 7824728, 4, false},
	["ThiefKegDelay"] = {2, 7824728, 6, false},
    -- data for the thief itself, use type PU_Thief
    ["ThiefBombRechargeTime"] = {2, 7824308, 4, true}, --default 90
    ["ThiefBombArmTime"] = {2, 7824308, 5, false},  --default 5
    ["ThiefBombDisarmTime"] = {2, 7824308, 6, false},  --default 3
    -- data for stealing goods
    ["ThiefTimeToSteal"] = {2, 7813600, 4, true}, --default 5
    ["ThiefMinimumAmountToSteal"] = {2, 7813600, 5, true}, --default 100
    ["ThiefMaximumAmountToSteal"] = {2, 7813600, 6, true}, --default 200
	-- data for leader stats; CLeaderBehaviorProps
	["LeaderDamage"] = {2, 7823268, 14, true},
	["LeaderRandomDamageBonus"] = {2, 7823268, 15, true},
	["LeaderDamageClass"] = {2, 7823268, 13, true},
	["LeaderAoERange"] = {2, 7823268, 16, false},
	["LeaderMaxRange"] = {2, 7823268, 23, false},
	["LeaderAutoRange"] = {2, 7823268, 30, false},
	-- data for soldier stats; CSoldierBehaviorProps
	["SoldierDamage"] = {2, 7814416, 14, true},
	["SoldierRandomDamageBonus"] = {2, 7814416, 15, true},
	["SoldierDamageClass"] = {2, 7814416, 13, true},
	["SoldierMaxRange"] = {2, 7814416, 23, false},
	-- CLimitedAttachmentBehaviorProperties
	["LeaderMaxSoldiers"] = {2, 7823028, {5, 7}, true}
}

SW.SV.BackUps = {}
-- Makes heavy use of upvalues!
function SW.SV.Init()
	for k,v in pairs(SW.SV.Data) do
		local c = {type = v[1], vTable = v[2], index = v[3], int = v[4]}	--Create a copy of v for use
		if c.type == 2 then	--Behaviortable
			SW["Get"..k] = function( _eType)
				local behPointer = SW.SV.SearchForBehTable( _eType, c.vTable)
				if behPointer ~= nil then
					if c.int then
						return SW.SV.UnpackIndex( behPointer, c.index):GetInt()
					else
						return SW.SV.UnpackIndex( behPointer, c.index):GetFloat()
					end
				end
			end
			SW.SV.BackUps[k] = {}
			local kCopy = k
			SW["Set"..k] = function( _eType, _val)
				local behPointer = SW.SV.SearchForBehTable( _eType, c.vTable)
				if behPointer ~= nil then
					SW.SV.BackUps[kCopy][_eType] = SW.SV.BackUps[kCopy][_eType] or SW["Get"..kCopy](_eType)
					if c.int then
						SW.SV.UnpackIndex( behPointer, c.index):SetInt( _val)
					else
						SW.SV.UnpackIndex( behPointer, c.index):SetFloat( _val)
					end
				else
					Message("Failed to set "..kCopy.." for ".._eType)
				end
			end
		elseif c.type == 1 then	--Logic table
			SW["Get"..k] = function( _eType)
				local logicPointer = S5Hook.GetRawMem(9002416)[0][16][_eType*8+2]
				if logicPointer[0]:GetInt() == c.vTable then
					if c.int then
						return logicPointer[c.index]:GetInt()
					else
						return logicPointer[c.index]:GetFloat()
					end
				else return -1 end
			end
			SW.SV.BackUps[k] = {}
			local kCopy = k
			SW["Set"..k] = function( _eType, _val)
				local logicPointer = S5Hook.GetRawMem(9002416)[0][16][_eType*8+2]
				if logicPointer[0]:GetInt() == c.vTable then
					SW.SV.BackUps[kCopy][_eType] = SW.SV.BackUps[kCopy][_eType] or SW["Get"..kCopy](_eType)
					if c.int then
						logicPointer[c.index]:SetInt( _val)
					else
						logicPointer[c.index]:SetFloat( _val)
					end
				else
					Message("Failed to set "..kCopy.." for ".._eType)
				end
			end
		end
	end	
end
function SW.SV.GreatReset()
	for k,v in pairs(SW.SV.BackUps) do
		for k2,v2 in pairs(v) do	--k2 == eType, v2 == val
			SW["Set"..k]( k2, v2)
		end
		SW.SV.BackUps[k] = {}
	end
end
function SW.SV.SearchForBehTable( _eType, _vTable)
	local typePointer = S5Hook.GetRawMem(9002416)[0][16]
	local behPointer = typePointer[_eType*8+5]
	local upperBorder = typePointer[_eType*8+7]:GetInt()
	local i = 0
	while typePointer[_eType*8+5]:Offset(i):GetInt() < upperBorder do
		--LuaDebugger.Log(behPointer[i]:GetInt())
		if behPointer[i]:GetInt() > 0 then	--adress looks good, check associated vtable
			--LuaDebugger.Log(behPointer[i][0]:GetInt())
			if behPointer[i][0]:GetInt() == _vTable then
				return behPointer[i]
			end
		end
		i = i + 1
	end
end
function SW.SV.UnpackIndex( _p, _t)
	if type(_t) == "number" then
		return _p[_t]
	end
	for i = 1, table.getn(_t) do
		_p = _p[_t[i]]
	end
	return _p
end

SW.SV.ArmorClasses = {
	None = 1,
	Jerkin = 2,
	Leather = 3,
	Iron = 4,
	Fortification = 5,
	Hero = 6,
	Fur = 7
}
function SW.SV.GetTechData( _tId)
	return S5Hook.GetRawMem(8758176)[0][13][1][ _tId-1]
end
function SW.SV.GetDamageXMLPointer()
	return S5Hook.GetRawMem(8758236)[0][2]
end
function SW.SV.GetLogicXMLPointer()
	return S5Hook.GetRawMem(8758240)[0]
end
function SW.SV.GetMarketIndex( _p, _ressType)
	for i = 0, 5 do
		if _p[i*8+1]:GetInt() == _ressType then
			return i
		end
	end
end
SW.SV.MarketData = {
	{
		RessType = ResourceType.Gold,
		BasePrice = 1,
		MinPrice = 1,
		MaxPrice = 1,
		Inflation = 0.00015000000712462,
		Deflation = 0.00015000000712462,
		WorkAmount = 0.1
	},
	{
		RessType = ResourceType.Clay,
		BasePrice = 1,
		MinPrice = 0.20000000298023,
		MaxPrice = 2.7999999523163,
		Inflation = 9.9999997473788e-005,
		Deflation = 9.9999997473788e-005,
		WorkAmount = 0.1
	},
	{
		RessType = ResourceType.Wood,
		BasePrice = 1.3999999761581,
		MinPrice = 0.20000000298023,
		MaxPrice = 2.7999999523163,
		Inflation = 0.00019999999494758,
		Deflation = 0.00019999999494758,
		WorkAmount = 0.1
	},
	{
		RessType = ResourceType.Iron,
		BasePrice = 1,
		MinPrice = 0.20000000298023,
		MaxPrice = 2.7999999523163,
		Inflation = 9.9999997473788e-005,
		Deflation = 9.9999997473788e-005,
		WorkAmount = 0.1
	},
	{
		RessType = ResourceType.Stone,
		BasePrice = 1,
		MinPrice = 0.20000000298023,
		MaxPrice = 2.7999999523163,
		Inflation = 9.9999997473788e-005,
		Deflation = 9.9999997473788e-005,
		WorkAmount = 0.1
	},
	{
		RessType = ResourceType.Sulfur,
		BasePrice = 0.60000002384186,
		MinPrice = 0.20000000298023,
		MaxPrice = 2.7999999523163,
		Inflation = 9.9999997473788e-005,
		Deflation = 9.9999997473788e-005,
		WorkAmount = 0.1
	},
	{
		RessType = ResourceType.SulfurRaw,
		BasePrice = 10,
		MinPrice = 6,
		MaxPrice = 15,
		Inflation = 9.9999997473788e-005,
		Deflation = 9.9999997473788e-005,
		WorkAmount = 0.1
	}
}
function SW.SV.TransformTableToMarketData( _t)
	local n = table.getn(_t)
	LuaDebugger.Log(n)
	local p = S5Hook.GetRawMem(S5Hook.ReAllocMem( 0, n*8*4))
	LuaDebugger.Log(p:GetInt())
	for i = 0, n-1 do
		local t = _t[i+1]
		p[8*i]:SetInt(7794472) --set vTable
		p[8*i+1]:SetInt(t.RessType)
		p[8*i+2]:SetFloat(t.BasePrice)
		p[8*i+3]:SetFloat(t.MinPrice)
		p[8*i+4]:SetFloat(t.MaxPrice)
		p[8*i+5]:SetFloat(t.Inflation)
		p[8*i+6]:SetFloat(t.Deflation)
		p[8*i+7]:SetFloat(t.WorkAmount)
	end
	return p
end
function SW.SV.ReplaceMarketData( _newData)
	local n = table.getn( _newData)
	local p1 = SW.SV.TransformTableToMarketData( _newData)
	local p2 = SW.SV.GetLogicXMLPointer()
	LuaDebugger.Log("Old vals: "..p2[15]:GetInt().." "..p2[16]:GetInt())
	p2[15]:SetInt(p1:GetInt())
	p2[16]:SetInt(p1:Offset(8*n):GetInt())
	p2[17]:SetInt(p1:Offset(8*n):GetInt())
end
SVTests = {}
function SVTests.StartWatch()
	SVTests.eId = GUI.GetSelectedEntity()
	SVTests.p = S5Hook.GetEntityMem(SVTests.eId)[31][2][4]
	SVTests.Val = SVTests.p:GetInt()
	LuaDebugger.Log("Start watching with val = "..SVTests.Val)
	SVTests_WatchJob = function()
		if SVTests.p:GetInt() ~= SVTests.Val then
			local newVal = SVTests.p:GetInt()
			LuaDebugger.Log("Regsitered change from "..SVTests.Val.." to "..newVal.."; Diff "..(newVal-SVTests.Val))
			SVTests.Val = newVal
		end
	end
	StartSimpleJob("SVTests_WatchJob")
	Game.GameTimeSetFactor(10)
end
function SVTests.GetBehP()
	local p = S5Hook.GetRawMem(9002416)[0][16][Entities.PU_Serf*8+5][6][8]
	for i = 0, 19 do 
		LuaDebugger.Log(i.." "..p[i]:GetInt())
	end
	return p
end
function SVTests.PrintMarketData( _offset)
	local p = SW.SV.GetLogicXMLPointer()[15]
	LuaDebugger.Log("RessType = "..SVTests.GetRessTypeName( p[_offset*8+1]:GetInt())..",")
	LuaDebugger.Log("BasePrice = "..p[_offset*8+2]:GetFloat()..",")
	LuaDebugger.Log("MinPrice = "..p[_offset*8+3]:GetFloat()..",")
	LuaDebugger.Log("MaxPrice = "..p[_offset*8+4]:GetFloat()..",")
	LuaDebugger.Log("Inflation = "..p[_offset*8+5]:GetFloat()..",")
	LuaDebugger.Log("Deflation = "..p[_offset*8+6]:GetFloat()..",")
end
function SVTests.GetRessTypeName( _index)
	for k,v in pairs(ResourceType) do
		if _index == v then
			return "ResourceType."..k
		end
	end
	return _index
end
function SVTests.GetDamageClassPointer()
	--[[
	SIMI:
	(0x85A3DC)[0][2][0]
	(0x85A3DC)[0][2][1]
	...
	(0x85A3DC)[0][2][8]
	]]
	return S5Hook.GetRawMem(8758236)[0][2]
end
function SVTests.ScanPInt( _p, _m)
	for i = 0, _m do
		LuaDebugger.Log(i.." ".._p[i]:GetInt())
	end
end
function SVTests.ScanPFloat( _p, _m)
	for i = 0, _m do
		LuaDebugger.Log(i.." ".._p[i]:GetFloat())
	end
end
SVTests.VTable = 7836116 --GGL::CAffectMotivationBehaviorProps
function SVTests.Print( _eType, _lim)
	local pointer = SW.SV.SearchForBehTable( _eType, SVTests.VTable)
	if pointer == nil then return end
	for i = 0, _lim do
		LuaDebugger.Log(i.." "..pointer[i]:GetInt().." "..pointer[i]:GetFloat())
	end
end

-- Data GGL::CKegPlacerBehaviorProperties
--[[
-- > for i = 0, 20 do LuaDebugger.Log(i.." "..typePointer[8*631+5][18][i]:GetInt()) end
-- Log: "0 7824308"
-- Log: "1 7824296"		GGL::CKegPlacerBehavior?
-- Log: "2 9"			GGL::CKegPlacerBehavior?
-- Log: "3 -1089384361"
-- Log: "4 90"			RechargeTime
-- Log: "7 335"			TaskLists?
-- Log: "8 336"			TaskLists?
-- Log: "9 736"			Entity Type
-- Log: "10 1116320153"
-- Log: "11 -1946148832"
-- Floats:
-- Log: "3 -0.5676321387291"
-- Log: "5 5"			ArmTime
-- Log: "6 3"			DisarmTime
-- Log: "10 68.846870422363"
-- Log: "11 -9.8704285808038e-032"
--]]
-- Data GGL::CThiefBehaviorProperties
--[[
-- > for i = 0, 20 do LuaDebugger.Log(i.." "..typePointer[8*631+5][16][i]:GetInt().." "..typePointer[8*631+5][16][i]:GetFloat()) end
-- Log: "0 7813600 1.0949185680848e-038"		vTable
-- Log: "1 7813588 1.0949168865267e-038"		GGL::CThiefBehavior?
-- Log: "2 8 1.1210387714599e-044"				GGL::CThiefBehavior?
-- Log: "3 2061913623 5.9790606382992e+035"
-- Log: "4 5 7.0064923216241e-045"				SecondsNeededToSteal
-- Log: "5 100 1.4012984643248e-043"			MinimumAmountToSteal
-- Log: "6 200 2.8025969286496e-043"			MaximumAmountToSteal
-- Log: "7 647 9.0664010641816e-043"			CarryingModelID?
-- Log: "8 331 4.6382979169151e-043"			TL_THIEF_STEAL_GOODS?
-- Log: "9 332 4.6523109015584e-043"			TL_THIEF_SECURE_GOODS?
-- Log: "10 1116320131 68.846702575684"
-- Log: "11 -2013223150 -3.8714989096279e-034"
--]]
-- Data CLeaderBehaviorProps
--[[
> for i = 0, 30 do LuaDebugger.Log(i.." "..S5Hook.GetRawMem(9002416)[0][16][223*8+5][6][i]:GetInt()) end
Log: "0 7823268"
Log: "1 7823256"
Log: "13 2"					--DamageClass
Log: "14 8"					--Damage
Log: "17 14"				--EffektId Projektil
Log: "21 2500"				--BattleWaitUntil
Log: "22 12"				--MissChance
Log: "25 227"				--SOLDIER TYPE
Log: "26 25"				--BarrackUpgradeCategory
Log: "28 5"					--HealingPoints
Log: "29 3"					--HealingSecs
> for i = 0, 30 do LuaDebugger.Log(i.." "..S5Hook.GetRawMem(9002416)[0][16][223*8+5][6][i]:GetFloat()) end
Entry 16: AoE-Range?
Log: "23 2300"				--MaxRange
Log: "24 500"				--MinRange
Log: "27 2000"				--HomeRadius
Log: "30 2300"				--AARange 
Entry 31: Upkeep
]]
-- Data CSoldierBehaviorProps
--[[
> for i = 0, 40 do LuaDebugger.Log(i.." "..p[4][i]:GetFloat()) end
Log: "23 2500"				--MaxRange
> for i = 0, 40 do LuaDebugger.Log(i.." "..p[4][i]:GetInt()) end
Log: "0 7814416"
Log: "1 7814404"
Log: "2 2"
Log: "13 2"					--DamageClass
Log: "14 8"					--Damage
Log: "15 2"					--MaxRdnDamageBonus
Log: "17 14"				--EffectId Projektil
Log: "21 2500"				--BattleWaitUntil
Log: "22 12"				--MissChance]]
-- Data GGL::CServiceBuildingBehaviorProperties per Entity(Märkte + Hochschulen?)
--[[
Relevant für Markt:
EntityMem[31][1]
7(Float): Das, was ausbezahlt wird, auch relevant für Auszahlung
8(Float): Das, was man bezahlt hat
9(Float): Progress, zwischen 0 und ([7]+[8])/10
5(Int): RessType von dem, was verkauft
6(Int): RessType von dem, was angekauft wird
2(Int): EntityId Markt
0(Int): VTable; 7822540
3(Int): Zeigt auf typweiten Kram?
4(Int): PlayerID, die Trade bekommt
]]
-- Data GGL::CServiceBuildingBehaviorProperties for all entities
--[[
-- Index Int Float
Log: "0 7817264 1.0954320038422e-038"
Log: "1 7817252 1.095430322284e-038"
Log: "2 1 1.4012984643248e-045"
Log: "3 -1868218729 -6.5177459604168e-029"
Log: "4 1148846080 1000"
]]
-- Data for markets
-- LogicXMLPointers:
-- Log: "15 333070544"
-- Log: "16 333070736"
-- Log: "17 333070736"
