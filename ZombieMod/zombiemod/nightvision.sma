#if defined _ZOMBIEMOD_NIGHTVISION_
	#endinput
#endif

#define _ZOMBIEMOD_NIGHTVISION_

public Nvg_Init()
{
	register_message(get_user_msgid("NVGToggle"), "OnNvgToggle");
}

public OnNvgToggle(msgId, msgDest, id)
{
	if (get_msg_arg_int(1)) // on
	{
		if (boolGet(g_isZombie, id))
		{
			sendLightStyle(id, 0, "#");
			sendScreenFade(id, 0.0, 0.0, 0x0004, {255, 0, 0}, 80);
		}
		else
			sendScreenFade(id, 0.0, 0.0, 0x0004, {0, 255, 0}, 80);
	}
	else // off
	{
		if (boolGet(g_isZombie, id))
			sendLightStyle(id, 0, g_currentLight);
		
		sendScreenFade(id, 0.0, 0.0, 0x0000, {0, 0, 0}, 0);
	}
	
	return PLUGIN_HANDLED;
}

public Nvg_Think(id)
{
	static Float:lastUpdate[33];
	
	if (get_pdata_bool(id, m_bNightVisionOn))
	{
		if (!boolGet(g_isZombie, id) && get_gametime() - lastUpdate[id] >= 0.1)
		{
			static Float:origin[3];
			ExecuteHam(Ham_EyePosition, id, origin);
			
			static Float:vector[3];
			velocity_by_aim(id, 300, vector);
			xs_vec_add(origin, vector, vector);
			
			engfunc(EngFunc_TraceLine, origin, vector, IGNORE_MONSTERS, id, 0);
			get_tr2(0, TR_vecEndPos, origin);
			
			// dynamic light
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_DLIGHT);
			write_coord_f(origin[0]);
			write_coord_f(origin[1]);
			write_coord_f(origin[2]);
			write_byte(35); // radius
			write_byte(0); // r
			write_byte(200); // g
			write_byte(0); // b
			write_byte(2); // life
			write_byte(0);
			message_end();
			
			lastUpdate[id] = get_gametime();
		}
	}
}

// useless?
stock giveNightVision(id, bool:give)
{
	static msgItemStatus;
	msgItemStatus || (msgItemStatus = get_user_msgid("ItemStatus"));
	
	message_begin(MSG_ONE_UNRELIABLE, msgItemStatus, _, id);
	write_byte(give ? 1 << 0 : 0);
	message_end();
	
	set_pdata_bool(id, m_bHasNightVision, give);
}