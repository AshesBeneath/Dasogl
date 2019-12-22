/*
Restore Ragdolls
Copyright (C) 2012-2014  Buster "Mr. Zero" Nielsen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Includes */
#include <sourcemod>
#include <sdkhooks>
#include <l4d_stocks>

/* Plugin Information */
public Plugin:myinfo = 
{
	name		= "Restore Ragdolls",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Restores ragdolls of Survivors, upon death, instead of static death model",
	version		= "1.3.0",
	url		= "mrzerodk@gmail.com"
}

/* Globals */
#define MAXEDICTS 2048
#define MAXENTITIES 4096

#define CVAR_VERSION_NAME "l4d2_restoreragdoll_version"
#define CVAR_VERSION_DESC "Restore Ragdolls SourceMod Plugin Version"
#define CVAR_VERSION_VALUE "1.3.0"

#define CVAR_SURVIVOR_MAX_INCAP_COUNT "survivor_max_incapacitated_count"
new Handle:g_Cvar_MaxIncaps

/* Plugin Functions */
public OnPluginStart()
{
	new Handle:cvar = CreateConVar(CVAR_VERSION_NAME, CVAR_VERSION_VALUE, CVAR_VERSION_DESC, FCVAR_PLUGIN)
	SetConVarString(cvar, CVAR_VERSION_VALUE)
	
	g_Cvar_MaxIncaps = FindConVar(CVAR_SURVIVOR_MAX_INCAP_COUNT)
	if (g_Cvar_MaxIncaps == INVALID_HANDLE)
	{
		SetFailState("Unable to find \"%s\" cvar", CVAR_SURVIVOR_MAX_INCAP_COUNT)
	}
	
	HookEvent("player_hurt", PlayerHurt_Event)
}

public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor || !IsPlayerAlive(client))
	{
		return
	}
	
	new health = GetEventInt(event, "health")
	
	if (health > 0)
	{
		return
	}
	
	// Check for Witch attack
	new witch = GetEventInt(event, "attackerentid")
	new String:classname[16]
	new bool:isWitchAttack = false
	if (witch > 0 && witch < MAXENTITIES && IsValidEntity(witch))
	{
		GetEdictClassname(witch, classname, sizeof(classname))
		isWitchAttack = StrEqual(classname, "witch") || StrEqual(classname, "witch_bride")
	}
	
	if (!isWitchAttack && !L4D_IsPlayerIncapacitated(client) && L4D_GetPlayerReviveCount(client) < GetConVarInt(g_Cvar_MaxIncaps))
	{
		return
	}
	
	SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1)
	
	new weapon = GetPlayerWeaponSlot(client, _:L4DWeaponSlot_Secondary)
	if (weapon > 0 && weapon < MAXENTITIES && IsValidEntity(weapon))
	{
		SDKHooks_DropWeapon(client, weapon) // Drop their secondary weapon since they cannot be defibed
	}
}