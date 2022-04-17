static KeyValues configKv;

static char configPath[] = "cfg/sourcemod/movementhud-defaults.cfg";

void OnPluginStart_PreferencesDefaults()
{
    configKv = new KeyValues("MovementHUD-Defaults");
    configKv.ImportFromFile(configPath);
}

bool GetPreferenceDefault(char id[MHUD_MAX_ID], char value[MHUD_MAX_VALUE])
{
    if (!HasDefaultForPreferenceId(id))
    {
        return false;
    }

    configKv.GetString(id, value, sizeof(value));
    return true;
}

void SetPreferenceDefault(Preference preference)
{
    bool exists = HasDefaultForPreferenceId(preference.Id);
    if (exists)
    {
        return;
    }

    configKv.SetString(preference.Id, preference.DefaultValue);
    configKv.ExportToFile(configPath);
}

static bool HasDefaultForPreferenceId(const char id[MHUD_MAX_ID])
{
    bool exists = configKv.JumpToKey(id);
    if (!exists)
    {
        return false;
    }

    configKv.GoBack();
    return true;
}
