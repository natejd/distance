#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Distance", 
	author = "natejd4", 
	description = "Checks distance & height from one point to another.", 
	version = "1.0", 
	url = ""
};

ConVar g_hMsg;
char g_cMsg[256];
EngineVersion g_eEngine;

bool g_bDistanceEnabled[MAXPLAYERS + 1];
bool g_bFirstPos[MAXPLAYERS + 1];
float g_fFirstBulletImpactPos[MAXPLAYERS + 1][3];
float g_fLastBulletImpactPos[MAXPLAYERS + 1][3];

public void OnPluginStart()
{
	HookEvent("bullet_impact", Event_BulletImpact);
	
	RegConsoleCmd("sm_distance", SM_Distance, "");
	
	g_eEngine = GetEngineVersion();
	if (g_eEngine == Engine_CSS)
	{
		g_hMsg = CreateConVar("distance_msg", "{lightgreen}Distance {white}|", "Msg for plugin printing.");
	}
	else if (g_eEngine == Engine_CSGO)
	{
		g_hMsg = CreateConVar("distance_msg", "{lightgreen}Distance {white}|", "Msg for plugin printing.");
	}
	else
		SetFailState("[Distance] Plugin Not yet supported.");
	
	GetConVarString(g_hMsg, g_cMsg, sizeof(g_cMsg));
	HookConVarChange(g_hMsg, OnFormatsChanged);
}

public void OnFormatsChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_hMsg)
	{
		GetConVarString(g_hMsg, g_cMsg, sizeof(g_cMsg));
	}
}

public Action SM_Distance(int client, int args)
{
	if (!IsPlayerAlive(client))
	{
		PrintToClient(client, "%s You have to be alive to use this command", g_cMsg);
		return;
	}

	g_bDistanceEnabled[client] = true;
	PrintToClient(client, "%s Select points using your gun.", g_cMsg);
}

public Action Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!g_bDistanceEnabled[client])
		return;
	
	if (!g_bFirstPos[client])
	{
		g_fFirstBulletImpactPos[client][0] = GetEventFloat(event, "x");
		g_fFirstBulletImpactPos[client][1] = GetEventFloat(event, "y");
		g_fFirstBulletImpactPos[client][2] = GetEventFloat(event, "z");
		
		g_bFirstPos[client] = true;
	}
	else if(g_bFirstPos[client])
	{
		g_fLastBulletImpactPos[client][0] = GetEventFloat(event, "x");
		g_fLastBulletImpactPos[client][1] = GetEventFloat(event, "y");
		g_fLastBulletImpactPos[client][2] = GetEventFloat(event, "z");
	
		float distance = SquareRoot(Pow((g_fFirstBulletImpactPos[client][0] - g_fLastBulletImpactPos[client][0]), 2.0) + Pow((g_fFirstBulletImpactPos[client][1] - g_fLastBulletImpactPos[client][1]), 2.0));
		float height = g_fLastBulletImpactPos[client][2] - g_fFirstBulletImpactPos[client][2];
		
		PrintToClient(client, "%s Horizontal: {lightblue}%.2f {white}| Vertical: {lightblue}%.2f", g_cMsg, distance, height);
		
		g_bFirstPos[client] = false;
		g_bDistanceEnabled[client] = false;
	}
}

stock void PrintToClient(int client, char[] msg, any...)
{
	char buffer[255];
	VFormat(buffer, sizeof(buffer), msg, 3);
	
	if (g_eEngine == Engine_CSS)
	{
		MC_PrintToChat(client, buffer);
	}
	else
		C_PrintToChat(client, buffer);
} 