#if defined _ZOMBIEMOD_MONEY_
	#endinput
#endif

#define _ZOMBIEMOD_MONEY_

new Float:g_damageEarn[33];

public Money_Main()
{
	OrpheuRegisterHook(OrpheuGetFunction("AddAccount", "CBasePlayer"), "OnAddAccount");
}

public OrpheuHookReturn:OnAddAccount(id, amount, bool:trackChange)
{
	// block all CS default money rewards
	return amount > 0 ? OrpheuSupercede : OrpheuIgnored;
}

public Money_TakeDamage(id, inflictor, attacker, Float:damage, damageBits)
{
	if (isPlayer(attacker) && id != attacker && boolGet(g_isZombie, id) != boolGet(g_isZombie, attacker))
	{
		if (boolGet(g_isZombie, attacker))
		{
			g_damageEarn[attacker] += damage;
			
			while (g_damageEarn[attacker] >= 200.0)
			{
				setPlayerMoney(attacker, get_pdata_int(attacker, m_iAccount) + 50, true);
				g_damageEarn[attacker] -= 200.0;
			}
		}
		else
		{
			g_damageEarn[attacker] += damage;
			
			while (g_damageEarn[attacker] >= 300.0)
			{
				setPlayerMoney(attacker, get_pdata_int(attacker, m_iAccount) + 50, true);
				g_damageEarn[attacker] -= 300.0;
			}
		}
	}
}

public Money_Disconnect(id)
{
	g_damageEarn[id] = 0.0;
}