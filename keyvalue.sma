// this plugin allows spawn point trigger on/off in svencoop map for CS

#include amxmodx
#include engine
#include fakemeta
#include hamsandwich

public plugin_init()
{
	RegisterHam(Ham_Use, "info_player_deathmatch", "Spawn_Use");
	RegisterHam(Ham_IsTriggered, "info_player_deathmatch", "Spawn_IsTriggered");
	
	register_clcmd("respawn", "CmdRespawn");
	
	new ent = -1;
	while ((ent = find_ent_by_class(ent, "info_player_deathmatch")))
	{
		// Start off (2) - If checked, the spawn point will be disabled upon map start.
		if (pev_valid(ent) && pev(ent, pev_spawnflags) == 2)
			set_pev(ent, pev_iuser1, 1); // disabled
	}
}

public CmdRespawn(id)
{
	ExecuteHam(Ham_CS_RoundRespawn, id);
}

public Spawn_Use(ent, caller, activator, useType, Float:value)
{
	// typedef enum { USE_OFF = 0, USE_ON = 1, USE_SET = 2, USE_TOGGLE = 3 } USE_TYPE;
	
	switch (useType)
	{
		case 0: set_pev(ent, pev_iuser1, 1); // disabled
		case 1: set_pev(ent, pev_iuser1, 0); // enabled
		//case 2: don't know what it is...
		case 3: set_pev(ent, pev_iuser1, !pev(ent, pev_iuser1)); // toggle
	}
}

public Spawn_IsTriggered(ent, activator)
{
	/* from CS SDK
	BOOL IsSpawnPointValid(CBaseEntity *pPlayer, CBaseEntity *pSpot)
	{
		...

		if (!pSpot->IsTriggered(pPlayer))
			return FALSE;
		
		...
	}
	*/
	
	SetHamReturnInteger(!pev(ent, pev_iuser1));
	return HAM_OVERRIDE;
}