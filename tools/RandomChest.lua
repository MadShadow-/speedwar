-- RANDOM CHESTS :D

SW = SW or {}

SW.RandomChest = {}
SW.RandomChest.Number = 15 --Number of random chests generated
SW.RandomChest.OpeningRange = 500		--Opening range for l1-norm(taxidriver-norm, manhatten-norm, sum-norm), not l2-norm(euclidian)
										--Equivalence of norms on R^2 guarentees ||x||_2 <= ||x||_1 <= sqrt(2)||x||_2
SW.RandomChest.Action =  {}
SW.RandomChest.Keys = {}
SW.RandomChest.ListOfChests = {}
SW.RandomChest.SolarEclipseJobID = nil
SW.RandomChest.SolarEclipseParam = 0
SW.RandomChest.SolarEclipseTime = 60
function SW.RandomChest.Init()
	for k,v in pairs(SW.RandomChest.Action) do
		table.insert(SW.RandomChest.Keys, k)
	end
	for i = 1, SW.RandomChest.Number do
		SW.RandomChest.GenerateChest()
	end
	StartSimpleJob("SW_RandomChest_Job")
end
function SW.RandomChest.GenerateChest()
	--Same procedure as random start
	local success = false
	local positions = {
		{ X = 36000, Y = 28500 },
	};
	local sectors = {};
	local _, _, sector;
	for i = 1,table.getn(positions) do
		_, _, sector = S5Hook.GetTerrainInfo(positions[i].X, positions[i].Y);
		table.insert(sectors, sector)
	end;
	local worldSize = Logic.WorldGetSize()
	local ranX, ranY, sectorID
	local valid;
	while not success do
		ranX = math.random()*worldSize
		ranY = math.random()*worldSize
		_, _, sectorID = S5Hook.GetTerrainInfo( ranX, ranY);
		valid = false --invalid until proven otherwise
		for j = 1, table.getn(sectors) do
			if sectors[j] == sectorID then
				valid = true
				break;
			end
		end
		if valid then
			success = true
			SW.RandomChest.GenerateAtPos( ranX, ranY)
		end 
	end
end
function SW.RandomChest.GenerateAtPos( _x, _y)
	--Message("Chest at X: ".._x.." Y: ".._y)
	local key = SW.RandomChest.Keys[math.random(table.getn(SW.RandomChest.Keys))]
	--Message(key)
	local chestId = Logic.CreateEntity( Entities.XD_ChestClose, _x, _y, 0, 0)
	table.insert(SW.RandomChest.ListOfChests, {_x, _y, key, chestId})
end
function SW_RandomChest_Job()
	local version = 2
	local t1 = XGUIEng.GetSystemTime()
	if version == 1 then
		local n = table.getn(SW.RandomChest.ListOfChests)
		local v,x,y, eX, eY
		for eId in S5Hook.EntityIterator() do		--no good predicates for this use ):
			if Logic.IsSettler( eId) == 1 and Logic.EntityGetPlayer( eId) ~= 0 then
				eX, eY = Logic.EntityGetPos( eId)
				for i = n, 1, -1 do
					v = SW.RandomChest.ListOfChests[i]
					x, y = v[1], v[2]
					if math.abs(eX-x)+math.abs(eY-y) <= SW.RandomChest.OpeningRange then
						SW.RandomChest.OnChestFound( v, GetPlayer(eId))
						DestroyEntity( v[4])
						local stoneId = Logic.CreateEntity( Entities.XD_Rock1, v[1], v[2], 0, 0)
						Logic.SetModelAndAnimSet( stoneId, Models.XD_ChestOpen)
						table.remove( SW.RandomChest.ListOfChests, i)
						n = n - 1
						break		-- a entity may find only 1 chest per second
					end
				end
			end
		end
	else
		local n = table.getn(SW.RandomChest.ListOfChests)
		local v,x,y, eX, eY
		for eId in S5Hook.EntityIterator(Predicate.OfCategory(EntityCategories.Serf)) do		--no good predicates for this use ):
			eX, eY = Logic.EntityGetPos( eId)
			for i = n, 1, -1 do
				v = SW.RandomChest.ListOfChests[i]
				x, y = v[1], v[2]
				if math.abs(eX-x)+math.abs(eY-y) <= SW.RandomChest.OpeningRange then
						SW.RandomChest.OnChestFound( v, GetPlayer(eId))
					DestroyEntity( v[4])
					local stoneId = Logic.CreateEntity( Entities.XD_Rock1, v[1], v[2], 0, 0)
					Logic.SetModelAndAnimSet( stoneId, Models.XD_ChestOpen)
					table.remove( SW.RandomChest.ListOfChests, i)
					n = n - 1
					break		-- a entity may find only 1 chest per second
				end
			end
		end
		for eId in S5Hook.EntityIterator(Predicate.OfCategory(EntityCategories.Leader)) do		--no good predicates for this use ):
			eX, eY = Logic.EntityGetPos( eId)
			for i = n, 1, -1 do
				v = SW.RandomChest.ListOfChests[i]
				x, y = v[1], v[2]
				if math.abs(eX-x)+math.abs(eY-y) <= SW.RandomChest.OpeningRange then
					SW.RandomChest.OnChestFound( v, GetPlayer(eId))
					DestroyEntity( v[4])
					local stoneId = Logic.CreateEntity( Entities.XD_Rock1, v[1], v[2], 0, 0)
					Logic.SetModelAndAnimSet( stoneId, Models.XD_ChestOpen)
					table.remove( SW.RandomChest.ListOfChests, i)
					n = n - 1
					break		-- a entity may find only 1 chest per second
				end
			end
		end
	end
	local t2 = XGUIEng.GetSystemTime()
	SW.RandomChest.JobTimeNeeded = t2-t1
