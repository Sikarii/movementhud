static Handle HudSync;

MHudRGBPreference IndicatorsColor;
MHudXYPreference IndicatorsPosition;

MHudBoolPreference IndicatorsJBEnabled;
MHudBoolPreference IndicatorsCJEnabled;
MHudBoolPreference IndicatorsPBEnabled;

MHudBoolPreference IndicatorsAbbreviations;

void OnPluginStart_Element_Indicators()
{
    HudSync = CreateHudSynchronizer();

    IndicatorsColor = new MHudRGBPreference("indicators_color", "Indicators - Color", 0, 255, 0);
    IndicatorsPosition = new MHudXYPreference("indicators_position", "Indicators - Position", 550, 725);
    IndicatorsJBEnabled = new MHudBoolPreference("indicators_jb_enabled", "Indicators - Jump Bug", false);
    IndicatorsCJEnabled = new MHudBoolPreference("indicators_cj_enabled", "Indicators - Crouch Jump", false);
    IndicatorsPBEnabled = new MHudBoolPreference("indicators_pb_enabled", "Indicators - Perfect Bhop", false);
    IndicatorsAbbreviations = new MHudBoolPreference("indicators_abbrs", "Indicators - Abbreviations", true);
}

void OnPlayerRunCmdPost_Element_Indicators(int client, int target)
{
    bool drawJB = IndicatorsJBEnabled.GetBool(client);
    bool drawCJ = IndicatorsCJEnabled.GetBool(client);
    bool drawPB = IndicatorsPBEnabled.GetBool(client);

    // Nothing enabled
    if (!drawJB && !drawCJ && !drawPB)
    {
        return;
    }

    int rgb[3];
    IndicatorsColor.GetRGB(client, rgb);

    float xy[2];
    IndicatorsPosition.GetXY(client, xy);

    Call_OnDrawIndicators(client, xy, rgb);
    SetHudTextParams(xy[0], xy[1], 0.5, rgb[0], rgb[1], rgb[2], 255, _, _, 0.0, 0.0);

    bool useAbbr = IndicatorsAbbreviations.GetBool(client);

    char buffer[64];
    if (drawJB && gB_DidJumpBug[target])
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "JB" : "JUMPBUG"
        );
    }

    if (drawCJ && gB_DidCrouchJump[target])
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "CJ" : "CROUCH JUMP"
        );
    }

    if (drawPB && gB_DidPerf[target])
    {
        Format(buffer, sizeof(buffer), "%s%s\n",
            buffer,
            useAbbr ? "PERF" : "PERFECT BHOP"
        );
    }

    ShowSyncHudText(client, HudSync, "%s", buffer);
}
