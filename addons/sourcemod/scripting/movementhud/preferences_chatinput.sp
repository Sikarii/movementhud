static Handle InputTimer[MAXPLAYERS + 1];

static int InputMenuSelection[MAXPLAYERS + 1];
static char InputPreferenceId[MAXPLAYERS + 1][MHUD_MAX_ID];

void OnClientPutInServer_PreferencesChatInput(int client)
{
	ResetWaitForPreferenceChatInputFromClient(client);
}

void WaitForPreferenceChatInputFromClient(int client, char preferenceId[MHUD_MAX_ID], int menuSelection = 0)
{
    Preference preference;

    bool found = GetPreferenceById(preferenceId, preference);
    if (!found)
    {
        return;
    }

    InputTimer[client] = CreateTimeoutTimer(client);
    InputPreferenceId[client] = preferenceId;
    InputMenuSelection[client] = menuSelection;

    char format[64];
    GetPreferenceFormat(false, preference, format, sizeof(format));

    MHud_PrintToChat(client, "Enter a \x03value\x01 for \x05%s\x01 in the chat", preference.Name);
    MHud_PrintToChat(client, "Value format: %s", format);
    MHud_PrintToChat(client, "Available custom inputs: \x03cancel\x01, \x03reset\x01");
}

static Handle CreateTimeoutTimer(int client)
{
    ResetWaitForPreferenceChatInputFromClient(client);

    int userId = GetClientUserId(client);
    return CreateTimer(15.0, Timer_InputTimeout, userId);
}

public Action Timer_InputTimeout(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientConnected(client))
	{
		MHud_PrintToChat(client, "\x07Input timed out!\x01");
		ResetWaitForPreferenceChatInputFromClient(client, true);
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (InputPreferenceId[client][0] == '\0')
    {
        return Plugin_Continue;
    }

    char inputBuffer[MHUD_MAX_VALUE];
    strcopy(inputBuffer, sizeof(inputBuffer), sArgs);

    TrimString(inputBuffer);

    if (StrEqual(inputBuffer, "cancel", false))
    {
        HandleCancelInput(client);
    }
    else if (StrEqual(inputBuffer, "reset", false))
    {
        HandleResetInput(client, InputPreferenceId[client]);
    }
    else
    {
        HandlePreferenceInput(client, InputPreferenceId[client], inputBuffer);
    }

    RedisplayPreferencesMenu(client, InputMenuSelection[client]);

    ResetWaitForPreferenceChatInputFromClient(client);
    return Plugin_Handled;
}

static void HandleCancelInput(int client)
{
	MHud_PrintToChat(client, "\x07Cancelled input!\x01");
}

static void HandleResetInput(int client, char preferenceId[MHUD_MAX_ID])
{
    Preference preference;

    bool found = GetPreferenceById(preferenceId, preference);
    if (!found)
    {
        return;
    }

    SetPreferenceValue(client, preference, preference.DefaultValue);
    PrintChangeMessage(client, preference);
}

static void HandlePreferenceInput(int client, char preferenceId[MHUD_MAX_ID], char input[MHUD_MAX_VALUE])
{
    Preference preference;

    bool found = GetPreferenceById(preferenceId, preference);
    if (!found)
    {
        return;
    }

    SetPreferenceValue(client, preference, input);
    PrintChangeMessage(client, preference);
}

static void ResetWaitForPreferenceChatInputFromClient(int client, bool fromTimer = false)
{
    InputPreferenceId[client] = "";
    InputMenuSelection[client] = 0;

    if (!fromTimer)
    {
        delete InputTimer[client];
    }
}
