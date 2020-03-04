#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

#define ROCKET "models/props_debris/concrete_chunk01a.mdl"

public Plugin myinfo = 
{
	name = "L4D2 Tank Rock Glow",
	author = "Joshe Gatito, AshesBeneath",
	description = "Generates glow for rock once spawned, not visible for survivors",
	version = "1.1",
	url = "https://github.com/AshesBeneath/Dasogl"
};

public void OnEntityCreated (int entity, const char[] classname)
{	
	if (strcmp(classname, "tank_rock") == 0)
		SDKHook(entity, SDKHook_Spawn, SpawnThink);
}

public void SpawnThink(int entity)
{
	RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

public void OnNextFrame(int entity)
{
	int GlowRock = -1;
	float Pos[3], Ang[3];

	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Pos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", Ang);
	
	if (IsL4D())
	{
		GlowRock = CreateEntityByName("prop_glowing_object"); 
		if( GlowRock == -1)
		{
		    LogError("Failed to create 'prop_glowing_object'");
		    return;
		}
		
		DispatchKeyValue(GlowRock, "model", ROCKET);
		SetEntityRenderFx(GlowRock, RENDERFX_FADE_FAST);
		SetVariantString("!activator");
		AcceptEntityInput(GlowRock, "SetParent", entity);
		DispatchSpawn(GlowRock);
		AcceptEntityInput(GlowRock, "StartGlowing");
			
		TeleportEntity(GlowRock, Pos, Ang, NULL_VECTOR);
	}
	else 
	{
		GlowRock = CreateEntityByName("prop_dynamic_override"); 
		if( GlowRock == -1)
		{
		    LogError("Failed to create 'prop_dynamic_override'");
		    return;
		}
		
		SDKHook(GlowRock, SDKHook_SetTransmit, OnSetTransmit);
		
		DispatchKeyValue(GlowRock, "model", ROCKET);
		SetVariantString("!activator");
		AcceptEntityInput(GlowRock, "SetParent", entity);
		DispatchSpawn(GlowRock);
		AcceptEntityInput(GlowRock, "StartGlowing");
		SetEntProp(GlowRock, Prop_Send, "m_iGlowType", 3);
		SetEntProp(GlowRock, Prop_Send, "m_nGlowRange", 5000);
		int R = 255, G = 255, B = 255; //Force white glow
		SetEntProp(GlowRock, Prop_Send, "m_glowColorOverride", R + (G * 256) + (B * 65536));

		TeleportEntity(GlowRock, Pos, Ang, NULL_VECTOR);
	}
}

bool IsL4D()
{
	EngineVersion engine = GetEngineVersion();
	return ( engine == Engine_Left4Dead );
}

public Action OnSetTransmit(int entity, int client)
{
    if (GetClientTeam(client) == 2)
        return Plugin_Handled;

    return Plugin_Continue;
} 