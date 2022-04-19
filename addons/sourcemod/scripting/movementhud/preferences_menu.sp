static bool gB_InAdvMode[MAXPLAYERS + 1];
static bool gB_FromMainMenu[MAXPLAYERS + 1];

void OnClientPutInServer_PreferencesMenu(int client)
{
    gB_InAdvMode[client] = false;
    gB_FromMainMenu[client] = false;
}

void DisplayMainMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Main);
    menu.SetTitle("MovementHUD %.20s\n%s\n ", MHUD_VERSION, MHUD_SOURCE_URL);

    menu.AddItem("1", "Simple preferences");
    menu.AddItem("2", "Advanced preferences");
    //menu.AddItem("3", "Preferences helpers & tools");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayPreferencesMenu(int client, bool advanced, bool fromMainMenu = false, int displayAt = 0)
{
    gB_InAdvMode[client] = advanced;
    gB_FromMainMenu[client] = fromMainMenu;

    Menu menu = new Menu(MenuHandler_Preferences);
    menu.SetTitle("MovementHUD %.20s\n%s\n ", MHUD_VERSION, MHUD_SOURCE_URL);

    for (int i = 0; i < g_Preferences.Length; i++)
    {
        Preference preference;
        g_Preferences.GetArray(i, preference);

        char display[256];

        // Show raw values if in custom mode
        if (advanced)
        {
            char value[MHUD_MAX_VALUE];
            GetPreferenceValue(client, preference, value);

            Format(display, sizeof(display), "%s: %s", preference.Name, value);
        }
        else
        {
            bool hasCapability = Call_DisplayHandler(client, preference, display, sizeof(display));
            if (!hasCapability)
            {
                continue;
            }

            Format(display, sizeof(display), "%s: %s", preference.Name, display);
        }

        bool isCorePreference = preference.OwningPlugin == GetMyHandle();
        if (!isCorePreference)
        {
            Format(display, sizeof(display), "[Third-Party] %s", display);
        }

        menu.AddItem(preference.Id, display);
    }

    menu.ExitButton = true;
    menu.ExitBackButton = fromMainMenu;
    menu.DisplayAt(client, displayAt, MENU_TIME_FOREVER);
}

void RedisplayPreferencesMenu(int client, int displayAt = 0)
{
    DisplayPreferencesMenu(client, gB_InAdvMode[client], gB_FromMainMenu[client], displayAt);
}

public int MenuHandler_Main(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char selection[2];
        menu.GetItem(param2, selection, sizeof(selection));

        bool advanced = selection[0] == '2';
        DisplayPreferencesMenu(param1, advanced, true);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

public int MenuHandler_Preferences(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char id[MHUD_MAX_ID];
        menu.GetItem(param2, id, sizeof(id));

        Preference preference;

        bool found = GetPreferenceById(id, preference);
        if (!found)
        {
            return;
        }

        if (gB_InAdvMode[param1])
        {
            WaitForPreferenceChatInputFromClient(param1, id, menu.Selection);
            return;
        }

        char value[MHUD_MAX_VALUE];

        bool hasCapability = Call_GetNextHandler(param1, preference, value);
        if (hasCapability)
        {
            SetPreferenceValue(param1, preference, value);
        }

        RedisplayPreferencesMenu(param1, menu.Selection);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        DisplayMainMenu(param1);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
