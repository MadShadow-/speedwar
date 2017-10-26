SW = SW or {};
SW.Logging = {};
function SW.Logging.Init()
	SW.Logging.NrOfLogs = 0;
	SW.Logging.Sync = {};
	SW.Logging.Pussy = {};
	if xXPussySlayer69Xx then
		Sync.Call("SW.Logging.PussyDetection", GUI.GetPlayerID());
	end
end

function SW.Logging.GetCurrentTimeStamp()
	return "[TIME:"..math.floor(Logic.GetTime()).."s] ";
end

function SW.Logging.AddSyncLog(_text)
	SW.Logging.NrOfLogs = SW.Logging.NrOfLogs + 1;
	table.insert(SW.Logging.SyncLogs, SW.Logging.GetCurrentTimeStamp() .. _text);
end

function SW.Logging.PussyDetection(_player)
	table.insert(SW.Logging.Pussy, "Player " .. tostring(_player) .. " " .. UserTool_GetPlayerName(_player) .. " might be a pussy!");
end