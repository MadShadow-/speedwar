SW = SW or {}


SW.ScriptingValueBackup = SW.ScriptingValueBackup or {};
SW.ScriptingValueBackup.ConstructionCosts = SW.ScriptingValueBackup.ConstructionCosts or {};
SW.ScriptingValueBackup.RecruitingCosts = SW.ScriptingValueBackup.RecruitingCosts or {};
SW.ScriptingValueBackup.UpgradeCosts = SW.ScriptingValueBackup.UpgradeCosts or {};
SW.ScriptingValueBackup.UpgradeTime = SW.ScriptingValueBackup.UpgradeTime or {};
SW.ScriptingValueBackup.ConstructionTime = SW.ScriptingValueBackup.ConstructionTime or {};
SW.ScriptingValueBackup.Exploration = SW.ScriptingValueBackup.Exploration or {};
SW.ScriptingValueBackup.RecruitingTime = SW.ScriptingValueBackup.RecruitingTime or {};
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
	
	for k, v in pairs(SW.ScriptingValueBackup.UpgradeTime) do
		SW.SetUpgradeTime(k,v);
	end;
	for k, v in pairs(SW.ScriptingValueBackup.ConstructionTime) do
		SW.SetConstructionTime(k,v);
	end;
	for k, v in pairs(SW.ScriptingValueBackup.Exploration) do
		SW.SetExploration(k,v);
	end;
	for k, v in pairs(SW.ScriptingValueBackup.RecruitingTime) do
		SW.SetRecruitingTime(k,v);
	end;
end;

--HelperFunc: Set Movement speed of given entity
function SW.SetMovementspeed( _eId, _ms)
	S5Hook.GetEntityMem( _eId)[31][1][5]:SetFloat( _ms)
end
--HelperFunc: Get Movement speed of given entity
function SW.GetMovementspeed( _eId)
	return S5Hook.GetEntityMem( _eId)[31][1][5]:GetFloat()
end
--HelperFunc: Set construction time of given entity type, developed by mcb
function SW.SetConstructionTime( _eType, _time)
	SW.ScriptingValueBackup.ConstructionTime[_eType] = SW.ScriptingValueBackup.ConstructionTime[_eType] or SW.GetConstructionTime(_eType);
	S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][55]:SetInt(_time);
end
--HelperFunc: Get construction time of given entity type, developed by mcb
function SW.GetConstructionTime( _eType)
	return S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][55]:GetInt();
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
	if Logic.IsLeader(id) == 0 then
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
--HelperFunc: Set exploration range in settler meters
function SW.SetExploration( _eType, _range)
	SW.ScriptingValueBackup.Exploration[_eType] = SW.ScriptingValueBackup.Exploration[_eType] or SW.GetExploration(_eType);
	S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][19]:SetFloat( _range);
end
--HelperFunc: Get exploration range in settler meters
function SW.GetExploration( _eType)
	S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][19]:GetFloat();
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
--HelperFunc: Get upgrade time of given building
function SW.GetUpgradeTime( _eType)
	return S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][80]:GetFloat();
end
--HelperFunc: Set upgrade time of given building
function SW.SetUpgradeTime( _eType, _time)
	SW.ScriptingValueBackup.UpgradeTime[_eType] = SW.ScriptingValueBackup.UpgradeTime[_eType] or SW.GetUpgradeTime(_eType);
	S5Hook.GetRawMem(9002416)[0][16][_eType * 8 + 2][80]:SetFloat( _time);
end
-- Set recruiting time for this building type, only for barracks, archerys and stables!
function SW.SetRecruitingTime( _eType, _time)
	local index = {
		[Entities.PB_Barracks1] = 4,
		[Entities.PB_Barracks2] = 4,
		[Entities.PB_Archery1] = 4,
		[Entities.PB_Archery2] = 6,
		[Entities.PB_Stable1] = 4,
		[Entities.PB_Stable2] = 4
	}
	if index[_eType] == nil then return false end
	local behTable = S5Hook.GetRawMem(9002416)[0][16][_eType*8+5][index[_eType]]
	if behTable[0] ~= 7834420 then return false end		--GGL::CBarrackBehavior == 7834420
	SW.ScriptingValueBackup.RecruitingTime[_eType] = SW.ScriptingValueBackup.RecruitingTime[_eType] or SW.GetRecruitingTime(_eType)
	behTable[9]:SetFloat( _time)
end
-- Get recruiting time for this building type, only for barracks, archerys and stables!
function SW.GetRecruitingTime( _eType)
	local index = {
		[Entities.PB_Barracks1] = 4,
		[Entities.PB_Barracks2] = 4,
		[Entities.PB_Archery1] = 4,
		[Entities.PB_Archery2] = 6,
		[Entities.PB_Stable1] = 4,
		[Entities.PB_Stable2] = 4
	}
	if index[_eType] == nil then return 0 end
	local behTable = S5Hook.GetRawMem(9002416)[0][16][_eType*8+5][index[_eType]]
	if behTable[0] ~= 7834420 then return 0 end		--GGL::CBarrackBehavior == 7834420
	return behTable[9]:GetFloat()
end
