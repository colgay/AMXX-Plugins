#include <amxmodx>
#include <fakemeta>

#define VERSION "0.1"

#define FIXED_BIT(%0) (1 << (%0 & 31))

new g_menuPlayers[33];
new g_votePlayers[33];

new g_maxClients;

public plugin_init()
{
	register_plugin("Voteban", VERSION, "Cogreyt");
	
	register_clcmd("say /voteban", "CmdVoteBan");
	
	g_maxClients = get_maxplayers();
}

public client_disconnect(id)
{
	for (new i = 1; i <= g_maxClients; i++)
		g_menuPlayers[i] &= ~FIXED_BIT(id);
	
	g_votePlayers[id] = 0;
	g_menuPlayers[id] = 0;
}

public CmdVoteBan(id)
{
	DisplayVoteBan(id);
	return PLUGIN_HANDLED;
}

public DisplayVoteBan(id)
{
	new menu = menu_create("Voteban Player", "MenuVoteBan");
	
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		static name[32]; // declaring 'static' inside loop is just fine
		get_user_name(i, name, charsmax(name));
		
		static text[64], info[2];
		formatex(text, charsmax(text), "%s \y%i%%", name, banPercent(i));
		info[0] = i;
		
		menu_additem(menu, text, info);
		g_menuPlayers[id] |= FIXED_BIT(i);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y"); // yellow is good
	menu_display(id, menu);
}

public MenuVoteBan(id, menu, item)
{
	static info[2], dummy;
	menu_item_getinfo(menu, item, dummy, info, charsmax(info), _, _, dummy);
	menu_destroy(menu);
	
	if (item == MENU_EXIT)
		return;
	
	new player = info[0];
	
	// player not in menu anymore (avoid selected a wrong player)
	if (~g_menuPlayers[id] & FIXED_BIT(player))
	{
		DisplayVoteBan(id); // update menu
		return;
	}
	
	static name[32], name2[32];
	get_user_name(id, name, charsmax(name));
	get_user_name(player, name2, charsmax(name2));
	
	if (g_votePlayers[id] & FIXED_BIT(player))
	{
		g_votePlayers[id] &= ~FIXED_BIT(player);
		client_print_color(0, id, "^1* ^3%s ^1canceled voteban on ^3%s^1(%i%%)", name, name2, banPercent(player));
	}
	else
	{
		g_votePlayers[id] |= FIXED_BIT(player);
		client_print_color(0, id, "^1* ^3%s ^1added voteban on^x03 ^3%s^1(%i%%)", name, name2, banPercent(player));
	}
}

stock percent(part, all, value=100)
{
	return part * value / all;
}

stock banPercent(id, value=100)
{
	return percent(countVotes(id), countPlayers(), value);
}

stock countVotes(id)
{
	new num = 0;
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (g_votePlayers[i] & FIXED_BIT(id))
			num++;
	}
	
	return num;
}

stock countPlayers()
{
	new num = 0;
	for (new i = 1; i <= g_maxClients; i++)
	{
		if (is_user_connected(i) /*&& !is_user_bot(i)*/)
			num++;
	}
	
	return num;
}