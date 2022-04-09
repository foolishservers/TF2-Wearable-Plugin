#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>
#include <tf2wearables>

#define FUCCA "\x0700ccff[뿌까] "
#define GCLASS TF2_GetPlayerClass(client)

// ------------------------------------ 룩 컨픽 / 설정 ------------------------------------ //
ArrayList LookList;
ArrayList PaintList;

enum struct Look
{
	int index;
	char item_name[128];
}

enum struct Paint
{
	char name[64];
	char index[32];
}

enum struct Wearable
{
	int Index;
	int RentalIndex;
	
	void Init()
	{
		this.Index = -1;
		this.RentalIndex = -1;
	}
	
	bool IsEmpty()
	{
		return this.Index < 0 && this.RentalIndex < 0;
	}
}

enum struct MenuSlotInfo
{
	int Slot;
	int Index;
	bool IsRent;
	
	void Init()
	{
		this.Slot = -1;
		this.Index = -1;
		this.IsRent = false;
	}
}

MenuSlotInfo SlotInfo[MAXPLAYERS+1];

StringMap LookMap;
int MaxItem_Look;

int GiveLook[MAXPLAYERS+1][3][10];
Wearable OriginalLook[MAXPLAYERS+1][3][10];

// ------------------------------------ 페인트 컨픽 / 설정 ------------------------------------ //
char PaintLook[MAXPLAYERS+1][3][10][100];

int MaxItem_Paint;

// ------------------------------------ 페인트 컨픽 / 설정 ------------------------------------ //
float StyleLook[MAXPLAYERS+1][3];

// ------------------------------------ 설정 옵션 ------------------------------------ //
bool SettingReset[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Wearable Plugin",
	author = "뿌까",
	description = "hahahahahahahahahahaha",
	version = "3.0",
	url = "https://steamcommunity.com/id/ssssssaaaazzzzzxxc/"
};

public Extension:__ext_langparser = 
{
    name = "langparser",
    file = "langparser.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
};

public Extension:__ext_LanguagePhrasesParser = 
{
    name = "LanguagePhrasesParser",
    file = "LanguagePhrasesParser.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
};

public void OnPluginStart()
{
	LoadTranslations("tf.phrases");

	LookList = new ArrayList(sizeof(Look));
	LookMap = new StringMap();
	PaintList = new ArrayList(sizeof(Paint));
	
	RegConsoleCmd("sm_look", LookMenu);
	RegConsoleCmd("sm_paint", PaintMenu);
	RegConsoleCmd("sm_style", StyleMenu);
	RegConsoleCmd("sm_lookreset", ResetCommand);
	RegConsoleCmd("sm_lall", ResetCommand2);
	RegConsoleCmd("sm_looksetting", SettingCommand);
	
	HookEvent("post_inventory_application", inven, EventHookMode_Post);
	
	for(int i = 1; i <= MaxClients+1; i++)
	{
		OnClientPutInServer(i);
	}
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
			char sidx[12], sItemName[128], sLocalizedItemName[128];
			int idx;
			
			kvItems.GetSectionName(sidx, sizeof(sidx));
			idx = StringToInt(sidx);
			
			kvItems.GetString("name", sItemName, sizeof(sItemName), "");
			TF2Econ_GetItemName(idx, sItemName, 128);
			TF2Econ_GetLocalizedItemName(idx, sLocalizedItemName, 128);
			
			ReplaceString(sLocalizedItemName, sizeof(sLocalizedItemName), "#", "", false);
			
			String_ToLower(sLocalizedItemName, sLocalizedItemName, sizeof(sLocalizedItemName));
			
			Look look;			
			look.index = idx;
			look.item_name = sLocalizedItemName;
			
			LookList.PushArray(look, sizeof(look));
			
			Format(sKey, 128, "%d_item_name", idx);
			LookMap.SetValue(sKey, true);
			
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
}

public void OnMapEnd()
{
	LookList.Clear();
	LookMap.Clear();
	PaintList.Clear();
}

public void OnClientPutInServer(int client)
{
	for(int i = 0; i <= 2; i++)
	{
		StyleLook[client][i] = 0.0;
	
		for(int j = 0; j <= 9; j++)
		{
			GiveLook[client][i][j] = 0;
			OriginalLook[client][i][j].Init();
			PaintLook[client][i][j] = "";
		}
	}
	
	SlotInfo[client].Init();
	
	SettingReset[client] = false;
}

