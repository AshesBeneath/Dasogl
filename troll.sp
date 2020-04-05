#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Troll",
	author = "AshesBeneath",
	description = "ahahdas",
	version = "1.0",
	url = "https://github.com/AshesBeneath/Dasogl"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_troll", ahahdas);
}

public Action:ahahdas(client, args)
{
	FakeClientCommand(client, "say \"ahahdas düs düs \"");
}