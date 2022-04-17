void OnPluginStart_Commands()
{
    RegConsoleCmd("sm_mhud", Command_MHud);
    RegConsoleCmd("sm_mhud_export", Command_MHud_Export);
    RegConsoleCmd("sm_mhud_import", Command_MHud_Import);

    RegConsoleCmd("sm_mhud_preferences", Command_MHud_Preferences);

    // Backwards compat aliases
    RegConsoleCmd("sm_mhud_settings_export", Command_MHud_Export);
    RegConsoleCmd("sm_mhud_settings_import", Command_MHud_Import);

    RegConsoleCmd("sm_mhud_preferences_export", Command_MHud_Export);
    RegConsoleCmd("sm_mhud_preferences_import", Command_MHud_Import);
}

void HookPreferenceCommand(Preference preference)
{
    char cmdName[64];
    Format(cmdName, sizeof(cmdName), "sm_mhud_%s", preference.Id);

    if (!CommandExists(cmdName))
    {
        RegConsoleCmd(cmdName, Command_Preference, "MovementHUD preference command");
    }
}

public Action Command_MHud(int client, int args)
{
    char mode[32];
    GetCmdArg(1, mode, sizeof(mode));

    if (StrEqual(mode, "a")
        || StrEqual(mode, "adv")
        || StrEqual(mode, "advanced")
    ) {
        DisplayPreferencesMenu(client, true);
        return Plugin_Handled;
    }

    if (StrEqual(mode, "s") || StrEqual(mode, "simple"))
    {
        DisplayPreferencesMenu(client, false);
        return Plugin_Handled;
    }

    DisplayMainMenu(client);
    return Plugin_Handled;
}

public Action Command_MHud_Export(int client, int args)
{
    char code[256];
    GeneratePreferencesCode(client, code, sizeof(code));

    PrintToConsole(client, "%s\n", code);
    return Plugin_Handled;
}

public Action Command_MHud_Import(int client, int args)
{
    char code[256];
    GetCmdArgString(code, sizeof(code));

    bool loaded = LoadFromPreferencesCode(client, code);
    if (!loaded)
    {
        MHud_PrintToChat(client, "Failed to load from code");
        return Plugin_Handled;
    }

    MHud_PrintToChat(client, "Successfully imported preferences");
    return Plugin_Handled;
}

public Action Command_MHud_Preferences(int client, int args)
{
    char szPage[16];
    GetCmdArg(1, szPage, sizeof(szPage));

    int entriesPerPage = 10;
    int availablePages = RoundToCeil(g_Preferences.Length / float(entriesPerPage));

    int page = MHud_ClampInt(StringToInt(szPage), 1, availablePages);

    // Slicing
    int cursor = (page - 1) * entriesPerPage;
    int goUntil = MHud_ClampInt(page * entriesPerPage, 0, g_Preferences.Length);

    PrintToConsole(client, "[MovementHUD] Page %d of %d preferences:", page, availablePages);

    for (int i = cursor; i < goUntil; i++)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        PrintToConsole(client, "- sm_mhud_%s (%s)", preference.Id, preference.Name);
    }

    if (page < availablePages)
    {
        char cmdName[64];
        GetCmdArg(0, cmdName, sizeof(cmdName));

        PrintToConsole(client, "* See \"%s %d\" for more preferences", cmdName, page + 1);
    }

    PrintToConsole(client, "");
    return Plugin_Handled;
}

public Action Command_Preference(int client, int args)
{
    char cmdName[64];
    GetCmdArg(0, cmdName, sizeof(cmdName));

    Preference preference;

    bool found = GetPreferenceById(cmdName[8], preference);
    if (!found)
    {
        // Commands cannot be unregistered, so
        // plugins unloaded since registration will end up here
        return Plugin_Handled;
    }

    char szArgs[256];
    GetCmdArgString(szArgs, sizeof(szArgs));

    char action[32];
    int valueIdx = BreakString(szArgs, action, sizeof(action));

    if (StrEqual(action, "get", false))
    {
        HandleGetCommand(client, preference);
        return Plugin_Handled;
    }

    if (StrEqual(action, "set", false))
    {
        HandleSetCommand(client, preference, szArgs[valueIdx]);
        return Plugin_Handled;
    }

    if (StrEqual(action, "info", false))
    {
        HandleInfoCommand(client, preference);
        return Plugin_Handled;
    }

    if (StrEqual(action, "cycle", false))
    {
        HandleCycleCommand(client, preference);
        return Plugin_Handled;
    }

    if (StrEqual(action, "reset", false))
    {
        HandleResetCommand(client, preference);
        return Plugin_Handled;
    }

    char format[64];
    GetPreferenceFormat(true, preference, format, sizeof(format));

    PrintToConsole(client, "%s Usage for %s:", MHUD_TAG_RAW, preference.Name);
    PrintToConsole(client, "- %s get", cmdName);
    PrintToConsole(client, "- %s set %s", cmdName, format);
    PrintToConsole(client, "- %s info", cmdName);
    PrintToConsole(client, "- %s cycle", cmdName);
    PrintToConsole(client, "- %s reset", cmdName);
    return Plugin_Handled;
}

// =====[ PRIVATE ]=====

static void HandleGetCommand(int client, Preference preference)
{
    char value[MHUD_MAX_VALUE];
    GetPreferenceValue(client, preference, value);

    PrintToConsole(client, "%s %s: %s", MHUD_TAG_RAW, preference.Name, value);
}

static void HandleSetCommand(int client, Preference preference, char[] value)
{
    if (GetCmdArgs() <= 1)
    {
        char format[64];
        GetPreferenceFormat(true, preference, format, sizeof(format));

        char cmdName[64];
        GetCmdArg(0, cmdName, sizeof(cmdName));

        PrintToConsole(client, "Usage: %s set %s", cmdName, format);
        return;
    }

    bool isSet = SetPreferenceValue(client, preference, value);
    if (!isSet)
    {
        return;
    }

    PrintChangeMessage(client, preference);
}

static void HandleInfoCommand(int client, Preference preference)
{
    char type[32] = "N/A";
    preference.Metadata.GetString("type", type, sizeof(type));

    char format[64];
    GetPreferenceFormat(true, preference, format, sizeof(format));

    char defaultVal[MHUD_MAX_VALUE];
    GetPreferenceDefault(preference.Id, defaultVal);

    char pluginFile[PLATFORM_MAX_PATH];
    GetPluginFilename(preference.OwningPlugin, pluginFile, sizeof(pluginFile));

    PrintToConsole(client, "%s", MHUD_TAG_RAW);
    PrintToConsole(client, "- Id: %s", preference.Id);
    PrintToConsole(client, "- Name: %s", preference.Name);
    PrintToConsole(client, "- Type: %s", type);
    PrintToConsole(client, "- Format: %s", format);
    PrintToConsole(client, "- Provider: %s", pluginFile);
    PrintToConsole(client, "- Default value: %s", defaultVal);
}

static void HandleCycleCommand(int client, Preference preference)
{
    char value[MHUD_MAX_VALUE];

    bool hasCapability = Call_GetNextHandler(client, preference, value);
    if (!hasCapability)
    {
        return;
    }

    bool isSet = SetPreferenceValue(client, preference, value);
    if (!isSet)
    {
        return;
    }

    PrintChangeMessage(client, preference);
}

static void HandleResetCommand(int client, Preference preference)
{
    // TODO: Param to bypass hooks?
    SetPreferenceValue(client, preference, preference.DefaultValue);
    PrintChangeMessage(client, preference);
}
