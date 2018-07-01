SW = SW or {}

SW.ThiefBuff = {}
SW.ThiefBuff.Range = 800
SW.ThiefBuff.ToDestroy = {}
SW.ThiefBuff.IsJobRunning = false
function SW.ThiefBuff.Init()
	-- try to catch all explosions
	Trigger.RequestTrigger(Events.LOGIC_EVENT_ENTITY_DESTROYED, "SW_Thief_IsKeg", "SW_Thief_OnKegDestroyed", 1)
	-- make walls die after one bomb; KegFactor = 1 equals 70% MaxHP damage
	SW.SetKegFactor( Entities.XD_WallStraight, 2)
	SW.SetKegFactor( Entities.XD_WallStraightGate, 2)
	SW.SetKegFactor( Entities.XD_WallStraightGate_Closed, 2)
	-- command to make thief bomb need more time to explode:
	-- SW.SetThiefKegDelay( Entities.XD_Keg1, _time); time in seconds
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
	-- so keg is  exploded, get position and playerId
	local eId = Event.GetEntityID()
	local pId = Logic.EntityGetPlayer( _eId)
	local x, y = Logic.EntityGetPos( _eId)
	local playerList  = {}
	for i = 1, 8 do
		if Logic.GetDiplomacyState( pId, i) == Diplomacy.Hostile then
			table.insert( playerList, i)
		end
	end
	local typePred = Predicate.OfAnyType( Entities.XD_WallStraight, Entities.XD_WallStraightGate, Entities.XD_WallStraightGate_Closed)
	local playerPred = Predicate.OfAnyPlayer(unpack(playerList))
	local rangePred = Predicate.InCircle( x, y, SW.ThiefBuff.Range)
	for eId in S5Hook.EntityIterator( rangePred, typePred, playerPred) do
		table.insert( SW.ThiefBuff.ToDestroy, eId)
	end
	if table.getn( SW.ThiefBuff.ToDestroy) > 0 and not SW.ThiefBuff.IsJobRunning then
		SW.ThiefBuff.IsJobRunning = true
		StartSimpleHiResJob("SW_ThiefBuff_Job")
	end
end
function SW_ThiefBuff_Job()
	SW.ThiefBuff.IsJobRunning = false
	local pos;
	for k,v in pairs(SW.ThiefBuff.ToDestroy) do
		pos = GetPosition( v)
		Logic.CreateEffect( GGL_Effects.FXExplosionShrapnel, pos.X, pos.Y, 1)
		Logic.HurtEntity( v, 5000)  -- KILL IT HARD
	end
	SW.ThiefBuff.ToDestroy = {}
	return true
end
