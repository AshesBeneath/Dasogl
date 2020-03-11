/* Changelog
*  1.0 - initial release
*  1.1 - changed method with timers
*  1.2 - changed method again with more events (Fucking Valve fires events in versus like: *survivors wiped*, round_end, round_end again, round_start, *other round loads*
*  1.2.1 - Added check for OnMapStart so alltalk enabled prints don't get disappear next maps.
*/

#include <sourcemod>
#include <colors>

new bool:isPrintedOnce = false;

public Plugin myinfo =
{
    name = "Standalone Round End Alltalk",
    author = "AshesBeneath",
    description = "Enables sv_alltalk for 10 game ticks on round end",
    version = "1.2.1",
    url = "https://github.com/AshesBeneath/Dasogl"
};

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	isPrintedOnce = false;
}

//"round_end" eventi versus modunda 2 kere etkinleştirilmektedir. (Valve bugu)
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetCvar("sv_alltalk", 1);
	if (!isPrintedOnce)
	{
		CPrintToChatAll("{olive}Toplu Konuşma {green}Açık");
		isPrintedOnce = true;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetCvar("sv_alltalk", 0);
	CPrintToChatAll("{olive}Toplu Konuşma {green}Kapalı");
}

//credits goes to https://forum.sourceturk.net/d/102-cvar-degisikligi-sohbet-mesajini-gizleme-kodu
SetCvar(char cvarName[64], value)
{
	Handle IntCvar;
	IntCvar = FindConVar(cvarName);
	if (IntCvar)
	{
		int flags = GetConVarFlags(IntCvar);
		flags &= -257;
		SetConVarFlags(IntCvar, flags);
		SetConVarInt(IntCvar, value, false, false);
		flags |= 256;
		SetConVarFlags(IntCvar, flags);
	}
}