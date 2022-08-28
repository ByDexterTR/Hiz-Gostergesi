#include <sourcemod>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "SpeedHud", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

Handle Hud = null;
Cookie Force = null;
bool Enabled[65] = { false, ... };
int frame = 0;

public void OnPluginStart()
{
	Force = new Cookie("Speedhud-Enable", "ByDexter", CookieAccess_Protected);
	Hud = CreateHudSynchronizer();
	RegConsoleCmd("sm_sh", Command_Toggle, "");
	RegConsoleCmd("sm_hud", Command_Toggle, "");
	RegConsoleCmd("sm_speedhud", Command_Toggle, "");
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i))
	{
		OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	char sBuffer[8];
	Force.Get(client, sBuffer, 8);
	if (sBuffer[0] == '\0')
	{
		Enabled[client] = true;
		Force.Set(client, "1");
	}
	else
	{
		if (StringToInt(sBuffer) == 0)
		{
			Enabled[client] = false;
		}
		else
		{
			Enabled[client] = true;
		}
	}
}

public Action Command_Toggle(int client, int args)
{
	char sBuffer[8];
	Force.Get(client, sBuffer, 8);
	if (StringToInt(sBuffer) == 0)
	{
		Enabled[client] = true;
		ReplyToCommand(client, "[SM] Hız göstergesi \x07açıldı.");
		Force.Set(client, "1");
		return Plugin_Handled;
	}
	else
	{
		Enabled[client] = false;
		ReplyToCommand(client, "[SM] Hız göstergesi \x07kapandı.");
		Force.Set(client, "0");
		return Plugin_Handled;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	frame++;
	if (frame >= 5 && IsValidClient(client) && Enabled[client])
	{
		int target = GetSpectedOrSelf(client);
		ShowHud(client, target);
		frame = 0;
	}
}

void ShowHud(int client, int target)
{
	if (!Enabled[client])
	{
		return;
	}
	float speed = GetSpeed(target);
	SetHudTextParams(-1.0, 0.1, 0.5, 255, 255, 255, 255, 0, 1.0, 0.0, 0.0);
	ShowSyncHudText(client, Hud, "%.0f", speed);
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

static float GetSpeed(int client)
{
	float vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	
	float x = Pow(vec[0], 2.0);
	float y = Pow(vec[1], 2.0);
	
	return SquareRoot(x + y);
}

int GetSpectedOrSelf(int client)
{
	int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if (mode != 4 && mode != 5)
	{
		return client;
	}
	
	int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if (target == -1)
	{
		return client;
	}
	
	return target;
} 