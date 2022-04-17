enum struct Preference
{
    char Id[24];
    char Name[64];
    char DefaultValue[100];

    Cookie Cookie;
    Handle OwningPlugin;

    StringMap Metadata;
    StringMap ValueCache;

    Function InputHandler;
    Function DisplayHandler;
    Function GetNextHandler;
}

ArrayList g_Preferences;
StringMap g_PreferenceMap;

// =====[ LISTENERS ]=====

void OnPluginStart_Preferences()
{
    g_Preferences = new ArrayList(sizeof(Preference));
    g_PreferenceMap = new StringMap();
}

void OnClientPutInServer_Preferences(int client)
{
    InvalidatePreferencesValueCache(client);
}

// =====[ PUBLIC ]=====

int DisposePreferencesForPlugin(Handle plugin)
{
    int disposedCount = 0;

    for (int i = g_Preferences.Length - 1; i > 0; i--)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        if (preference.OwningPlugin != plugin)
        {
            continue;
        }

        delete preference.Cookie;
        delete preference.Metadata;
        delete preference.ValueCache;

        g_Preferences.Erase(i);
        g_PreferenceMap.Remove(preference.Id);

        Call_OnPreferenceDeleted(preference.Id);

        disposedCount++;
    }

    return disposedCount;
}

Handle CreatePreferenceThisParam(const char id[MHUD_MAX_ID], Handle plugin)
{
    Preference preference;
    GetPreferenceById(id, preference);

    StringMap thisParam = new StringMap();
    thisParam.SetString("id", id);
    thisParam.SetValue("valueCache", preference.ValueCache);

    Handle cloned = CloneHandle(thisParam, plugin);

    delete thisParam;
    return cloned;
}

void RegisterPreference(
    char id[MHUD_MAX_ID],
    char name[MHUD_MAX_NAME],
    char defaultValue[MHUD_MAX_VALUE],
    Handle callingPlugin
) {
    char cookieId[30];
    Format(cookieId, sizeof(cookieId), "mhud3_%s", id);

    Cookie cookie = new Cookie(cookieId, "MovementHUD preference", CookieAccess_Private);

    GetPreferenceDefault(id, defaultValue);

    Preference preference;
    preference.Id = id;
    preference.Name = name;
    preference.Metadata = new StringMap();
    preference.ValueCache = new StringMap();
    preference.DefaultValue = defaultValue;
    preference.Cookie = cookie;
    preference.OwningPlugin = callingPlugin;

    g_Preferences.PushArray(preference);
    g_PreferenceMap.SetArray(id, preference, sizeof(preference));

    SetPreferenceDefault(preference);
    HookPreferenceCommand(preference);

    Call_OnPreferenceCreated(preference.Id);
}

bool HasPreference(const char[] id)
{
    Preference preference;
    return GetPreferenceById(id, preference);
}

bool GetPreferenceById(const char[] id, Preference foundPreference)
{
    return g_PreferenceMap.GetArray(id, foundPreference, sizeof(foundPreference));
}

bool GetPreferenceByThisParam(StringMap thisParam, Preference foundPreference)
{
    char id[MHUD_MAX_ID];
    thisParam.GetString("id", id, sizeof(id));

    return GetPreferenceById(id, foundPreference);
}

void GetPreferenceValue(int client, Preference preference, char buffer[MHUD_MAX_VALUE])
{
    char value[MHUD_MAX_VALUE];
    preference.Cookie.Get(client, value, sizeof(value));

    buffer = !StrEqual(value, "")
        ? value
        : preference.DefaultValue;

    SetPreferenceValueCache(client, preference, buffer);
}

void GetPreferenceFormat(bool stripColors, Preference preference, char[] buffer, int maxlength)
{
    bool exists = preference.Metadata.GetString("format", buffer, maxlength);
    if (!exists)
    {
        Format(buffer, maxlength, "<\x03value\x01>");
    }

    if (stripColors)
    {
        StripColorBytes(buffer, maxlength);
    }
}

