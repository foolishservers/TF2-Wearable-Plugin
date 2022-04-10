int g_iMiscSlot = -1;

public void LoadMiscItem() 
{
	g_iMiscSlot = TF2Econ_TranslateLoadoutSlotNameToIndex("misc");
	
	if (g_iMiscSlot == -1) 
	{
		SetFailState("Failed to determine index for slot name '%s'", "misc");
		return;
	}
	
	char sIdx[32], sLocalizedItemName[128];
	
	StringMap miscMap = new StringMap();
	
	for(int TFClass = 1; TFClass < 10; TFClass++)
	{
		ArrayList miscList = TF2Econ_GetItemList(FilterClassMisc, view_as<TFClassType>(TFClass));
		
		for (int i = 0; i < miscList.Length; i++)
		{
			int defindex = miscList.Get(i);
		
			Format(sIdx, sizeof(sIdx), "%d", defindex);
			
			TF2Econ_GetLocalizedItemName(defindex, sLocalizedItemName, sizeof(sLocalizedItemName));
			ReplaceString(sLocalizedItemName, sizeof(sLocalizedItemName), "#", "", false);
			String_ToLower(sLocalizedItemName, sLocalizedItemName, sizeof(sLocalizedItemName));
		
			miscMap.SetString(sIdx, sLocalizedItemName);
		}
		delete miscList;
	}
	
	StringMapSnapshot snapMiscMap = miscMap.Snapshot();
	
	for (int i = 0; i < snapMiscMap.Length; i++)
	{
		snapMiscMap.GetKey(i, sIdx, sizeof(sIdx));
		miscMap.GetString(sIdx, sLocalizedItemName, sizeof(sLocalizedItemName));
		
		Look look;			
		look.index = StringToInt(sIdx);
		look.item_name = sLocalizedItemName;
		
		LookList.PushArray(look, sizeof(look));
	}
	
	delete snapMiscMap;
	delete miscMap;
}

bool FilterClassMisc(int defindex, TFClassType playerClass)
{
	return TF2Econ_GetItemLoadoutSlot(defindex, playerClass) == g_iMiscSlot;
}

public void LoadPaintConfig()
{
	KeyValues kvItems;
	char sPath[192];
	int count = 0;

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