end
function SW.RandomChest.OnChestFound( _data, _pId)
	if GUI.GetPlayerID() == _pId then
		Message("Ihr habt eine Truhe gefunden!")
		--Message(_data[3])
		GUI.ScriptSignal( _data[1], _data[2], 2, 0 )
		Sound.PlayGUISound( Sounds.Misc_Chat, 0 )
	end
	SW.RandomChest.Action[_data[3]]( _pId, _data[1], _data[2])
end
function SW.RandomChest.Action.EternalFire( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war Feuer!")
	end
	Logic.SetModelAndAnimSet( Logic.CreateEntity(Entities.XD_Rock1, _x, _y, 0, 0), Models.Effects_XF_HouseFireMedium)
end
function SW.RandomChest.Action.Stone( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war ein Stein!")
	end
	local eId = Logic.CreateEntity(Entities.XD_Rock1, _x, _y, 0, 0)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(25)
end
function SW.RandomChest.Action.Sonic( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war Sonic!")
	end
	local eId = Logic.CreateEntity( Entities.CU_AggressiveWolf, _x, _y, 0, _pId)
	SW.SetMovementspeed( eId, 1600)
end
function SW.RandomChest.Action.Tree( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war ein Baum!")
	end
	local eId = Logic.CreateEntity(Entities.XD_ResourceTree, _x, _y, 0, 0)
	Logic.SetModelAndAnimSet( eId, Models.XD_Fir1)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(5)
	S5Hook.GetEntityMem( eId)[67]:SetInt(5000)
	--Message( eId)
	--for i = 0, 100 do
	--	LuaDebugger.Log(i.." "..S5Hook.GetEntityMem(eId)[i]:GetInt())
	--end
end
function SW.RandomChest.Action.SolarEclipse( _pId, _x, _y)
	if SW.RandomChest.SolarEclipseJobID ~= nil then
		if GUI.GetPlayerID() == _pId then
			Message("Darin war nix!")
		end
		return
	end
	if GUI.GetPlayerID() == _pId then
		Message("Darin war eine Sonnenfinsternis!")
	else
		Message("Jemand hat eine Sonnenfinsternis gefunden!")
	end
	SW.RandomChest.SolarEclipseParam = 0
	SW.RandomChest.SolarEclipseJobID = StartSimpleHiResJob("SW_RandomChest_SolarEclipseJob")
end
function SW.RandomChest.Action.Bomb( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war eine Bombe!")
	end
	local bombId = Logic.CreateEntity(Entities.XD_Bomb1, _x, _y, 0, 0)
	S5Hook.GetEntityMem(bombId)[31][0][4]:SetInt(600) --wait a minute...
	S5Hook.GetEntityMem(bombId)[25]:SetFloat(5)
end
function SW_RandomChest_SolarEclipseJob()
	SW.RandomChest.SolarEclipseParam = SW.RandomChest.SolarEclipseParam + 0.1
	if SW.RandomChest.SolarEclipseParam >= 60 then
		SW.RandomChest.SolarEclipseJobID = nil
		return true
	end
	local state = 2*SW.RandomChest.SolarEclipseParam/SW.RandomChest.SolarEclipseTime - 1   --varies from -1 to 1 throughout the eclipse
	-- formula for darkness calc: darkness(-1) = darkness(1) = 0
	--							  darkness(x) = -(x+1)(x-1)
	SW.RandomChest.SolarEclipseSetGFX( 1 + (state-1)*(state+1))
end
function SW.RandomChest.SolarEclipseSetGFX(_scale)
	if _scale > 1 then
		_scale = 1
	elseif _scale < 0 then
		_scale = 0
	end
	Display.GfxSetSetLightParams(1,  0.0, 1.0, 40, -15, -50,  30+math.floor(90*_scale),30+math.floor(80*_scale),60+math.floor(50*_scale),  math.floor(255*_scale), math.floor(254*_scale), math.floor(230*_scale))
	Display.GfxSetSetLightParams(3,  0.0, 1.0,  40, -15, -75,  25+math.floor(75*_scale),30+math.floor(80*_scale),60+math.floor(50*_scale), math.floor(250*_scale), math.floor(250*_scale), math.floor(250*_scale))
	Display.GfxSetSetLightParams(2,  0.0, 1.0, 40, -15, -50,  30+math.floor(90*_scale),30+math.floor(80*_scale),60+math.floor(50*_scale),  math.floor(255*_scale), math.floor(254*_scale), math.floor(230*_scale))
end
function SW.RandomChest.Action.NobleMan( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war ein mächtiger Krieger!")
	end
	local eId = Logic.CreateEntity(Entities.PU_LeaderPoleArm3, _x, _y, 0, _pId)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(1.8)
	SW.AddExperiencePoints( eId, 800)
end
function SW.RandomChest.Action.WildMan( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war ein Wilder!")
	end
	local eId = Logic.CreateEntity(Entities.CU_Evil_LeaderBearman1, _x, _y, 0, _pId)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(2)
	SW.SetMovementspeed( eId, 600)
end
SW.RandomChest.GoetheText = {
	"Habe nun, ach! Philosophie,",
	"Juristerei und Medizin,",
	"Und leider auch Theologie",
	"Durchaus studiert, mit heißem Bemühn.",
	"Da steh ich nun, ich armer Tor!",
	"Und bin so klug als wie zuvor;",
	"Heiße Magister, heiße Doktor gar",
	"Und ziehe schon an die zehen Jahr",
	"Herauf, herab und quer und krumm",
	"Meine Schüler an der Nase herum –",
	"Und sehe, daß wir nichts wissen können!",
	"Das will mir schier das Herz verbrennen.",
	"Zwar bin ich gescheiter als all die Laffen,",
	"Doktoren, Magister, Schreiber und Pfaffen;",
	"Mich plagen keine Skrupel noch Zweifel,",
	"Fürchte mich weder vor Hölle noch Teufel –",
	"Dafür ist mir auch alle Freud entrissen,",
	"Bilde mir nicht ein, was Rechts zu wissen,",
	"Bilde mir nicht ein, ich könnte was lehren,",
	"Die Menschen zu bessern und zu bekehren.",
	"Auch hab ich weder Gut noch Geld,",
	"Noch Ehr und Herrlichkeit der Welt;"
}
function SW.RandomChest.Action.Goethe( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war die Gelehrtentragödie!")
	end
	_G["SW_RandomChest_Goethe".._pId.."Counter"] = 0
	_G["SW_RandomChest_Goethe".._pId.."Job"] = function()
		if Counter.Tick2("SW_RandomChest_GoetheCounter".._pId, 2) then
			return
		end
		_G["SW_RandomChest_Goethe".._pId.."Counter"] = _G["SW_RandomChest_Goethe".._pId.."Counter"] + 1
		local text = SW.RandomChest.GoetheText[_G["SW_RandomChest_Goethe".._pId.."Counter"]]
		if text ~= nil then
			if _pId == GUI.GetPlayerID() then
				Message(text)
			end
		else
			return true
		end
	end
	StartSimpleJob("SW_RandomChest_Goethe".._pId.."Job")
end
function SW.RandomChest.Action.Statue( _pId, _x, _y)
	if GUI.GetPlayerID() == _pId then
		Message("Darin war eine Statue unseres geliebten Herrschers!")
	end
	local eId = Logic.CreateEntity(Entities.XD_Rock1, _x, _y, 0, 0)
	Logic.SetModelAndAnimSet( eId, Models.PB_Beautification01)
	S5Hook.GetEntityMem( eId)[25]:SetFloat(2.5)
end
--Ideen:
--	CTHULHU
--	Ein eisiger Winter
--	Eine Läuterung?
--	Konfetti
--	Endraläer Krustenbrot
--	Ein Ring, sie zu knechten, sie alle zu finden, ins Dunkel zu treiben und ewig zu binden