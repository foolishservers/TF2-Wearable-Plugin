#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf2idb>
#include <localization_server>

#define FUCCA "\x0700ccff[뿌까] "
#define GCLASS TF2_GetPlayerClass(client)

// ------------------------------------ 게임 데이터 핸들 ------------------------------------ //
Handle g_hWearableEquip;

// ------------------------------------ 룩 컨픽 / 설정 ------------------------------------ //
ArrayList LookList;
ArrayList PaintList;

enum struct Look
{
	int index;
	char item_name[128];
	char item_name_ko[128];
}

enum struct Paint
{
	char name[64];
	char index[32];
}

StringMap LookMap;
int MaxItem_Look;

int GiveLook[MAXPLAYERS+1][3][10];
int RemoveLook[MAXPLAYERS+1][3];

// ------------------------------------ misc 슬롯 체크 ------------------------------------ //
int SlotCheck[MAXPLAYERS+1];

// ------------------------------------ 페인트 컨픽 / 설정 ------------------------------------ //
char PaintLook[MAXPLAYERS+1][3][10][100];

int MaxItem_Paint;

// ------------------------------------ 페인트 컨픽 / 설정 ------------------------------------ //
float StyleLook[MAXPLAYERS+1][3];

// ------------------------------------ 랜덤 설정 ------------------------------------ //
bool RandomCheck[MAXPLAYERS+1];
Handle h_hat, h_misc, h_misc2, h_paint;

// ------------------------------------ 설정 옵션 ------------------------------------ //
bool SettingPaint[MAXPLAYERS+1];
bool SettingReset[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Wearable Plugin",
	author = "뿌까",
	description = "hahahahahahahahahahaha",
	version = "3.0",
	url = "https://steamcommunity.com/id/ssssssaaaazzzzzxxc/"
};

