#if defined _ZOMBIEMOD_ZOMBIE_
	#endinput
#endif

#define _ZOMBIEMOD_ZOMBIE_

new const SOUND_ZOMBIE_ATTACK[][] = 
{
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav"
}

new g_isZombie;

public Zombie_Precache()
{
	for (new i = 0; i < sizeof(SOUND_ZOMBIE_ATTACK); i++)
		precache_sound(SOUND_ZOMBIE_ATTACK[i]);
	
	precache_model("models/zombiemod_test/v_hands.mdl");
	precache_player_model("zombie_source");
	Nemesis_Precache();
}

public Zombie_Main()
{
	Nemesis_Main();
}

public Zombie_Spawn(id)
{
	if (boolGet(g_isZombie, id))
		set_pdata_int(id, m_iTeam, TEAM_TERRORIST);
}

public Zombie_Spawn_P(id)
{
	if (boolGet(g_isZombie, id))
		ZombieBorn(id);
}

public Zombie_Killed_P(id)
{
	Nemesis_Killed_P(id);
}

public Zombie_SetHands(ent, id)
{
	if (boolGet(g_isZombie, id))
	{
		set_pev(id, pev_viewmodel2, "models/zombiemod_test/v_hands.mdl");
		set_pev(id, pev_weaponmodel2, "");
	}
	
	Nemesis_SetHands(ent, id);
}

public Zombie_TouchWeapon(ent, id)
{
	return boolGet(g_isZombie, id) ? HAM_SUPERCEDE : HAM_IGNORED;
}

public Zombie_EmitSound(id, channel, sample[], Float:volume, Float:attenuation, flags, pitch)
{
	if (!boolGet(g_isZombie, id))
		return FMRES_IGNORED;
	
	// weapons
	if (sample[0] == 'w' && sample[3] == 'p')
	{
		// knife
		if (sample[8] == 'k' && sample[11] == 'f')
		{
			// hit or stab
			if ((sample[14] == 'h' && sample[16] == 't') || (sample[14] == 's' && sample[17] == 'b'))
			{
				emit_sound(id, channel, SOUND_ZOMBIE_ATTACK[random(sizeof SOUND_ZOMBIE_ATTACK)], volume, attenuation, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public Zombie_Disconnect(id)
{
	boolUnset(g_isZombie, id);
	Nemesis_Disconnect(id);
}

ZombieBorn(id)
{
	boolSet(g_isZombie, id);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	set_user_health(id, 1000);
	
	fm_set_user_model(id, "zombie_source");
}

ZombieInfect(id, attacker, bool:score=true, bool:notify=true)
{
	if (score)
	{
		if (isPlayer(attacker))
		{
			set_user_frags(attacker, get_user_frags(attacker) + 1);
			updateScoreInfo(attacker);
		}
		
		set_pdata_int(id, m_iDeaths, get_pdata_int(id, m_iDeaths) + 1);
		updateScoreInfo(id);
	}
	
	if (notify)
	{
		sendDeathMsg(attacker, id, 0, "infection");
		setScoreAttrib(id, 0);
	}
	
	dropPlayerWeapons(id, 0);
	setPlayerTeam(id, TEAM_TERRORIST, true, false);
	ZombieBorn(id);
	
	if (isPlayer(attacker))
		checkWinConditions();
}

stock zombieGetCount()
{
	new count = 0;
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_alive(i) && boolGet(g_isZombie, i))
			count++
	}
	return count;
}