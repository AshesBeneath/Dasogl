#include <sourcemod>
#include <sdktools_sound>
#include <colors>

#define MAX_STR_LEN 30
#define MIN_MIX_START_COUNT 5

#define COND_HAS_ALREADY_VOTED 0
#define COND_NEED_MORE_VOTES 1
#define COND_START_MIX 2
#define COND_START_MIX_ADMIN 3

#define STATE_FIRST_CAPT 0
#define STATE_SECOND_CAPT 1
#define STATE_NO_MIX 2
#define STATE_PICK_TEAMS 3

enum L4D2Team                                                                   
{                                                                               
    L4D2Team_None = 0,                                                          
    L4D2Team_Spectator,                                                         
    L4D2Team_Survivor,                                                          
    L4D2Team_Infected                                                           
}

new currentState = STATE_NO_MIX;
new Menu:mixMenu;
new StringMap:hVoteResultsTrie;
new StringMap:hSwapWhitelist;
new mixCallsCount = 0;
char currentMaxVotedCaptAuthId[MAX_STR_LEN];
char survCaptainAuthId[MAX_STR_LEN];
char infCaptainAuthId[MAX_STR_LEN];
new maxVoteCount = 0;
new pickCount = 0;
new survivorsPick = 0;
new bool:isMixAllowed = false;
new bool:isPickingCaptain = false;
new Handle:mixStartedForward;
new Handle:mixStoppedForward;
new Handle:captainVoteTimer;

public Plugin myinfo =
{
    name = "L4D2 Mix Manager [TR]",
    author = "Luckylock, AshesBeneath",
    description = "Provides ability to pick captains and teams through menus",
    version = "3.6",
    url = "https://github.com/AshesBeneath/Dasogl"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_mix", Cmd_MixStart, "Mix command");
    RegAdminCmd("sm_stopmix", Cmd_MixStop, ADMFLAG_ROOT, "Mix command");
    AddCommandListener(Cmd_OnPlayerJoinTeam, "jointeam");
    hVoteResultsTrie = CreateTrie();
    hSwapWhitelist = CreateTrie();
    mixStartedForward = CreateGlobalForward("OnMixStarted", ET_Event);
    mixStoppedForward = CreateGlobalForward("OnMixStopped", ET_Event);
    PrecacheSound("buttons/blip1.wav");
}

public void OnMapStart()
{
    isMixAllowed = true;
    StopMix();
}

public void OnRoundIsLive() {
    isMixAllowed = false;
    StopMix();
}

//TODO: Find better method to handle with least errors.
public void StartMix()
{
    FakeClientCommandAll("sm_hide");
    Call_StartForward(mixStartedForward);
    Call_Finish();
    EmitSoundToAll("buttons/blip1.wav");
    for (new c = 1; c <= MaxClients; c++)
    {
    	if (IsClientInGame(c) && GetClientTeam(c) == 1)
	{
		KickClient(c, "Mix yapiliyor. Slotlar acilince geri girersin.");
	}
    }
    SetCvar("sv_maxplayers", 8);
}

public void StopMix()
{
    currentState = STATE_NO_MIX;
    FakeClientCommandAll("sm_show");
    Call_StartForward(mixStoppedForward);
    Call_Finish();

    if (isPickingCaptain && captainVoteTimer != INVALID_HANDLE) {
        KillTimer(captainVoteTimer);
    }
    SetCvar("sv_maxplayers", 30);
}

public void FakeClientCommandAll(char[] command)
{
    for (new client = 1; client <= MaxClients; ++client) {
        if (IsClientInGame(client) && !IsFakeClient(client)) {
            FakeClientCommand(client, command);
        }  
    }
}

public Action Cmd_OnPlayerJoinTeam(int client, const char[] command, int argc)
{
    char authId[MAX_STR_LEN];
    char cmdArgBuffer[MAX_STR_LEN];
    L4D2Team allowedTeam;
    L4D2Team newTeam;

    if (argc >= 1) {

        GetCmdArg(1, cmdArgBuffer, MAX_STR_LEN);
        newTeam = L4D2Team:StringToInt(cmdArgBuffer);

        if (currentState != STATE_NO_MIX && newTeam != L4D2Team_Spectator && IsHuman(client)) {

            GetClientAuthId(client, AuthId_SteamID64, authId, MAX_STR_LEN); 

            if (!hSwapWhitelist.GetValue(authId, allowedTeam) || allowedTeam != newTeam) {
                CPrintToChat(client, "{blue}[{default}Mix{blue}] {default}Takım kaptanı tarafından seçilmeden takımlara geçemezsiniz.");
                return Plugin_Stop;
            }
        }
        
    }

    return Plugin_Continue; 
}

