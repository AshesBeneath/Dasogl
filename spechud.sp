#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include <l4d2util>
#include <readyup>
#include <pause>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_hybrid_scoremod_zone>

#define SPECHUD_DRAW_INTERVAL   0.5

#define ZOMBIECLASS_NAME(%0) (L4D2_InfectedNames[_:(%0)-1])

enum L4D2WeaponSlot
{
	L4D2WeaponSlot_Primary,
	L4D2WeaponSlot_Secondary,
	L4D2WeaponSlot_Throwable,
	L4D2WeaponSlot_HeavyHealthItem,
	L4D2WeaponSlot_LightHealthItem
};

enum L4D2Gamemode
{
	L4D2Gamemode_None,
	L4D2Gamemode_Versus,
	L4D2Gamemode_Scavenge
};

new Handle:survivor_limit;
new Handle:z_max_player_zombies;

new bool:bSpecHudActive[MAXPLAYERS + 1];
new bool:bSpecHudHintShown[MAXPLAYERS + 1];
new bool:bTankHudActive[MAXPLAYERS + 1];
new bool:bTankHudHintShown[MAXPLAYERS + 1];
new bool:hybridScoringAvailable;

public Plugin:myinfo = 
{
	name = "Confogl Evoluated Spectator HUD [TR]",
	author = "Visor, Sir, devilesk",
	description = "Provides different HUDs for spectators",
	version = "3.1.3",
	url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() 
{
	survivor_limit = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");

	RegConsoleCmd("sm_spechud", ToggleSpecHudCmd);
	RegConsoleCmd("sm_tankhud", ToggleTankHudCmd);

	CreateTimer(SPECHUD_DRAW_INTERVAL, HudDrawTimer, _, TIMER_REPEAT);
}

public OnAllPluginsLoaded()
{
	hybridScoringAvailable = LibraryExists("l4d2_hybrid_scoremod_zone");
}
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "l4d2_hybrid_scoremod_zone", true))
	{
		hybridScoringAvailable = false;
	}
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "l4d2_hybrid_scoremod_zone", true))
	{
		hybridScoringAvailable = true;
	}
}

public OnClientConnected(client)
{
	bSpecHudActive[client] = false;
	bSpecHudHintShown[client] = false;
	bTankHudActive[client] = true;
	bTankHudHintShown[client] = false;
}

public Action:ToggleSpecHudCmd(client, args) 
{
	bSpecHudActive[client] = !bSpecHudActive[client];
	CPrintToChat(client, "{lightgreen}★ {olive}SpecHUD - %s.", (bSpecHudActive[client] ? "{blue}AÇIK{default}" : "{red}KAPALI{default}"));
}

public Action:ToggleTankHudCmd(client, args) 
{
	bTankHudActive[client] = !bTankHudActive[client];
	CPrintToChat(client, "{lightgreen}★ {olive}TankHUD - %s.", (bTankHudActive[client] ? "{blue}AÇIK{default}" : "{red}KAPALI{default}"));
}

public Action:HudDrawTimer(Handle:hTimer) 
{
	if (IsInReady() || IsInPause())
		return Plugin_Handled;

	new bool:bSpecsOnServer = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsSpectator(i))
		{
			bSpecsOnServer = true;
			break;
		}
	}

	if (bSpecsOnServer) // Only bother if someone's watching us
	{
		new Handle:specHud = CreatePanel();

		FillHeaderInfo(specHud);
		FillSurvivorInfo(specHud);
		FillInfectedInfo(specHud);
		FillTankInfo(specHud);
		FillGameInfo(specHud);

		for (new i = 1; i <= MaxClients; i++) 
		{
			if (!bSpecHudActive[i] || !IsSpectator(i) || IsFakeClient(i))
				continue;

			SendPanelToClient(specHud, i, DummySpecHudHandler, 3);
			if (!bSpecHudHintShown[i])
			{
				bSpecHudHintShown[i] = true;
				CPrintToChat(i, "{lightgreen}★  {green}!spechud{default} yazarak izleyici panelini açıp kapatabilirsiniz.");
			}
		}

		CloseHandle(specHud);
	}
	
	new Handle:tankHud = CreatePanel();
	if (!FillTankInfo(tankHud, true)) // No tank -- no HUD
	{
		CloseHandle(tankHud);
		return Plugin_Handled;
	}

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!bTankHudActive[i] || !IsClientInGame(i) || IsFakeClient(i) || IsSurvivor(i) || (bSpecHudActive[i] && IsSpectator(i)))
			continue;

		SendPanelToClient(tankHud, i, DummyTankHudHandler, 3);
		if (!bTankHudHintShown[i])
		{
			bTankHudHintShown[i] = true;
			CPrintToChat(i, "{lightgreen}★ {green}!tankhud{default} yazarak Tank kontrol panelini açıp kapatabilirsiniz.");
		}
	}

	CloseHandle(tankHud);
	return Plugin_Continue;
}

