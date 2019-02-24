#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf2idb>
#include <f_limit>

#define GCLASS TF2_GetPlayerClass(client)
#define MAX 4000

#define FUCCA "\x0700ccff[뿌까] \x07FFFFFF"

// ------------------------------------ 게임 데이터 핸들 ------------------------------------ //
new Handle:g_hWearableEquip, Handle:g_hGameConfig;

new Handle:test = INVALID_HANDLE;

// ------------------------------------ 룩 컨픽 / 설정 ------------------------------------ //
new Handle:kv[MAX] = {INVALID_HANDLE, ...};

new Handle:db = INVALID_HANDLE;
new MaxItem_Look;

new Handle:Lmenu;

new GiveLook[MAXPLAYERS+1][3][10];
new RemoveLook[MAXPLAYERS+1][3];

// ------------------------------------ misc 슬롯 체크 ------------------------------------ //
new SlotCheck[MAXPLAYERS+1];

// ------------------------------------ 페인트 컨픽 / 설정 ------------------------------------ //
new String:PaintLook[MAXPLAYERS+1][3][10][100];

new Handle:kv2[100] = {INVALID_HANDLE, ...};
new MaxItem_Paint;

// ------------------------------------ 랜덤 설정 ------------------------------------ //
new bool:RandomCheck[MAXPLAYERS+1];
new Handle:h_hat, Handle:h_misc, Handle:h_medal, Handle:h_nmedal, Handle:h_paint;

// ------------------------------------ 설정 옵션 ------------------------------------ //
new bool:SettingPaint[MAXPLAYERS+1];
new bool:SettingReset[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "룩 플러그인",
	author = "뿌까",
	description = "하하하하",
	version = "4.0",
	url = "x"
};

