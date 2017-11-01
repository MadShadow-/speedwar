--	Sync:
--		Sync.Call sends Sync.KeyPrep.."something" to all players via message
--		Receivers send Sync.KeyAck message
--		Once all players sent Sync.KeyAck, tribute will be paid


Sync = {};
function Sync.Init()
	
	Sync.Key = "SyncXYZABC";
	Sync.KeyPrep = Sync.Key .. "_Prepare";
	Sync.KeyPrep_Length = string.len(Sync.KeyPrep);
	Sync.KeyAck = Sync.Key .. "_Acknowledge";
	Sync.KeyAck_Length = string.len(Sync.KeyAck);
	Sync.KeyNoSyncCall = "_NoSync";
	Sync.KeyNoSyncCall_Length = string.len(Sync.KeyNoSyncCall);
	Sync.NumOfTributes = 100;
	Sync.UseWhitelist = false;
	Sync.Whitelist = {
		["SW.Activate"] = true,
		["SW.Bastille.TrackGroup"] = true,
		["SW.Bastille.SpawnReleasedUnit"] = true,
		["DestroyEntity"] = true,
		["SW.Walls.ToggleGate"] = true,
		["SW.WallGUI.PayCosts"] = true,
		["SW.WallGUI.AddWallInConstructionToQueue"] = true,
	};

	GameCallback_FulfillTribute = function() return 1 end
	
	Sync.GetTribut = function(_player, _index)
		return AddTribute({
			text = "",
			cost = {},
			pId = 8,
			Callback = function()
				local fs = Sync.Tributes[_player][_index].FunctionString;
				SW.PreciseLog.Log("Calling "..fs)
				if fs ~= "" then
					Sync.ExecuteFunctionByString(fs);
				else
					SW.PreciseLog.Log("Sync: function string not set")
				end
				Sync.Tributes[_player][_index].Id = Sync.GetTribut(_player, _index);
				Sync.Tributes[_player][_index].InUse = false;
				Sync.Tributes[_player][_index].Completion = {}
			end
			});
	end
	
	Sync.Tributes = {};
	for playerId = 1,8 do
		Sync.Tributes[playerId] = {};
		for i = 1, Sync.NumOfTributes do
			Sync.Tributes[playerId][i] = {
				Id = Sync.GetTribut(playerId, i),
				FunctionString = "",
				InUse = false,
			};
		end
	end
	
	Sync.MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage;
	MPGame_ApplicationCallback_ReceivedChatMessage = function( _Message, _AlliedOnly, _SenderPlayerID )
		SW.PreciseLog.Log( "Received by ".._SenderPlayerID.." ".._Message, "Chat")
		if string.find(_Message, Sync.KeyPrep, 1, true) then
			local tributPlayer = tonumber(string.sub(_Message, Sync.KeyPrep_Length +1, Sync.KeyPrep_Length +1)); -- ex "2" - 1 digit
			local indexString = string.sub(_Message, Sync.KeyPrep_Length +2, Sync.KeyPrep_Length +5); -- ex "0010" - 4 digits
			local tributIndex = tonumber(indexString);
			local fs = string.sub(_Message, Sync.KeyPrep_Length + 6);
			Sync.Tributes[tributPlayer][tributIndex].FunctionString = fs;
			Sync.Acknowledge(tributPlayer, indexString);
			return;
		elseif string.find(_Message, Sync.KeyAck, 1, true) then
			local tributPlayer = tonumber(string.sub(_Message, Sync.KeyAck_Length +1, Sync.KeyAck_Length +1)); -- ex "2" - 1 digit
			local tributIndex = tonumber(string.sub(_Message, Sync.KeyAck_Length + 2, Sync.KeyAck_Length + 5)); -- ex "0010" - 4 digits
			if GUI.GetPlayerID() == tributPlayer then
				Sync.Complete(tributPlayer, tributIndex, _SenderPlayerID);
			end
			return;
		elseif string.find(_Message, Sync.KeyNoSyncCall, 1, true) then
			local sendingPlayer = tonumber(string.sub(_Message, Sync.KeyNoSyncCall_Length +1, Sync.KeyNoSyncCall_Length +1)); -- ex "2" - 1 digit
			local fs = string.sub(_Message, Sync.KeyNoSyncCall_Length + 2); -- start after player
			if GUI.GetPlayerID() ~= sendingPlayer then
				Sync.ExecuteFunctionByString(fs);
			end
			return;
		end
		Sync.MPGame_ApplicationCallback_ReceivedChatMessage(_Message, _AlliedOnly, _SenderPlayerID);
	end

	Sync.GameCallback_GUI_ChatStringInputDone = GameCallback_GUI_ChatStringInputDone;
	GameCallback_GUI_ChatStringInputDone = function(_Message, _WidgetID) 
		if string.find(_Message, Sync.Key , 1, true) then
			return;
		end
		Sync.GameCallback_GUI_ChatStringInputDone(_Message,_WidgetID)
	end
	
