#if defined _ZOMBIEMOD_BUY_
	#endinput
#endif

#define _ZOMBIEMOD_BUY_

new const BUY_ITEM_NAMES[][] = 
{
	"Medical Kit", "Anodyne", "Kevlar Armor", "Night Vision", 
	"HE Grenade", "Flashbang", "Dragon Balls",
	"MP5", "UMP45", "P90", "M3", "M1014", "Galil", "Famas", "AK-47", "M4A1", "SG 552", "AUG", "G3SG1", "SG550", "Scout", "AWP", "M249"
};

new const BUY_ITEM_COSTS[] = 
{
	0, 0, 0, 0,
	0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

enum _:AmmoData
{
	AD_Amt,
	AD_Cost,
	AD_Max
};

new const AMMO_DATAS[][AmmoData] =
{
/*  {Amt, Cost, Max}  */
	{-1,  -1,  -1},
	{10, 125,  30}, // 338magnum
	{30,  80,  90}, // 762nato
	{30,  60, 200}, // 556natobox
	{30,  60,  90}, // 556nato
	{ 8,  65,  32}, // buckshot
	{12,  25, 100}, // 45acp
	{50,  50, 100}, // 57mm
	{ 7,  40,  35}, // 50ae
	{13,  50,  52}, // 357sig
	{30,  20, 120}, // 9mm
	{ 1,  -1,   2}, // Flashbang
	{ 1,  -1,   2}, // HEGrenade
	{ 1,  -1,   2}, // SmokeGrenade
	{-1,  -1,  -1} // C4
};

new const AMMO_NAMES[][] =
{
	"",
	"338magnum",
	"762nato",
	"556natobox",
	"556nato",
	"buckshot",
	"45acp",
	"57mm",
	"50ae",
	"357sig",
	"9mm",
	"Flashbang",
	"HEGrenade",
	"SmokeGrenade",
	"C4"
};

public Buy_Precache()
{
	new ent = create_entity("func_buyzone");
	DispatchSpawn(ent);
}

public Buy_Main()
{
	RegisterHam(Ham_GiveAmmo, "player", "OnGiveAmmo");
	
	register_clcmd("buy2", "CmdBuy");
	//register_clcmd("buy",  "CmdBuy");
	register_clcmd("buyammo1", "CmdBuyAmmo1");
	register_clcmd("buyammo2", "CmdBuyAmmo2");
}

public CmdBuy(id)
{
	BuyMenu(id);
	return PLUGIN_HANDLED;
}

public CmdBuyAmmo1(id)
{
	buyGunAmmo(id, 1);
	return PLUGIN_HANDLED;
}

public CmdBuyAmmo2(id)
{
	buyGunAmmo(id, 2);
	return PLUGIN_HANDLED;
}

public OnGiveAmmo(id, amount, ammoName[], max)
{
	client_print(id, print_chat, ammoName);
	
	// apply custom max ammo and amount
	new ammoId = getAmmoIndex(ammoName);
	if (ammoId > 0 && amount > 0)
	{
		new ammoAmount = AMMO_DATAS[ammoId][AD_Amt];
		if (ammoAmount != amount)
			SetHamParamInteger(2, ammoAmount);
		
		new ammoMax = AMMO_DATAS[ammoId][AD_Max];
		if (ammoMax != max)
			SetHamParamInteger(4, ammoMax);
	}
}

public BuyMenu(id)
{
	new menu = menu_create("Buy Everywhere", "HandleBuyMenu");
	
	for (new i = 0; i < sizeof(BUY_ITEM_NAMES); i++)
	{
		static string[64];
		formatex(string, charsmax(string), "%s \R\y$%i", BUY_ITEM_NAMES[i], BUY_ITEM_COSTS[i]);
		
		menu_additem(menu, string);
	}
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y"); // I like yellow
	menu_display(id, menu);
}

public HandleBuyMenu(id, menu, item)
{
	menu_destroy(menu);
	
	if (item < 0) // exit
		return;
	
	// not enough money
	new money = get_pdata_int(id, m_iAccount);
	if (money < BUY_ITEM_COSTS[item])
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money");
		sendBlinkAcct(id, 3);
		return;
	}
	
	if (item >= 7) // guns
	{
		static const buyGunNames[][] =
		{
			"weapon_mp5navy", "weapon_ump45", "weapon_p90", "weapon_m3", "weapon_xm1014",
			"weapon_galil", "weapon_famas", "weapon_ak47", "weapon_m4a1", "weapon_sg552", "weapon_aug",
			"weapon_g3sg1", "weapon_sg550", "weapon_scout", "weapon_awp", 
			"weapon_m249"
		};
		
		new item2 = item - 7;
		
		// already own that weapon?
		if (find_ent_by_owner(-1, buyGunNames[item2], id))
		{
			client_print(id, print_center, "#Cstrike_TitlesTXT_Cstrike_Already_Own_Weapon");
			return;
		}
		
		dropPlayerWeapons(id, 1);
		give_item(id, buyGunNames[item2]);
	}
	else if (item >= 4) // grenades
	{
		static const buyNadeNames[][] = {"weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade"};
		
		// TODO: custom max bpammo for grenades??
		new item2 = item - 4;
		give_item(id, buyNadeNames[item2]);
	}
	else
	{
		switch (item)
		{
			case 2: // armor
			{
				if (get_pdata_int(id, m_iKevlar) && pev(id, pev_armorvalue) >= 100)
				{
					client_print(id, print_center, "#Cstrike_TitlesTXT_Already_Have_One");
					return;
				}
				
				give_item(id, "item_assaultsuit");
			}
			case 3: // night vision
			{
				if (get_pdata_bool(id, m_bHasNightVision))
				{
					client_print(id, print_center, "#Cstrike_TitlesTXT_Already_Have_One");
					return;
				}
				
				giveNightVision(id, true);
			}
		}
	}
	
	setPlayerMoney(id, money - BUY_ITEM_COSTS[item], true);
}