public void OnClientPutInServer(int client)
{
    char authId[MAX_STR_LEN];

    if (currentState != STATE_NO_MIX && IsHuman(client))
    {
        GetClientAuthId(client, AuthId_SteamID64, authId, MAX_STR_LEN);
        ChangeClientTeamEx(client, L4D2Team_Spectator);
    }
}

public Action Cmd_MixStop(int client, int args) {
    if (currentState != STATE_NO_MIX) {
        StopMix();
        CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Yetkili ({olive}%N{default}) mix'i durdurdu.", client);
    } else {
        CPrintToChat(client, "{blue}[{default}Mix{blue}] {default}Şu an yürülükte bir mix yok.");
    }
}

public Action Cmd_MixStart(int client, int args)
{
    if (currentState != STATE_NO_MIX) {
        CPrintToChat(client, "{blue}[{default}Mix{blue}] {default}Zaten bir mix başlatılmış.");
        return Plugin_Handled;
    } else if (!isMixAllowed) {
        CPrintToChat(client, "{blue}[{default}Mix{blue}] {default}Mixler sadece Ready-Up sürecinde yapılabilir.");
        return Plugin_Handled;
    } else if (GetClientTeamEx(client) == 1 && GetUserAdmin(client) == INVALID_ADMIN_ID) {
	CPrintToChat(client, "{blue}[{default}Mix{blue}] {default}Izleyiciler mix için oy veremez.");
	return Plugin_Handled;
	}

    new mixConditions;
    mixConditions = GetMixConditionsAfterVote(client);

    if (mixConditions == COND_START_MIX || mixConditions == COND_START_MIX_ADMIN) {
        if (mixConditions == COND_START_MIX_ADMIN) {
            CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Yetkili ({olive}%N{default}) tarafından mix başlatıldı.", client);
        } else {
            CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Mix için gereken son oyu {green}%N {default}verdi.", client);
            CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Oylama birliği ile mix başlatıldı.");
        }

        currentState = STATE_FIRST_CAPT;
        StartMix();
        SwapAllPlayersToSpec();

        // Initialise values
        mixCallsCount = 0;
        hVoteResultsTrie.Clear();
        hSwapWhitelist.Clear();
        maxVoteCount = 0;
        strcopy(currentMaxVotedCaptAuthId, MAX_STR_LEN, " ");
        pickCount = 0;

        if (Menu_Initialise()) {
            Menu_AddAllSpectators();
            Menu_DisplayToAllSpecs();
        }

        captainVoteTimer = CreateTimer(11.0, Menu_StateHandler, _, TIMER_REPEAT); 
        isPickingCaptain = true;

    } else if (mixConditions == COND_NEED_MORE_VOTES) {
        CPrintToChatAll("{blue}[{default}Mix{blue}] {green}%N {default}oyladı (Oylar: {olive}%d{default}/{default}%d | Oylamak için {green}!mix {default})", client, mixCallsCount, MIN_MIX_START_COUNT);

    } else if (mixConditions == COND_HAS_ALREADY_VOTED) {
        CPrintToChat(client, "{blue}[{default}Mix{blue}] {default}Sen zaten oyladın, 2 kere oy veremiyon xD");

    }

    return Plugin_Handled;
}

public int GetMixConditionsAfterVote(int client)
{
    new bool:dummy = false;
    new bool:hasVoted = false;
    char clientAuthId[MAX_STR_LEN];
    GetClientAuthId(client, AuthId_SteamID64, clientAuthId, MAX_STR_LEN);
    hasVoted = GetTrieValue(hVoteResultsTrie, clientAuthId, dummy)

    if (GetAdminFlag(GetUserAdmin(client), Admin_Root)) {
        return COND_START_MIX_ADMIN;

    } else if (hasVoted){
        return COND_HAS_ALREADY_VOTED;

    } else if (++mixCallsCount >= MIN_MIX_START_COUNT) {
        return COND_START_MIX; 

    } else {
        SetTrieValue(hVoteResultsTrie, clientAuthId, true);
        return COND_NEED_MORE_VOTES;

    }
}

public bool Menu_Initialise()
{
    if (currentState == STATE_NO_MIX) return false;

    mixMenu = new Menu(Menu_MixHandler, MENU_ACTIONS_ALL);
    mixMenu.ExitButton = false;

    switch(currentState) {
        case STATE_FIRST_CAPT: {
            mixMenu.SetTitle("Ilk Takım Kaptani Kim Olsun?");
            return true;
        }

        case STATE_SECOND_CAPT: {
            mixMenu.SetTitle("Diger Takim Kaptani Kim Olsun? ");
            return true;
        }

        case STATE_PICK_TEAMS: {
            mixMenu.SetTitle("Takimin Icin Oyuncu Sec");
            return true;
        }
    }

    CloseHandle(mixMenu);
    return false;
}

