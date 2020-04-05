#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Yeter artık intihar ediyom len???",
	author = "AshesBeneath",
	description = "Zonemod pratiği için !kill komudu",
	version = "1.0",
	url = "https://github.com/AshesBeneath/Dasogl"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_kill", KurtarBeniBuCehaletten);
}

public Action:KurtarBeniBuCehaletten(client, args)
{
	ForcePlayerSuicide(client);
}