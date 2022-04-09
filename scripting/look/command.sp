public void InitCommand()
{
	RegConsoleCmd("sm_look", LookMenu);
	RegConsoleCmd("say", Command_ItemSearch);
	RegConsoleCmd("say_team", Command_ItemSearch);
	/*
	RegConsoleCmd("sm_paint", PaintMenu);
	RegConsoleCmd("sm_style", StyleMenu);
	RegConsoleCmd("sm_lookreset", ResetCommand);
	RegConsoleCmd("sm_lall", ResetCommand2);
	RegConsoleCmd("sm_looksetting", SettingCommand);
	*/
}

public Action LookMenu(int client, int args)
{
	Menu_ItemSlot(client);
	
	return Plugin_Handled;
}

public Action Command_ItemSearch(int client, int args)
{
	if(SlotInfo[client].Slot > -1)
	{
		char sSearch[256];
		
		GetCmdArgString(sSearch, sizeof(sSearch));
		
		ReplaceString(sSearch, sizeof(sSearch), "\"", "", false);
		
		PrintToChat(client, "%s", sSearch);
		
		Menu_ItemSearch(client, sSearch);
		
		return Plugin_Handled;
	}

	return Plugin_Continue;
}