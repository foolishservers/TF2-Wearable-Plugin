public void LoadItemConfig()
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
}

public void LoadPaintConfig()
{
	KeyValues kvItems;
	char sPath[192], sKey[128];
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