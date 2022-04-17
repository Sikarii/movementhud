// =====[ HELPERS ]=====

static char XYMapping[][][] =
{
	{ "-1 900", "Bottom" },
	{ "100 900", "Bottom left" },
	{ "660 900", "Bottom right" },
	{ "-1 700", "Middle" },
	{ "100 700", "Middle left" },
	{ "660 700", "Middle right" },
	{ "-1 100", "Top" },
	{ "100 100", "Top left" },
	{ "660 100", "Top right" }
};

static void StringToXY(const char[] str, int xy[2])
{
    char entries[2][4];
    ExplodeString(str, " ", entries, sizeof(entries), sizeof(entries[]));

    xy[0] = MHud_ClampInt(StringToInt(entries[0]), -1, 1000);
    xy[1] = MHud_ClampInt(StringToInt(entries[1]), -1, 1000);
}

// =====[ IMPLEMENTATION ]=====

methodmap MHudXYPreference < MHudPreference
{
    public MHudXYPreference(
        char id[MHUD_MAX_ID],
        char name[MHUD_MAX_NAME],
        int defaultX,
        int defaultY
    ) {
        char defaultVal[MHUD_MAX_VALUE];
        Format(defaultVal, sizeof(defaultVal), "%d %d", defaultX, defaultY);

        MHudPreference preference = MHudPreference.Create(id, name, defaultVal);

        return view_as<MHudXYPreference>(
            preference
                .WithMetadata("type", "xy")
                .WithMetadata("format", "<\x03-1 to 1000\x01> <\x03-1 to 1000\x01>")
                .WithMetadataCell("self", preference)
                .HandleInput(MHud_XY_InputHandler)
                .HandleDisplay(MHud_XY_DisplayHandler)
                .HandleGetNext(MHud_XY_GetNextHandler)
        );
    }

    public void GetXY(int client, float xy[2])
    {
        char value[MHUD_MAX_VALUE];
        this.GetValue(client, value);

        int xyAsInt[2];
        StringToXY(value, xyAsInt);

        xy[0] = xyAsInt[0] == -1 ? -1.00 : xyAsInt[0] / 1000.0;
        xy[1] = xyAsInt[1] == -1 ? -1.00 : xyAsInt[1] / 1000.0;
    }

    public void SetXY(int client, int xy[2])
    {
        char buffer[MHUD_MAX_VALUE];
        Format(buffer, sizeof(buffer), "%d %d", xy[0], xy[1]);

        this.SetValue(client, buffer);
    }

    public static MHudXYPreference Find(char id[MHUD_MAX_ID])
    {
        return view_as<MHudXYPreference>(MHudPreference.Find(id));
    }
}

public bool MHud_XY_InputHandler(int client, char[] input, char buffer[MHUD_MAX_VALUE])
{
    int xy[2];
    StringToXY(input, xy);

    Format(buffer, sizeof(buffer), "%d %d", xy[0], xy[1]);
    return true;
}

public bool MHud_XY_DisplayHandler(int client, char[] buffer, int maxlength, StringMap metadata)
{
    MHudPreference preference;
    metadata.GetValue("self", preference);

    char value[MHUD_MAX_VALUE];
    preference.GetValue(client, value);

    int currentIndex = MHud_GetCurrentPresetIndex(value, XYMapping, sizeof(XYMapping));
    if (currentIndex == -1)
    {
        Format(buffer, maxlength, "Custom");
        return true;
    }

    Format(buffer, maxlength, "%s", XYMapping[currentIndex][1]);
    return true;
}

public bool MHud_XY_GetNextHandler(int client, char buffer[MHUD_MAX_VALUE], StringMap metadata)
{
    MHudPreference preference;
    metadata.GetValue("self", preference);

    char value[MHUD_MAX_VALUE];
    preference.GetValue(client, value);

    int nextIndex = MHud_GetNextPresetIndex(value, XYMapping, sizeof(XYMapping));

    Format(buffer, sizeof(buffer), "%s", XYMapping[nextIndex][0]);
    return true;
}
