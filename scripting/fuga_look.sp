#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>
#include <tf2wearables>

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

public Plugin myinfo = 
{
	name = "[TF2] Wearable Plugin",
	author = "뿌까",
	description = "hahahahahahahahahahaha",
	version = "3.0",
	url = "https://steamcommunity.com/id/ssssssaaaazzzzzxxc/"
};

#define FUCCA "\x0700ccff[뿌까] "
#define GCLASS TF2_GetPlayerClass(client)

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

// ------------------------------------ 룩 컨픽 / 설정 ------------------------------------ //
ArrayList LookList;
ArrayList PaintList;

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

#include "look/config.sp"
#include "look/command.sp"
#include "look/menu.sp"
#include "look/helper.sp"

public void OnPluginStart()
{
	LoadTranslations("tf.phrases");

	LookList = new ArrayList(sizeof(Look));
	LookMap = new StringMap();
	PaintList = new ArrayList(sizeof(Paint));

	InitCommand();
	
	HookEvent("post_inventory_application", inven, EventHookMode_Post);
	
	for(int i = 1; i <= MaxClients+1; i++)
	{
		OnClientPutInServer(i);
	}
}

public void OnConfigsExecuted()
{	
	LoadItemConfig();
	LoadPaintConfig();
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