// ------------------------------------ 플러그인 시작 ------------------------------------ //
public OnPluginStart()
{
	g_hGameConfig = LoadGameConfigFile("give.bots.weapons");
	if (!g_hGameConfig) SetFailState("Failed to find give.bots.weapons.txt gamedata! Can't continue.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();
	
	if (!g_hWearableEquip) SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.");
	
	RegConsoleCmd("sm_look", LookMenu);
	RegConsoleCmd("sm_paint", PaintMenu);
	RegConsoleCmd("sm_randomlook", RandomLook);
	RegConsoleCmd("sm_lookreset", ResetCommand);
	RegAdminCmd("sm_lall", ResetCommand2, ADMFLAG_KICK);
	RegConsoleCmd("sm_looksetting", SettingCommand);
	
	HookEvent("post_inventory_application", inven);
	HookEvent("player_spawn", PlayerSpawn);
	
	test = CreateConVar("sm_look_test", "0", "켜기 끄기 1/0");
	
	decl String:error[256];
	error[0] = '\0';
    
	if(SQL_CheckConfig("look")) db = SQL_Connect("look", true, error, sizeof(error));
	
	if(db==INVALID_HANDLE || error[0])
	{
		LogError("[look] Could not connect to look database: %s", error);
		return;
    }	

	PrintToServer("[look] Connection successful.");
	
	SQL_SetCharset(db, "utf8");
	SQL_TQuery(db, SQLErrorCallback, "create table if not exists look(idx int NULL DEFAULT '0', name varchar(256) NULL DEFAULT '0') ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	if(GetConVarInt(test) == 1) SQL_TQuery(db, SQLQueryItemField, "select * from look;");
}

public SQLQueryItemField(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(GetConVarInt(test) == 1) 
	{
		if(hndl==INVALID_HANDLE) LogError("Query failed: %s", error);
		
		decl String:index[256], String:name[256], String:query[222]
		for(new i = 0 ; i < MaxItem_Look ; i++)
		{
			if(kv[i] != INVALID_HANDLE)
			{
				GetArrayString(kv[i], 0, index, sizeof(index));
				GetArrayString(kv[i], 1, name, sizeof(name));
			}
			
			Format(query, 256, "insert into look (idx, name) VALUES (%d, '%s');", StringToInt(index), name);
			SQL_TQuery(db, SQLErrorCallback, query);
		}
	}
}

public OnMapStart()
{
	PrecacheModel("models/workshop/player/items/Scout/dec15_hot_heels/dec15_hot_heels.mdl", true);
}

// ------------------------------------ 플레이어가 들어왔을때 ------------------------------------ //

public OnClientPutInServer(client)
{
	for(new i = 0; i <= 2; i++) for(new j = 0; j <= 9; j++) GiveLook[client][i][j] = 0;
	for(new i = 0; i <= 2; i++) for(new j = 0; j <= 9; j++) PaintLook[client][i][j] = "";
	
	RemoveLook[client][0] = 0;
	RemoveLook[client][1] = 0;
	RemoveLook[client][2] = 0;
	
	SlotCheck[client] = 0;
	RandomCheck[client] = false;
	SettingPaint[client] = false;
	SettingReset[client] = false;
}

// ------------------------------------ 플러그인 종료 ------------------------------------ //

public OnPluginEnd() OnMapEnd();

public OnMapEnd()
{
	if(GetConVarInt(test) == 1) for(new i = 0 ; i < MAX && i < MaxItem_Look; i++) if(kv[i] != INVALID_HANDLE) CloseHandle(kv[i]);
	for(new i = 0 ; i < 100 && i < MaxItem_Paint; i++) if(kv2[i] != INVALID_HANDLE) CloseHandle(kv2[i]);
	
	if(h_hat != INVALID_HANDLE) CloseHandle(h_hat);
	if(h_misc != INVALID_HANDLE) CloseHandle(h_misc);
	if(h_medal != INVALID_HANDLE) CloseHandle(h_medal);
	if(h_nmedal != INVALID_HANDLE) CloseHandle(h_nmedal);
	if(h_paint != INVALID_HANDLE) CloseHandle(h_paint);
}



public OnConfigsExecuted()
{
	
	decl String:szBuffer[100];
	// ------------------------------------ 룩 컨픽 ------------------------------------ //
	
	if(GetConVarInt(test) == 1) 
	{
		decl String:strPath[192];
		new count = 0;
		
		BuildPath(Path_SM, strPath, sizeof(strPath), "configs/wearables/item.cfg");
		
		new Handle:DB = CreateKeyValues("items");
		FileToKeyValues(DB, strPath);

		if(KvGotoFirstSubKey(DB))
		{
			do
			{
				kv[count] = CreateArray(MAX);
				
				KvGetSectionName(DB, szBuffer, sizeof(szBuffer));
				PushArrayString(kv[count], szBuffer);	
				
				KvGetString(DB, "name", szBuffer, sizeof(szBuffer));
				PushArrayString(kv[count], szBuffer);
				count++;
			}
			while(KvGotoNextKey(DB));
		}
		CloseHandle(DB);
		MaxItem_Look = count;
		LogMessage("Look Max Item : %d", MaxItem_Look);
	}
	// ------------------------------------ 페인트 컨픽 ------------------------------------ //
	
	decl String:strPath2[192];
	new count2 = 0;
	
	BuildPath(Path_SM, strPath2, sizeof(strPath2), "configs/wearables/paint.cfg");
	
	new Handle:DB2 = CreateKeyValues("paint");
	FileToKeyValues(DB2, strPath2);

	if(KvGotoFirstSubKey(DB2))
	{
		do
		{
			kv2[count2] = CreateArray(100);
			
			KvGetSectionName(DB2, szBuffer, sizeof(szBuffer));
			PushArrayString(kv2[count2], szBuffer);	
			
			KvGetString(DB2, "index", szBuffer, sizeof(szBuffer));
			PushArrayString(kv2[count2], szBuffer);
			count2++;
		}
		while(KvGotoNextKey(DB2));
	}
	CloseHandle(DB2);
	MaxItem_Paint = count2;
	LogMessage("Paint Max Item : %d", MaxItem_Paint);
	
	// ------------------------------------ 랜덤 설정 ------------------------------------ //
	
	h_hat = CreateArray(10);
	h_misc = CreateArray(10);
	h_medal = CreateArray(10);
	h_nmedal = CreateArray(10);
	
	SQL_TQuery(db, SqlRandom, "select * from look;", _, DBPrio_High);
	CreateTimer(2.0, timer);
	h_paint = CreateArray(20);

	for(new i = 0 ; i < MaxItem_Paint; i++)
	{
		decl String:index[20];
		if(kv2[i] != INVALID_HANDLE) GetArrayString(kv2[i], 1, index, sizeof(index));
		PushArrayString(h_paint, index);
	}
}

public Action:timer(Handle:timer)
{
	new Handle:aaaa;
	decl String:abc[10];
	for(new i = 0; i < GetArraySize(h_misc); i++) // 7777
	{
		decl String:index[10];
		if(h_misc != INVALID_HANDLE) GetArrayString(h_misc, i, index, sizeof(index));
		aaaa = TF2IDB_GetItemEquipRegions(StringToInt(index));
		for(new j = 0; j < GetArraySize(aaaa); j++)
		{
			GetArrayString(aaaa, j, abc, sizeof(abc));
			if(!StrEqual(abc, "medal")) PushArrayString(h_nmedal, index);
			else PushArrayString(h_medal, index);
		}
	}
	CloseHandle(aaaa);
}
public SqlRandom(Handle:owner, Handle:hndl, const String:error[], any:client) 
{
	if(hndl==INVALID_HANDLE) LogError("Query failed: %s", error);
	else if(SQL_GetRowCount(hndl) > 0)
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				decl String:aa[10];
				SQL_FetchString(hndl, 0, aa, sizeof(aa));
				
				if(TF2IDB_GetItemSlot(StringToInt(aa)) == TF2ItemSlot_Hat) PushArrayString(h_hat, aa);
				if(TF2IDB_GetItemSlot(StringToInt(aa)) == TF2ItemSlot_Misc) PushArrayString(h_misc, aa);
			}
		}
	}
}

public SQLErrorCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(!StrEqual("", error)) LogError("Query failed: %s", error);
    return false;
}

public Action:SettingCommand(client, args)
{
	new Handle:menu = CreateMenu(Setting_Select);
	
	new String:pp[64], String:rr[64];
	Format(pp, sizeof(pp), "랜덤룩에 페인트도 추가 [%s]", SettingPaint[client] ? "X" : "O");
	Format(rr, sizeof(rr), "초기화시 모든 클래스도 초기화 [%s]", SettingReset[client] ? "X" : "O");
	
	AddMenuItem(menu, "1", pp);
	AddMenuItem(menu, "1", rr);
	
	DisplayMenu(menu, client, 60);
		
	return Plugin_Handled;
}

public Setting_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			if(!SettingPaint[client])
			{
				SettingPaint[client] = true;
				PrintToChat(client, "%s랜덤 페인트가 적용되었습니다.", FUCCA);
			}
			else
			{
				SettingPaint[client] = false;
				PrintToChat(client, "%s랜덤 페인트를 해제합니다.", FUCCA);
			}
		}
		else if(select == 1)
		{
			if(!SettingReset[client])
			{
				SettingReset[client] = true;
				PrintToChat(client, "%s초기화시 모든 클래스를 초기화합니다.", FUCCA);
			}
			else
			{
				SettingReset[client] = false;
				PrintToChat(client, "%s초기화시 모든 클래스를 초기화하지 않습니다.", FUCCA);
			}
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

// ------------------------------------ 초기화 명령어 ------------------------------------ //

public Action:ResetCommand(client, args)
{
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s살아있을 때만 사용 가능합니다.", FUCCA);
		return Plugin_Handled;
	}	
		
	if(InLimitZone(client))
	{
		PrintToChat(client, "%s이 곳에서 명령어를 사용할 수 없습니다.", FUCCA);
		return Plugin_Handled;
	}
	
	if(!SettingReset[client])
	{
		for(new i = 0; i <= 2; i++)
		{
			GiveLook[client][i][GCLASS] = 0;
			PaintLook[client][i][GCLASS] = "";
		}
	}
	else
	{
		for(new i = 0; i <= 2; i++)
		{
			for(new j = 0; j <= 9; j++)
			{
				GiveLook[client][i][j] = 0;
				PaintLook[client][i][j] = "";
			}
		}
	}
	
	RandomCheck[client] = false
	teleport(client);
	PrintToChat(client, "%s초기화되었습니다.", FUCCA);
		
	return Plugin_Handled;
}

public Action:ResetCommand2(client, args)
{
	for (new c = 1; c <= MaxClients; c++)
	{
		if(IsValidClient(c))
		{
			for(new i = 0; i <= 2; i++)
			{
				for(new j = 0; j <= 9; j++)
				{
					GiveLook[c][i][j] = 0;
					PaintLook[c][i][j] = "";
				}
			}
			RandomCheck[c] = false
			teleport(c);
		}
	}
		
	return Plugin_Handled;
}

// ------------------------------------ 랜덤 룩 명령어 ------------------------------------ //

