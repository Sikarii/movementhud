static Handle HudSync;

MHudEnumPreference SpeedMode;
MHudXYPreference SpeedPosition;
MHudRGBPreference SpeedNormalColor;
MHudRGBPreference SpeedPerfColor;
MHudBoolPreference SpeedTakeoff;
MHudBoolPreference SpeedColorBySpeed;

static const char Modes[SpeedMode_COUNT][] =
{
    "Disabled",
    "As decimal",
    "As whole number"
};

void OnPluginStart_Element_Speed()
{
    HudSync = CreateHudSynchronizer();

    SpeedMode = new MHudEnumPreference("speed_mode", "Speed - Mode", Modes, sizeof(Modes) - 1, SpeedMode_None);
    SpeedPosition = new MHudXYPreference("speed_position", "Speed - Position", -1, 725);
    SpeedNormalColor = new MHudRGBPreference("speed_color_normal", "Speed - Normal Color", 255, 255, 255);
    SpeedPerfColor = new MHudRGBPreference("speed_color_perf", "Speed - Perfect Bhop Color", 0, 255, 0);
    SpeedTakeoff = new MHudBoolPreference("speed_takeoff", "Speed - Show Takeoff", true);
    SpeedColorBySpeed = new MHudBoolPreference("speed_color_by_speed", "Speed - Color by Speed", false);
}

void OnPlayerRunCmdPost_Element_Speed(int client, int target)
{
    int mode = SpeedMode.GetInt(client);
    if (mode == SpeedMode_None)
    {
        return;
    }

    float speed = gF_CurrentSpeed[target];

    bool showTakeoff = SpeedTakeoff.GetBool(client);
    bool colorBySpeed = SpeedColorBySpeed.GetBool(client);

    float xy[2];
    SpeedPosition.GetXY(client, xy);

    int rgb[3];
    if (!colorBySpeed)
    {
        MHudRGBPreference colorPreference = gB_DidPerf[target]
            ? SpeedPerfColor
            : SpeedNormalColor;

        colorPreference.GetRGB(client, rgb);
    }
    else
    {
        GetColorBySpeed(speed, rgb);
    }

    Call_OnDrawSpeed(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], 0.5, rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    if (mode == SpeedMode_Float)
    {
        if (!showTakeoff || !gB_DidTakeoff[target])
        {
            ShowSyncHudText(client, HudSync, "%.2f", speed);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%.2f\n(%.2f)", speed, gF_TakeoffSpeed[target]);
        }
    }
    else
    {
        int speedInt = RoundFloat(speed);
        if (!showTakeoff || !gB_DidTakeoff[target])
        {
            ShowSyncHudText(client, HudSync, "%d", speedInt);
        }
        else
        {
            ShowSyncHudText(client, HudSync, "%d\n(%d)", speedInt, RoundFloat(gF_TakeoffSpeed[target]));
        }
    }
}
