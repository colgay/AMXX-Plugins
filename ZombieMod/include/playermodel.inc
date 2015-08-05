#if defined _PLAYERMODEL_INC_
	#endinput
#endif

#define _PLAYERMODEL_INC_

native fm_set_user_model(id, const model[], bool:modelIndex=false);

native fm_reset_user_model(id);

stock precache_player_model(const model[])
{
	static precache[100];
	formatex(precache, charsmax(precache), "models/player/%s/%s.mdl", model, model);
	precache_model(precache);
	
	// support *T.mdl
	formatex(precache, charsmax(precache), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(precache))
		precache_model(precache);
}