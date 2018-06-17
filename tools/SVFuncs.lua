SW = SW or {}


SW.ScriptingValueBackup = SW.ScriptingValueBackup or {};
SW.ScriptingValueBackup.ConstructionCosts = SW.ScriptingValueBackup.ConstructionCosts or {};
SW.ScriptingValueBackup.RecruitingCosts = SW.ScriptingValueBackup.RecruitingCosts or {};
SW.ScriptingValueBackup.UpgradeCosts = SW.ScriptingValueBackup.UpgradeCosts or {};
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
	["PlacesProvided"] = {2, 7823028, {5,7}, true}
}

SW.SV.BackUps = {}
-- Makes use of upvalues!
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

SVTests = {}
SVTests.VTable = 7836116 --GGL::CAffectMotivationBehaviorProps
function SVTests.Print( _eType, _lim)
	local pointer = SW.SV.SearchForBehTable( _eType, SVTests.VTable)
	if pointer == nil then return end
	for i = 0, _lim do
		LuaDebugger.Log(i.." "..pointer[i]:GetInt().." "..pointer[i]:GetFloat())
	end
end