public Action LookMenu(int client, int args)
{
	Menu menu = new Menu(Slot_Select);
	
	menu.SetTitle("룩 대여\n현재 착용 중인 장식");	
	
	for(int i = 0; i < 3; i++)
	{
		int id;
		char sInfo[64], sItemName[128], sLocalizedItemName[128];

		if(OriginalLook[client][i][GCLASS].RentalIndex <= 0)
		{
			id = OriginalLook[client][i][GCLASS].Index;
			
			if(id)
			{
				Format(sInfo, sizeof(sInfo), "%d;%d;%d", i, id, 0);
			
				TF2Econ_GetLocalizedItemName(id, sLocalizedItemName, sizeof(sLocalizedItemName));
				ReplaceString(sLocalizedItemName, sizeof(sLocalizedItemName), "#", "", false);
				String_ToLower(sLocalizedItemName, sLocalizedItemName, sizeof(sLocalizedItemName));
				
				Format(sItemName, sizeof(sItemName), "%t", sLocalizedItemName);
				
				menu.AddItem(sInfo, sItemName);
			}
			else
			{
				Format(sInfo, sizeof(sInfo), "%d;%d;%d", i, 0, 0);
				menu.AddItem(sInfo, "- 비어 있음 -");
			}
		}
		else
		{
			id = OriginalLook[client][i][GCLASS].RentalIndex;
			
			Format(sInfo, sizeof(sInfo), "%d;%d;%d", i, id, 1);
			
			TF2Econ_GetLocalizedItemName(id, sLocalizedItemName, sizeof(sLocalizedItemName));
			ReplaceString(sLocalizedItemName, sizeof(sLocalizedItemName), "#", "", false);
			String_ToLower(sLocalizedItemName, sLocalizedItemName, sizeof(sLocalizedItemName));
			
			Format(sItemName, sizeof(sItemName), "%t [대여중]", sLocalizedItemName);
			
			menu.AddItem(sInfo, sItemName);
		}
	}
 
	menu.ExitButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Slot_Select(Menu previousMenu, MenuAction action, int client, int select)
{
	switch(action)
	{
		case MenuAction_Select :
		{
			Menu menu = CreateMenu(Slot_Setting);
		
			char sInfo[64], sInfoSplit[3][16], sItemName[128], sLocalizedItemName[128];
		
			GetMenuItem(previousMenu, select, sInfo, sizeof(sInfo));
		
			ExplodeString(sInfo, ";", sInfoSplit, sizeof(sInfoSplit), sizeof(sInfoSplit[]));
		
			int slot = StringToInt(sInfoSplit[0]);
			int id = StringToInt(sInfoSplit[1]);
			bool isRent = (StringToInt(sInfoSplit[2]) > 0);
		
			PrintToChat(client, "Slot Select %d %d %d", slot, id, isRent);
		
			if(id > 0)
			{
				TF2Econ_GetLocalizedItemName(id, sLocalizedItemName, sizeof(sLocalizedItemName));
				ReplaceString(sLocalizedItemName, sizeof(sLocalizedItemName), "#", "", false);
				String_ToLower(sLocalizedItemName, sLocalizedItemName, sizeof(sLocalizedItemName));
				
				if(!isRent) Format(sItemName, sizeof(sItemName), "\"%t\" 장식 설정", sLocalizedItemName);
				else Format(sItemName, sizeof(sItemName), "\"%t [대여중]\" 장식 설정", sLocalizedItemName);
				
				menu.SetTitle("%s", sItemName);
			}
			else
			{
				menu.SetTitle("\"-비어 있음-\" 장식 설정", sItemName);
			}
			
			menu.AddItem(sInfo, "대여");
			menu.AddItem(sInfo, "언유");
			menu.AddItem(sInfo, "페인트");
		
			if(isRent) menu.AddItem(sInfo, "삭제");
			else menu.AddItem(sInfo, "삭제", ITEMDRAW_DISABLED);
		
			menu.ExitBackButton = true;
		
			menu.Display(client, MENU_TIME_FOREVER);
		}
		case MenuAction_End : 
		{
			CloseHandle(previousMenu);
		}
	}
}

public Slot_Setting(Menu previousMenu, MenuAction action, int client, int select)
{
	switch(action)
	{
		case MenuAction_Select :
		{
			char info[64], infoSplit[3][16];
			
			GetMenuItem(previousMenu, select, info, sizeof(info));
			
			ExplodeString(info, ";", infoSplit, sizeof(infoSplit), sizeof(infoSplit[]));
			
			int slot = StringToInt(infoSplit[0]);
			int id = StringToInt(infoSplit[1]);
			bool isRent = (StringToInt(infoSplit[2]) > 0);
			
			SlotInfo[client].Slot = slot;
			SlotInfo[client].Index = id;
			SlotInfo[client].IsRent = isRent;
			
			PrintToChat(client, "slot setting %d %d %d", SlotInfo[client].Slot, SlotInfo[client].Index, SlotInfo[client].IsRent);
		
			switch(select)
			{
				case 0 :
				{
					Look_Search(client);
				}
				case 1 :
				{
				}
				case 2 :
				{
				}
				case 3 :
				{
					PrintToChat(client, "재보급시, 해당 장식이 해제됩니다.");
					OriginalLook[client][slot][GCLASS].RentalIndex = 0;
					GiveLook[client][slot][GCLASS] = 0;
				}
			}
		}
		case MenuAction_Cancel :
		{
			PrintToChat(client, "ㄻㄴㄹ");
			if(select == MenuCancel_ExitBack)
			{
				PrintToChat(client, "ㄻㄴㄹ");
				previousMenu.Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End : 
		{
			CloseHandle(previousMenu);
		}
	}
}

public void Look_Search(int client)
{
	char SearchWord[32], SearchValue, sIndex[12], sItemName[128];
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	Menu menu = new Menu(Look_Select);

	menu.SetTitle("옷 고르삼\n \n!룩 <검색> | !look <search>", client);
	
	for(int i = 0 ; i < MaxItem_Look ; i++)
	{
		Look look;
		LookList.GetArray(i, look, sizeof(look));
	
		IntToString(look.index, sIndex, 12);
		
		Format(sItemName, sizeof(sItemName), "%t", look.item_name); 
		
		if(StrContains(sItemName, SearchWord, false) > -1)
		{
			menu.AddItem(sIndex, sItemName);
			SearchValue++;
		}
	}
	
	if(!SearchValue) PrintToChat(client, "%s\x03이름이 잘못되었거나 없는 이름입니다.",FUCCA);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Look_Select(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{		
		char info[32];
		GetMenuItem(menu, select, info, sizeof(info));
		
		int index = StringToInt(info);
		bool isDuplicated = false;
		
		int slot = SlotInfo[client].Slot;
		
		for(int i = 0; i < 3; i++)
		{
			if(	OriginalLook[client][i][GCLASS].Index == index ||
				OriginalLook[client][i][GCLASS].RentalIndex == index ||
				GiveLook[client][i][GCLASS] == index)
			{
				isDuplicated = true;
			}
		}
		
		if(isDuplicated)
		{
			PrintToChat(client, "중복해서 장식을 착용할 수 없습니다.");
		}
		else
		{
			PrintToChat(client, "재보급시, 해당 장식이 착용됩니다.");
			OriginalLook[client][slot][GCLASS].RentalIndex = index;
			GiveLook[client][slot][GCLASS] = index;
		}
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

// ------------------------------------ 리젠 되었을때 ------------------------------------ //

public Action inven(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	PrintToChat(client, "%d %d %d", GiveLook[client][0][GCLASS], GiveLook[client][1][GCLASS], GiveLook[client][2][GCLASS]);
	
	if(OriginalLook[client][0][GCLASS].IsEmpty())
	{
		PrintToChat(client,"첫 등록");
		InitOriginalLook(client);
	}
	else
	{
		PrintToChat(client,"정보 있음");
		if(IsOriginalLookNeedUpdate(client))
		{
			PrintToChat(client,"로드아웃 장식이 변경되어 장식 대여 설정이 초기화 됩니다");
			InitOriginalLook(client);
		}
	}
	
	for(int i = 0; i < 3; i++)
	{
		if(GiveLook[client][i][GCLASS] != 0)
		{
			RemoveHat(client, GiveLook[client][i][GCLASS]);
			TF2Item_GiveWearable(client, GiveLook[client][i][GCLASS], PaintLook[client][i][GCLASS], StyleLook[client][i]);
		}
	}
}

/*
public Action TF2Items_OnGiveNamedItem(int client, char[] szClassName, int index, Handle &hItem)
{
	return Plugin_Continue;   
}
*/

void InitOriginalLook(int client)
{
	int hat = -1, slot = 0;
	
	for(slot = 0; slot < 3; slot++)
	{
		OriginalLook[client][slot][GCLASS].Init();
	}
	
	slot = 0;
	
	while ((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) 
	{
		if ((hat != INVALID_ENT_REFERENCE) && (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client))
		{
			int id = GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex");
			
			if (!IsWearableWeapon(id) && OriginalLook[client][slot][GCLASS].IsEmpty()) 
			{
				OriginalLook[client][slot][GCLASS].Index = id;	
				
				if(slot < 3)
				{
					slot++;
				}
			}
		}
	}
	
	slot = 0;
	
	for(slot = 0; slot < 3; slot++)
	{
		if(OriginalLook[client][slot][GCLASS].IsEmpty()) 
		{
			OriginalLook[client][slot][GCLASS].Index = 0;
		}
	}
	
	PrintToChat(client, "초기화 %d %d %d", OriginalLook[client][0][GCLASS], OriginalLook[client][1][GCLASS], OriginalLook[client][2][GCLASS]);
}

bool IsOriginalLookNeedUpdate(int client)
{
	int OldHatCount = 0, HatCount = 0;
	bool IsNeedUpdate[3] = {true, true, true};
	
	for(int slot = 0; slot < 3; slot++)
	{
		if(OriginalLook[client][slot][GCLASS].Index != 0)
		{
			OldHatCount++;
		}
	}
	
	int hat = -1, id = -1;
	while((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) 
	{
		if ((hat != INVALID_ENT_REFERENCE) && (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client))
		{
			id = GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex");
			
			if(!IsWearableWeapon(id))
			{
				if(OriginalLook[client][0][GCLASS].Index == id)
				{
					IsNeedUpdate[0] = false;
				}
			
				if(OriginalLook[client][1][GCLASS].Index == id)
				{
					IsNeedUpdate[1] = false;
				}
			
				if(OriginalLook[client][2][GCLASS].Index == id)
				{
					IsNeedUpdate[2] = false;
				}
				
				HatCount++;
			}
		}
	}
	
	PrintToChat(client, "IsNeedUpdate %d %d %d", IsNeedUpdate[0], IsNeedUpdate[1], IsNeedUpdate[2]);
	PrintToChat(client, "Old %d New %d ", OldHatCount, HatCount);
	
	if(OldHatCount != HatCount)
	{
		return true;
	}
	
	for(int slot = 0; slot < 3;  slot++)
	{
		if(IsNeedUpdate[slot] && OriginalLook[client][slot][GCLASS].Index != 0)
		{
			return true;
		}
	}
	
	return false;
}

stock bool TF2Item_GiveWearable(int client, int index, char[] att, float att2)
{
	Handle item = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
	
	if(index != 1067) TF2Items_SetClassname(item, "tf_wearable");
	else  TF2Items_SetClassname(item, "tf_wearable_levelable_item");
	
	TF2Items_SetItemIndex(item, index);
	//TF2Items_SetQuality(item, 6);
	//TF2Items_SetLevel(item, 1);
	
	int wearable = TF2Items_GiveNamedItem(client, item);
	
	if(!StrEqual(att, "")) SetPaint(wearable, att);
	if(att2 != 0.0) Style(wearable, att2);
	
	SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	delete item;
	
	TF2_EquipPlayerWearable(client, wearable);
}

stock void RemoveHat(int client, int index)
{
	int slot = 0;
	for(slot = 0; slot < 3; slot++)
	{
		if(OriginalLook[client][slot][GCLASS].RentalIndex == index)
		{
			break;
		}
	}
	
	int hat = -1;
	while ((hat = FindEntityByClassname(hat, "tf_wearable")) != -1) {
		if ((hat != INVALID_ENT_REFERENCE) && (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client)) {
			int id = GetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex");
			
			if (id == OriginalLook[client][slot][GCLASS].Index)
			{
				AcceptEntityInput(hat, "Kill");
			}
		}
	}
}

stock void AttAtt(int entity, char[] att)
{
	char atts[32][32]; 
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	
	if (count > 1) for (int i = 0;  i < count;  i+= 2) TF2Attrib_SetByDefIndex(entity, StringToInt(atts[i]), StringToFloat(atts[i+1]));
}

stock void SetPaint(int entity, char[] att)
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

stock bool IsWearableWeapon(int id)
{
	switch (id) {
		case 133, 444, 405, 608, 231, 642:
			return true;
	}
	return false;
}

stock bool AliveCheck(int client)
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

// ------------------------------------ 리팩토링 필요 ------------------------------------ //
stock void Fucca_ReplyToCommand(client, String:say[])
{ 
	ReplyToCommand(client, "%s\x07FFFFFF%s", FUCCA, say);
}

public Action SettingCommand(int client, int args)
{
	Menu menu = CreateMenu(Setting_Select);
	
	char rr[64];
	Format(rr, sizeof(rr), "초기화시 모든 클래스도 초기화 [%s]", SettingReset[client] ? "X" : "O");
	
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
		}
	}
		
	return Plugin_Handled;
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
	
	PrintToChat(client, "%s\x04스타일은 적용이 안될 수 있습니다.", FUCCA);
	
	return Plugin_Handled;
}

stock String_ToLower(const String:input[], String:output[], size)
{
	size--;

	new x=0;
	while (input[x] != '\0' && x < size) {

		output[x] = CharToLower(input[x]);

		x++;
	}

	output[x] = '\0';
}