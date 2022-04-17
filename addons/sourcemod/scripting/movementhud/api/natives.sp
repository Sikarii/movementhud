// =====[ LISTENERS ]=====

void OnAskPluginLoad2_Natives()
{
    CreateNative("MHud_IsReady", Native_IsReady);
    CreateNative("MHud_DisposeResources", Native_DisposeResources);

    CreateNative("MHudPreference.Find", Native_PreferenceFind);
    CreateNative("MHudPreference.Create", Native_PreferenceCreate);
    CreateNative("MHudPreference.HandleInput", Native_PreferenceSetInputHandler);
    CreateNative("MHudPreference.HandleDisplay", Native_PreferenceSetDisplayHandler);
    CreateNative("MHudPreference.HandleGetNext", Native_PreferenceSetGetNextHandler);

    CreateNative("MHudPreference.GetId", Native_PreferenceGetId);
    CreateNative("MHudPreference.GetName", Native_PreferenceGetName);

    CreateNative("MHudPreference.GetValueEx", Native_GetPreferenceValue);
    CreateNative("MHudPreference.SetValue", Native_SetPreferenceValue);

    CreateNative("MHudPreference.WithMetadata", Native_PreferenceSetMetadata);
    CreateNative("MHudPreference.WithMetadataCell", Native_PreferenceSetMetadataCell);
}

// =====[ PUBLIC ]=====

public int Native_IsReady(Handle plugin, int numParams)
{
    return gB_IsReady;
}

public int Native_DisposeResources(Handle plugin, int numParams)
{
    return DisposePreferencesForPlugin(plugin);
}

public any Native_PreferenceFind(Handle plugin, int numParams)
{
    char id[MHUD_MAX_ID];
    GetNativeString(1, id, sizeof(id));

    Preference preference;

    bool exists = GetPreferenceById(id, preference);
    if (!exists)
    {
        return INVALID_HANDLE;
    }

    return CreatePreferenceThisParam(id, plugin);
}

public any Native_PreferenceCreate(Handle plugin, int numParams)
{
    char id[MHUD_MAX_ID];
    GetNativeString(1, id, sizeof(id));

    char name[MHUD_MAX_NAME];
    GetNativeString(2, name, sizeof(name));

    char defaultValue[MHUD_MAX_VALUE];
    GetNativeString(3, defaultValue, sizeof(defaultValue));

    bool exists = HasPreference(id);
    if (exists)
    {
        // TODO: Throw if some argument is true?
        return CreatePreferenceThisParam(id, plugin);
    }

    RegisterPreference(id, name, defaultValue, plugin);

    return CreatePreferenceThisParam(id, plugin);
}

public any Native_PreferenceSetInputHandler(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);
    Function handler = GetNativeFunction(2);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return INVALID_HANDLE;
    }

    preference.InputHandler = handler;
    SavePreference(preference);

    return thisParam;
}

public any Native_PreferenceSetDisplayHandler(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);
    Function handler = GetNativeFunction(2);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return INVALID_HANDLE;
    }

    preference.DisplayHandler = handler;
    SavePreference(preference);

    return thisParam;
}

public any Native_PreferenceSetGetNextHandler(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);
    Function handler = GetNativeFunction(2);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return INVALID_HANDLE;
    }

    preference.GetNextHandler = handler;
    SavePreference(preference);

    return thisParam;
}

public int Native_PreferenceGetId(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return false;
    }

    int maxlength = GetNativeCell(3);

    SetNativeString(2, preference.Id, maxlength);
    return true;
}

public int Native_PreferenceGetName(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return false;
    }

    int maxlength = GetNativeCell(3);

    SetNativeString(2, preference.Name, maxlength);
    return true;
}

public int Native_GetPreferenceValue(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);
    int client = GetNativeCell(2);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return false;
    }

    char value[MHUD_MAX_VALUE];
    GetPreferenceValue(client, preference, value);

    SetNativeString(3, value, sizeof(value));
    return true;
}

public int Native_SetPreferenceValue(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);
    int client = GetNativeCell(2);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return false;
    }

    char buffer[MHUD_MAX_VALUE];
    GetNativeString(3, buffer, sizeof(buffer));

    SetPreferenceValue(client, preference, buffer);
    return true;
}

public any Native_PreferenceSetMetadata(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return INVALID_HANDLE;
    }

    char key[128];
    GetNativeString(2, key, sizeof(key));

    char value[256];
    GetNativeString(3, value, sizeof(value));

    preference.Metadata.SetString(key, value);
    return thisParam;
}

public any Native_PreferenceSetMetadataCell(Handle plugin, int numParams)
{
    StringMap thisParam = GetNativeCell(1);

    Preference preference;

    bool found = GetPreferenceByThisParam(thisParam, preference);
    if (!found)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Invalid preference");
        return INVALID_HANDLE;
    }

    char key[128];
    GetNativeString(2, key, sizeof(key));

    any value = GetNativeCell(3);

    preference.Metadata.SetValue(key, value);
    return thisParam;
}