public Action:RandomLook(client, args)
{
	if(!RandomCheck[client])
	{
		RandomCheck[client] = true;
		PrintToChat(client, "%s리스폰시 랜덤룩이 적용됩니다.", FUCCA);
	}
	else
	{
		RandomCheck[client] = false;
		PrintToChat(client, "%s리스폰시 랜덤룩이 해제됩니다.", FUCCA);
	}
	return Plugin_Handled;
}

// ------------------------------------ 룩 명령어 ------------------------------------ //

public Action:LookMenu(client, args)
{
	new String:query[256], String:SearchWord[64];
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	
	Lmenu = CreateMenu(Slot_Select);
	SetMenuTitle(Lmenu, "옷 고르삼\n \n!룩 <검색> | !look <search>", client);
	AddMenuItem(Lmenu, "0", "삭제");
	
	if(!StrEqual(SearchWord, ""))
	{
		Format(query, 256, "select * from look where name like \"%%%s%%\";", SearchWord);
		SQL_TQuery(db, SqLSearch, query, client, DBPrio_High);
	}
	else
	{
		SQL_TQuery(db, SqlNoSearch, "select * from look;", client, DBPrio_High);
	}
	return Plugin_Handled;
}

public SqLSearch(Handle:owner, Handle:hndl, const String:error[], any:client) 
{
	if(!IsClientInGame(client)) return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		CloseHandle(Lmenu);
	}
	else if(SQL_GetRowCount(hndl) > 0)
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				decl String:aa[32], String:bb[256];
				SQL_FetchString(hndl, 0, aa, sizeof(aa));
				SQL_FetchString(hndl, 1, bb, sizeof(bb));
				AddMenuItem(Lmenu, aa, bb);
			}
		}
	}
	SetMenuExitButton(Lmenu, true);
	DisplayMenu(Lmenu, client, 30);
}

public SqlNoSearch(Handle:owner, Handle:hndl, const String:error[], any:client) 
{
	if(!IsClientInGame(client)) return;
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		CloseHandle(Lmenu);
	}
	else if(SQL_GetRowCount(hndl) > 0)
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				decl String:aa[32], String:bb[256];
				SQL_FetchString(hndl, 0, aa, sizeof(aa));
				SQL_FetchString(hndl, 1, bb, sizeof(bb));
				AddMenuItem(Lmenu, aa, bb);
			}
		}
	}
	SetMenuExitButton(Lmenu, true);
	DisplayMenu(Lmenu, client, 30);
}

public Slot_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		GetMenuItem(menu, select, info, sizeof(info));
		ItemSlot(client, info);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public ItemSlot(client, String:index[])
{
	new Handle:info = CreateMenu(Look_Select);
	SetMenuTitle(info, "로드아웃 차례대로 슬롯 고르삼");
	
	AddMenuItem(info, index, "슬롯 1"); 
	AddMenuItem(info, index, "슬롯 2"); 
	AddMenuItem(info, index, "슬롯 3"); 
 
	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
} 

