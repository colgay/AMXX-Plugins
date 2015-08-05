#include <amxmodx>
#include <fakemeta>

#define boolGet(%1,%2) (%1 & (1 << (%2 & 31)))
#define boolSet(%1,%2) (%1 |= (1 << (%2 & 31)))
#define boolUnset(%1,%2) (%1 &= ~(1 << (%2 & 31)))

const OFFSET_TEAM = 114;
const OFFSET_MODELINDEX = 491;

new g_isModeled;
new g_model[32][33];

public plugin_init()
{
	register_plugin("Player Model", "0.1", "cogreyt");
	
	register_forward(FM_SetClientKeyValue, "OnSetClientKeyValue");
	register_message(get_user_msgid("ClCorpse"), "OnClientCorpse");
}

public client_disconnect(id)
{
	boolUnset(g_isModeled, id);
}

public OnSetClientKeyValue(id, const infoBuffer[], const key[], const value[])
{
	if (boolGet(g_isModeled, id) && equal(key, "model") && !equal(value, g_model[id]))
	{
		set_user_info(id, "model", g_model[id]);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public OnClientCorpse()
{
	new id = get_msg_arg_int(12);
	if (boolGet(g_isModeled, id))
		set_msg_arg_string(1, g_model[id]);
}

public plugin_natives()
{
	register_library("playermodel");
	
	register_native("fm_set_user_model",   "_set_user_model");
	register_native("fm_reset_user_model", "_reset_user_model");
}

public _set_user_model()
{
	new id = get_param(1);
	
	new model[33];
	get_string(2, model, charsmax(model));
	g_model[id] = model;
	
	// set player model
	boolSet(g_isModeled, id);
	set_user_info(id, "model", model);
	
	// set model index?
	if (get_param(3))
	{
		set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_PrecacheModel, model));
	}
}

public _reset_user_model()
{
	new id = get_param(1);
	
	if (!boolGet(g_isModeled, id))
		return;
	
	// reset player model
	boolUnset(g_isModeled, id);
	dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id));
	
	// reset model index
	switch (get_pdata_int(id, OFFSET_TEAM))
	{
		case 1: set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, "models/player/terror/terror.mdl"));
		case 2: set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, "models/player/urban/urban.mdl"));
	}
}