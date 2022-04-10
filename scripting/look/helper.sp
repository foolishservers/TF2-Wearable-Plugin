public void InitOriginalLook(int client)
{
	for(int slot = 0; slot < 3; slot++)
	{
		OriginalLook[client][slot][GCLASS].Init();
	}

	for (int i,n = TF2Util_GetPlayerWearableCount(client), slot = 0; i < n; i++)
	{
		int wearable = TF2Util_GetPlayerWearable(client, i);
		int itemdef = TF2_GetItemDefinitionIndex(wearable);
		
		if (!IsWearableWeapon(itemdef) && OriginalLook[client][slot][GCLASS].IsEmpty()) 
		{
			OriginalLook[client][slot][GCLASS].Index = itemdef;
			slot++;
		}
	}
	
	for(int slot = 0; slot < 3; slot++)
	{
		if(OriginalLook[client][slot][GCLASS].IsEmpty()) 
		{
			OriginalLook[client][slot][GCLASS].Index = 0;
		}
	}
	
	PrintToChat(client, "초기화 %d %d %d", OriginalLook[client][0][GCLASS], OriginalLook[client][1][GCLASS], OriginalLook[client][2][GCLASS]);
}

public bool IsOriginalLookNeedUpdate(int client)
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
	
	for (int i,n = TF2Util_GetPlayerWearableCount(client); i < n; i++)
	{
		int wearable = TF2Util_GetPlayerWearable(client, i);
		int itemdef = TF2_GetItemDefinitionIndex(wearable);
		
		if (!IsWearableWeapon(itemdef)) 
		{
			if(OriginalLook[client][0][GCLASS].Index == itemdef)
			{
				IsNeedUpdate[0] = false;
			}
			
			if(OriginalLook[client][1][GCLASS].Index == itemdef)
			{
				IsNeedUpdate[1] = false;
			}
			
			if(OriginalLook[client][2][GCLASS].Index == itemdef)
			{
				IsNeedUpdate[2] = false;
			}
			
			HatCount++;
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
	
	TF2Util_EquipPlayerWearable(client, wearable);
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
	
	for (int i,n = TF2Util_GetPlayerWearableCount(client); i < n; i++)
	{
		int wearable = TF2Util_GetPlayerWearable(client, i);
		int itemdef = TF2_GetItemDefinitionIndex(wearable);
		
		if (itemdef == OriginalLook[client][slot][GCLASS].Index)
		{
			AcceptEntityInput(wearable, "Kill");
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
		case 133, 444, 405, 608, 231, 642, 
			 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 489, 493, 542, 1152, 30015, 
			 1069, 1070, 1132, 5604, 
			 30535, 536, 673, 5869 :
		{
			return true;
		}
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

stock void String_ToLower(const char[] input, char[] output, size)
{
	size--;

	new x=0;
	while (input[x] != '\0' && x < size) {

		output[x] = CharToLower(input[x]);

		x++;
	}

	output[x] = '\0';
}

stock int TF2_GetItemDefinitionIndex(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
}