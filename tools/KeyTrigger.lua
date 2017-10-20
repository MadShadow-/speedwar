SW = SW or {};
SW.KeyTrigger = {};

-- TODO: One table for functions that should be called with every key

function SW.KeyTrigger.Init()
	SW.KeyTrigger.Callbacks = {};
	S5Hook.SetKeyTrigger(SW.KeyTrigger.Trigger);
	-- Keys:
	SW.KeyTrigger.Add(70, SW.WallGUI.WallHotKey);
end

function SW.KeyTrigger.Add(_keyCode, _callback)
	if SW.KeyTrigger.Callbacks[_keyCode] == nil then
		SW.KeyTrigger.Callbacks[_keyCode] = _callback;
	elseif type(SW.KeyTrigger.Callbacks[_keyCode]) == "function" then
		local f = SW.KeyTrigger.Callbacks[_keyCode];
		SW.KeyTrigger.Callbacks[_keyCode] = {f, _callback};
	else
		table.insert(SW.KeyTrigger.Callbacks[_keyCode], f);
	end
end

function SW.KeyTrigger.Trigger(_keyCode, _keyIsUp)
	if not SW.KeyTrigger.Callbacks[_keyCode] then
		return;
	end
	
	if type(SW.KeyTrigger.Callbacks[_keyCode]) == "function" then
		SW.KeyTrigger.Callbacks[_keyCode](_keyIsUp);
	else
		for i = 1, table.getn(SW.KeyTrigger.Callbacks[_keyCode]) do
			SW.KeyTrigger.Callbacks[_keyCode](_keyIsUp);
		end
	end
end