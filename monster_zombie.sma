#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>

public plugin_precache()
{
	precache_model("models/zombie.mdl");
	precache_model("models/zombiet.mdl");
}

public plugin_init()
{
	register_plugin("Monster Zombie", "0.1", "ds");
	
	register_forward(FM_AddToFullPack, "OnAddToFullPack_P", 1);
	
	register_think("cs_monster_zombie", "ZombieThink");
	register_think("cs_monster_zombie_dead", "ZombieDeadThink");
	
	register_clcmd("zombie", "CmdZombie");
}

public CmdZombie(id)
{
	new Float:origin[3];
	pev(id, pev_origin, origin);
	origin[2] += 80.0;
	
	new Float:angles[3];
	pev(id, pev_angles, angles);
	
	CreateZombie(100.0, origin, angles);
}

public OnAddToFullPack_P(es, e, ent, host, flags, player, pset)
{
	if (!player && pev_valid(ent) && get_es(es, ES_MoveType) == MOVETYPE_STEP)
	{
		// fix MOVETYPE_STEP in multiplayer
		set_es(es, ES_MoveType, MOVETYPE_PUSHSTEP);
	}
}

public ZombieThink(ent)
{
	// ...
}

public ZombieDeadThink(ent)
{
	new Float:deadTime;
	pev(ent, pev_frags, deadTime);
	
	if (get_gametime() - deadTime < 5.0)
	{
		set_pev(ent, pev_renderamt, (1.0 - (get_gametime() - deadTime) / 5.0) * 255.0);
		set_pev(ent, pev_nextthink, get_gametime() + 0.01);
	}
	else
		remove_entity(ent);
}

public ZombieKilled(ent)
{
	set_pev(ent, pev_classname, "cs_monster_zombie_dead");
	set_pev(ent, pev_solid, SOLID_NOT);
	set_pev(ent, pev_rendermode, kRenderTransAlpha);
	set_pev(ent, pev_renderamt, 255.0);
	
	// set animation
	set_pev(ent, pev_framerate, 1.0);
	set_pev(ent, pev_animtime, get_gametime());
	set_pev(ent, pev_sequence, random_num(15, 19));
	
	set_pev(ent, pev_nextthink, get_gametime() + 5.0);
	set_pev(ent, pev_frags, get_gametime() + 5.0); // dead time
	
	return HAM_SUPERCEDE;
}

CreateZombie(Float:health, Float:origin[3], Float:angles[3])
{
	new ent = create_entity("info_target");
	
	set_pev(ent, pev_classname, "cs_monster_zombie");
	set_pev(ent, pev_solid, SOLID_SLIDEBOX);
	set_pev(ent, pev_movetype, MOVETYPE_STEP);
	set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_MONSTER);
	set_pev(ent, pev_takedamage, DAMAGE_YES);
	set_pev(ent, pev_health, health);
	set_pev(ent, pev_angles, angles);
	
	set_pev(ent, pev_controller, 125);
	set_pev(ent, pev_controller_1, 125);
	set_pev(ent, pev_controller_2, 125);
	set_pev(ent, pev_controller_3, 125);
	
	entity_set_origin(ent, origin);
	entity_set_model(ent, "models/zombie.mdl");
	entity_set_size(ent, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 72.0});
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1);
	
	static bool:hook;
	if (!hook)
	{
		hook = true;
		RegisterHamFromEntity(Ham_Killed, ent, "ZombieKilled");
	}
}