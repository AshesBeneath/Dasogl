#include <sourcemod>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

float g_flTimeConnected[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Loading Time",
    author = "AshesBeneath",
    description = "Prints loading time when fully loaded",
    version = "1.0",
    url = "https://github.com/AshesBeneath/Dasogl"
};

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
	{
		g_flTimeConnected[client] = GetEngineTime();
	}

	return true;
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		float flFinalTime = GetEngineTime() - g_flTimeConnected[client];
		CPrintToChatAll("{olive}%N {default}sunucuya {green}%.2f {default}saniyede bağlandı.", client, flFinalTime);
	}
}

public void OnClientDisconnect(int client)
{
	g_flTimeConnected[client] = 0.0;
}