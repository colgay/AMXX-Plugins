#include <amxmodx>
#include <fakemeta>

#define VERSION "0.1"

new g_maxClients;

public plugin_init()
{
	register_plugin("Voteban", VERSION, "Cogreyt");
	
	register_clcmd("say /voteban", "CmdVoteBan");
	
	g_maxClients = get_maxplayers();
}

public CmdVoteBan(id)
{
	new menu = menu_create("Voteban Player", "HandleVoteBan");
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		
	}
}