static int CurrentRevision = 3;
static ArrayList PreferencesInCode;

void OnPluginStart_PreferencesCode()
{
    PreferencesInCode = new ArrayList();

    /*
        This is the order that the preferences are going to be serialized.
        The preference code format expects preference values to be sequential.
        The order of preferences are VERY important to maintain backwards compat.
    */
    PreferencesInCode.Push(SpeedMode);
    PreferencesInCode.Push(SpeedPosition);
    PreferencesInCode.Push(SpeedNormalColor);
    PreferencesInCode.Push(SpeedPerfColor);
    PreferencesInCode.Push(KeysMode);
    PreferencesInCode.Push(KeysPosition);
    PreferencesInCode.Push(KeysNormalColor);
    PreferencesInCode.Push(KeysOverlapColor);
    PreferencesInCode.Push(KeysMouseDirection);

    // Revision 3
    PreferencesInCode.Push(SpeedTakeoff);
    PreferencesInCode.Push(SpeedColorBySpeed);
    PreferencesInCode.Push(KeysColorBySpeed);
    PreferencesInCode.Push(IndicatorsColor);
    PreferencesInCode.Push(IndicatorsPosition);
    PreferencesInCode.Push(IndicatorsJBEnabled);
    PreferencesInCode.Push(IndicatorsCJEnabled);
    PreferencesInCode.Push(IndicatorsPBEnabled);
}

void GeneratePreferencesCode(int client, char[] buffer, int maxlength)
{
    JSON_Array hData = new JSON_Array(JSON_Type_String);

    for (int i = 0; i < PreferencesInCode.Length; i++)
    {
        MHudPreference preference = PreferencesInCode.Get(i);

        char value[MHUD_MAX_VALUE];
        preference.GetValue(client, value);

        hData.PushString(value);
    }

    JSON_Object hObj = new JSON_Object();
    hObj.SetInt("rev", CurrentRevision);
    hObj.SetObject("data", hData);

    char json[256];
    hObj.Encode(json, sizeof(json));

    EncodeBase64(buffer, maxlength, json);
    json_cleanup_and_delete(hObj);
}

bool LoadFromPreferencesCode(int client, const char[] code)
{
    char json[256];
    DecodeBase64(json, sizeof(json), code);

    JSON_Object hObj = json_decode(json);
    if (hObj == null)
    {
        return false;
    }

    int revision = hObj.GetInt("rev");
    if (revision <= 0 || revision > CurrentRevision)
    {
        json_cleanup_and_delete(hObj);
        return false;
    }

    JSON_Array hData = view_as<JSON_Array>(hObj.GetObject("data"));
    if (hData == null)
    {
        json_cleanup_and_delete(hObj);
        return false;
    }

    int len = MHud_ClampInt(hData.Length, 0, PreferencesInCode.Length);

    for (int i = 0; i < len; i++)
    {
        JSONCellType type = hData.GetType(i);
        if (type != JSON_Type_String)
        {
            json_cleanup_and_delete(hObj);
            return false;
        }

        MHudPreference preference = PreferencesInCode.Get(i);

        char value[MHUD_MAX_VALUE];
        hData.GetString(i, value, sizeof(value));

        if (revision <= 2)
        {
            TransformOldPosition(preference, value);
        }

        preference.SetValue(client, value);
    }

    json_cleanup_and_delete(hObj);
    return true;
}

/*
    Backwards compat helper for older preference codes.
    Transforms a position preference from older format, examples:
        "-1.0 -1.0" into "-1 -1"
        "0.33 0.25" into "333 250"
        "0.75 0.10" into "750 100"
        "1.00 -1.0" into "1000 -1"
*/
static void TransformOldPosition(MHudPreference preference, char buffer[MHUD_MAX_VALUE])
{
    if (preference == KeysPosition || preference == SpeedPosition)
    {
        char entries[2][6];
        ExplodeString(buffer, " ", entries, sizeof(entries), sizeof(entries[]));

        float x = StringToFloat(entries[0]);
        float y = StringToFloat(entries[1]);

        int xAsInt = MHud_CloseEnough(x, -1.0) ? -1 : RoundFloat(x * 1000);
        int yAsInt = MHud_CloseEnough(y, -1.0) ? -1 : RoundFloat(y * 1000);

        Format(buffer, sizeof(buffer), "%d %d", xAsInt, yAsInt);
    }
}
