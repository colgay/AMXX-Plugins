#if defined _ZOMBIEMOD_HUMAN_
	#endinput
#endif

#define _ZOMBIEMOD_HUMAN_

#include "zombiemod/zombie.sma"

public Human_Main()
{
	RegisterHam(Ham_CS_Item_CanDrop, "weapon_hegrenade", "OnGrenadeCanDrop");
	RegisterHam(Ham_CS_Item_CanDrop, "weapon_flashbang", "OnGrenadeCanDrop");
	RegisterHam(Ham_CS_Item_CanDrop, "weapon_smokegrenade", "OnGrenadeCanDrop");
}

public Human_Spawn(id)
{
	if (!boolGet(g_isZombie, id))
		set_pdata_int(id, m_iTeam, TEAM_CT);
}

public Human_Spawn_P(id)
{
	if (!boolGet(g_isZombie, id))
		HumanBorn(id);
}

public Human_Killed(id)
{
	dropPlayerWeapons(id, 0);
}

public Human_TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	// TODO: how to block CS default armor damage calculation?
	if (get_pdata_int(id, m_iKevlar))
	{
		new Float:armor;
		pev(id, pev_armorvalue, armor);
		
		if (armor > 0.0 && (~damageBits & (DMG_FALL|DMG_DROWN)))
		{
			armor = 0.0;
		}
	}
	
	return HAM_IGNORED;
}

public OnGrenadeCanDrop(ent)
{
	SetHamReturnInteger(true);
	return HAM_OVERRIDE;
}

HumanBorn(id)
{
	give_item(id, "weapon_knife");
	
	boolUnset(g_isZombie, id);
	
	set_user_health(id, 100);
	
	fm_reset_user_model(id);
	
	new ent = get_pdata_cbase(id, m_pActiveItem);
	if (ent > 0)
		ExecuteHam(Ham_Item_Deploy, ent);
}

stock humanGetCount()
{
	new count = 0;
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_alive(i) && !boolGet(g_isZombie, i))
			count++
	}
	return count;
}