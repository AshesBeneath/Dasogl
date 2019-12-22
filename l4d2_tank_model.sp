#include <sourcemod>
#include <sdktools>
#include <colors>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#define g_sTankNorm	"models/infected/hulk.mdl"
#define g_sTankSac	"models/infected/hulk_dlc3.mdl"

new bool:g_bIsTankAlive;

public Plugin:myinfo = 
{
	name = "Rastgele Tank Model",
	author = "AshesBeneath",
	description = "Tank uyarısı & The Sacrifice ile varsayılan tank modeli arasında randomlama",
	version = PLUGIN_VERSION,
	url = "https://github.com/AshesBeneath/Dasogl"
}

public OnPluginStart()
{	
	HookEvent("tank_spawn", eTankSpawn);
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_killed", EventHook:OnTankDead, EventHookMode_PostNoCopy);
}

//Hazırlık
public OnMapStart()
{
	PrecacheModel(g_sTankNorm, true);
	PrecacheModel(g_sTankSac, true);
	PrecacheSound("ui/pickup_secret01.wav");
}

public OnRoundStart()
{
	g_bIsTankAlive = false;
}

//%50 model şansı
public eTankSpawn(Handle:hEvent, const String:sname[], bool:bDontBroadcast)
{
	new iTank =  GetEventInt(hEvent, "tankid");
	if(iTank > 0 && iTank <= MaxClients && IsClientInGame(iTank) && GetClientTeam(iTank) == 3 && IsPlayerAlive(iTank))
	{
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				SetEntityModel(iTank, g_sTankSac);
			}
			case 2:
			{
				SetEntityModel(iTank, g_sTankNorm);
			}
		}
	}
	//Tank varsa ses çal
	if (!g_bIsTankAlive)
	{
		g_bIsTankAlive = true;
		CPrintToChatAll("{lightgreen}★ {green}Tank spawnlandı!!!");
		EmitSoundToAll("ui/pickup_secret01.wav");
	}
}

//Tank öldüğünü bilsin
public OnTankDead()
{
	if (g_bIsTankAlive)
		g_bIsTankAlive = false;
}
