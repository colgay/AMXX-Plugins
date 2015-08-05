#if defined _ZOMBIEMOD_GAMERULES_
	#endinput
#endif

#define _ZOMBIEMOD_GAMERULES_

// TODO: better task id manage?
#define TASK_NEWROUND 100
#define TASK_ROUNDTIME 200
#define TASK_RESPAWN 300

new bool:g_isFirstJoined;
new bool:g_isGameStarted;
new bool:g_isFreezePeriod;
new g_roundWinStatus;

new Float:g_roundTimeSecs;
new Float:g_roundTimeCount;

new g_hookSpawn;
new g_gameRules;

public GameRules_Precache()
{
	g_hookSpawn = register_forward(FM_Spawn, "OnSpawn");
	OrpheuRegisterHook(OrpheuGetFunction("InstallGameRules"), "OnInstallGameRules_P", OrpheuHookPost);
}

public OnInstallGameRules_P()
{
	g_gameRules = OrpheuGetReturn();
}

public OnSpawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED;
	
	static const objectives[][] = 
	{
		"func_bomb_target",
		"info_bomb_target",
		"info_vip_start",
		"func_vip_safetyzone",
		"func_escapezone",
		"hostage_entity",
		"monster_scientist",
		"func_hostage_rescue",
		"info_hostage_rescue",
		"func_buyzone"
	};
	
	static className[32];
	pev(ent, pev_classname, className, charsmax(className));
	
	for (new i = 0; i < sizeof objectives; i++)
	{
		if (equal(className, objectives[i]))
		{
			remove_entity(ent);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public GameRules_Main()
{
	unregister_forward(FM_Spawn, g_hookSpawn);
	
	OrpheuRegisterHookFromObject(g_gameRules, "IsFreezePeriod", "CGameRules", "OnIsFreezePeriod");
	OrpheuRegisterHookFromObject(g_gameRules, "FPlayerCanRespawn", "CGameRules", "OnPlayerCanRespawn");
	OrpheuRegisterHookFromObject(g_gameRules, "GetPlayerSpawnSpot", "CGameRules", "OnGetPlayerSpawnSpot");
	OrpheuRegisterHookFromObject(g_gameRules, "CheckWinConditions", "CGameRules", "OnCheckWinConditions");
	
	terminateRound(0.0, WinStatus_Draw); // terminate on first round
}

public OrpheuHookReturn:OnCheckWinConditions(this)
{
	if (g_isFirstJoined && g_roundWinStatus)
		return OrpheuSupercede;
	
	new numCt = 0;
	new numTs = 0;
	new numRealCt = 0;
	new numRealTs = 0;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		switch (get_pdata_int(i, m_iTeam))
		{
			case TEAM_TERRORIST:
			{
				if (get_pdata_int(i, m_iMenu) != 3)
					numRealTs++;
				
				numTs++;
			}
			case TEAM_CT:
			{
				if (get_pdata_int(i, m_iMenu) != 3)
					numRealCt++;
				
				numCt++;
			}
		}
	}
	
	omSetA(this, "m_iNumCT", 1, numCt);
	omSetA(this, "m_iNumTerrorist", 1, numTs);
	omSetA(this, "m_iNumSpawnableCT", 1, numRealCt);
	omSetA(this, "m_iNumSpawnableTerrorist", 1, numRealTs);
	
	if (numRealTs + numRealCt < 3)
	{
		g_isFirstJoined = false;
	}
	
	if (!g_isFirstJoined && numRealTs + numRealCt >= 3)
	{
		// reset player scores
		for (new i = 1; i <= g_maxClients; i++)
		{
			if (is_user_connected(i))
			{
				set_user_frags(i, 0);
				set_pdata_int(i, m_iDeaths, 0);
				updateScoreInfo(i);
			}
		}
		
		// reset team scores
		setTeamScore(TEAM_TERRORIST, 0);
		setTeamScore(TEAM_CT, 0);
		
		// restart round
		g_isFirstJoined = true;
		terminateRound2(3.0, WinStatus_Draw, Event_Game_Commencing, "#Game_Commencing");
	}
	else if (g_isGameStarted)
	{
		if (!humanGetCount())
		{
			terminateRound2(5.0, WinStatus_Terrorist, Event_Terrorists_Win, "#Terrorists_Win", "terwin");
		}
		else if (roundTimeRemaining() <= 0.0)
		{
			terminateRound2(5.0, WinStatus_CT, Event_CTs_Win, "#CTs_Win", "ctwin");
		}
	}
	else if (!humanGetCount() || (roundTimeRemaining() <= 0.0 && !g_isFreezePeriod))
	{
		terminateRound2(5.0, WinStatus_Draw, Event_Round_Draw, "#Round_Draw", "rounddraw");
	}
	
	return OrpheuSupercede;
}

public OrpheuHookReturn:OnIsFreezePeriod(this)
{
	// allow move and attack during freeze period
	if (g_isFreezePeriod && roundTimeRemaining() <= 0.0)
		OrpheuSetReturn(true);
	else
		OrpheuSetReturn(false);
		
	return OrpheuOverride;
}

public GameRules_Spawn(id)
{
	set_pdata_bool(id, m_bNotKilled, true);
}

public GameRules_NewRound()
{
	g_isZombie = 0;
	g_isGameStarted = false;
	g_isFreezePeriod = true;
	
	g_roundWinStatus = 0;
	g_roundTimeCount = get_gametime();
	g_roundTimeSecs = get_pcvar_float(cVarFreezeTime);
	
	remove_task(TASK_NEWROUND);
	remove_task(TASK_ROUNDTIME);
}

public GameRules_RoundStart()
{
	g_isFreezePeriod = false;
	
	g_roundTimeCount = get_gametime();
	g_roundTimeSecs = get_pcvar_float(cVarRoundTime) * 60.0;
	
	set_task(g_roundTimeSecs, "RoundTimeExpired", TASK_ROUNDTIME);
	
	MakeGameStart();
}

// TODO: I think there is a better way to do this with lesser code
public OrpheuHookReturn:OnGetPlayerSpawnSpot(this, id)
{
	new spawnClass[23] = "info_player_deathmatch";
	if (random_num(0, 1))
		copy(spawnClass, charsmax(spawnClass), "info_player_start");
	if (!find_ent_by_class(-1, spawnClass)) // no spawn spot found, try another team
		copy(spawnClass[12], charsmax(spawnClass)-12, spawnClass[12] == 'd' ? "start" : "deathmatch");
	
	// TODO: don't really need to get all spots like this, maybe we can just store the last spot for next random get.
	new spot = -1;
	new numSpawns = 0;
	while ((spot = find_ent_by_class(spot, spawnClass)))
		numSpawns++;
	
	if (!numSpawns) // both teams have no spawn spot
		return OrpheuSupercede;
	
	// find a random spawn spot
	spot = -1;
	for (new i = random_num(1, numSpawns); i > 0; i--)
		spot = find_ent_by_class(spot, spawnClass);
	
	// validate the spawn spot
	new first = spot;
	do
	{
		if (spot)
		{
			if (isEntHullFree(spot, DONT_IGNORE_MONSTERS, HULL_HUMAN))
				break;
		}
		
		spot = find_ent_by_class(spot, spawnClass);
	} while (spot != first);
	
	// spawn spot is ready
	if (pev_valid(spot))
	{
		new Float:origin[3], Float:angles[3];
		pev(spot, pev_origin, origin);
		pev(spot, pev_angles, angles);
		
		set_pev(id, pev_origin, origin);
		set_pev(id, pev_angles, angles);
		
		set_pev(id, pev_v_angle, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_fixangle, true);
	}
	
	client_print(id, print_chat, "[TEST] class=^"%s^" num=%i edict=%i", spawnClass, numSpawns, spot);
	OrpheuSetReturn(spot);
	return OrpheuSupercede;
}

public OrpheuHookReturn:OnPlayerCanRespawn(this, id)
{
	if (get_pdata_int(id, m_iNumSpawns) > 0)
		return OrpheuIgnored;
	
	if (!g_isGameStarted || get_gametime() - g_roundTimeCount <= 20.0)
		OrpheuSetReturn(true);
	else
		OrpheuSetReturn(false);
	
	return OrpheuOverride;
}

public GameRules_TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (!boolGet(g_isZombie, id) && boolGet(g_isZombie, attacker) && isPlayer(attacker))
	{
		if (inflictor == attacker && get_user_weapon(attacker) == CSW_KNIFE)
		{
			if (get_user_health(id) - damage < 1)
			{
				// TODO: if this function blocked by other plugin, hp will never be reseted!
				set_pev(id, pev_health, damage + 999999.0);
				boolSet(g_isZombie, id);
			}
		}
	}
	
	return HAM_IGNORED;
}