public void Menu_AddAllSpectators()
{
    char clientName[MAX_STR_LEN];
    char clientId[MAX_STR_LEN];

    mixMenu.RemoveAllItems();

    for (new client = 1; client <= MaxClients; ++client) {
        if (IsClientSpec(client)) {
            GetClientAuthId(client, AuthId_SteamID64, clientId, MAX_STR_LEN);
            GetClientName(client, clientName, MAX_STR_LEN);
            mixMenu.AddItem(clientId, clientName);
        }  
    }
}

public void Menu_AddTestSubjects()
{
    mixMenu.AddItem("test", "test");
}

public void Menu_DisplayToAllSpecs()
{
    for (new client = 1; client <= MaxClients; ++client) {
        if (IsClientSpec(client)) {
            mixMenu.Display(client, 10);
        }
    }
}

public int Menu_MixHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select) {
        if (currentState == STATE_FIRST_CAPT || currentState == STATE_SECOND_CAPT) {
            char authId[MAX_STR_LEN];
            menu.GetItem(param2, authId, MAX_STR_LEN);

            new voteCount = 0;

            if (!GetTrieValue(hVoteResultsTrie, authId, voteCount)) {
                voteCount = 0;
            }

            SetTrieValue(hVoteResultsTrie, authId, ++voteCount, true);

            if (voteCount > maxVoteCount) {
                strcopy(currentMaxVotedCaptAuthId, MAX_STR_LEN, authId);
                maxVoteCount = voteCount;
            }

        } else if (currentState == STATE_PICK_TEAMS) {
            char authId[MAX_STR_LEN]; 
            menu.GetItem(param2, authId, MAX_STR_LEN);
            new L4D2Team:team = GetClientTeamEx(param1);

            if (team == L4D2Team_Spectator || (team == L4D2Team_Infected && survivorsPick == 1) || (team == L4D2Team_Survivor && survivorsPick == 0)) {
                CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Takım kaptanı ({olive}%N{default}) yanlış takımda bulundu. {green}Mix iptal edildi", param1);
                StopMix();

            } else {
               
                if (SwapPlayerToTeam(authId, team, 0)) {
                    pickCount++;
                    if (pickCount == 4) {
                        // Do not switch picks 

                    } else if (pickCount > 5) {
                        CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Herkes takımlardan memnunsa r verin başlayalım :)");
                        StopMix();
                    } else {
                        survivorsPick = survivorsPick == 1 ? 0 : 1;
                    } 
                } else {
                    CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Takıma seçilen oyuncu bulunamadı. {green}Mix iptal edildi", param1);
                    StopMix();
                }
            }
        }
    }

    return 0;
}

public Action Menu_StateHandler(Handle timer, Handle hndl)
{
    switch(currentState) {
        case STATE_FIRST_CAPT: {
            new numVotes = 0;
            GetTrieValue(hVoteResultsTrie, currentMaxVotedCaptAuthId, numVotes);
            ClearTrie(hVoteResultsTrie);
           
            if (SwapPlayerToTeam(currentMaxVotedCaptAuthId, L4D2Team_Survivor, numVotes)) {
                strcopy(survCaptainAuthId, MAX_STR_LEN, currentMaxVotedCaptAuthId);
                currentState = STATE_SECOND_CAPT;
                maxVoteCount = 0;

                if (Menu_Initialise()) {
                    Menu_AddAllSpectators();
                    Menu_DisplayToAllSpecs();
                }
            } else {
                CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Ilk takım kaptanı seçilemedi. {green}Mix iptal edildi");
                StopMix();
            }

            strcopy(currentMaxVotedCaptAuthId, MAX_STR_LEN, " ");
        }

        case STATE_SECOND_CAPT: {
            new numVotes = 0;
            GetTrieValue(hVoteResultsTrie, currentMaxVotedCaptAuthId, numVotes);
            ClearTrie(hVoteResultsTrie);

            if (SwapPlayerToTeam(currentMaxVotedCaptAuthId, L4D2Team_Infected, numVotes)) {
                strcopy(infCaptainAuthId, MAX_STR_LEN, currentMaxVotedCaptAuthId);
                currentState = STATE_PICK_TEAMS;
                CreateTimer(0.5, Menu_StateHandler); 

            } else {
                CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Ikinci takım kaptanı seçilemedi. {green}Mix iptal edildi");
                StopMix();
            }

            strcopy(currentMaxVotedCaptAuthId, MAX_STR_LEN, " ");
        }

        case STATE_PICK_TEAMS: {
            isPickingCaptain = false;
            survivorsPick = GetURandomInt() & 1;            
            CreateTimer(1.0, Menu_TeamPickHandler, _, TIMER_REPEAT);
        }
    }

    if (currentState == STATE_NO_MIX || currentState == STATE_PICK_TEAMS) {
        return Plugin_Stop; 
    } else {
        return Plugin_Handled;
    }
}

