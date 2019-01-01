SW = SW or {}


SW.ScriptingValueBackup = SW.ScriptingValueBackup or {};
SW.ScriptingValueBackup.ConstructionCosts = SW.ScriptingValueBackup.ConstructionCosts or {};
SW.ScriptingValueBackup.RecruitingCosts = SW.ScriptingValueBackup.RecruitingCosts or {};
SW.ScriptingValueBackup.UpgradeCosts = SW.ScriptingValueBackup.UpgradeCosts or {};
SW.ScriptingValueBackup.TechCosts = SW.ScriptingValueBackup.TechCosts or {};
SW.ScriptingValueBackup.TechBuildReq = SW.ScriptingValueBackup.TechBuildReq or {}
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
	["WorkTimeChangeWork"] = {2, 7809936, 17, true},
	["RecruitingTime"] = {2, 7834420, 9, false},
	["RefinedPerTick"] = {2, 7818276, 5, false},
	["WorkerTransportAmount"] = {2, 7809936, 24, true},
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
    ["ThiefMaximumAmountToSteal"] = {2, 7813600, 6, true} --default 200
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

function SW.SV.GetTechData( _tId)
	return S5Hook.GetRawMem(8758176)[0][13][1][ _tId-1]
end
SVTests = {}
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