public GameRules_TakeDamage_P(id, inflictor, attacker, Float:damage, damageBits)
{
	// change team in function post to make pain shock work correctly
	if (boolGet(g_isZombie, id) && get_pdata_int(id, m_iTeam) == TEAM_CT)
	{
		ZombieInfect(id, attacker);
		set_user_health(id, get_user_health(id) / 2);
	}
}

public GameRules_Spawn_P(id)
{
	remove_task(id + TASK_RESPAWN);
}

public GameRules_Killed_P(id)
{
	if (g_isGameStarted && !g_roundWinStatus)
	{
		remove_task(id + TASK_RESPAWN);
		set_task(5.0, "RespawnPlayer", id + TASK_RESPAWN);
	}
}

public GameRules_Disconnect(id)
{
	remove_task(id + TASK_RESPAWN);
}

public MakeGameStart()
{
	new players[32], numPlayers;
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (1 <= get_pdata_int(i, m_iTeam) <= 2 && get_pdata_int(i, m_iMenu) != 3)
		{
			if (!is_user_alive(i))
				ExecuteHam(Ham_CS_RoundRespawn, i);
			
			players[numPlayers++] = i;
		}
	}
	
	if (numPlayers < 3)
	{
		client_print(0, print_center, "The game requires at least 3 players to start...");
		return;
	}
	
	new numZombies = 0;
	new maxZombies = floatround(numPlayers * 0.2, floatround_ceil);
	
	while (numZombies < maxZombies)
	{
		static player;
		do
		{
			player = players[random(numPlayers)]
		} while (boolGet(g_isZombie, player));
		
		ZombieInfect(player, 0, false, false);
		numZombies++;
	}
	
	g_isGameStarted = true;
	client_print(0, print_center, "Game Start");
}