public void OnPluginStart()
{
	GameData gamedata = new GameData("tf2.look"); // need to replace file name
	if(gamedata == null)
		SetFailState("Could not find gamedata/tf2.look.txt!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();
	
	if (!g_hWearableEquip) SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	
	delete gamedata;
	
	LookList = new ArrayList(sizeof(Look));
	LookMap = new StringMap();
	PaintList = new ArrayList(sizeof(Paint));
	
	RegConsoleCmd("sm_look", LookMenu);
	RegConsoleCmd("sm_paint", PaintMenu);
	RegConsoleCmd("sm_style", StyleMenu);
	RegConsoleCmd("sm_randomlook", RandomLook);
	RegConsoleCmd("sm_lookreset", ResetCommand);
	RegConsoleCmd("sm_lall", ResetCommand2);
	RegConsoleCmd("sm_looksetting", SettingCommand);
	
	HookEvent("post_inventory_application", inven);
	HookEvent("player_spawn", PlayerSpawn);
}

public void OnClientPutInServer(int client)
{
	for(int i = 0; i <= 2; i++)
	{
		for(int j = 0; j <= 9; j++)
		{
			GiveLook[client][i][j] = 0;
		}
	}
	
	for(int i = 0; i <= 2; i++)
	{
		for(int j = 0; j <= 9; j++)
		{
			PaintLook[client][i][j] = "";
		}
	}
	
	for(int i = 0; i <= 2; i++)
	{
		StyleLook[client][i] = 0.0;
	}
	
	RemoveLook[client][0] = 0;
	RemoveLook[client][1] = 0;
	RemoveLook[client][2] = 0;
	
	SlotCheck[client] = 0;
	
	RandomCheck[client] = false;
	SettingPaint[client] = false;
	SettingReset[client] = false;
}

public void OnMapEnd()
{
	LookList.Clear();
	LookMap.Clear();
	PaintList.Clear();
	
	if(h_hat != INVALID_HANDLE) CloseHandle(h_hat);
	if(h_misc != INVALID_HANDLE) CloseHandle(h_misc);
	if(h_misc2 != INVALID_HANDLE) CloseHandle(h_misc2);
	if(h_paint != INVALID_HANDLE) CloseHandle(h_paint);
}

public void OnConfigsExecuted()
{
	KeyValues kvItems;
	char sPath[192], sKey[128];
	int count = 0;
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/wearables/item.cfg");
	
	kvItems = CreateKeyValues("items");
	FileToKeyValues(kvItems, sPath);

	if(KvGotoFirstSubKey(kvItems))
	{
		do
		{
			char sidx[12], sItemName[128], sRealItemName[128], sRealItemNameKo[128];
			int idx;
			
			kvItems.GetSectionName(sidx, sizeof(sidx));
			idx = StringToInt(sidx);
			
			kvItems.GetString("name", sItemName, sizeof(sItemName), "");
			LanguageServer_ResolveLocalizedString(GetLanguageByCode("en"), sItemName, sRealItemName, 128);
			LanguageServer_ResolveLocalizedString(GetLanguageByCode("ko"), sItemName, sRealItemNameKo, 128);
			
			Look look;			
			look.index = idx;
			look.item_name = sRealItemName;
			look.item_name_ko = sRealItemNameKo;
			
			LookList.PushArray(look, sizeof(look));
			
			//PrintToServer("%s", look.item_name_ko);
			
			Format(sKey, 128, "%d_item_name", idx);
			LookMap.SetString(sKey, sRealItemName);
			
			count++;
		}
		while(KvGotoNextKey(kvItems));
	}
	
	CloseHandle(kvItems);
	
	MaxItem_Look = count;
	LogMessage("Look Max Item : %d", MaxItem_Look);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/wearables/paint.cfg");
	
	kvItems = CreateKeyValues("paint");
	FileToKeyValues(kvItems, sPath);

	count = 0;

	if(KvGotoFirstSubKey(kvItems))
	{
		do
		{
			char sName[64], sIdx[32];
			
			kvItems.GetSectionName(sName, sizeof(sName));
			
			kvItems.GetString("index", sIdx, sizeof(sIdx), "");
			
			Paint paint;
			paint.name = sName;
			paint.index = sIdx;
			
			PaintList.PushArray(paint, sizeof(paint));
			
			//PrintToServer("%s | %s", paint.name, paint.index);
			
			count++;
		}
		while(KvGotoNextKey(kvItems));
	}
	CloseHandle(kvItems);
	
	MaxItem_Paint = count;
	LogMessage("Paint Max Item : %d", MaxItem_Paint);
	
	h_hat = CreateArray(10);
	h_misc = CreateArray(10);
	h_misc2 = CreateArray(10);
	
	for(int itemIndex = 0 ; itemIndex < MaxItem_Look; itemIndex++)
	{		
		Look look;
		LookList.GetArray(itemIndex, look, sizeof(look));
		
		if(strlen(look.item_name) < 0) continue;
		
		char sItemIndex[12];
		
		IntToString(itemIndex, sItemIndex, 12);
		
		if(TF2IDB_GetItemSlot(itemIndex) == TF2ItemSlot_Hat) PushArrayString(h_hat, sItemIndex);
		if(TF2IDB_GetItemSlot(itemIndex) == TF2ItemSlot_Misc) PushArrayString(h_misc, sItemIndex);
	}
	
	char sItemEquipRegion[10];
	Handle hItemEquipRegion;
	
	for(int i = 0; i < GetArraySize(h_misc); i++)
	{
		char index[10];
		
		if(h_misc != INVALID_HANDLE)
		{
			GetArrayString(h_misc, i, index, sizeof(index));
		}
		
		hItemEquipRegion = TF2IDB_GetItemEquipRegions(StringToInt(index));
		
		for(int j = 0; j < GetArraySize(hItemEquipRegion); j++)
		{
			GetArrayString(hItemEquipRegion, j, sItemEquipRegion, sizeof(sItemEquipRegion));
			if(!StrEqual(sItemEquipRegion, "medal")) PushArrayString(h_misc2, index);
		}
	}
	
	CloseHandle(hItemEquipRegion);
	
	h_paint = CreateArray(20);

	for(int paintNum = 0; paintNum < MaxItem_Paint; paintNum++)
	{
		Paint paint;
		PaintList.GetArray(paintNum, paint, sizeof(paint));
	
		if(strlen(paint.index) < 0) continue;
		
		PushArrayString(h_paint, paint.index);
	}
}

public Action SettingCommand(int client, int args)
{
	Menu menu = CreateMenu(Setting_Select);
	
	char pp[64], rr[64];
	Format(pp, sizeof(pp), "랜덤룩에 페인트도 추가 [%s]", SettingPaint[client] ? "X" : "O");
	Format(rr, sizeof(rr), "초기화시 모든 클래스도 초기화 [%s]", SettingReset[client] ? "X" : "O");
	
	AddMenuItem(menu, "1", pp);
	AddMenuItem(menu, "1", rr);
	
	DisplayMenu(menu, client, 60);
		
	return Plugin_Handled;
}

public Setting_Select(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			if(!SettingPaint[client])
			{
				SettingPaint[client] = true;
				PrintToChat(client, "%s\x07FFFFFF랜덤 페인트가 적용되었습니다.", FUCCA);
			}
			else
			{
				SettingPaint[client] = false;
				PrintToChat(client, "%s\x07FFFFFF랜덤 페인트를 해제합니다.", FUCCA);
			}
		}
		else if(select == 1)
		{
			if(!SettingReset[client])
			{
				SettingReset[client] = true;
				PrintToChat(client, "%s\x07FFFFFF초기화시 모든 클래스를 초기화합니다.", FUCCA);
			}
			else
			{
				SettingReset[client] = false;
				PrintToChat(client, "%s\x07FFFFFF초기화시 모든 클래스를 초기화하지 않습니다.", FUCCA);
			}
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action ResetCommand(int client, int args)
{
	if(!SettingReset[client])
	{
		for(int i = 0; i <= 2; i++)
		{
			GiveLook[client][i][GCLASS] = 0;
			PaintLook[client][i][GCLASS] = "";
		}
	}
	else
	{
		for(int i = 0; i <= 2; i++)
		{
			for(int j = 0; j <= 9; j++)
			{
				GiveLook[client][i][j] = 0;
				PaintLook[client][i][j] = "";
			}
		}
	}
	
	RandomCheck[client] = false;
	teleport(client);
	PrintToChat(client, "%s\x07FFFFFF초기화되었습니다.", FUCCA);
		
	return Plugin_Handled;
}

public Action ResetCommand2(int client, int args)
{
	for (int c = 1; c <= MaxClients; c++)
	{
		if(IsValidClient(c))
		{
			for(int i = 0; i <= 2; i++)
			{
				for(int j = 0; j <= 9; j++)
				{
					GiveLook[c][i][j] = 0;
					PaintLook[c][i][j] = "";
				}
			}
			RandomCheck[c] = false;
			teleport(c);
		}
	}
		
	return Plugin_Handled;
}

public Action RandomLook(int client, int args)
{
	if(!RandomCheck[client])
	{
		RandomCheck[client] = true;
		PrintToChat(client, "%s\x07FFFFFF리스폰시 랜덤룩이 적용됩니다.", FUCCA);
	}
	else
	{
		RandomCheck[client] = false;
		PrintToChat(client, "%s\x07FFFFFF리스폰시 랜덤룩이 해제됩니다.", FUCCA);
	}
	return Plugin_Handled;
}

public Action LookMenu(int client, int args)
{
	char SearchWord[32], SearchValue, sIndex[12], sItemName[128];
	
	int LanguageNum = GetClientLanguage(client);
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	Menu menu = CreateMenu(Slot_Select);

	SetMenuTitle(menu, "옷 고르삼\n \n!룩 <검색> | !look <search>", client);
	AddMenuItem(menu, "0", "삭제");
	
	for(int i = 0 ; i < MaxItem_Look ; i++)
	{
		Look look;
		LookList.GetArray(i, look, sizeof(look));
	
		IntToString(look.index, sIndex, 12);
		
		sItemName = (strlen(look.item_name_ko) > 0 && LanguageNum == 15) ? look.item_name_ko : look.item_name;
		
		if(StrContains(sItemName, SearchWord, false) > -1)
		{
			AddMenuItem(menu, sIndex, sItemName);
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "%s\x03이름이 잘못되었거나 없는 이름입니다.",FUCCA);
	
	DisplayMenu(menu, client, 60);
	
	return Plugin_Handled;
}

public Slot_Select(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[10];
		GetMenuItem(menu, select, info, sizeof(info));
		ItemSlot(client, info);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public void ItemSlot(int client, char[] index)
{
	Menu info = CreateMenu(Look_Select);
	SetMenuTitle(info, "로드아웃 차례대로 슬롯 고르삼");
	
	AddMenuItem(info, index, "모자 슬롯"); 
	AddMenuItem(info, index, "장식 슬롯"); 
	AddMenuItem(info, index, "장식 슬롯 2"); 
 
	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
} 

public Look_Select(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, select, info, sizeof(info));
		if(select == 0) GiveLook[client][0][GCLASS] = StringToInt(info);
		else if(select == 1) GiveLook[client][1][GCLASS] = StringToInt(info);
		else if(select == 2) GiveLook[client][2][GCLASS] = StringToInt(info);
		
		teleport(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action PaintMenu(int client, int args)
{
	char SearchWord[16], SearchValue;
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	Menu menu = CreateMenu(PaintSlot_Select);

	SetMenuTitle(menu, "페인트 고르삼\n \n!페인트 <검색> | !paint <search>", client);
	AddMenuItem(menu, "", "삭제");
	
	for(int i = 0 ; i < MaxItem_Paint; i++)
	{
		Paint paint;
		PaintList.GetArray(i, paint, sizeof(paint));
		
		//PrintToServer("%s | %s", paint.name, paint.index);
		
		if(StrContains(paint.name, SearchWord, false) > -1)
		{
			AddMenuItem(menu, paint.index, paint.name);
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "%s\x03이름이 잘못되었거나 없는 이름입니다.", FUCCA);
	
	DisplayMenu(menu, client, 60);
	
	return Plugin_Handled;
}

public PaintSlot_Select(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, select, info, sizeof(info));
		PaintSlot(client, info);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public void PaintSlot(int client, char[] index)
{
	Menu info = CreateMenu(Paint_Select);
	SetMenuTitle(info, "로드아웃 차례대로 슬롯 고르삼");
	
	AddMenuItem(info, index, "모자 슬롯"); 
	AddMenuItem(info, index, "장식 슬롯"); 
	AddMenuItem(info, index, "장식 슬롯 2"); 
 
	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
} 

public Paint_Select(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, select, info, sizeof(info));

		if(select == 0) Format(PaintLook[client][0][GCLASS], 100, "%s", info);
		else if(select == 1) Format(PaintLook[client][1][GCLASS], 100, "%s", info);
		else if(select == 2) Format(PaintLook[client][2][GCLASS], 100, "%s", info);
		
		teleport(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public Action StyleMenu(int client, int args)
{
	if(args != 2)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_style <item slot> <style index>");
		Fucca_ReplyToCommand(client, "Usage: sm_style <1 ~ 3> <0 ~ 4>");
		return Plugin_Handled;
	}
	
	char arg[2], arg2[2];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int slot = StringToInt(arg);
	float style = StringToFloat(arg2);
	
	if(slot < 1 || slot > 3)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_style <1 ~ 3> <0 ~ 4>");
		return Plugin_Handled;
	}
	
	if(style < 0.0 || style > 4.0)
	{
		Fucca_ReplyToCommand(client, "Usage: sm_style <1 ~ 3> <0 ~ 4>");
		return Plugin_Handled;
	}
	
	StyleLook[client][slot-1] = style;
	teleport(client);
	
	PrintToChat(client, "%s\x04스타일은 적용이 안될 수 있습니다.", FUCCA);
	
	return Plugin_Handled;
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(RandomCheck[client]) // 7777
	{
		char r_hat[12], r_misc[12], r_misc2[12];
		char r_paint[20], r_paint2[20], r_paint3[20];
		
		for(int i = 0; i < GetArraySize(h_hat); i++) GetArrayString(h_hat, GetRandomInt(0, i), r_hat, sizeof(r_hat));
		for(int i = 0; i < GetArraySize(h_misc); i++) GetArrayString(h_misc, GetRandomInt(0, i), r_misc, sizeof(r_misc));
		for(int i = 0; i < GetArraySize(h_misc2); i++) GetArrayString(h_misc2, GetRandomInt(0, i), r_misc2, sizeof(r_misc2));
		
		GiveLook[client][0][GCLASS] = StringToInt(r_hat);
		GiveLook[client][1][GCLASS] = StringToInt(r_misc);
		GiveLook[client][2][GCLASS] = StringToInt(r_misc2);
		
		if(SettingPaint[client])
		{
			for(int i = 0; i < GetArraySize(h_paint); i++)
			{
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint, sizeof(r_paint));
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint2, sizeof(r_paint2));
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint3, sizeof(r_paint3));
				
				Format(PaintLook[client][0][GCLASS], 100, "%s", r_paint);
				Format(PaintLook[client][1][GCLASS], 100, "%s", r_paint2);
				Format(PaintLook[client][2][GCLASS], 100, "%s", r_paint3);
			}
		}
		
		SetHudTextParams(-1.0, 0.1, 3.0, 0, 204, 255, 255, 2, 1.0, 0.05, 0.5);
		ShowHudText(client, 0, "%s", RandomLookName(r_hat));

		SetHudTextParams(-1.0, 0.15, 3.0, 249, 255, 61, 255, 2, 1.0, 0.05, 0.5);
		ShowHudText(client, 1, "%s", RandomLookName(r_misc));
		
		SetHudTextParams(-1.0, 0.2, 3.0, 255, 234, 255, 0, 2, 1.0, 0.05, 0.5);
		ShowHudText(client, 2, "%s", RandomLookName(r_misc2));

		RandomCheck[client] = false;
		teleport(client);
		RandomCheck[client] = true;
	}
}

// ------------------------------------ 리젠 되었을때 ------------------------------------ //

public Action inven(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SlotCheck[client] = 0;
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][0]) == TF2ItemSlot_Hat)
	{
		if(GiveLook[client][0][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][0][GCLASS], PaintLook[client][0][GCLASS], StyleLook[client][0]);
			RemoveHat(client, RemoveLook[client][0]);
		}
	}
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][1]) == TF2ItemSlot_Misc)
	{
		if(GiveLook[client][1][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][1][GCLASS], PaintLook[client][1][GCLASS], StyleLook[client][1]);
			RemoveHat(client, RemoveLook[client][1]);
		}
	}
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][2]) == TF2ItemSlot_Misc)
	{
		if(GiveLook[client][2][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][2][GCLASS], PaintLook[client][2][GCLASS], StyleLook[client][2]);
			RemoveHat(client, RemoveLook[client][2]);
		}
	}
}

