// Should I separate all plugins and use API to link just like what ZP50 did?

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <orpheu>
#include <orpheu_memory>
#include <orpheu_stocks>
#include <xs>

#include <playermodel>

#define VERSION "0.0"

#include "zombiemod/global.sma"
#include "zombiemod/human.sma"
#include "zombiemod/zombie.sma"
#include "zombiemod/nemesis.sma"
#include "zombiemod/gamerules.sma"
#include "zombiemod/ambience.sma"
#include "zombiemod/money.sma"
#include "zombiemod/buy.sma"
#include "zombiemod/nightvision.sma"
#include "zombiemod/hudinfo.sma"

public plugin_precache()
{
	Zombie_Precache();
	GameRules_Precache();
	Ambience_Precache();
	Buy_Precache();
}

public plugin_init()
{
	register_plugin("Zombie Mod", VERSION, "cogreyt");
	
	register_event("HLTV", "OnNewRound", "a", "1=0", "2=0");
	
	register_logevent("OnRoundStart", 2, "1=Round_Start");
	
	register_forward(FM_ClientPutInServer, "OnClientPutInServer_P", 1);
	register_forward(FM_ClientDisconnect, "OnClientDisconnect_P", 1);
	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");
	register_forward(FM_EmitSound, "OnEmitSound");
	
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn");
	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_P", 1);
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled");
	RegisterHam(Ham_Killed, "player", "OnPlayerKilled_P", 1);
	RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage_P", 1);
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnKnifeDeploy_P", 1);
	
	RegisterHam(Ham_Touch, "armoury_entity", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weapon_shield", "OnWeaponTouch");
	RegisterHam(Ham_Touch, "weaponbox", "OnWeaponTouch");
	
	cVarFreezeTime = get_cvar_pointer("mp_freezetime");
	cVarRoundTime = get_cvar_pointer("mp_roundtime");
	 
	g_maxClients = get_maxplayers();
	
	OnPluginInit();
}

public OnPluginInit()
{
	Human_Main();
	Zombie_Main();
	GameRules_Main();
	Ambience_Main();
	Money_Main();
	Buy_Main();
	Nvg_Init();
	HudInfo_Main();
}

public OnNewRound()
{
	GameRules_NewRound();
	Ambience_NewRound();
}

public OnRoundStart()
{
	GameRules_RoundStart();
	Ambience_RoundStart();
}

public OnClientPutInServer_P(id)
{
	Ambience_PutInServer(id);
}

public OnClientDisconnect_P(id)
{
	Zombie_Disconnect(id);
	GameRules_Disconnect(id);
	Money_Disconnect(id);
}

public OnPlayerPreThink(id)
{
	Nvg_Think(id);
}

public OnEmitSound(id, channel, sample[], Float:volume, Float:attenuation, flags, pitch)
{
	API_RESULT = FMRES_IGNORED;
	API_CALL(Zombie_EmitSound(id, channel, sample, volume, attenuation, flags, pitch));
	
	return API_RESULT;
}

public OnPlayerSpawn(id)
{
	if (1 <= get_pdata_int(id, m_iTeam) <= 2)
	{
		Human_Spawn(id);
		Zombie_Spawn(id);
		GameRules_Spawn(id);
	}
}

public OnPlayerSpawn_P(id)
{
	if (is_user_alive(id))
	{
		Human_Spawn_P(id);
		Zombie_Spawn_P(id);
		GameRules_Spawn_P(id);
	}
}

public OnPlayerKilled(id)
{
	Human_Killed(id);
}

public OnPlayerKilled_P(id)
{
	Zombie_Killed_P(id);
	GameRules_Killed_P(id);
}

public OnPlayerTakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	API_RESULT = HAM_IGNORED;
	API_CALL(Human_TakeDamage(id, inflictor, attacker, damage, damageBits));
	API_CALL(GameRules_TakeDamage(id, inflictor, attacker, damage, damageBits));
	API_CALL(Money_TakeDamage(id, inflictor, attacker, damage, damageBits));
	
	return API_RESULT;
}

public OnPlayerTakeDamage_P(id, inflictor, attacker, Float:damage, damageBits)
{
	GameRules_TakeDamage_P(id, inflictor, attacker, damage, damageBits);
}

public OnKnifeDeploy_P(ent)
{
	new id = get_pdata_cbase(ent, m_pPlayer);
	Zombie_SetHands(ent, id);
}

public OnWeaponTouch(ent, toucher)
{
	API_RESULT = HAM_IGNORED;
	if (isPlayer(toucher))
		API_CALL(Zombie_TouchWeapon(ent, toucher));
	
	return API_RESULT;
}