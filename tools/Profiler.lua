-- SimpleJob profiler

-- Searches for ineffecient simple jobs

SW = SW or {}
SW.Profiler = {}
SW.Profiler.Jobs = {} --key = jobId, val = name
SW.Profiler.UniqueId = 1
SW.Profiler.CriticalJobs = {} --key: name, val: maxTimeUsed
SW.Profiler.CriticalTime = 0.005
function SW.Profiler.Init()
	StartSimpleJob("SW_Profiler_Job")
	StartSimpleJob = function( _name)
		SW.Profiler.Jobs[SW.Profiler.UniqueId] = _name
		SW.Profiler.UniqueId = SW.Profiler.UniqueId + 1
		return SW.Profiler.UniqueId - 1
	end
	EndJob = function( _id)
		SW.Profiler.Jobs[_id] = ""
	end
end
function SW_Profiler_Job()
	local s, t1, t2, diff
	for i = 1, table.getn(SW.Profiler.Jobs) do
		s = SW.Profiler.Jobs[i]
		if s ~= "" then
			t1 = XGUIEng.GetSystemTime()
			_G[s]()
			t2 = XGUIEng.GetSystemTime()
			diff = t2 - t1
			if diff > SW.Profiler.CriticalTime then
				--SW.PreciseLog.Log("Job "..s.." needs "..diff)
				if SW.Profiler.CriticalJobs[s] == nil or SW.Profiler.CriticalJobs[s] < diff then
					SW.Profiler.CriticalJobs[s] = diff
				end
			end
		end
	end
end
SW.Profiler.Init()