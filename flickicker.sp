#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.2"

new Handle:gcvar_fkDuration = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Flickicker",
	author = "Lange",
	description = "Silently kicks (or bans) the player under your crosshair. Don't miss!",
	version = PLUGIN_VERSION,
	url = "http://alexvan.camp/"
};

public OnPluginStart() {
  CreateConVar("sm_flickicker_version", PLUGIN_VERSION, "Flickicker plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  gcvar_fkDuration = CreateConVar("sm_flickick_duration", "3", "Duration (in minutes) of the temp ban for sm_flickick (0 = kick only)", FCVAR_PLUGIN);
  
  RegAdminCmd("sm_flickick", Flickick, ADMFLAG_KICK, "Kick (and optionally temp ban) the player under your crosshair.");
  RegAdminCmd("sm_flickban", Flickban, ADMFLAG_BAN, "Permaban the player under your crosshair.");
}

public Action:Flickick(caller, args) {
  if(!IsValidClient(caller)) {
		return Plugin_Handled;
  }
    
  new target = GetPlayerUnderXhair(caller);
  
  if (!IsValidClient(target)) {
    return Plugin_Handled;
  }
  
  new duration = GetConVarInt(gcvar_fkDuration);
  
  if (duration == 0) {
    KickClient(target);
  } else {
    decl String:msg[64];
    Format(msg, sizeof(msg), "You have been banned for %d minutes", duration); 
    BanClient(target, duration, BANFLAG_AUTHID, "Flickick", msg, "Flickick");
  }
  
  
  
  return Plugin_Handled;
}

public Action:Flickban(caller, args) {
  if (!IsValidClient(caller)) {
		return Plugin_Handled;
  }
    
  new target = GetPlayerUnderXhair(caller);
  
  if (!IsValidClient(target)) {
    return Plugin_Handled;
  }
  
  BanClient(target, GetConVarInt(gcvar_fkDuration), BANFLAG_AUTHID, "Flickban", "You have been permanently banned", "Flickban");
  
  return Plugin_Handled;
}

public GetPlayerUnderXhair(client) {
  if (!IsValidClient(client)) {
    return -1;
  }
  
  new Float:vecAngles[3], Float:vecOrigin[3];
  
  GetClientEyePosition(client, vecOrigin);
  GetClientEyeAngles(client, vecAngles);
  
  new Handle:hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, TraceEntityOtherPlayersOnly, client);
  
  if(TR_DidHit(hTrace)) {
    new target = TR_GetEntityIndex(hTrace);
    CloseHandle(hTrace);
    
    return target;
	}
  
  CloseHandle(hTrace);
  
  return -1;
}

public bool:TraceEntityOtherPlayersOnly(entity, contentsMask, any:caller) {
  // Stop hitting yourself!
  if (entity == caller) {
    return false;
  }
  
  return IsValidClient(entity);
}

public bool:IsValidClient(iClient) {
  if(iClient < 1 || iClient > MaxClients)
    return false;  
  if(!IsClientConnected(iClient))
		return false;
  if(IsClientInKickQueue(iClient))
    return false;  
  if(IsClientSourceTV(iClient))
    return false;
  
  return IsClientInGame(iClient);
}