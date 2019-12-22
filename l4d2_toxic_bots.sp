#include <sourcemod>
#include <sdktools>
#include <colors>
#include <l4d2_skill_detect>

#define DEBUG 0

new bool:RoundBitti;
new bool:SafeKapisiKapandi;

new String:botchat[256];

public Plugin:myinfo = 
{
	name = "L4D2 Bot Chat Kullanımı",
	author = "AshesBeneath",
	description = "",
	version = "1.0.1",
	url = "https://github.com/AshesBeneath/Dasogl"
};

public OnPluginStart()
{
	HookEvent("survivor_rescued", AdamKurtuldu);
	HookEvent("player_incapacitated", AdamIncap);
	HookEvent("door_close", SafeKapiKapali);
	HookEvent("lunge_pounce", HunterKapti);
	HookEvent("player_entered_checkpoint", SafeUlasti);
	HookEvent("door_open",SafeKapiAcik);
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
}

public OnRoundStart()
{
	RoundBitti = false;
	SafeKapisiKapandi = false;
}

public SafeUlasti(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundBitti = true;
}
// İncap yiyen nooblar için
public AdamIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidPlayer(client) && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsValidPlayer(i))
			{
				if (IsFakeClient(i) && GetClientTeam(i) == 2)
				{
					switch (GetRandomInt(1, 7))
					{
						case 1:
						{
							Format(botchat,sizeof(botchat),"yine düştü noob %N",client);
						}
						case 2:
						{
							Format(botchat,sizeof(botchat),"lol u noob");
						}
						case 3:
						{
							Format(botchat,sizeof(botchat),"zayıf halka düşmeye devam ediyor");
						}
						case 4:
						{
							Format(botchat,sizeof(botchat),"kickleyin şunu da yükünüz hafiflesin");
						}
						case 5:
						{
							Format(botchat,sizeof(botchat),"%N namı diğer noob",client);
						}
						case 6:
						{
							Format(botchat,sizeof(botchat),"%N kardesm oyunda yeni misin?",client);
						}
						case 7:
						{
							Format(botchat,sizeof(botchat),"%N geber ahahahaha",client);
						}
					}
					CPrintToChatAll("{blue}%N{default} :  %s", i, botchat);
				}
			}
		}
	}
}

public SafeKapiAcik(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:safedoor = GetEventBool(event, "checkpoint");
	if (safedoor)
	{
		if (!SafeKapisiKapandi) SafeKapisiKapandi = false;
	}
}

// Roundu sağ bitirirlerse
public SafeKapiKapali(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:safedoor = GetEventBool(event, "checkpoint");
	if (safedoor && RoundBitti && !SafeKapisiKapandi)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsClientConnected(i) || !IsValidPlayer(i)) return;
			if (IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				switch (GetRandomInt(1, 6))
				{
					case 1:
					{
						Format(botchat,sizeof(botchat),"ahahdas düs düs");
					}
					case 2:
					{
						Format(botchat,sizeof(botchat),"noob enfekteler");
					}
					case 3:
					{
						Format(botchat,sizeof(botchat),"ukolaydı");
					}
					case 4:
					{
						Format(botchat,sizeof(botchat),"izi pizi biçızz");
					}
					case 5:
					{
						Format(botchat,sizeof(botchat),"niye bu kadar kolaydı?");
					}
					case 6:
					{
						Format(botchat,sizeof(botchat),"karşısı baya güçsüz kaldı galiba");
					}
				}
				CPrintToChatAll("{blue}%N{default} :  %s", i, botchat);
			}
		}
		SafeKapisiKapandi = true;
	}
}

// Boomer pop yaparlarsa
public OnBoomerPop( attacker, victim, shoveCount, Float:timeAlive )
{
	if (IsValidPlayer(attacker) && IsValidPlayer(victim) && !IsFakeClient(victim))
	{
		if (IsFakeClient(attacker))
		{
			switch (GetRandomInt(1, 4))
			{
				case 1:
				{
					Format(botchat,sizeof(botchat),"zaaa");
				}
				case 2:
				{
					Format(botchat,sizeof(botchat),"noob %N",victim);
				}
				case 3:
				{
					Format(botchat, sizeof(botchat), "%N, ben varken kusamazsın qoçumm ;]]", victim);
				}
				case 4:
				{
					Format(botchat,sizeof(botchat),"noob boomer");
				}
			}
			CPrintToChatAll("{blue}%N{default} :  %s", attacker, botchat);
		}
	}
}

// Kusarsa
public OnBoomerVomitLanded( boomer, amount )
{
	if (IsValidPlayer(boomer) && IsClientInGame(boomer))
	{
		if (IsFakeClient(boomer))
		{
			if (amount > 0)
				CPrintToChatAll("{red}Boomer{default} :  ahaha bottan da kusmuk yiyen de ne diyim");
		}
	}
}

// Kaya yerse
public OnTankRockEaten( attacker, victim )
{
	if (IsValidPlayer(attacker) && IsValidPlayer(victim) && !IsFakeClient(victim))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsClientConnected(i) || !IsValidPlayer(i)) return;
			if (IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				switch (GetRandomInt(1, 5))
				{
					case 1:
					{
						Format(botchat,sizeof(botchat),"saklansana noob kaya yiyon ikide bir");
					}
					case 2:
					{
						Format(botchat,sizeof(botchat),"bu mal yüzünden saklanmamız boşuna");
					}
					case 3:
					{
						Format(botchat,sizeof(botchat),"%N hide yapsana lo",victim);
					}
					case 4:
					{
						Format(botchat,sizeof(botchat),"mal");
					}
					case 5:
					{
						Format(botchat,sizeof(botchat),"yeme kaya yeter artık");
					}
				}
				CPrintToChatAll("{blue}%N{default} :  %s", i, botchat);
			}
		}
	}
}

// Hunter yerse
public HunterKapti(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsValidPlayer(hunter) && IsValidPlayer(victim) && !IsFakeClient(victim))
	{
		if (IsFakeClient(hunter))
		{
			CPrintToChatAll("{red}Hunter{default} :  bot huntera bile skeet atamayan da ne diyim");
		}
	}	
}

// Kurtulursa
public AdamKurtuldu(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsValidPlayer(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				switch (GetRandomInt(1, 6))
				{
					case 1:
					{
						Format(botchat,sizeof(botchat),"geberrr");
					}
					case 2:
					{
						Format(botchat,sizeof(botchat),"zaaa ehehehe");
					}
					case 3:
					{
						Format(botchat, sizeof(botchat), "askajfaskjfkj");
					}
					case 4:
					{
						Format(botchat,sizeof(botchat),"das");
					}
					case 5:
					{
						Format(botchat,sizeof(botchat),"hala yaşıyorum leeen");
					}
					case 6:
					{
						Format(botchat,sizeof(botchat),"lol");
					}
				}
				CPrintToChatAll("{blue}%N{default} :  %s", i, botchat);
			}
		}
	}
}

// Adam bot mu?
static bool:IsValidPlayer(client)
{
	if (0 < client <= MaxClients)
		return true;
	return false;
}