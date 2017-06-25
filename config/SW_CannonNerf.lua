--config file for nerfed cannons
SW = SW or {}

SW.CannonNerfTypes = {
	[Entities.PV_Cannon1] = true,
	[Entities.PV_Cannon2] = true,
	[Entities.PV_Cannon3] = true,
	[Entities.PV_Cannon4] = true,
	[Entities.PB_Tower2_Ballista] = true,
	[Entities.PB_Tower3_Cannon] = true,
	[Entities.PB_DarkTower2_Ballista] = true,
	[Entities.PB_DarkTower3_Cannon] = true
}
SW.CannonNerfDMGFactor = 0.8
SW.CannonNerfCooldownTime = 2

--if onHurt event of player is registered, change damage of all cannons by factor
--reduced damage ends after CooldownTime seconds
--TODO: Write that shit!
