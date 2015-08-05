#if defined _ZOMBIEMOD_GLOBAL_
	#endinput
#endif

#define _ZOMBIEMOD_GLOBAL_

#define boolGet(%1,%2) (%1 & (1 << (%2 & 31)))
#define boolSet(%1,%2) (%1 |= (1 << (%2 & 31)))
#define boolUnset(%1,%2) (%1 &= ~(1 << (%2 & 31)))

#define omGetA(%1,%2) (OrpheuMemoryGetAtAddress(%1, %2))
#define omSetA(%1,%2,%3,%4) (OrpheuMemorySetAtAddress(%1, %2, %3, %4))

#define isPlayer(%0) (1 <= %0 <= g_maxClients)

#define API_RESULT _apiResult
#define API_CALL(%0) (_apiResult = (_apiTemp = %0) > _apiResult ? _apiTemp : _apiResult)

enum
{
	TEAM_UNASSIGNED = 0,
	TEAM_TERRORIST,
	TEAM_CT,
	TEAM_SPECTATOR
};

enum
{
    Event_Target_Bombed = 1,
    Event_VIP_Escaped,
    Event_VIP_Assassinated,
    Event_Terrorists_Escaped,
    Event_CTs_PreventEscape,
    Event_Escaping_Terrorists_Neutralized,
    Event_Bomb_Defused,
    Event_CTs_Win,
    Event_Terrorists_Win,
    Event_Round_Draw,
    Event_All_Hostages_Rescued,
    Event_Target_Saved,
    Event_Hostages_Not_Rescued,
    Event_Terrorists_Not_Escaped,
    Event_VIP_Not_Escaped,
    Event_Game_Commencing,
};

enum
{
    WinStatus_CT = 1,
    WinStatus_Terrorist,
    WinStatus_Draw
};

new any:_apiResult, any:_apiTemp;
new g_maxClients;

new cVarFreezeTime, cVarRoundTime;

stock const m_pPlayer = 41;
stock const m_pNext = 42;
stock const m_iPrimaryAmmoType = 49;
stock const m_iSecondaryAmmoType = 50;
stock const m_flPainShock = 108;
stock const m_iTeam = 114;
stock const m_iAccount = 115;
stock const m_iMenu = 205;
stock const m_iNumSpawns = 365;
stock const m_rgpPlayerItems = 367;
stock const m_pActiveItem = 373;
stock const m_rgAmmo = 376;
stock const m_iDeaths = 444;
stock const m_iKevlar = 448;
stock const m_bNotKilled = 452;
stock const m_bHasNightVision = 516;
stock const m_bNightVisionOn = 517;

stock dropPlayerWeapons(id, slot)
{
	// TODO: improve this
	new weapons = pev(id, pev_weapons);
	for (new i = CSW_P228; i <= CSW_P90; i++)
	{
		if (~weapons & (1 << i))
			continue;
		
		static name[32];
		get_weaponname(i, name, charsmax(name));
		if (!name[0])
			continue;
			
		new ent = find_ent_by_owner(-1, name, id);
		if (!pev_valid(ent))
			continue;
		
		if (slot && ExecuteHamB(Ham_Item_ItemSlot, ent) != slot)
			continue;
		
		if (ExecuteHamB(Ham_CS_Item_CanDrop, ent))
			engclient_cmd(id, "drop", name);
	}
}

stock bool:isEntHullFree(ent, noMonsters=DONT_IGNORE_MONSTERS, hull) 
{ 
	static Float:origin[3];
	pev(ent, pev_origin, origin);
	
	engfunc(EngFunc_TraceHull, origin, origin, noMonsters, hull, ent, 0);
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return false;
	
	return true;
}

stock setPlayerMoney(id, money, bool:update)
{
	set_pdata_int(id, m_iAccount, money);
	
	if (update)
	{
		static msgMoney;
		msgMoney || (msgMoney = get_user_msgid("Money"));
		
		message_begin(MSG_ONE_UNRELIABLE, msgMoney, _, id);
		write_long(money);
		write_byte(update);
		message_end();
	}
}

stock setPlayerTeam(id, team, bool:scoreBoard=true, bool:dontCheck=true)
{
	if (!dontCheck && get_pdata_int(id, m_iTeam) == team)
		return;
	
	set_pdata_int(id, m_iTeam, team);
	
	if (scoreBoard)
	{
		static msgTeamInfo;
		msgTeamInfo || (msgTeamInfo = get_user_msgid("TeamInfo"));
		
		emessage_begin(MSG_BROADCAST, msgTeamInfo);
		ewrite_byte(id);
		switch (team)
		{
			case TEAM_TERRORIST: ewrite_string("TERRORIST");
			case TEAM_CT: 		 ewrite_string("CT");
			case TEAM_SPECTATOR: ewrite_string("SPECTATOR");
			default: 			 ewrite_string("UNASSIGNED");
		}
		emessage_end();
	}
}

stock updateScoreInfo(id, class=0)
{
	static msgScoreInfo;
	msgScoreInfo || (msgScoreInfo = get_user_msgid("ScoreInfo"));
	
	message_begin(MSG_BROADCAST, msgScoreInfo);
	write_byte(id); // player
	write_short(get_user_frags(id)); // frags
	write_short(get_pdata_int(id, m_iDeaths)); // deaths
	write_short(class); // class
	write_short(get_pdata_int(id, m_iTeam)); // team
	message_end();
}

stock sendAudioMessage(id, sender=0, const audio[], pitch=100)
{
	static msgSendAudio;
	msgSendAudio || (msgSendAudio = get_user_msgid("SendAudio"));
	
	emessage_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgSendAudio, _, id);
	ewrite_byte(sender);
	ewrite_string(audio);
	ewrite_short(pitch);
	emessage_end();
}

stock sendDeathMsg(killer, victim, headShot, const weapon[])
{
	static msgDeathMsg;
	msgDeathMsg || (msgDeathMsg = get_user_msgid("DeathMsg"));
	
	message_begin(MSG_BROADCAST, msgDeathMsg);
	write_byte(killer); // killer
	write_byte(victim); // victim
	write_byte(headShot); // headshot
	write_string(weapon); // weapon
	message_end();
}

stock setScoreAttrib(id, attrib)
{
	static msgScoreAttrib;
	msgScoreAttrib || (msgScoreAttrib = get_user_msgid("ScoreAttrib"));
	
	message_begin(MSG_BROADCAST, msgScoreAttrib);
	write_byte(id); // id
	write_byte(attrib); // attrib
	message_end();
}

stock sendBlinkAcct(id, amount)
{
	static msgBlinkAcct;
	msgBlinkAcct || (msgBlinkAcct = get_user_msgid("BlinkAcct"));
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgBlinkAcct, _, id);
	write_byte(amount);
	message_end();
}

// unnecessary?
stock sendLightStyle(id, style, const light[])
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_LIGHTSTYLE, _, id);
	write_byte(style);
	write_string(light);
	message_end();
}

stock sendScreenFade(id, Float:duration, Float:holdTime, flags, color[3], alpha)
{
	static msgScreenFade;
	msgScreenFade || (msgScreenFade = get_user_msgid("ScreenFade"));
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgScreenFade, _, id);
	write_short(floatround((1 << 12) * duration));
	write_short(floatround((1 << 12) * holdTime));
	write_short(flags);
	write_byte(color[0]);
	write_byte(color[1]);
	write_byte(color[2]);
	write_byte(alpha);
	message_end();
}