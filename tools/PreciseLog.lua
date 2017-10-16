--Precise logging

-- Creates a log command

-- Keeps the last 10 000 logs in memory
-- Useful for logging a lot of small things


SW = SW or {}
SW.PreciseLog = {}
SW.PreciseLog.Keeping = 10000
SW.PreciseLog.Data = {}
SW.PreciseLog.CurrIndex = 0
function SW.PreciseLog.TrackCreateEntity()
	SW.PreciseLog.CreateEntity = Logic.CreateEntity
	Logic.CreateEntity = function( _eType, _x, _y, _rot, _pId)
		SW.PreciseLog.CreateEntity( _eType, _x, _y, _rot, _pId)
		SW.PreciseLog.Log("CreateEntity: "..tostring(_eType).." "..tostring(_x).." "..tostring(_y).." "..tostring(_rot).." "..tostring(_pId))
	end
end
function SW.PreciseLog.Log(_s)
	SW.PreciseLog.CurrIndex = SW.PreciseLog.GetNextIndex(SW.PreciseLog.CurrIndex)
	SW.PreciseLog.Data[SW.PreciseLog.CurrIndex] = _s
end
function SW.PreciseLog.PrintLatestLogs(_n)
	local currIndex = SW.PreciseLog.CurrIndex
	for i = 1, _n do
		if SW.PreciseLog.Data[currIndex] ~= nil then
			LuaDebugger.Log(i..": "..SW.PreciseLog.Data[currIndex])
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