stock buyGunAmmo(id, slot)
{
	new money = get_pdata_int(id, m_iAccount);
	new boughtAmmo, canBuy;
	
	new playerItem = get_pdata_cbase(id, m_rgpPlayerItems + slot);
	
	// find player items
	while (playerItem > 0)
	{
		// each ammo type can only buy once
		new ammoId = get_pdata_int(playerItem, m_iPrimaryAmmoType);
		if (ammoId > 0 && (~boughtAmmo & (1 << ammoId)))
		{
			// ammo is not full
			if (get_pdata_int(id, m_rgAmmo + ammoId) < AMMO_DATAS[ammoId][AD_Max])
			{
				new cost = AMMO_DATAS[ammoId][AD_Cost];
				if (money >= cost)
				{
					// use give_item() for compatibility
					new itemName[16] = "ammo_";
					add(itemName, charsmax(itemName), AMMO_NAMES[ammoId]);
					give_item(id, itemName);
					
					boughtAmmo |= (1 << ammoId);
					money -= cost;
				}
				canBuy = true;
			}
		}
		
		playerItem = get_pdata_cbase(id, m_pNext);
	}
	
	if (boughtAmmo)
	{
		setPlayerMoney(id, money, true);
	}
	else if (canBuy)
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money");
		sendBlinkAcct(id, 3);
	}
}

stock getAmmoIndex(const ammoName[])
{
	static Trie:ammoNameIndex;
	if (!ammoNameIndex)
	{
		ammoNameIndex = TrieCreate();
		for (new i = 1; i < sizeof (AMMO_NAMES); i++)
			TrieSetCell(ammoNameIndex, AMMO_NAMES[i], i);
	}
	
	static result;
	return TrieGetCell(ammoNameIndex, ammoName, result) ? result : 0;
}