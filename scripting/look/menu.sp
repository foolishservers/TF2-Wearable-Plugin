public void Menu_ItemSlot(int client)
{
	Menu menu = new Menu(Select_ItemSlot);
	
	menu.SetTitle("룩 대여\n현재 착용 중인 장식");	
	
	for(int i = 0; i < 3; i++)
	{
		int id;
		char sInfo[64], sItemName[128], sLocalizedItemName[128];

		if(OriginalLook[client][i][GCLASS].RentalIndex <= 0)
		{
			id = OriginalLook[client][i][GCLASS].Index;
			
			if(id == 65535)
			{
				PrintToChatAll("!!!65535 뜸!!!");
				InitOriginalLook(client);
			}
			
			if(id)
			{	
				PrintToChatAll("%N %d %d %d", client, i, id, 0);
			
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
}

public Select_ItemSlot(Menu previousMenu, MenuAction action, int client, int select)
{
	switch(action)
	{
		case MenuAction_Select :
		{
			char sInfo[64], sInfoSplit[3][16];
	
			GetMenuItem(previousMenu, select, sInfo, sizeof(sInfo));
	
			ExplodeString(sInfo, ";", sInfoSplit, sizeof(sInfoSplit), sizeof(sInfoSplit[]));
	
			int slot = StringToInt(sInfoSplit[0]);
			int id = StringToInt(sInfoSplit[1]);
			bool isRent = (StringToInt(sInfoSplit[2]) > 0);
		
			Menu_ItemSetting(client, slot, id, isRent);
		}
		case MenuAction_End : 
		{
			CloseHandle(previousMenu);
		}
	}
}

public void Menu_ItemSetting(int client, int slot, int id, bool isRent)
{
	Menu menu = CreateMenu(Select_ItemSetting);
	
	char sInfo[64], sItemName[128], sLocalizedItemName[128];
	
	Format(sInfo, sizeof(sInfo), "%d;%d;%d", slot, id, isRent);
	
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
	menu.AddItem(sInfo, "언유", ITEMDRAW_DISABLED);
	menu.AddItem(sInfo, "페인트", ITEMDRAW_DISABLED);
	
	if(isRent) menu.AddItem(sInfo, "삭제");
	else menu.AddItem(sInfo, "삭제", ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Select_ItemSetting(Menu previousMenu, MenuAction action, int client, int select)
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
					Menu_ItemSearch(client, "");
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
				Menu_ItemSlot(client);
			}
			SlotInfo[client].Init();
		}
		case MenuAction_End : 
		{
			CloseHandle(previousMenu);
		}
	}
}

public void Menu_ItemSearch(int client, char[] searchWord)
{
	char SearchWord[32], SearchValue, sIndex[12], sItemName[128];
	
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	Menu menu = new Menu(Select_ItemSearch);

	menu.SetTitle("대여 장식 검색\n채팅에 장식 이름 입력", client);
	
	for(int i = 0 ; i < LookList.Length ; i++)
	{
		Look look;
		LookList.GetArray(i, look, sizeof(look));
	
		if(StrContains(look.item_name, "tf_gatebot", false) == -1)
		{
			IntToString(look.index, sIndex, 12);
			
			Format(sItemName, sizeof(sItemName), "%t", look.item_name); 
		
			if(StrContains(sItemName, searchWord, false) > -1)
			{
				menu.AddItem(sIndex, sItemName);
				SearchValue++;
			}
		}
	}
	
	if(!SearchValue)
	{
		char sNoSearch[256];
		Format(sNoSearch, sizeof(sNoSearch), "\"%s\" 단어가 포함된 장식이 없습니다.", searchWord); 
		menu.AddItem("0", sNoSearch, ITEMDRAW_DISABLED);
	}
	
	menu.ExitBackButton = true;
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Select_ItemSearch(Menu menu, MenuAction action, int client, int select)
{
	switch(action)
	{
		case MenuAction_Select : 
		{
			char info[32];
			GetMenuItem(menu, select, info, sizeof(info));
		
			int index = StringToInt(info);
			int slot = SlotInfo[client].Slot;
		
			int curentSlot[3];

			for(int i = 0; i < 3; i++)
			{
				curentSlot[i] = (OriginalLook[client][i][GCLASS].RentalIndex > 0) ? OriginalLook[client][i][GCLASS].RentalIndex : OriginalLook[client][i][GCLASS].Index;
			}
			
			curentSlot[slot] = index;
			
			bool isRepetition = false;
			
			for(int i = 0 ; i < 3; i++)
			{
				if(slot != i && curentSlot[slot] == curentSlot[i])
				{
					isRepetition = true;
					break;
				}
			}
			
			PrintToChat(client, "%d %d %d", curentSlot[0], curentSlot[1], curentSlot[2]);
			
			if(isRepetition)
			{
				PrintToChat(client, "중복해서 장식을 착용할 수 없습니다.");
			}
			else
			{
				PrintToChat(client, "재보급시, 해당 장식이 착용됩니다.");
				OriginalLook[client][slot][GCLASS].RentalIndex = index;
				GiveLook[client][slot][GCLASS] = index;
			}
		
			SlotInfo[client].Init();
		}
		case MenuAction_Cancel :
		{
			switch(select)
			{
				case MenuCancel_Disconnected :
				{
					SlotInfo[client].Init();
					PrintToChat(client, "클라이언트 연결 끊김");
				}
				case MenuCancel_Interrupted :
				{
					PrintToChat(client, "인터셉트");
				}
				case MenuCancel_Exit :
				{
					SlotInfo[client].Init();
					PrintToChat(client, "메뉴나감");
				}
				case MenuCancel_NoDisplay :
				{
					//SlotInfo[client].Init();
					PrintToChat(client, "노디스플레이");
				}
				case MenuCancel_Timeout :
				{
					SlotInfo[client].Init();
					PrintToChat(client, "타임아웃");
				}
				case MenuCancel_ExitBack :
				{
					Menu_ItemSetting(client, SlotInfo[client].Slot, SlotInfo[client].Index, SlotInfo[client].IsRent);
					PrintToChat(client, "메뉴뒤로가기");
				}
			}
		}
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
}