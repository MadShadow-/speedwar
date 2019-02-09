SW = SW or {}

SW.DesyncDetector = {}
SW.DesyncDetector.CheckSum = 1
SW.DesyncDetector.Intervall = 10
SW.DesyncDetector.Prime = 2017
SW.DesyncDetector.Data = {}
function SW.DesyncDetector.Init()
	if CNetwork == nil then
		return
	end
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_CREATED, nil, "SW_DesyncDetector_OnCreated", 1)
	CNetwork.SetNetworkHandler( "SendChecksum", SW.DesyncDetector.ReceiveChecksum)
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
		CNetwork.send_command( "SendChecksum", SW.DesyncDetector.CheckSum, time)
	end
end
function SW.DesyncDetector.ReceiveChecksum( _sender, _checksum, _time)
	if SW.DesyncDetector.Data[_time] == nil then return end
	if SW.DesyncDetector.Data[_time] ~= _checksum then
		Message("Time: ".._time.."; DESYNC WITH ".._sender.." FOUND!")
	end
end