public DummySpecHudHandler(Handle:hMenu, MenuAction:action, param1, param2) {}
public DummyTankHudHandler(Handle:hMenu, MenuAction:action, param1, param2) {}

FillHeaderInfo(Handle:hSpecHud) 
{
	DrawPanelText(hSpecHud, "Izleyici Paneli");

	decl String:buffer[512];
	Format(buffer, sizeof(buffer), "Kontenjan %i/%i || Tickrate %i", GetRealClientCount(), GetConVarInt(FindConVar("sv_maxplayers")), RoundToNearest(1.0 / GetTickInterval()));
	DrawPanelText(hSpecHud, buffer);
}

GetMeleePrefix(client, String:prefix[], length) 
{
	new secondary = GetPlayerWeaponSlot(client, _:L4D2WeaponSlot_Secondary);
	new WeaponId:secondaryWep = IdentifyWeapon(secondary);

	decl String:buf[4];
	switch (secondaryWep)
	{
		case WEPID_NONE: buf = "N";
		case WEPID_PISTOL: buf = (GetEntProp(secondary, Prop_Send, "m_isDualWielding") ? "DP" : "P");
		case WEPID_MELEE: buf = "M";
		case WEPID_PISTOL_MAGNUM: buf = "DE";
		default: buf = "?";
	}

	strcopy(prefix, length, buf);
}

FillSurvivorInfo(Handle:hSpecHud) 
{
	decl String:info[512];
	decl String:buffer[64];
	decl String:name[MAX_NAME_LENGTH];

	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->1. Sag Kalanlar");

	new survivorCount;
	for (new client = 1; client <= MaxClients && survivorCount < GetConVarInt(survivor_limit); client++) 
	{
		if (!IsSurvivor(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client))
		{
			Format(info, sizeof(info), "%s: Geberdi", name);
		}
		else
		{
			new WeaponId:primaryWep = IdentifyWeapon(GetPlayerWeaponSlot(client, _:L4D2WeaponSlot_Primary));
			GetLongWeaponName(primaryWep, info, sizeof(info));
			GetMeleePrefix(client, buffer, sizeof(buffer)); 
			Format(info, sizeof(info), "%s/%s", info, buffer);

			if (IsSurvivorHanging(client))
			{
				Format(info, sizeof(info), "%s: %iHP <Asili> [%s]", name, GetSurvivorHealth(client), info);
			}
			else if (IsIncapacitated(client))
			{
				Format(info, sizeof(info), "%s: %iHP <%i. Incap> [%s]", name, GetSurvivorHealth(client), (GetSurvivorIncapCount(client) + 1), info);
			}
			else
			{
				new health = GetSurvivorHealth(client) + GetSurvivorTemporaryHealth(client);
				new incapCount = GetSurvivorIncapCount(client);
				if (incapCount == 0)
				{
					Format(info, sizeof(info), "%s: %iHP [%s]", name, health, info);
				}
				else
				{
					Format(buffer, sizeof(buffer), "%i kere dustu", incapCount);
					Format(info, sizeof(info), "%s: %iHP (%s) [%s]", name, health, buffer, info);
				}
			}
		}

		survivorCount++;
		DrawPanelText(hSpecHud, info);
	}
	if (hybridScoringAvailable)
	{
		new healthBonus = SMPlus_GetHealthBonus();
		new damageBonus = SMPlus_GetDamageBonus();
		new pillsBonus = SMPlus_GetPillsBonus();
		DrawPanelText(hSpecHud, " ");
		Format(info, 512, "HP Bonusu: %i <%.1f%%>", healthBonus, ToPercent(healthBonus, SMPlus_GetMaxHealthBonus()));
		DrawPanelText(hSpecHud, info);
		Format(info, 512, "Hasar Bonusu: %i <%.1f%%>", damageBonus, ToPercent(damageBonus, SMPlus_GetMaxDamageBonus()));
		DrawPanelText(hSpecHud, info);
		Format(info, 512, "Pills Bonusu: %i <%.1f%%>", pillsBonus, ToPercent(pillsBonus, SMPlus_GetMaxPillsBonus()));
		DrawPanelText(hSpecHud, info);
	}
}

