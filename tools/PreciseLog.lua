--Precise logging

-- Creates a log command

-- Keeps the last 10 000 logs in memory
-- Useful for logging a lot of small things


SW = SW or {}
SW.PreciseLog = {}
SW.PreciseLog.Keeping = 10000
SW.PreciseLog.Indizes = {}
SW.PreciseLog.Data = {}
SW.PreciseLog.CurrIndex = 0
function SW.PreciseLog.TrackCreateEntity()
	SW.PreciseLog.CreateEntity = Logic.CreateEntity
	Logic.CreateEntity = function( _eType, _x, _y, _rot, _pId)
		local eId = SW.PreciseLog.CreateEntity( _eType, _x, _y, _rot, _pId)
		SW.PreciseLog.Log("CreateEntity: "..tostring(_eType).." "..tostring(_x).." "..tostring(_y).." "..tostring(_rot).." "..tostring(_pId).." "..eId, "Create")
		return eId
	end
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_CREATED, nil, "SW_PreciseLog_OnCreate", 1)
	Trigger.RequestTrigger( Events.LOGIC_EVENT_ENTITY_DESTROYED, nil, "SW_PreciseLog_OnDestroyed", 1)
end
function SW_PreciseLog_OnCreate()
	local eId = Event.GetEntityID()
	SW.PreciseLog.Log("Created: "..eId.." of type "..tostring(Logic.GetEntityTypeName(Logic.GetEntityType(eId))).." at "
	..GetPosition(eId).X.." "..GetPosition(eId).Y.." time "..Logic.GetTimeMs(), "OnCreate")
end
function SW_PreciseLog_OnDestroyed()
	local eId = Event.GetEntityID()
	SW.PreciseLog.Log("Destroyed: "..eId.." of type "..tostring(Logic.GetEntityTypeName(Logic.GetEntityType(eId))).." at "
	..GetPosition(eId).X.." "..GetPosition(eId).Y.." time "..Logic.GetTimeMs(), "OnDestroyed")
end
function SW.PreciseLog.Log(_s, _key)
	if _key == nil then
		_key = "General"
	end
	if SW.PreciseLog.Data[_key] == nil then
		SW.PreciseLog.Data[_key] = {}
		SW.PreciseLog.Indizes[_key] = 0
	end
	SW.PreciseLog.Indizes[_key] = SW.PreciseLog.GetNextIndex(SW.PreciseLog.Indizes[_key])
	SW.PreciseLog.Data[_key][SW.PreciseLog.Indizes[_key]] = Logic.GetTimeMs().." ".._s
end
function SW.PreciseLog.PrintLatestLogs(_n, _key)
	if _key == nil then _key = "General" end
	local currIndex = SW.PreciseLog.Indizes[_key]
	for i = 1, _n do
		if SW.PreciseLog.Data[_key][currIndex] ~= nil then
			LuaDebugger.Log(i..": "..SW.PreciseLog.Data[_key][currIndex])
		end
		currIndex = SW.PreciseLog.GetPriorIndex(currIndex)
	end
end
function SW.PreciseLog.GetNextIndex( _n)
	if _n >= SW.PreciseLog.Keeping then
		return 1
	else
		return _n+1
	end
end
function SW.PreciseLog.GetPriorIndex(_n)
	if _n >= 2 then
		return _n-1
	else
		return SW.PreciseLog.Keeping
	end
end
SW.PreciseLog.TrackCreateEntity()

--SW.PreciseLog.PrintLatestLogs(100);SW.PreciseLog.PrintLatestLogs(100,"WallGUI");SW.PreciseLog.PrintLatestLogs(100,"Chat");