#if defined _ZOMBIEMOD_AMBIENCE_
	#endinput
#endif

#define _ZOMBIEMOD_AMBIENCE_

new g_defaultLight[32];
new g_currentLight[32];

public Ambience_Precache()
{
	new ent = create_entity("env_fog");
	DispatchKeyValue(ent, "density", "0.0013");
	DispatchKeyValue(ent, "rendercolor", "100 70 70");
}

public Ambience_Main()
{
	register_forward(FM_LightStyle, "OnLightStyle");
}

public OnLightStyle(style, const light[])
{
	if (style == 0)
		copy(g_defaultLight, charsmax(g_defaultLight), light);
}

public Ambience_NewRound()
{
	setGlobalLight(g_defaultLight);
}

public Ambience_RoundStart()
{
	setGlobalLight("d");
}

public Ambience_PutInServer(id)
{
	sendLightStyle(id, 0, g_currentLight);
}

stock setGlobalLight(const light[])
{
	copy(g_currentLight, charsmax(g_currentLight), light);
	sendLightStyle(0, 0, light);
}