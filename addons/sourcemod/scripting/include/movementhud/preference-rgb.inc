// =====[ HELPERS ]=====

static char RGBMapping[][][] =
{
	{ "255 0 0", "Red" },
	{ "0 255 0", "Green" },
	{ "150 255 0", "Lime" },
	{ "0 0 255", "Blue" },
	{ "0 255 255", "Cyan" },
	{ "255 215 0", "Yellow" },
	{ "255 165 0", "Orange" },
	{ "128 0 128", "Purple" },
	{ "255 255 255", "White" },
	{ "0 0 0", "Black" },
	{ "128 128 128", "Gray" }
};

static void StringToRGB(const char[] str, int rgb[3])
{
    char entries[3][4];
    ExplodeString(str, " ", entries, sizeof(entries), sizeof(entries[]));

    rgb[0] = MHud_ClampInt(StringToInt(entries[0]), 0, 255);
    rgb[1] = MHud_ClampInt(StringToInt(entries[1]), 0, 255);
    rgb[2] = MHud_ClampInt(StringToInt(entries[2]), 0, 255);
}

// =====[ IMPLEMENTATION ]=====

methodmap MHudRGBPreference < MHudPreference
{
    public MHudRGBPreference(
        char id[MHUD_MAX_ID],
        char name[MHUD_MAX_NAME],
        int defaultR,
        int defaultG,
        int defaultB
    ) {
        char defaultVal[MHUD_MAX_VALUE];
        Format(defaultVal, sizeof(defaultVal), "%d %d %d", defaultR, defaultG, defaultB);

        MHudPreference preference = MHudPreference.Create(id, name, defaultVal);

        return view_as<MHudRGBPreference>(
            preference
                .WithMetadata("type", "rgb")
                .WithMetadata("format", "<\x070-255\x01> <\x040-255\x01> <\x0C0-255\x01>")
                .WithMetadataCell("self", preference)
                .HandleInput(MHud_RGB_InputHandler)
                .HandleDisplay(MHud_RGB_DisplayHandler)
                .HandleGetNext(MHud_RGB_GetNextHandler)
        );
    }

    public void GetRGB(int client, int rgb[3])
    {
        char value[MHUD_MAX_VALUE];
        this.GetValue(client, value);

        StringToRGB(value, rgb);
    }

    public void SetRGB(int client, int rgb[3])
    {
        char buffer[MHUD_MAX_VALUE];
        Format(buffer, sizeof(buffer), "%d %d %d", rgb[0], rgb[1], rgb[2]);

        this.SetValue(client, buffer);
    }

    public static MHudRGBPreference Find(char id[MHUD_MAX_ID])
    {
        return view_as<MHudRGBPreference>(MHudPreference.Find(id));
    }
}

public bool MHud_RGB_InputHandler(int client, char[] input, char buffer[MHUD_MAX_VALUE])
{
    int rgb[3];
    StringToRGB(input, rgb);

    Format(buffer, sizeof(buffer), "%d %d %d", rgb[0], rgb[1], rgb[2]);
    return true;
}

public bool MHud_RGB_DisplayHandler(int client, char[] buffer, int maxlength, StringMap metadata)
{
    MHudPreference preference;
    metadata.GetValue("self", preference);

    char value[MHUD_MAX_VALUE];
    preference.GetValue(client, value);

    int currentIndex = MHud_GetCurrentPresetIndex(value, RGBMapping, sizeof(RGBMapping));
    if (currentIndex == -1)
    {
        Format(buffer, maxlength, "Custom");
        return true;
    }

    Format(buffer, maxlength, "%s", RGBMapping[currentIndex][1]);
    return true;
}

public bool MHud_RGB_GetNextHandler(int client, char buffer[MHUD_MAX_VALUE], StringMap metadata)
{
    MHudPreference preference;
    metadata.GetValue("self", preference);

    char value[MHUD_MAX_VALUE];
    preference.GetValue(client, value);

    int nextIndex = MHud_GetNextPresetIndex(value, RGBMapping, sizeof(RGBMapping));

    Format(buffer, sizeof(buffer), "%s", RGBMapping[nextIndex][0]);
    return true;
}