public Look_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(!IsPlayerAlive(client))
		{
			PrintToChat(client, "%s살아있을 때만 사용 가능합니다.", FUCCA);
			return;
		}	
		
		if(InLimitZone(client))
		{
			PrintToChat(client, "%s이 곳에서 착용할 수 없습니다.", FUCCA);
			return;
		}
		
		decl String:info[32];
		GetMenuItem(menu, select, info, sizeof(info));

		if(select == 0) GiveLook[client][0][GCLASS] = StringToInt(info);
		else if(select == 1) GiveLook[client][1][GCLASS] = StringToInt(info);
		else if(select == 2) GiveLook[client][2][GCLASS] = StringToInt(info);
		
		teleport(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

// ------------------------------------ 페인트 명령어 ------------------------------------ //

public Action:PaintMenu(client, args)
{
	new String:SearchWord[16], SearchValue;
	decl String:name[100], String:index[64];
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	new Handle:menu = CreateMenu(PaintSlot_Select);

	SetMenuTitle(menu, "페인트 고르삼\n \n!페인트 <검색> | !paint <search>", client);
	AddMenuItem(menu, "", "삭제");
	
	for(new i = 0 ; i < MaxItem_Paint; i++)
	{
		if(kv2[i] != INVALID_HANDLE)
		{
			GetArrayString(kv2[i], 0, name, sizeof(name));
			GetArrayString(kv2[i], 1, index, sizeof(index));
		}
			
		if(StrContains(name, SearchWord, false) > -1)
		{
			AddMenuItem(menu, index, name);
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "\x03이름이 잘못되었거나 없는 이름입니다.");
	
	DisplayMenu(menu, client, 60);
	
	return Plugin_Handled;
}

public PaintSlot_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, select, info, sizeof(info));
		PaintSlot(client, info);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

public PaintSlot(client, String:index[])
{
	new Handle:info = CreateMenu(Paint_Select);
	SetMenuTitle(info, "로드아웃 차례대로 슬롯 고르삼");
	
	AddMenuItem(info, index, "슬롯 1"); 
	AddMenuItem(info, index, "슬롯 2"); 
	AddMenuItem(info, index, "슬롯 3"); 
 
	SetMenuExitButton(info, true);
	DisplayMenu(info, client, 30);
} 

public Paint_Select(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		if(!IsPlayerAlive(client))
		{
			PrintToChat(client, "%s살아있을 때만 사용 가능합니다.", FUCCA);
			return;
		}	
	
		if(InLimitZone(client))
		{
			PrintToChat(client, "%s이 곳에서 착용할 수 없습니다.", FUCCA);
			return;
		}
		
		decl String:info[64];
		GetMenuItem(menu, select, info, sizeof(info));

		if(select == 0) Format(PaintLook[client][0][GCLASS], 100, "%s", info);
		else if(select == 1) Format(PaintLook[client][1][GCLASS], 100, "%s", info);
		else if(select == 2) Format(PaintLook[client][2][GCLASS], 100, "%s", info);
		
		teleport(client);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

// ------------------------------------ 리스폰시 랜덤 ------------------------------------ //

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(RandomCheck[client]) // 7777
	{
		decl String:r_hat[10], String:r_nmedal[10], String:r_medal[10];
		decl String:r_paint[20], String:r_paint2[20], String:r_paint3[20];
		
		for(new i = 0; i < GetArraySize(h_hat); i++) GetArrayString(h_hat, GetRandomInt(0, i), r_hat, sizeof(r_hat));
		for(new i = 0; i < GetArraySize(h_medal); i++) GetArrayString(h_medal, GetRandomInt(0, i), r_medal, sizeof(r_medal));
		for(new i = 0; i < GetArraySize(h_nmedal); i++) GetArrayString(h_nmedal, GetRandomInt(0, i), r_nmedal, sizeof(r_nmedal));
		
		GiveLook[client][0][GCLASS] = StringToInt(r_hat);
		GiveLook[client][1][GCLASS] = StringToInt(r_medal);
		GiveLook[client][2][GCLASS] = StringToInt(r_nmedal);

		if(SettingPaint[client])
		{
			for(new i = 0; i < GetArraySize(h_paint); i++)
			{
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint, sizeof(r_paint));
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint2, sizeof(r_paint2));
				GetArrayString(h_paint, GetRandomInt(0, i), r_paint3, sizeof(r_paint3));
				
				Format(PaintLook[client][0][GCLASS], 100, "%s", r_paint);
				Format(PaintLook[client][1][GCLASS], 100, "%s", r_paint2);
				Format(PaintLook[client][2][GCLASS], 100, "%s", r_paint3);
			}
		}
		
		new String:query[256]
		Format(query, 256, "select * from look where idx = %d;", GiveLook[client][0][GCLASS]);
		SQL_TQuery(db, SqlHud, query, client, DBPrio_High);

		Format(query, 256, "select * from look where idx = %d;", GiveLook[client][1][GCLASS]);
		SQL_TQuery(db, SqlHud2, query, client, DBPrio_High);
		
		Format(query, 256, "select * from look where idx = %d;", GiveLook[client][2][GCLASS]);
		SQL_TQuery(db, SqlHud3, query, client, DBPrio_High);

		RandomCheck[client] = false;
		teleport(client);
		RandomCheck[client] = true;
	}
}

// ------------------------------------ 리젠 되었을때 ------------------------------------ //