public Action TF2Items_OnGiveNamedItem(int client, char[] szClassName, int index, Handle &hItem)
{
	if(TF2IDB_GetItemSlot(index) == TF2ItemSlot_Hat) RemoveLook[client][0] = index;
	if(TF2IDB_GetItemSlot(index) == TF2ItemSlot_Misc)
	{
		SlotCheck[client] ++;
		if(SlotCheck[client] == 1) RemoveLook[client][1] = index;
		if(SlotCheck[client] == 2) RemoveLook[client][2] = index;
	}
	return Plugin_Continue;   
}

stock bool CreateHat(int client, int itemindex, char[] att, float att2)
{
	int hat;
	
	if(itemindex == 1067) hat = CreateEntityByName("tf_wearable_levelable_item");
	else hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat)) return false;
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), 69);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	DispatchSpawn(hat);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);
	SDKCall(g_hWearableEquip, client, hat);
	
	if(!StrEqual(att, "")) SetPaint(hat, att);
	if(att2 != 0.0) Style(hat, att2);
	
	return true;
}

stock void RemoveHat(int client, int index)
{
	int hat = -1;
	if(index == 1067) 
	{
		while((hat=FindEntityByClassname(hat, "tf_wearable_levelable_item"))!=INVALID_ENT_REFERENCE)
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)
				if(GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == index) AcceptEntityInput(hat, "Kill");
	}
	else
	{
		while((hat=FindEntityByClassname(hat, "tf_wearable"))!=INVALID_ENT_REFERENCE)
			if(GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)
				if(GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex") == index) AcceptEntityInput(hat, "Kill");
	}
}

