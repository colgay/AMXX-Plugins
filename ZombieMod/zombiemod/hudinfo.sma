#if defined _ZOMBIEMOD_HUDINFO_
	#endinput
#endif

#define _ZOMBIEMOD_HUDINFO_

public HudInfo_Main()
{
	register_event("Health", "EventHealth", "b");
	set_task(1.0, "ShowHudInfo", 3434, .flags="b");
}

public EventHealth(id)
{
	updateHudInfo(id);
}

public ShowHudInfo()
{
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_alive(i))
			updateHudInfo(i);
	}
}

updateHudInfo(id)
{
	static Float:lastUpdate[33];
	if (get_gametime() - lastUpdate[id] < 0.1)
		return;
	
	static class[32], color[3];
	
	if (boolGet(g_isZombie, id))
	{
		if (boolGet(g_isNemesis, id))
		{
			copy(class, charsmax(class), "Nemesis");
			color = {250, 0, 50};
		}
		else
		{
			copy(class, charsmax(class), "Dead");
			color = {250, 100, 0};
		}
	}
	else
	{
		switch (get_user_health(id))
		{
			case 0 .. 25:
			{
				copy(class, charsmax(class), "Danger");
				color = {200, 55, 0};
			}
			case 26 .. 50:
			{
				copy(class, charsmax(class), "Caution");
				color = {100, 160, 0};
			}
			default:
			{
				copy(class, charsmax(class), "Fine");
				color = {0, 255, 0};
			}
		}
	}
	
	set_hudmessage(color[0], color[1], color[2], 0.01, 0.9, 0, 0.0, 1.0, 0.1, 0.5, 4);
	show_hudmessage(id, "HP %i - %s", get_user_health(id), class);
	
	lastUpdate[id] = get_gametime();
}