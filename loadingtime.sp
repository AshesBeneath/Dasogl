#include <sourcemod>
#include <geoip>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

float ilk_sure[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Loading Time",
    author = "AshesBeneath",
    description = "Prints loading time when fully loaded",
    version = "1.2",
    url = "https://github.com/AshesBeneath/Dasogl"
};

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
	{
		ilk_sure[client] = GetEngineTime();
	}

	return true;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		float son_sure = GetEngineTime() - ilk_sure[client];
		char ip[64], konum[64], isim[64];
		GetClientName(client, isim, sizeof(isim));
		GetClientIP(client, ip, sizeof(ip));
		GeoipCountry(ip, konum, sizeof(konum));
		CPrintToChatAll("{olive}%s {default}sunucuya bağlandı ({green}%.2f {default}sn | Konum: {lightgreen}%s {default})", isim, son_sure, konum);
	}
}

public void OnClientDisconnect(int client)
{
	ilk_sure[client] = 0.0;
}