FillInfectedInfo(Handle:hSpecHud) 
{
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->2. Enfekteler");

	decl String:info[512];
	decl String:buffer[32];
	decl String:name[MAX_NAME_LENGTH];

	new infectedCount;
	for (new client = 1; client <= MaxClients && infectedCount < GetConVarInt(z_max_player_zombies); client++) 
	{
		if (!IsInfected(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client)) 
		{
			new CountdownTimer:spawnTimer = L4D2Direct_GetSpawnTimer(client);
			new Float:timeLeft = -1.0;
			if (spawnTimer != CTimer_Null)
			{
				timeLeft = CTimer_GetRemainingTime(spawnTimer);
			}

			if (timeLeft < 0.0)
			{
				Format(info, sizeof(info), "%s: Geberdi", name);
			}
			else
			{
				Format(buffer, sizeof(buffer), "%i sn", RoundToNearest(timeLeft));
				Format(info, sizeof(info), "%s: Geberdi (%s)", name, (RoundToNearest(timeLeft) ? buffer : "Spawnlaniyor..."));
			}
		}
		else 
		{
			new L4D2_Infected:zClass = GetInfectedClass(client);
			if (zClass == L4D2Infected_Tank)
				continue;

			if (IsInfectedGhost(client))
			{
				// TO-DO: Handle a case of respawning chipped SI, show the ghost's health
				Format(info, sizeof(info), "%s: %s (Spawn olacak)", name, ZOMBIECLASS_NAME(zClass));
			}
			else if (GetEntityFlags(client) & FL_ONFIRE)
			{
				Format(info, sizeof(info), "%s: %s (%iHP) [Alev aliyor]", name, ZOMBIECLASS_NAME(zClass), GetClientHealth(client));
			}
			else
			{
				Format(info, sizeof(info), "%s: %s (%iHP)", name, ZOMBIECLASS_NAME(zClass), GetClientHealth(client));
			}
		}

		infectedCount++;
		DrawPanelText(hSpecHud, info);
	}
	
	if (!infectedCount)
	{
		DrawPanelText(hSpecHud, "Takim Bos");
	}
}

bool:FillTankInfo(Handle:hSpecHud, bool:bTankHUD = false)
{
	new tank = FindTank();
	if (tank == -1)
		return false;

	decl String:info[512];
	decl String:name[MAX_NAME_LENGTH];

	if (bTankHUD)
	{
		GetConVarString(FindConVar("l4d_ready_cfg_name"), info, sizeof(info));
		Format(info, sizeof(info), "->Tank Paneli | %s", info);
		DrawPanelText(hSpecHud, info);
		DrawPanelText(hSpecHud, "___________________");
	}
	else
	{
		DrawPanelText(hSpecHud, " ");
		DrawPanelText(hSpecHud, "->3. Tank");
	}

	// Draw owner & pass counter
	new passCount = L4D2Direct_GetTankPassedCount();
	switch (passCount)
	{
		case 0: Format(info, sizeof(info), "N/A");
		case 1: Format(info, sizeof(info), "#%i", passCount);
		case 2: Format(info, sizeof(info), "#%i", passCount);
		case 3: Format(info, sizeof(info), "#%i", passCount);
		default: Format(info, sizeof(info), "#%i", passCount);
	}

	if (!IsFakeClient(tank))
	{
		GetClientFixedName(tank, name, sizeof(name));
		Format(info, sizeof(info), "%s | Pass %s", name, info);
	}
	else
	{
		Format(info, sizeof(info), "Kontrol : BOT");
	}
	DrawPanelText(hSpecHud, info);

	// Draw health
	new health = GetClientHealth(tank);
	if (health <= 0 || IsIncapacitated(tank) || !IsPlayerAlive(tank))
	{
		info = "0 HP (0%)";
	}
	else
	{
		new healthPercent = RoundFloat((100.0 / (GetConVarFloat(FindConVar("z_tank_health")) * 1.5)) * health);
		Format(info, sizeof(info), "%i HP (%i%%)", health, ((healthPercent < 1) ? 1 : healthPercent));
	}
	DrawPanelText(hSpecHud, info);

	// Draw frustration
	if (!IsFakeClient(tank))
	{
		Format(info, sizeof(info), "Kontrol: %d%%", GetTankFrustration(tank));
	}
	else
	{
		info = "Kontrol: BOT";
	}
	DrawPanelText(hSpecHud, info);

	// Draw fire status
	if (GetEntityFlags(tank) & FL_ONFIRE)
	{
		new timeleft = RoundToCeil(health / 80.0);
		Format(info, sizeof(info), "Yaniyor!!! (%i sn sonra sönecek)", timeleft);
		DrawPanelText(hSpecHud, info);
	}

	return true;
}

