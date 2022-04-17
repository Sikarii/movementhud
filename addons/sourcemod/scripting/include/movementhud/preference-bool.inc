// =====[ HELPERS ]=====

static char TruthyValues[][] =
{
    "1",
    "on",
    "yes",
    "true",
    "enable",
    "enabled"
};

static bool StringToBool(const char[] str)
{
    for (int i = 0; i < sizeof(TruthyValues); i++)
    {
        if (StrEqual(str, TruthyValues[i]))
        {
            return true;
        }
    }

    return false;
}

// =====[ IMPLEMENTATION ]=====

methodmap MHudBoolPreference < MHudPreference
{
    public MHudBoolPreference(char id[MHUD_MAX_ID], char name[MHUD_MAX_NAME], bool defaultBool)
    {
        char defaultVal[MHUD_MAX_VALUE];
        Format(defaultVal, sizeof(defaultVal), "%d", defaultBool ? 1 : 0);

        MHudPreference preference = MHudPreference.Create(id, name, defaultVal);

        return view_as<MHudBoolPreference>(
            preference
                .WithMetadata("type", "bool")
                .WithMetadata("format", "<\x03true/false\x01>")
                .WithMetadataCell("self", preference)
                .HandleInput(MHud_Bool_InputHandler)
                .HandleDisplay(MHud_Bool_DisplayHandler)
                .HandleGetNext(MHud_Bool_GetNextHandler)
        );
    }

    public bool GetBool(int client)
    {
        char value[MHUD_MAX_VALUE];
        this.GetValue(client, value);

        return StrEqual(value, "1");
    }

    public void SetBool(int client, bool value)
    {
        char buffer[MHUD_MAX_VALUE];
        Format(buffer, sizeof(buffer), "%d", value ? 1 : 0);

        this.SetValue(client, buffer);
    }

    public static MHudBoolPreference Find(char id[MHUD_MAX_ID])
    {
        return view_as<MHudBoolPreference>(MHudPreference.Find(id));
    }
}

public bool MHud_Bool_InputHandler(int client, char[] input, char buffer[MHUD_MAX_VALUE])
{
    bool value = StringToBool(input);

    IntToString(value, buffer, sizeof(buffer));
    return true;
}

public bool MHud_Bool_DisplayHandler(int client, char[] buffer, int maxlength, StringMap metadata)
{
    MHudBoolPreference preference;
    metadata.GetValue("self", preference);

    bool enabled = preference.GetBool(client);

    Format(buffer, maxlength, "%s", enabled ? "Enabled" : "Disabled");
    return true;
}

public bool MHud_Bool_GetNextHandler(int client, char buffer[MHUD_MAX_VALUE], StringMap metadata)
{
    MHudBoolPreference preference;
    metadata.GetValue("self", preference);

    bool value = preference.GetBool(client);

    IntToString(!value, buffer, sizeof(buffer));
    return true;
}