public Action:inven(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SlotCheck[client] = 0;
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][0]) == TF2ItemSlot_Hat)
	{
		if(GiveLook[client][0][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][0][GCLASS], PaintLook[client][0][GCLASS]);
			RemoveHat(client, RemoveLook[client][0]);
		}
	}
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][1]) == TF2ItemSlot_Misc)
	{
		if(GiveLook[client][1][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][1][GCLASS], PaintLook[client][1][GCLASS]);
			RemoveHat(client, RemoveLook[client][1]);
		}
	}
	
	if(TF2IDB_GetItemSlot(RemoveLook[client][2]) == TF2ItemSlot_Misc)
	{
		if(GiveLook[client][2][GCLASS] != 0)
		{
			CreateHat(client, GiveLook[client][2][GCLASS], PaintLook[client][2][GCLASS]);
			RemoveHat(client, RemoveLook[client][2]);
		}
	}
}

public Action:TF2Items_OnGiveNamedItem(client, String:szClassName[], index, &Handle:hItem)
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

// ------------------------------------ 스톡 함수 ------------------------------------ //

stock bool:CreateHat(client, itemindex, String:att[])
{
	new hat;
	
	if(itemindex == 1067) hat = CreateEntityByName("tf_wearable_levelable_item");
	else hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat)) return false;
	
	new String:entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), 69);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	DispatchSpawn(hat);
	SetEntProp(hat, Prop_Send, "m_bValidatedAttachedEntity", 1);
	SDKCall(g_hWearableEquip, client, hat);
	
	if(!StrEqual(att, "")) Paint(hat, att);
	
	return true;
}

stock RemoveHat(client, index)
{
	new hat = -1;
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

stock AttAtt(entity, String:att[])
{
	new String:atts[32][32]; 
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	
	if (count > 1) for (new i = 0;  i < count;  i+= 2) TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
}

stock Paint(entity, String:att[])
{
	TF2Attrib_RemoveByDefIndex(entity, 1004);
	TF2Attrib_RemoveByDefIndex(entity, 142);
	TF2Attrib_RemoveByDefIndex(entity, 261);
	
	new Float:paint = StringToFloat(att);
	
	if(paint <= 5.0 && paint >= 0.0) TF2Attrib_SetByDefIndex(entity, 1004, paint);
	else
	{
		new String:aa[3][32]; 
		ExplodeString(att, " ", aa, 3, 32);
		
		if(StrEqual(aa[0], "m"))
		{
			TF2Attrib_SetByDefIndex(entity, 142, StringToFloat(aa[1]));
			TF2Attrib_SetByDefIndex(entity, 261, StringToFloat(aa[2]));
		}
		else TF2Attrib_SetByDefIndex(entity, 142, paint);
	}
}

public SqlHud(Handle:owner, Handle:hndl, const String:error[], any:client) 
{
	if(!IsClientInGame(client)) return;
	
	if(hndl == INVALID_HANDLE) LogError("Query failed: %s", error);
	else if(SQL_GetRowCount(hndl) > 0)
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				decl String:bb[256];
				SQL_FetchString(hndl, 1, bb, sizeof(bb));
				
				SetHudTextParams(-1.0, 0.1, 3.0, 0, 204, 255, 255, 2, 1.0, 0.05, 0.5);
				ShowHudText(client, 0, bb);
			}
		}
	}
}

public SqlHud2(Handle:owner, Handle:hndl, const String:error[], any:client) 
{
	if(!IsClientInGame(client)) return;
	
	if(hndl == INVALID_HANDLE) LogError("Query failed: %s", error);
	else if(SQL_GetRowCount(hndl) > 0)
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				decl String:bb[256];
				SQL_FetchString(hndl, 1, bb, sizeof(bb));
				
				SetHudTextParams(-1.0, 0.15, 3.0, 249, 255, 61, 255, 2, 1.0, 0.05, 0.5);
				ShowHudText(client, 1, bb);
			}
		}
	}
}

public SqlHud3(Handle:owner, Handle:hndl, const String:error[], any:client) 
{
	if(!IsClientInGame(client)) return;
	
	if(hndl == INVALID_HANDLE) LogError("Query failed: %s", error);
	else if(SQL_GetRowCount(hndl) > 0)
	{
		if(SQL_HasResultSet(hndl))
		{
			while(SQL_FetchRow(hndl))
			{
				decl String:bb[256];
				SQL_FetchString(hndl, 1, bb, sizeof(bb));
				
				SetHudTextParams(-1.0, 0.2, 3.0, 255, 234, 255, 0, 2, 1.0, 0.05, 0.5);
				ShowHudText(client, 2, bb);
			}
		}
	}
}

stock teleport(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	TF2_RespawnPlayer(client);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public bool:AliveCheck(client)
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

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}