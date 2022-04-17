methodmap MHudEnumPreference < MHudPreference
{
    public MHudEnumPreference(
        char id[MHUD_MAX_ID],
        char name[MHUD_MAX_NAME],
        const char[][] values,
        int numValues,
        int defaultInt
    ) {
        char defaultVal[MHUD_MAX_VALUE];
        IntToString(defaultInt, defaultVal, sizeof(defaultVal));

        char format[64];
        Format(format, sizeof(format), "<\x030-%d\x01>", numValues);

        MHudPreference preference = MHudPreference.Create(id, name, defaultVal);

        for (int i = 0; i <= numValues; i++)
        {
            char szKey[64];
            Format(szKey, sizeof(szKey), "values[%d]", i);

            preference.WithMetadata(szKey, values[i]);
        }

        return view_as<MHudEnumPreference>(
            preference
                .WithMetadata("type", "enum")
                .WithMetadata("format", format)
                .WithMetadataCell("max", numValues)
                .WithMetadataCell("self", preference)
                .HandleInput(MHud_Enum_InputHandler)
                .HandleDisplay(MHud_Enum_DisplayHandler)
                .HandleGetNext(MHud_Enum_GetNextHandler)
        );
    }

    public int GetInt(int client)
    {
        char value[MHUD_MAX_VALUE];
        this.GetValue(client, value);

        return StringToInt(value);
    }

    public void SetInt(int client, int value)
    {
        char buffer[MHUD_MAX_VALUE];
        IntToString(value, buffer, sizeof(buffer));

        this.SetValue(client, buffer);
    }

    public static MHudEnumPreference Find(char id[MHUD_MAX_ID])
    {
        return view_as<MHudEnumPreference>(MHudPreference.Find(id));
    }
}

public bool MHud_Enum_InputHandler(int client, char[] input, char buffer[MHUD_MAX_VALUE], StringMap metadata)
{
    int max;
    metadata.GetValue("max", max);

    int value = StringToInt(input);
    int clamped = MHud_ClampInt(value, 0, max);

    IntToString(clamped, buffer, sizeof(buffer));
    return true;
}

public bool MHud_Enum_DisplayHandler(int client, char[] buffer, int maxlength, StringMap metadata)
{
    MHudEnumPreference preference;
    metadata.GetValue("self", preference);

    int value = preference.GetInt(client);

    char szKey[64];
    Format(szKey, sizeof(szKey), "values[%d]", value);

    metadata.GetString(szKey, buffer, maxlength);
    return true;
}

public bool MHud_Enum_GetNextHandler(int client, char buffer[MHUD_MAX_VALUE], StringMap metadata)
{
    int max = 0;
    metadata.GetValue("max", max);

    MHudEnumPreference preference;
    metadata.GetValue("self", preference);

    int value = preference.GetInt(client);
    int nextValue = MHud_ClampInt(value + 1, 0, max, true);

    IntToString(nextValue, buffer, sizeof(buffer));
    return true;
}
