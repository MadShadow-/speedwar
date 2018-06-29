SW = SW or {}

SW.ThiefBuff = {}

function SW.ThiefBuff.Init()
	-- try to catch all explosions
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_Thief_IsKeg", "SW_Thief_OnKegDestroyed", 1)
end
function SW_Thief_IsKeg()
	return Logic.GetEntityType(Event.GetEntityID()) == Entities.XD_Keg1
end
function SW_Thief_OnKegDestroyed()
	local eId = Event.GetEntityID()
	if SW.GetKegTimer( eId) ~= 0 then return end -- bomb defused
	SW.ThiefBuff.OnKegExploded(eId)
end
function SW.ThiefBuff.OnKegExploded( _eId)
	
end