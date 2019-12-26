#pragma semicolon 1

#include <sourcemod>
#include <colors>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>

public Plugin:myinfo =
{
	name = "Pause [TR]",
	author = "CanadaRox, Sir, AshesBeenath",
	description = "Adds pause functionality without breaking pauses, also prevents SI from spawning because of the Pause.",
	version = "6.1",
	url = "https://github.com/AshesBeenath/Dasogl"
};

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

new String:teamString[L4D2Team][] =
{
	"None",
	"Spectator",
	"Sağ Kalanlar",
	"Enfekteler"
};

new Handle:menuPanel;
new Handle:readyCountdownTimer;
new Handle:sv_pausable;
new Handle:sv_noclipduringpause;
new bool:adminPause;
new bool:isPaused;
new bool:teamReady[L4D2Team];
new readyDelay;
new Handle:pauseDelayCvar;
new pauseDelay;
new bool:readyUpIsAvailable;
new Handle:pauseForward;
new Handle:unpauseForward;
new Handle:deferredPauseTimer;
new Handle:SpecTimer[66];
new IgnorePlayer[66];
new bool:RoundEnd;

min(a, b)
{
	return (a < b) ? a : b;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsInPause", Native_IsInPause);
	pauseForward = CreateGlobalForward("OnPause", ET_Event);
	unpauseForward = CreateGlobalForward("OnUnpause", ET_Event);
	RegPluginLibrary("pause");

	MarkNativeAsOptional("IsInReady");
	return APLRes_Success;
}

public OnPluginStart()
{
	RegConsoleCmd("sm_spectate", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_spec", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_s", Spectate_Cmd, "Moves you to the spectator team");
	RegConsoleCmd("sm_pause", Pause_Cmd, "Pauses the game");
	RegConsoleCmd("sm_unpause", Unpause_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_ready", Unpause_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_unready", Unready_Cmd, "Marks your team as ready for an unpause");
	RegConsoleCmd("sm_toggleready", Toggleready_Cmd, "Marks your team as ready for an unpause");
	
	RegAdminCmd("sm_forcepause", ForcePause_Cmd, ADMFLAG_BAN, "Pauses the game and only allows admins to unpause");
	RegAdminCmd("sm_forceunpause", ForceUnpause_Cmd, ADMFLAG_BAN, "Unpauses the game regardless of team ready status.  Must be used to unpause admin pauses");

	AddCommandListener(Say_Callback, "say");
	AddCommandListener(TeamSay_Callback, "say_team");
	AddCommandListener(Unpause_Callback, "unpause");
	AddCommandListener(Callvote_Callback, "callvote");
	
	sv_pausable = FindConVar("sv_pausable");
	sv_noclipduringpause = FindConVar("sv_noclipduringpause");

	pauseDelayCvar = CreateConVar("sm_pausedelay", "0", "Delay to apply before a pause happens.  Could be used to prevent Tactical Pauses", FCVAR_PLUGIN, true, 0.0);

	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStart_Event);
}

public OnAllPluginsLoaded()
{
	readyUpIsAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "readyup")) readyUpIsAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "readyup")) readyUpIsAvailable = true;
}

public Native_IsInPause(Handle:plugin, numParams)
{
	return _:isPaused;
}

public OnClientPutInServer(client)
{
	if (isPaused)
	{
		if (!IsFakeClient(client))
			CPrintToChatAll("{lightgreen}★ {olive}%N {default}sunucuya tamamen bağlandı.", client);
	}
}

public OnMapStart()
{
	PrecacheSound("buttons/blip2.wav");
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (deferredPauseTimer != INVALID_HANDLE)
	{
		CloseHandle(deferredPauseTimer);
		deferredPauseTimer = INVALID_HANDLE;
	}
	RoundEnd = true;
}