FillGameInfo(Handle:hSpecHud)
{
	// Turns out too much info actually CAN be bad, funny ikr
	new tank = FindTank();
	if (tank != -1)
		return;

	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->3. Mac Bilgileri");

	decl String:info[512];
	decl String:buffer[512];

	GetConVarString(FindConVar("l4d_ready_cfg_name"), info, sizeof(info));

	if (GetCurrentGameMode() == L4D2Gamemode_Versus)
	{
		Format(info, sizeof(info), "Mac Modu: %s (Tur %s/2)", info, (InSecondHalfOfRound() ? "2" : "1"));
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "Su anda: %i%%", RoundToNearest(GetHighestSurvivorFlow() * 100.0));
		DrawPanelText(hSpecHud, info);

		if (RoundHasFlowTank())
		{
			Format(info, sizeof(info), "Tank: %i%% (%i%%)", RoundToNearest(L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) * 100.0), RoundToNearest(GetTankFlow() * 100.0));
			DrawPanelText(hSpecHud, info);
		}

		if (RoundHasFlowWitch())
		{
			Format(info, sizeof(info), "Cadi: %i%% (%i%%)", RoundToNearest(L4D2Direct_GetVSWitchFlowPercent(InSecondHalfOfRound()) * 100.0), RoundToNearest(GetWitchFlow() * 100.0));
			DrawPanelText(hSpecHud, info);
		}
	}
	else if (GetCurrentGameMode() == L4D2Gamemode_Scavenge)
	{
		DrawPanelText(hSpecHud, info);

		new round = GetScavengeRoundNumber();
		switch (round)
		{
			case 0: Format(buffer, sizeof(buffer), "N/A");
			case 1: Format(buffer, sizeof(buffer), "%i.", round);
			case 2: Format(buffer, sizeof(buffer), "%i.", round);
			case 3: Format(buffer, sizeof(buffer), "%i.", round);
			default: Format(buffer, sizeof(buffer), "%i.", round);
		}

		Format(info, sizeof(info), "%s Yari", (InSecondHalfOfRound() ? "2." : "1."));
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "%s Tur", buffer);
		DrawPanelText(hSpecHud, info);
	}
}

/* Stocks */

Float:ToPercent(score, maxbonus)
{
	return score < 1 ? 0.0 : float(score) / float(maxbonus) * 100.0;
}

GetClientFixedName(client, String:name[], length) 
{
	GetClientName(client, name, length);

	if (name[0] == '[') 
	{
		decl String:temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp)-2] = 0;
		strcopy(name[1], length-1, temp);
		name[0] = ' ';
	}

	if (strlen(name) > 25) 
	{
		name[22] = name[23] = name[24] = '.';
		name[25] = 0;
	}
}

GetRealClientCount() 
{
	new clients = 0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) clients++;
	}
	return clients;
}

GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

Float:GetClientFlow(client)
{
	return (L4D2Direct_GetFlowDistance(client) / L4D2Direct_GetMapMaxFlowDistance());
}

Float:GetHighestSurvivorFlow()
{
	new Float:flow;
	new Float:maxflow = 0.0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsSurvivor(i))
		{
			flow = GetClientFlow(i);
			if (flow > maxflow)
			{
				maxflow = flow;
			}
		}
	}
	return maxflow;
}

bool:RoundHasFlowTank()
{
	return L4D2Direct_GetVSTankToSpawnThisRound(InSecondHalfOfRound());
}

bool:RoundHasFlowWitch()
{
	return L4D2Direct_GetVSWitchToSpawnThisRound(InSecondHalfOfRound());
}

Float:GetTankFlow() 
{
	return L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) -
		(GetConVarFloat(FindConVar("versus_boss_buffer")) / L4D2Direct_GetMapMaxFlowDistance());
}

Float:GetWitchFlow() 
{
	return L4D2Direct_GetVSWitchFlowPercent(InSecondHalfOfRound()) -
		(GetConVarFloat(FindConVar("versus_boss_buffer")) / L4D2Direct_GetMapMaxFlowDistance());
}

bool:IsSpectator(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1;
}

FindTank() 
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsInfected(i) && GetInfectedClass(i) == L4D2Infected_Tank && IsPlayerAlive(i))
			return i;
	}

	return -1;
}

bool:IsSurvivorHanging(client)
{
	return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

GetSurvivorHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

L4D2Gamemode:GetCurrentGameMode()
{
	static String:sGameMode[32];
	if (sGameMode[0] == EOS)
	{
		GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	}
	if (StrContains(sGameMode, "scavenge") > -1)
	{
		return L4D2Gamemode_Scavenge;
	}
	if (StrContains(sGameMode, "versus") > -1
		|| StrEqual(sGameMode, "mutation12")) // realism versus
	{
		return L4D2Gamemode_Versus;
	}
	else
	{
		return L4D2Gamemode_None; // Unsupported
	}
}