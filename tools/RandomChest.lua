-- RANDOM CHESTS :D

SW = SW or {}

SW.RandomChest = {}
SW.RandomChest.Number = 5 --Number of random chests generated

function SW.RandomChest.Init()
	for i = 1, SW.RandomChest.Number do
		SW.RandomChest.GenerateChest()
	end
end
function SW.RandomChest.GenerateChest()
	--Same procedure as random start
	local success = false
	local positions = {
		{ X = 4000, Y = 18000 };
		{ X = 22000, Y = 6000 };
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

end


--Ideen:
--	SONIC
--	Ein eisiger Winter
--	Eine Läuterung?
--	Ewiges Feuer
--	Konfetti
--	Ein Stein
--	Endraläer Krustenbrot
--	Eine Sonnenfinsternis
--	Ein Baum
--	Ein Ring, sie zu knechten, sie alle zu finden, ins Dunkel zu treiben und ewig zu binden