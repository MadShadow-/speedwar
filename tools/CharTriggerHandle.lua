--[[
	Char Trigger Handle
	Author: MadShadow

	Ermöglicht die gleichzeitige Verwendung mehrerer Char Trigger.
	Benötigt den S5Hook.
	
	Beispiel:
	function MyCharTrigger(charAsNum)
		Message(charAsNum)
	end
	myCTId = CTH.RegisterCT(MyCharTrigger);
	...
	CTH.RemoveCT(myCTId);
]]

CTH = {Active=false,Trigger={}};

function CTH.RegisterCT(_function)
	assert(S5Hook, "S5Hook not found!");
	local id = 0;
	while(CTH.Trigger[id]~=nil) do
		id = id + 1;
	end
	CTH.Trigger[id] = _function;
	if not CTH.Active then
		S5Hook.SetCharTrigger(CTH.CharTrigger);
		CTH.Active = true;
	end
	return id;
end

function CTH.RemoveCT(_id)
	CTH.Trigger[_id] = nil;
	for k,v in pairs(CTH.Trigger) do
		return;
	end
	S5Hook.RemoveCharTrigger()
	CTH.Active = false;
end

function CTH.CharTrigger(charAsNum)
	for k, f in pairs(CTH.Trigger) do
		f(charAsNum);
	end
end