public RoundStart_Event(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			IgnorePlayer[client] = 0;
		}
	}
	RoundEnd = false;
}		
public Action:Spectate_Cmd(client, args)
{
	if (IgnorePlayer[client] <= 10)
	{
		IgnorePlayer[client] = IgnorePlayer[client] + 2;
	}
	if (!SpecTimer[client])
	{
		SpecTimer[client] = CreateTimer(1.0, SecureSpec, client, 1);
	}
	return Plugin_Continue;
}
public Action:SecureSpec(Handle:timer, any:client)		
{		
	IgnorePlayer[client]--;
	if (IgnorePlayer[client])
	{
		return Plugin_Continue;
	}		
	SpecTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Pause_Cmd(client, args)
{
	if ((!readyUpIsAvailable || !IsInReady()) && pauseDelay == 0 && !isPaused && IsPlayer(client) && !RoundEnd)
	{
		CPrintToChatAll("{lightgreen}★ {teamcolor}%N {default}oyunu duraklattı!!!", client);
		pauseDelay = GetConVarInt(pauseDelayCvar);
		if (pauseDelay == 0)
			AttemptPause();
		else
			CreateTimer(1.0, PauseDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:PauseDelay_Timer(Handle:timer)
{
	if (pauseDelay == 0)
	{
		CPrintToChatAll("{lightgreen}★ {default}Oyun duraklatıldı!!!");
		AttemptPause();
		return Plugin_Stop;
	}
	else
	{
		CPrintToChatAll("{lightgreen}★ {olive}%d {default}saniye sonra oyun duraklatılacak!!!", pauseDelay);
		pauseDelay--;
	}
	return Plugin_Continue;
}

public Action:Unpause_Cmd(client, args)
{
	if (isPaused && IsPlayer(client))
	{
		new L4D2Team:clientTeam = L4D2Team:GetClientTeam(client);
		if (!teamReady[clientTeam])
		{
			if (GetClientTeam(client) == 2)
			{
				CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR {default}olarak işaretledi.", client, teamString[GetClientTeam(client)]);
			}
			else
			{
				CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR {default}olarak işaretledi.", client, teamString[GetClientTeam(client)]);
			}
		}
		teamReady[clientTeam] = true;
		if (CheckFullReady())
		{
			InitiateLiveCountdown();
		}
	}
	return Plugin_Handled;
}

public Action:Unready_Cmd(client, args)
{
	if (isPaused && IsPlayer(client) && !adminPause)
	{
		new L4D2Team:clientTeam = L4D2Team:GetClientTeam(client);
		if (teamReady[clientTeam])
		{
			if (GetClientTeam(client) == 2)
			{
				CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR DEĞİL {default}olarak işaretledi.", client, teamString[GetClientTeam(client)]);
			}
			else
			{
				CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR DEĞİL {default}olarak işaretledi", client, teamString[GetClientTeam(client)]);
			}
		}
		teamReady[clientTeam] = false;
		CancelFullReady(client);
	}
	return Plugin_Handled;
}

public Action:Toggleready_Cmd(client, args)
{
	if (isPaused && IsPlayer(client) && !adminPause)
	{
		new L4D2Team:clientTeam = L4D2Team:GetClientTeam(client);
		if (teamReady[clientTeam])
		{
			if (GetClientTeam(client) == 2)
			{
				CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR DEĞİL {default}olarak işaretledi.", client, teamString[GetClientTeam(client)]);
			}
			else
			{
				CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR DEĞİL {default}olarak işaretledi", client, teamString[GetClientTeam(client)]);
			}
			teamReady[clientTeam] = false;
			CancelFullReady(client);
		}
		else
		{
			if (!teamReady[clientTeam])
			{
				if (GetClientTeam(client) == 2)
				{
					CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR {default}olarak işaretledi.", client, teamString[GetClientTeam(client)]);
				}
				else
				{
					CPrintToChatAll("{lightgreen}★ {green}%N {default}, {olive}%s {default}tarafını {olive}HAZIR {default}olarak işaretledi.", client, teamString[GetClientTeam(client)]);
				}
				teamReady[clientTeam] = true;
				if (CheckFullReady())
				{
					InitiateLiveCountdown();
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:ForcePause_Cmd(client, args)
{
	if (!isPaused)
	{
		adminPause = true;
		Pause();
	}
}

public Action:ForceUnpause_Cmd(client, args)
{
	if (isPaused)
	{
		InitiateLiveCountdown();
	}
}

AttemptPause()
{
	if (deferredPauseTimer == INVALID_HANDLE)
	{
		if (CanPause())
		{
			Pause();
		}
		else
		{
			CPrintToChatAll("{lightgreen}★ {default}Oyunu duraklatma süreci, spawndan dolayı ertelendi.");
			deferredPauseTimer = CreateTimer(0.1, DeferredPause_Timer, _, TIMER_REPEAT);
		}
	}
}

public Action:DeferredPause_Timer(Handle:timer)
{
	if (CanPause())
	{
		deferredPauseTimer = INVALID_HANDLE;
		Pause();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Pause()
{
	for (new L4D2Team:team; team < L4D2Team; team++)
	{
		teamReady[team] = false;
	}

	isPaused = true;
	readyCountdownTimer = INVALID_HANDLE;

	CreateTimer(1.0, MenuRefresh_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	new bool:pauseProcessed = false;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 3 && IsGhost(client))
			{
				SetEntProp(client, PropType:0, "m_hasVisibleThreats", any:1, 4, 0);
				new buttons = GetClientButtons(client);
				if (buttons & IN_ATTACK)
				{
					buttons &= -IN_JUMP;
					SetClientButtons(client, buttons);
					CPrintToChat(client, "{lightgreen}★ {default}Duraklatma sürecinden dolayı spawnınız engellendi.");
				}
			}
			if(!pauseProcessed)
			{
				SetConVarBool(sv_pausable, true);
				FakeClientCommand(client, "pause");
				SetConVarBool(sv_pausable, false);
				pauseProcessed = true;
			}
			if (L4D2Team:GetClientTeam(client) == L4D2Team_Spectator)
			{
				SendConVarValue(client, sv_noclipduringpause, "1");
			}
		}
	}
	Call_StartForward(pauseForward);
	Call_Finish();
}

Unpause()
{
	isPaused = false;

	new bool:unpauseProcessed = false;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if(!unpauseProcessed)
			{
				SetConVarBool(sv_pausable, true);
				FakeClientCommand(client, "unpause");
				SetConVarBool(sv_pausable, false);
				unpauseProcessed = true;
			}
			if (L4D2Team:GetClientTeam(client) == L4D2Team_Spectator && !IsFakeClient(client))
			{
				SendConVarValue(client, sv_noclipduringpause, "0");
			}
		}
	}
	Call_StartForward(unpauseForward);
	Call_Finish();
}

public Action:MenuRefresh_Timer(Handle:timer)
{
	if (isPaused)
	{
		UpdatePanel();
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

UpdatePanel()
{
	if (menuPanel != INVALID_HANDLE)
	{
		CloseHandle(menuPanel);
		menuPanel = INVALID_HANDLE;
	}

	menuPanel = CreatePanel();

	DrawPanelText(menuPanel, "Takım Durumları:");
	DrawPanelText(menuPanel, teamReady[L4D2Team_Survivor] ? "->☑ Sag Kalanlar" : "->☐ Sag Kalanlar");
	DrawPanelText(menuPanel, teamReady[L4D2Team_Infected] ? "->☑ Enfekteler" : "->☐ Enfekteler");

	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			SendPanelToClient(menuPanel, client, DummyHandler, 1);
		}
	}
}

InitiateLiveCountdown()
{
	if (readyCountdownTimer == INVALID_HANDLE)
	{
		CPrintToChatAll("{lightgreen}★ {default}Iptal etmek için {olive}!unready {default}yazınız.");
		readyDelay = 3;
		readyCountdownTimer = CreateTimer(1.0, ReadyCountdownDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:ReadyCountdownDelay_Timer(Handle:timer)
{
	if (readyDelay == 0)
	{
		PrintHintTextToAll("!!! Oyun Devam Ediyor !!!");
		EmitSoundToAll("buttons/blip2.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		Unpause();
		return Plugin_Stop;
	}
	else
	{
		CPrintToChatAll("{lightgreen}★ {olive}%d {default}saniye içinde oyun devam edecek!!!", readyDelay);
		readyDelay--;
	}
	return Plugin_Continue;
}

CancelFullReady(client)
{
	if (readyCountdownTimer != INVALID_HANDLE)
	{
		CloseHandle(readyCountdownTimer);
		readyCountdownTimer = INVALID_HANDLE;
		CPrintToChatAll("{lightgreen}★ {green}%N {default}geri sayımı iptal etti!", client);
	}
}

public Action:Callvote_Callback(client, String:command[], argc)
{
	if (GetClientTeam(client) == 1)
	{
		CPrintToChat(client, "{lightgreen}★ {default}Iyi deneme, kimi atacaktın xD");
		return Plugin_Handled;
	}
	if (IgnorePlayer[client] > 0)
	{
		CPrintToChat(client, "{lightgreen}★ {default}Az önce takım değiştirdin, oylama başlatabilmen için birkaç saniye bekleyiniz.");
		return Plugin_Handled;
	}
	if (argc < 2)
	{
		return Plugin_Continue;
	}
	decl String:votereason[16];
	GetCmdArg(1, votereason, 16);
	if (!!strcmp(votereason, "kick", false))
	{
		return Action:0;
	}
	decl String:therest[256];
	GetCmdArg(2, therest, 256);
	new userid;
	new spacepos = FindCharInString(therest, 32, false);
	if (spacepos > -1)
	{
		decl String:temp[12];
		strcopy(temp, min(spacepos + 1, 12), therest);
		userid = StringToInt(temp, 10);
	}
	else
	{
		userid = StringToInt(therest, 10);
	}
	new target = GetClientOfUserId(userid);
	if (target < 1)
	{
		return Plugin_Continue;
	}
	new AdminId:clientAdmin = GetUserAdmin(client);
	new AdminId:targetAdmin = GetUserAdmin(target);

	if (clientAdmin == AdminId:-1 && targetAdmin == AdminId:-1)
	{
		return Plugin_Continue;
	}
	if (CanAdminTarget(clientAdmin, targetAdmin))
	{
		return Plugin_Continue;
	}
	CPrintToChat(client, "{lightgreen}★ {default}Bu amdin sana naptı???", target);
	return Plugin_Handled;
}

public Action:Say_Callback(client, const String:command[], argc)
{
	if (isPaused)
	{
		decl String:buffer[256];
		GetCmdArgString(buffer, sizeof(buffer));
		StripQuotes(buffer);
		if (buffer[0] == '!' || buffer[0] == '/')  // Hidden command or chat trigger
		{
			return Plugin_Handled;
		}
		if (client == 0)
		{
			PrintToChatAll("Console : %s", buffer);
		}
		else
		{
			CPrintToChatAllEx(client, "{teamcolor}%N{default} : %s", client, buffer);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:TeamSay_Callback(client, const String:command[], argc)
{
	if (isPaused)
	{
		decl String:buffer[256];
		GetCmdArgString(buffer, sizeof(buffer));
		StripQuotes(buffer);
		if (buffer[0] == '!' || buffer[0] == '/')
		{
			return Plugin_Handled;
		}
		PrintToTeam(client, L4D2Team:GetClientTeam(client), buffer);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Unpause_Callback(client, const String:command[], argc)
{
	if (isPaused)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:CheckFullReady()
{
	return (teamReady[L4D2Team_Survivor] || GetTeamHumanCount(L4D2Team_Survivor) == 0)
		&& (teamReady[L4D2Team_Infected] || GetTeamHumanCount(L4D2Team_Infected) == 0);
}

stock IsPlayer(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}
	new L4D2Team:team = L4D2Team:GetClientTeam(client);
	if (IgnorePlayer[client] > 0)
	{
		return false;
	}
	return (client && (team == L4D2Team_Survivor || team == L4D2Team_Infected));
}

stock PrintToTeam(author, L4D2Team:team, const String:buffer[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && L4D2Team:GetClientTeam(client) == team)
		{
			CPrintToChatEx(client, author, "(%s) {teamcolor}%N{default} :  %s", teamString[L4D2Team:GetClientTeam(author)], author, buffer);
		}
	}
}

public DummyHandler(Handle:menu, MenuAction:action, param1, param2) { }

stock GetTeamHumanCount(L4D2Team:team)
{
	new humans = 0;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && L4D2Team:GetClientTeam(client) == team)
		{
			humans++;
		}
	}
	
	return humans;
}

stock bool:IsPlayerIncap(client) return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");

bool:CanPause()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && L4D2Team:GetClientTeam(client) == L4D2Team_Survivor)
		{
			if (IsPlayerIncap(client))
			{
				if (GetEntProp(client, Prop_Send, "m_reviveOwner") > 0)
				{
					return false;
				}
			}
			else
			{
				if (GetEntProp(client, Prop_Send, "m_reviveTarget") > 0)
				{
					return false;
				}
			}
		}
	}
	return true;
}

bool:IsGhost(client)
{
	return GetEntProp(client, PropType:0, "m_isGhost", 4, 0) == 1;
}
public SetClientButtons(client, button)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		SetEntProp(client, PropType:1, "m_nButtons", button, 4, 0);
	}
}