-- SW = SW or {}
-- SW.Debug = {}

-- SW.Debug.StopTick = 17140
-- SW.Debug.TriggerArg = {}
-- function SW.Debug.HookIntoRequestTrigger()
	-- Trigger_RequestTrigger = Trigger.RequestTrigger
	-- Trigger.RequestTrigger = function( _t, _conName, _acName, _active)
		-- LuaDebugger.Log("Registered type "..SW.Debug.GetEventNameById(_t).." with condition "..(_conName or "").." and action "..(_acName or ""))
		-- if _conName ~= nil then
			-- _G[_conName.."Hooked"] = function()
				-- if SW.Debug.VerboseConMet() then
					-- LuaDebugger.Log("Calling ".._conName)
				-- end
				-- return _G[_conName]()
			-- end
		-- end
	-- end
-- end
-- function SW.Debug.GetEventNameById( _id)
	-- for k,v in pairs(Events) do
		-- if v == _id then return k end
	-- end
	-- return "UNKNOWN"
-- end