public RespawnPlayer(taskId)
{
	new id = taskId - TASK_RESPAWN;
	if (g_isGameStarted && !g_roundWinStatus)
	{
		boolSet(g_isZombie, id);
		ExecuteHam(Ham_CS_RoundRespawn, id);
	}
}

public RoundTimeExpired()
{
	if (!g_roundWinStatus)
	{
		g_roundTimeCount = get_gametime() - g_roundTimeSecs;
		checkWinConditions();
	}
	
	client_print(0, print_chat, "[TEST] RoundTimeExpired() called.");
}

stock getTeamScore(team)
{
	return omGetA(g_gameRules, team == 1 ? "m_iNumTerroristWins" : "m_iNumCTWins");
}

stock setTeamScore(team, score, bool:update=true)
{
	omSetA(g_gameRules, team == 1 ? "m_iNumTerroristWins" : "m_iNumCTWins", 1, score);
	
	if (update)
	{
		static msgTeamScore;
		msgTeamScore || (msgTeamScore = get_user_msgid("TeamScore"));
		
		emessage_begin(MSG_BROADCAST, msgTeamScore);
		ewrite_string(team == 1 ? "TERRORIST" : "CT");
		ewrite_short(score);
		emessage_end();
	}
}

stock Float:roundTimeRemaining()
{
	return g_roundTimeCount + g_roundTimeSecs - get_gametime();
}

stock checkWinConditions()
{
	static OrpheuFunction:funcWinConditions;
	if (!funcWinConditions)
		funcWinConditions = OrpheuGetFunctionFromObject(g_gameRules, "CheckWinConditions", "CGameRules");
		
	OrpheuCallSuper(funcWinConditions, g_gameRules);
}

stock endRoundMessage(const message[], event)
{
	static OrpheuFunction:funcEndRoundMsg;
	funcEndRoundMsg || (funcEndRoundMsg = OrpheuGetFunction("EndRoundMessage"));
	
	OrpheuCall(funcEndRoundMsg, message, event);
}

stock terminateRound(Float:delay, status)
{
	omSetA(g_gameRules, "m_iRoundWinStatus", 1, status);
	omSetA(g_gameRules, "m_bRoundTerminating", 1, true);
	omSetA(g_gameRules, "m_fTeamCount", 1, get_gametime() + delay);
	
	g_roundWinStatus = status;
}

stock terminateRound2(Float:delay, status, event, const message[], const audio[]="", bool:score=true)
{
	if (audio[0])
	{
		new code[32] = "%!MRAD_";
		add(code, charsmax(code), audio);
		sendAudioMessage(0, 0, code, 100);
	}
	
	if (score)
	{
		if (status == WinStatus_Terrorist)
			setTeamScore(1, getTeamScore(1) + 1);
		else if (status == WinStatus_CT)
			setTeamScore(2, getTeamScore(2) + 1);
	}
	
	endRoundMessage(message, event);
	terminateRound(delay, status);
}