public Action Menu_TeamPickHandler(Handle timer)
{
    if (currentState == STATE_PICK_TEAMS) {

        if (Menu_Initialise()) {
            Menu_AddAllSpectators();
            new captain;

            if (survivorsPick == 1) {
               captain = GetClientFromAuthId(survCaptainAuthId); 
            } else {
               captain = GetClientFromAuthId(infCaptainAuthId); 
            }

            if (captain > 0) {
                if (GetSpectatorsCount() > 0) {
                    mixMenu.Display(captain, 1); 
                } else {
                    CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Seçilecek oyuncu bulunamadı. {green}Mix iptal edildi");
                    StopMix();
                    return Plugin_Stop;
                }
            } else {
                CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Takım kaptanı bulunamadı. {green}Mix iptal edildi");
                StopMix();
                return Plugin_Stop;
            }

            return Plugin_Continue;
        }
    }
    return Plugin_Stop;
}

public void SwapAllPlayersToSpec()
{
    for (new client = 1; client <= MaxClients; ++client) {
        if (IsClientInGame(client) && !IsFakeClient(client)) {
            ChangeClientTeamEx(client, L4D2Team_Spectator);
        }
    }
}

public bool SwapPlayerToTeam(const char[] authId, L4D2Team:team, numVotes)
{
    new client = GetClientFromAuthId(authId);
    new bool:foundClient = client > 0;

    if (foundClient) {
        hSwapWhitelist.SetValue(authId, team);
        ChangeClientTeamEx(client, team);

        switch(currentState) {
            case STATE_FIRST_CAPT: {
                CPrintToChatAll("{blue}[{default}Mix{blue}] {green}%d {default}oy ile ilk takım kaptanı {olive}%N {default}seçildi.", numVotes, client);
            }
            
            case STATE_SECOND_CAPT: {
                CPrintToChatAll("{blue}[{default}Mix{blue}] {green}%d {default}oy ile ikinci takım kaptanı {olive}%N {default}seçildi.", numVotes, client);
            }

            case STATE_PICK_TEAMS: {
                if (survivorsPick == 1) {
                    CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Oyuncu {olive}%N {default}sağ kalanlar tarafına seçildi.", client)
                } else {
                    CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Oyuncu {olive}%N {default}enfekteler tarafına seçildi.", client)
                }
            }
        }
    }

    return foundClient;
}

public void OnClientDisconnect(client)
{
    if (currentState != STATE_NO_MIX && IsPlayerCaptain(client))
    {
        CPrintToChatAll("{blue}[{default}Mix{blue}] {default}Takım kaptanı ({olive}%N{default}) oyundan ayrıldı. {green}Mix iptal edildi", client);
        StopMix();
    }
}

public bool IsPlayerCaptain(client)
{
    return GetClientFromAuthId(survCaptainAuthId) == client || GetClientFromAuthId(infCaptainAuthId) == client;
}

public int GetClientFromAuthId(const char[] authId)
{
    char clientAuthId[MAX_STR_LEN];
    new client = 0;
    new i = 0;
    
    while (client == 0 && i < MaxClients) {
        ++i;

        if (IsClientInGame(i) && !IsFakeClient(i)) {
            GetClientAuthId(i, AuthId_SteamID64, clientAuthId, MAX_STR_LEN); 

            if (StrEqual(authId, clientAuthId)) {
                client = i;
            }
        }
    }

    return client;
}

public bool IsClientSpec(int client) {
    return IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 1;
}

public int GetSpectatorsCount()
{
    new count = 0;

    for (new client = 1; client <= MaxClients; ++client) {
        if (IsClientSpec(client)) {
            ++count;
        }
    }

    return count;
}

stock bool:ChangeClientTeamEx(client, L4D2Team:team)
{
    if (GetClientTeamEx(client) == team) {
        return true;
    }

    if (team != L4D2Team_Survivor) {
        ChangeClientTeam(client, _:team);
        return true;
    } else {
        new bot = FindSurvivorBot();

        if (bot > 0) {
            new flags = GetCommandFlags("sb_takecontrol");
            SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
            FakeClientCommand(client, "sb_takecontrol");
            SetCommandFlags("sb_takecontrol", flags);
            return true;
        }
    }
    return false;
}

stock L4D2Team:GetClientTeamEx(client)
{
    return L4D2Team:GetClientTeam(client);
}

stock FindSurvivorBot()
{
    for (new client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeamEx(client) == L4D2Team_Survivor)
        {
            return client;
        }
    }
    return -1;
}

public bool IsHuman(client)
{
    return IsClientInGame(client) && !IsFakeClient(client);
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