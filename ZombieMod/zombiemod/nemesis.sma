#if defined _ZOMBIEMOD_NEMESIS_
	#endinput
#endif

#define _ZOMBIEMOD_NEMESIS_

new g_isNemesis;

new g_sprSmoke;
new g_sprExplo;
new g_sprGasPuff;

new Float:g_rpgLastFire;
new bool:g_isRocketReloaded;

public Nemesis_Precache()
{
	g_sprSmoke = precache_model("sprites/smoke.spr");
	g_sprExplo = precache_model("sprites/bexplo.spr");
	g_sprGasPuff = precache_model("sprites/gas_puff_01.spr");
	
	precache_sound("weapons/rocketfire1.wav");
	precache_sound("weapons/rocket1.wav");
	
	precache_model("models/zombiemod_test/v_rpg_nemesis.mdl");
	precache_model("models/zombiemod_test/p_rpg.mdl");
	precache_model("models/rpgrocket.mdl");
	precache_player_model("contagion_nemesis");
}

public Nemesis_Main()
{
	register_clcmd("nemesis", "CmdNemesis");
	register_event("HLTV", "Nemesis_NewRound", "a", "1=0", "2=0");
	register_touch("rpgrocket", "*", "RocketTouch");
	register_think("rpgrocket", "RocketThink");
	register_forward(FM_CmdStart, "OnCmdStart");
}

public CmdNemesis(id)
{
	Nemesis_Born(id);
}

public Nemesis_NewRound()
{
	g_isNemesis = 0;
	g_isRocketReloaded = true; // fix gametime = 0 problem
	
	// remove all leftover rockets from previous round
	new ent = -1;
	while ((ent = find_ent_by_class(ent, "rpgrocket")))
	{
		if (pev_valid(ent))
		{
			emit_sound(ent, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, SND_STOP, PITCH_NORM);
			remove_entity(ent);
		}
	}
}

public Nemesis_SetHands(ent, id)
{
	if (boolGet(g_isNemesis, id))
	{
		set_pev(id, pev_viewmodel2, "models/zombiemod_test/v_rpg_nemesis.mdl");
		set_pev(id, pev_weaponmodel2, "models/zombiemod_test/p_rpg.mdl");
	}
}

public Nemesis_Killed_P(id)
{
	boolUnset(g_isNemesis, id);
}

public Nemesis_Disconnect(id)
{
	boolUnset(g_isNemesis, id);
}

public OnCmdStart(id, uc)
{
	if (boolGet(g_isNemesis, id) && is_user_alive(id))
	{
		if (!g_isRocketReloaded)
		{
			if (get_gametime() - g_rpgLastFire >= 0.1)
			{
				g_isRocketReloaded = true;
				client_print(0, print_center, "Nemesis' RPG has been reloaded");
			}
		}
		else if ((get_uc(uc, UC_Buttons) & IN_USE) && (~pev(id, pev_oldbuttons) & IN_USE))
		{
			RocketLaunch(id);
			g_isRocketReloaded = false;
			g_rpgLastFire = get_gametime();
		}
	}
}

public RocketThink(ent)
{
	// TODO: rewrite this block?
	if (pev(ent, pev_movetype) == MOVETYPE_FLY)
	{
		set_pev(ent, pev_gravity, 0.3);
		set_pev(ent, pev_movetype, MOVETYPE_TOSS);
		set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_LIGHT);
		
		// turbo
		new Float:vector[3];
		pev(ent, pev_velocity, vector);
		xs_vec_normalize(vector, vector);
		xs_vec_mul_scalar(vector, 1000.0, vector);
		set_pev(ent, pev_velocity, vector);
		
		// make tail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(ent); // ent
		write_short(g_sprSmoke); // spr
		write_byte(10); // life
		write_byte(5); // width
		write_byte(100); // r
		write_byte(100); // g
		write_byte(100); // b
		write_byte(200); // brightness
		message_end();
		
		set_pev(ent, pev_nextthink, get_gametime() + 10.0);
	}
	else
	{
		emit_sound(ent, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, SND_STOP, PITCH_NORM);
		remove_entity(ent);
	}
}