end

function Sync.Complete(_player, _index, _ackPlayer)
	Sync.Tributes[_player][_index].Completion = Sync.Tributes[_player][_index].Completion or {};
	table.insert(Sync.Tributes[_player][_index].Completion, _ackPlayer);
	for i = 1, table.getn(SW.Players) do
		if not table.contains(Sync.Tributes[_player][_index].Completion, SW.Players[i]) then
			-- not all players have acknowledged yet
			return;
		end
	end
	-- all players acknowledged
	GUI.PayTribute(8, Sync.Tributes[GUI.GetPlayerID()][_index].Id);
end

function Sync.Acknowledge(_playerId, _indexString)
	Sync.Send(Sync.KeyAck .. _playerId .. _indexString);
end

function Sync.Call( _func, ...)
	local player = GUI.GetPlayerID();
	for i = 1, Sync.NumOfTributes do
		if not Sync.Tributes[player][i].InUse then
			Sync.Tributes[player][i].InUse = true;
			local Id = tostring(i);
			while(string.len(Id) < 4) do
				Id = "0"..Id;
			end
			Sync.Send(
				Sync.KeyPrep .. GUI.GetPlayerID() .. Id ..
				Sync.ConvertFunctionToString( _func, unpack(arg))
			);
			return;
		end
	end
	Message("ERROR: Cant Sync - used more than " .. Sync.NumOfTributes .. " tributes");
end

function Sync.CallNoSync( _func, ...)
	local fs = Sync.ConvertFunctionToString( _func, unpack(arg));
	Sync.Send(
			Sync.KeyNoSyncCall .. GUI.GetPlayerID() .. fs
		);
	-- call local directly
	Sync.ExecuteFunctionByString(fs);
end

function table.contains(_table, _value)
	for k,v in pairs(_table) do
		if v == _value then
			return true;
		end
	end
	return false;
end

Sync.String = {};
Sync.String.Separators = {
	string.char(2),  -- replaces "("
	string.char(3),  -- replaces ")"
	string.char(4),  -- replaces "<"
	string.char(21), -- replaces ">"
	string.char(22), -- replaces ","
};

function Sync.ConvertFunctionToString(_funcName, ...)
	local sx = Sync.String.Separators;
	local str = _funcName;
	for i = 1, table.getn(arg) do
		if type(arg[i]) == "table" then
			str = str .. sx[1] .. type(arg[i]) .. sx[5] .. Sync.ConvertTableToString(arg[i]) .. sx[2];
		else
			str = str .. sx[1] .. type(arg[i]) .. sx[5] .. tostring(arg[i]) .. sx[2];
		end
	end
	return str;
end

