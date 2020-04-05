#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

#define TEAM_SURVIVOR 2

new String:g_items[][] = { 
	"pistol",
	"pistol_magnum",
	"pumpshotgun",
	"shotgun_chrome",
	"smg",
	"smg_silenced",
};

new g_iMeleeClassCount = 0;

new String:g_sMeleeClass[16][32];

public Plugin:myinfo =
{
	name = "Item Giver & Healer",
	author = "def (user00111), AshesBeneath",
	description = "Nope",
	version = PLUGIN_VERSION,
	url = "N/A"
};

public OnPluginStart() {
	CreateConVar("sm_give_version", PLUGIN_VERSION, "Plugin version?", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_give", Cmd_SM_Give, "sm_give [item_name] [item_name]");
	RegConsoleCmd("sm_heal", Cmd_Heal, "Can ver?");
}	

public OnMapStart()
{
	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	
	GetMeleeClasses();
}

public Action:Cmd_SM_Give(client, argCount)
{	
	if (!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}
	
	if (argCount < 1)
	{
		DisplayGiveMenu(client);
		return Plugin_Handled;
	}

	new bool:found = false;
	new i;
	
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
		
	for (new argnum = 1; argnum <= argCount; argnum++)
	{	
		decl String:arg[64], String:item[64];
		GetCmdArg(argnum, arg, sizeof(arg));
		
		if (found != false) found = false; // reset
		
		if (StrEqual(arg, "bile", false) ||
				StrEqual(arg, "puke", false)) {
			strcopy(item, sizeof(item), "vomitjar");
			found = true;
		}
		
		if (!found)
		{
			for (i = 0; i < g_iMeleeClassCount; i++)
			{
				if (StrContains(g_sMeleeClass[i], arg, false) > -1)
				{
					strcopy(item, sizeof(item), g_sMeleeClass[i]);
					found = true;
					break;
				}
			}
		}
		
		if (!found)
		{
			for (i = 0; i < sizeof(g_items); i++)
			{ 
				if (StrContains(g_items[i], arg, false) != -1) {
					strcopy(item, sizeof(item), g_items[i]);
					found = true;
					break;
				}	 
			}
		}

		if (!found) {
			strcopy(item, sizeof(item), arg);		
		}	 
		FakeClientCommand(client, "give %s", item);
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	return Plugin_Handled;		
}

public Action:Cmd_Heal(client,args)
{
	if (GetClientTeam(client) == 2)
	{
		new flags2 = GetCommandFlags("give");
		SetCommandFlags("give", flags2 & ~FCVAR_CHEAT);
		
		//Give player health
		FakeClientCommand(client, "give health");
		
		SetCommandFlags("give", flags2|FCVAR_CHEAT);
		return Plugin_Handled;
	} else
	{
		PrintToChat(client, "Sadece sağ kalanlar kullanabilir.");
		return Plugin_Handled;
	}
}

DisplayGiveMenu(client, time=MENU_TIME_FOREVER) 
{ 
	new Handle:menu = CreateMenu(GiveMenuHandler); 
	SetMenuTitle(menu, "Ne verim abime?");
	AddMenuItem(menu, "1", "Silah");
	AddMenuItem(menu, "2", "Melee"); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, time);
}

DisplayMeleeMenu(client, time=MENU_TIME_FOREVER)
{ 
	new Handle:menu = CreateMenu(MeleeMenuHandler); 
	SetMenuTitle(menu, "Melee: %d", g_iMeleeClassCount);
	for (new i = 0; i < g_iMeleeClassCount; i++)
	{
		AddMenuItem(menu, "", g_sMeleeClass[i]);
	}		
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, time);
}

DisplayItemsMenu(client, time=MENU_TIME_FOREVER) 
{ 
	new Handle:menu = CreateMenu(ItemsMenuHandler); 
	SetMenuTitle(menu, "Silah Sec:");
	for (new i = 0; i < sizeof(g_items); i++)
	{ 
		AddMenuItem(menu, "", g_items[i]);
	}
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, time); 
}

public ItemsMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) { 
		decl String:weapon[64];
		Format(weapon, sizeof(weapon), "weapon_%s", g_items[itemNum]);
	
		new entity = GivePlayerItem(client, weapon);
		if (entity != -1) {
			EquipPlayerWeapon(client, entity);
		}
		//DisplayMenu(menu, client, 60);
		//Native "CloseHandle" reported: Handle ******** is invalid (error 3)
		DisplayGiveMenu(client, 60);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public MeleeMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if (action == MenuAction_Select) { 
		new melee = CreateEntityByName("weapon_melee");
		DispatchKeyValue(melee, "melee_script_name", g_sMeleeClass[itemNum]);
		DispatchSpawn(melee);
		decl String:modelname[256];
		GetEntPropString(melee, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if (StrContains(modelname, "claw", false) == -1) // hunter claw bug
		{
			new Float:currentPos[3];
			GetClientAbsOrigin(client, currentPos);
			TeleportEntity(melee, currentPos, NULL_VECTOR, NULL_VECTOR);
			EquipPlayerWeapon(client, melee);
		}
		else { // can't spawn melee
			RemoveEdict(melee);
		}
		DisplayGiveMenu(client, 60);
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public GiveMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{ 
	if (action == MenuAction_Select) {
		switch (itemNum)
		{
			 case 0: DisplayItemsMenu(client);
			 case 1: DisplayMeleeMenu(client);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

bool:IsValidSurvivor(client)
{
	if (client && IsClientInGame(client)) {
		if (GetClientTeam(client) == TEAM_SURVIVOR) {
			if (IsPlayerAlive(client)) {
				return true;
			}
		}
	}
	return false;			 
}

stock GetMeleeClasses()
{
	new MeleeStringTable = FindStringTable( "MeleeWeapons" );
	g_iMeleeClassCount = GetStringTableNumStrings( MeleeStringTable );
	
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		ReadStringTable( MeleeStringTable, i, g_sMeleeClass[i], 32 );
	}	
}