public RocketTouch(rocket, toucher)
{
	const Float:MAX_RADIUS = 300.0;
	const Float:MAX_DAMAGE = 200.0;
	
	new owner = pev(rocket, pev_owner);
	
	new Float:origin[3];
	pev(rocket, pev_origin, origin);
	
	new ent = -1;
	while ((ent = find_ent_in_sphere(ent, origin, MAX_RADIUS)))
	{
		if (!pev_valid(ent))
			continue;
		
		static Float:takeDamage;
		pev(ent, pev_takedamage, takeDamage);
		// skip all entities that can't take damage
		if (takeDamage == DAMAGE_NO)
			continue;
		
		// kill and blow-up the target who directly got hit
		if (ent == toucher)
		{
			if (isEntBreakable(ent)) // support func_breakable
				force_use(rocket, ent);
			else
				ExecuteHamB(Ham_Killed, ent, owner, 2); // GIB_ALWAYS
			
			continue;
		}
		
		// calculate radius damage
		new Float:radius = entity_range(rocket, ent);
		new Float:damage = floatclamp(1.0 - radius / MAX_RADIUS, 0.0, 1.0) * MAX_DAMAGE;
		
		// blow-up the target with (DMG_ALWAYSGIB) if range is close enough
		ExecuteHamB(Ham_TakeDamage, ent, rocket, owner, damage, radius <= 100.0 ? DMG_ALWAYSGIB|DMG_GRENADE : DMG_GRENADE);
		client_print(owner, print_chat, "[TEST] damage=%f", damage);
	}
	
	new Float:origin2[3]; origin2 = origin; origin2[2] -= 50.0;
	engfunc(EngFunc_TraceLine, origin, origin2, IGNORE_MONSTERS, rocket, 0);
	get_tr2(0, TR_vecEndPos, origin2);
	if (origin[2] - origin2[2] < 50.0)
		origin2[2] += 50.0;
	else
		origin2[2] = origin[2];
	
	// make explosion effect
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin2);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin2[0]);
	write_coord_f(origin2[1]);
	write_coord_f(origin2[2]);
	write_short(g_sprExplo); // spr
	write_byte(40); // scale
	write_byte(15); // framerate
	write_byte(TE_EXPLFLAG_NONE); // flags
	message_end();
	
	// make world decal
	static decalScorch[2];
	if (!decalScorch[0])
	{
		decalScorch[0] = engfunc(EngFunc_DecalIndex, "{scorch1");
		decalScorch[1] = engfunc(EngFunc_DecalIndex, "{scorch2");
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_byte(decalScorch[random(sizeof decalScorch)]);
	message_end();
	
	// smoke
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_FIREFIELD);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(random_num(100, 120)); // radius
	write_short(g_sprGasPuff);
	write_byte(random_num(30, 60)); // count
	write_byte(TEFIRE_FLAG_SOMEFLOAT|TEFIRE_FLAG_ALPHA);
	write_byte(random_num(80, 100)); // life
	message_end();
	
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin2);
	write_byte(TE_FIREFIELD);
	write_coord_f(origin2[0]);
	write_coord_f(origin2[1]);
	write_coord_f(origin2[2]);
	write_short(random_num(60, 80)); // radius
	write_short(g_sprGasPuff);
	write_byte(random_num(30, 60)); // count
	write_byte(TEFIRE_FLAG_ALPHA);
	write_byte(30); // life
	message_end();
	
	// sparks
	new sparkCount = random_num(1, 3);
	for (new i = 0; i < sparkCount; i++)
	{
		new spark = create_entity("spark_shower");
		set_pev(spark, pev_origin, origin2);
		DispatchSpawn(spark);
	}
	
	emit_sound(rocket, CHAN_VOICE, "weapons/rocket1.wav", 0.0, 0.0, SND_STOP, PITCH_NORM);
	
	// remove the rocket
	remove_entity(rocket);
}

RocketLaunch(id)
{
	new Float:vector[3];
	pev(id, pev_punchangle, vector);
	vector[0] -= random_float(5.0, 10.0);
	vector[1] += random_float(-2.5, 2.5);
	vector[2] += random_float(-2.5, 2.5);
	set_pev(id, pev_punchangle, vector);
	
	emit_sound(id, CHAN_WEAPON, "weapons/rocketfire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	// create rocket
	new ent = create_entity("info_target");
	
	entity_set_model(ent, "models/rpgrocket.mdl");
	entity_set_size(ent, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	
	set_pev(ent, pev_classname, "rpgrocket");
	set_pev(ent, pev_solid, SOLID_BBOX);
	set_pev(ent, pev_movetype, MOVETYPE_FLY);
	set_pev(ent, pev_owner, id);
	
	// set gun position and direction
	ExecuteHam(Ham_EyePosition, id, vector);
	entity_set_origin(ent, vector);
	
	pev(id, pev_angles, vector);
	set_pev(ent, pev_angles, vector);
	
	velocity_by_aim(id, 2000, vector);
	set_pev(ent, pev_velocity, vector);
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.3);
}

Nemesis_Born(id)
{
	setPlayerTeam(id, TEAM_TERRORIST, true, false);
	
	boolSet(g_isZombie, id);
	boolSet(g_isNemesis, id);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	set_user_health(id, 2000);
	
	fm_set_user_model(id, "contagion_nemesis");
}

stock isEntBreakable(ent)
{
	static class[16] // func_breakable
	pev(ent, pev_classname, class, charsmax(class));
	
	return equal(class, "func_breakable");
}