bool SetPreferenceValue(int client, Preference preference, char[] value)
{
    char buffer[MHUD_MAX_VALUE];

    bool hasCapability = Call_InputHandler(client, preference, value, buffer);
    if (!hasCapability)
    {
        return false;
    }

    preference.Cookie.Set(client, buffer);

    SetPreferenceValueCache(client, preference, buffer);
    return true;
}

bool SavePreference(Preference newPreference)
{
    int indexInArr = -1;
    for (int i = 0; i < g_Preferences.Length; i++)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        if (StrEqual(preference.Id, newPreference.Id))
        {
            indexInArr = i;
            break;
        }
    }

    if (indexInArr == -1)
    {
        return false;
    }

    g_Preferences.SetArray(indexInArr, newPreference);
    g_PreferenceMap.SetArray(newPreference.Id, newPreference, sizeof(newPreference));
    return true;
}

void PrintChangeMessage(int client, Preference preference)
{
    char value[MHUD_MAX_VALUE];
    GetPreferenceValue(client, preference, value);

    char display[128];
    Call_DisplayHandler(client, preference, display, sizeof(display));

    MHud_PrintToChat(client, "\x05%s\x01 has been set to: \x03%s\x01 (\x0C%s\x01)", preference.Name, value, display);
}

bool Call_InputHandler(int client, Preference preference, char[] input, char buffer[MHUD_MAX_VALUE])
{
    if (!IsValidFunctionPointer(preference.InputHandler))
    {
        return false;
    }

    bool result = false;
    Call_StartFunction(preference.OwningPlugin, preference.InputHandler);
    Call_PushCell(client);
    Call_PushString(input);
    Call_PushStringEx(buffer, sizeof(buffer), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(preference.Metadata);
    Call_Finish(result);

    return result;
}

bool Call_DisplayHandler(int client, Preference preference, char[] value, int maxlength)
{
    if (!IsValidFunctionPointer(preference.DisplayHandler))
    {
        return false;
    }

    bool result = false;
    Call_StartFunction(preference.OwningPlugin, preference.DisplayHandler);
    Call_PushCell(client);
    Call_PushStringEx(value, maxlength, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(maxlength);
    Call_PushCell(preference.Metadata);
    Call_Finish(result);

    return result;
}

bool Call_GetNextHandler(int client, Preference preference, char buffer[MHUD_MAX_VALUE])
{
    if (!IsValidFunctionPointer(preference.GetNextHandler))
    {
        return false;
    }

    bool result = false;
    Call_StartFunction(preference.OwningPlugin, preference.GetNextHandler);
    Call_PushCell(client);
    Call_PushStringEx(buffer, sizeof(buffer), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(preference.Metadata);
    Call_Finish(result);

    return result;
}

// =====[ HELPERS ]=====

static bool IsValidFunctionPointer(Function func)
{
	/*
		The below "!!func" equals to "!(func == null)".
		In other words, "not null" (0), this is a HACK.
		You cannot directly compare "Function" type to "null".

		The reason we do this is because enum structs zero (0) inits
		all of it's members by default, and "INVALID_FUNCTION" is "-1".
		Simply checking for "INVALID_FUNCTION" would not be sufficient.

		This is the case as of spcomp 1.10.0.6460.
		See: https://github.com/alliedmodders/sourcepawn/issues/469.
	*/
	return (!!func && func != INVALID_FUNCTION);
}

static void SetPreferenceValueCache(int client, Preference preference, char value[MHUD_MAX_VALUE])
{
    char szClientIdx[12];
    IntToString(client, szClientIdx, sizeof(szClientIdx));

    preference.ValueCache.SetString(szClientIdx, value);

    // TODO: Would the users care about the old value?
    // This forward doesn't necessarily mean that the value changed
    // We can go from value 1 -> value 1, this is still a "set" being done
    Call_OnPreferenceValueSet(client, preference.Id, value);
}

static void InvalidatePreferencesValueCache(int client)
{
    char szClientIdx[12];
    IntToString(client, szClientIdx, sizeof(szClientIdx));

    for (int i = 0; i < g_Preferences.Length; i++)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        preference.ValueCache.Remove(szClientIdx);
    }
}
