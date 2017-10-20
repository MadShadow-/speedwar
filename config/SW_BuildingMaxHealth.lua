SW.BuildingMaxHealth = 
{
	["PB_Tower1"] = 500, -- orig: 1000
	["PB_Tower2"] = 1500, -- orig: 1200
	["PB_Tower3"] = 2000, -- orig: 1400
	
};

function SW.InitBuildingMaxHealth()
	for buildingType, maxHealth in pairs(SW.BuildingMaxHealth) do
		S5Hook.GetRawMem(9002416)[0][16][Entities[buildingType] * 8 + 2][13]:SetInt(maxHealth);
	end
end