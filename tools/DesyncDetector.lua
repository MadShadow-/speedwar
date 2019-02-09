SW = SW or {}

SW.DesyncDetector = {}
SW.DesyncDetector.CheckSum = 1
SW.DesyncDetector.Intervall = 10
SW.DesyncDetector.Prime = 2017
SW.DesyncDetector.Data = {}
SW.DesyncDetector.Key = "DeSyNcDeTeCtOr"
function SW.DesyncDetector.Init()
	if CNetwork == nil then
		return
	end
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, nil, "SW_DesyncDetector_OnCreated", 1)
	
	SW.DesyncDetector.ApplicationCallback_ReceivedChatMessageRaw = ApplicationCallback_ReceivedChatMessageRaw
	ApplicationCallback_ReceivedChatMessageRaw = function( _name, _msg, color, allied, _sender)
		local _, endd = string.find( _msg, SW.DesyncDetector.Key)
		if endd then
			SW.DesyncDetector.OnReceivedMsg( string.sub( _msg, endd+1), _sender, _name)
			return true
		else
			return SW.DesyncDetector.ApplicationCallback_ReceivedChatMessageRaw( _name, _msg, color, allied, _sender)
		end
	end
	StartSimpleJob("SW_DesyncDetector_Job")
end
function SW_DesyncDetector_OnCreated()
	local eId = Event.GetEntityID()
	local typee = Logic.GetEntityType(eId)
	local val = math.mod(eId*typee, SW.DesyncDetector.Prime)
	if val == 0 then
		val = 1
	end
	SW.DesyncDetector.CheckSum = math.mod(SW.DesyncDetector.CheckSum*val, SW.DesyncDetector.Prime)
	local pos = GetPosition(eId)
	val = math.mod(math.floor(pos.X)*math.floor(pos.Y), SW.DesyncDetector.Prime)
	if val == 0 then
		val = 1
	end
	SW.DesyncDetector.CheckSum = math.mod(SW.DesyncDetector.CheckSum*val, SW.DesyncDetector.Prime)
end
function SW_DesyncDetector_Job()
	if Counter.Tick2("DesyncDetector", SW.DesyncDetector.Intervall) then
		local time = math.ceil(Logic.GetTime())
		SW.DesyncDetector.Data[time] = SW.DesyncDetector.CheckSum
		SW.DesyncDetector.Send( SW.DesyncDetector.CheckSum, time)
	end
end
function SW.DesyncDetector.Send( _sum, _time)
	if XNetwork then
		XNetwork.Chat_SendMessageToAll(SW.DesyncDetector.Key.." C".._sum.."T".._time)
	end
end
function SW.DesyncDetector.OnReceivedMsg( _msg, _sender, _name)
	local start = string.find( _msg, "C")
	local start2 = string.find( _msg, "T")
	local n1 = tonumber(string.sub(_msg, start+1, start2-1))
	local n2 = tonumber(string.sub(_msg, start2+1))
	--LuaDebugger.Log(n1.." "..n2)
	if n1 == nil or n2 == nil then return end
	if n2 < 1 or n2 ~= math.floor(n2) then return end
	SW.DesyncDetector.ReceiveChecksum( UserTool_GetPlayerName( _sender), n1, n2)
end
function SW.DesyncDetector.ReceiveChecksum( _sender, _checksum, _time)
	if SW.DesyncDetector.Data[_time] == nil then return end
	if SW.DesyncDetector.Data[_time] ~= _checksum then
		Message("Time ".._time..": DESYNC WITH ".._sender.." FOUND!")
	end
end