function Sync.ExecuteFunctionByString(_str)
	local sx = Sync.String.Separators;
	local layers = {};
	local parameters = {};
	local separator;
	local pType;
	local pValue;
	local layer, layerEnd;
	while(string.find( _str, ".", 1, true) ~= nil ) do
		separator = string.find( _str, ".", 1, true);
		if string.find( _str, sx[1], 1, true) ~= nil then
			if separator > string.find( _str, sx[1], 1, true) then
				-- we may have fullstops in our paramters too.
				break;
			end
		end
		table.insert(layers, string.sub( _str, 1, separator-1));
		_str = string.sub(_str, separator+1);
	end
	separator = string.find( _str, sx[1], 1, true) or (string.len(_str)+1);
	table.insert(layers, string.sub( _str, 1, separator-1));
	_str = string.sub(_str, separator);

	while( string.find( _str, sx[1], 1, true) ~= nil ) do
		separator = string.find( _str, sx[1], 1, true);
		_str = string.sub( _str, separator + 1);
		separator = string.find( _str, sx[5], 1, true);
		pType = string.sub( _str, 1, separator - 1 );
		_str = string.sub( _str, separator + 1 );
		
		if pType == "table" then
			layer = string.find( _str, sx[3], 1, true);
			layerEnd = string.find( _str, sx[3], layer+1, true);
			layer = string.sub(_str, layer+1, layerEnd-1);
			separator = string.find( _str, sx[4] .. layer .. sx[4], 1, true);
			pValue = string.sub( _str, 1, separator);
			pValue = Sync.ConvertStringToTable(pValue)
			_str = string.sub(_str, separator + string.len(sx[4] .. layer .. sx[4]));
		else
			separator = string.find( _str, sx[2], 1, true);
			pValue = string.sub( _str, 1, separator-1);
			if pType == "number" then
				pValue = tonumber(pValue);
			elseif pType == "boolean" then
				if pValue == "true" then
					pValue = true;
				else
					pValue = false;
				end
			elseif pType == "nil" then
				pValue = nil;
			end
		end
		table.insert( parameters, pValue );
	end
	local ref = _G[layers[1]];
	for i = 2, table.getn(layers) do
		ref = ref[layers[i]];
	end
	if not Sync.UseWhitelist then
		ref(unpack(parameters));
	elseif Sync.Whitelist[ref] then
		ref(unpack(parameters));
	else
		local f = "";
		for i = 1, table.getn(layers) do
			f = f .. " " .. tostring(layers[i]);
		end
		local s = "";
		for i = 1, table.getn(parameters) do
			s = s .. "(" .. parameters[i] .. ") ";
		end
		SW.Logging.AddSyncLog("Unauthorized sync call: " .. f .. " with params " .. s);
	end
end

function Sync.ConvertTableToString(_t, _layer)
	local sx = Sync.String.Separators;
	_layer = _layer or 1;
	local str = sx[3] .. _layer .. sx[3];
	for k,v in pairs(_t) do
		str = str .. sx[1] .. type(k) .. sx[5] .. tostring(k) .. sx[5] .. type(v) .. sx[5];
		if type(v) == "table" then
			str = str .. Sync.ConvertTableToString(v, _layer + 1);
		else
			str = str .. tostring(v);
		end
		str = str .. sx[2];
	end
	return str .. sx[4] .. _layer .. sx[4];
end

function Sync.ConvertStringToTable(_str)
	-- ( key type, key, value type, value )
	local sx = Sync.String.Separators;
	local t = {};
	local p = {};
	local layer;
	local layerEnd;
	local separator;
	while( string.find( _str , sx[1], 1, true) ~= nil ) do
		separator = string.find( _str , sx[1], 1, true);
		_str = string.sub(_str, separator+1 );
		for i = 1,3 do
			separator = string.find( _str , sx[5], 1, true);
			p[i] = string.sub( _str, 1, separator - 1);
			_str = string.sub( _str, separator + 1);
		end
		if p[3] == "table" then
			layer = string.find( _str, sx[3], 1, true);
			layerEnd = string.find( _str, sx[3], layer+1, true);
			layer = string.sub(_str, layer+1, layerEnd-1);
			separator = string.find( _str, sx[4] .. layer .. sx[4], 1, true);
			p[4] = string.sub( _str, 1, separator);
			_str = string.sub( _str, separator + 1);
			p[4] = Sync.ConvertStringToTable( p[4] );
		else
			p[4] = string.sub( _str, 1, string.find( _str, sx[2], 1, true) - 1 );
			if p[3] == "number" then
				p[4] = tonumber(p[4]);
			elseif p[3] == "boolean" then
				if p[4] == "false" then
					p[4] = false;
				else
					p[4] = true;
				end
			end
		end
		if p[1] == "number" then
			p[2] = tonumber(p[2]);
		end
		t[p[2]] = p[4];
	end
	return t;
end

function Sync.Send( _str )
	SW.PreciseLog.Log("Sending ".._str, "Chat")
	if SW.IsMultiplayer() then
		XNetwork.Chat_SendMessageToAll( _str );
	else
		MPGame_ApplicationCallback_ReceivedChatMessage( _str, 0, GUI.GetPlayerID() );
	end
end

Sync = Sync2