stock void AttAtt(int entity, char[] att)
{
	char atts[32][32]; 
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	
	if (count > 1) for (int i = 0;  i < count;  i+= 2) TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
}

void SetPaint(int entity, char[] att)
{
	TF2Attrib_RemoveByDefIndex(entity, 1004);
	TF2Attrib_RemoveByDefIndex(entity, 142);
	TF2Attrib_RemoveByDefIndex(entity, 261);
	
	float paint = StringToFloat(att);
	
	if(paint <= 5.0 && paint >= 0.0) TF2Attrib_SetByDefIndex(entity, 1004, paint);
	else
	{
		char aa[3][32]; 
		ExplodeString(att, " ", aa, 3, 32);
		
		if(StrEqual(aa[0], "m"))
		{
			TF2Attrib_SetByDefIndex(entity, 142, StringToFloat(aa[1]));
			TF2Attrib_SetByDefIndex(entity, 261, StringToFloat(aa[2]));
		}
		else TF2Attrib_SetByDefIndex(entity, 142, paint);
	}
}

stock void Style(int entity, float att)
{
	TF2Attrib_RemoveByDefIndex(entity, 542);
	TF2Attrib_SetByDefIndex(entity, 542, att);
}

char[] RandomLookName(char[] lookIndex)
{
	char sItemName[128], sTemp[64];
		
	Format(sTemp, 64, "%s_item_name", lookIndex);
	LookMap.GetString(sTemp, sItemName, sizeof(sItemName));

	return sItemName;
}

stock void teleport(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	TF2_RespawnPlayer(client);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

stock void Fucca_ReplyToCommand(client, String:say[])
{ 
	ReplyToCommand(client, "%s\x07FFFFFF%s", FUCCA, say);
}

public bool AliveCheck(int client)
{
	if(client > 0 && client <= MaxClients)
		if(IsClientConnected(client) == true)
			if(IsClientInGame(client) == true)
				if(IsPlayerAlive(client) == true) return true;
				else return false;
			else return false;
		else return false;
	else return false;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}