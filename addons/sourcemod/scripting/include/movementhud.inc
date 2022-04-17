#if defined _MovementHUD_included_
#endinput
#endif
#define _MovementHUD_included_

// =====[ TYPES ]=====

#define MHUD_MAX_ID 24
#define MHUD_MAX_NAME 64
#define MHUD_MAX_VALUE 100

#define MHUD_TAG_RAW "[MovementHUD]"
#define MHUD_TAG_COLOR "[\x0CMovementHUD\x01]"

#define MHUD_VERSION "3.0.0"
#define MHUD_SOURCE_URL "https://github.com/Sikarii/MovementHUD"

typeset MHudPreferenceInputHandler
{
    function bool (int client, const char[] input, char buffer[MHUD_MAX_VALUE]);
    function bool (int client, const char[] input, char buffer[MHUD_MAX_VALUE], StringMap metadata);
};

typeset MHudPreferenceDisplayHandler
{
    function bool (int client, char[] buffer, int maxlength);
    function bool (int client, char[] buffer, int maxlength, StringMap metadata);
};

typeset MHudPreferenceGetNextHandler
{
    function bool (int client, char buffer[MHUD_MAX_VALUE]);
    function bool (int client, char buffer[MHUD_MAX_VALUE], StringMap metadata);
};

// =====[ FORWARDS ]=====

/**
 * Called when MovementHUD is ready.
 */
forward void MHud_OnReady();

/**
 * Called when keys are about to be drawn.
 *
 * @param client            Client index.
 * @param position          Position (x, y) of the hud (by reference).
 * @param color             Color (r, g, b) of the hud (by reference).
 */
forward void MHud_OnDrawKeys(int client, float position[2], int color[3]);

/**
 * Called when speed is about to be drawn.
 *
 * @param client            Client index.
 * @param position          Position (x, y) of the hud (by reference).
 * @param color             Color (r, g, b) of the hud (by reference).
 */
forward void MHud_OnDrawSpeed(int client, float position[2], int color[3]);

/**
 * Called when indicators are about to be drawn.
 *
 * @param client            Client index.
 * @param position          Position (x, y) of the hud (by reference).
 * @param color             Color (r, g, b) of the hud (by reference).
 */
forward void MHud_OnDrawIndicators(int client, float position[2], int color[3]);

/**
 * Called when a preference is created.
 *
 * @param id                Id of the created preference.
 */
forward void MHud_OnPreferenceCreated(char id[MHUD_MAX_ID]);

/**
 * Called when a preference is deleted.
 *
 * @param id                Id of the deleted preference.
 */
forward void MHud_OnPreferenceDeleted(char id[MHUD_MAX_ID]);

/**
 * Called when a preference is created.
 *
 * @param client            Client index of the player whose value was set.
 * @param id                Id of the preference that the value was set on.
 * @param value             The value that was set to the preference.
 */
forward void MHud_OnPreferenceValueSet(int client, char id[MHUD_MAX_ID], char value[MHUD_MAX_VALUE]);

// =====[ NATIVES ]=====

/**
 * Gets the ready status of MovementHUD.
 *
 * @return                  True if MovementHUD is ready, false otherwise.
 */
native bool MHud_IsReady();

/**
 * Disposes resources of the calling plugin.
 * NOTE: This will most likely be gone when SourceMod 1.11 lands.
 *
 * @return                  Amount of resources disposed.
 */
native int MHud_DisposeResources();

// =====[ METHODMAP ]=====

methodmap MHudPreference < Handle
{
    property StringMap Super
    {
        public get()
        {
            return view_as<StringMap>(this);
        }
    }

    public static native MHudPreference Find(char id[MHUD_MAX_ID]);

    public static native MHudPreference Create(
        char id[MHUD_MAX_ID],
        char name[MHUD_MAX_NAME],
        char defaultValue[MHUD_MAX_VALUE]
    );

    public native bool GetId(char[] buffer, int maxlength);
    public native bool GetName(char[] buffer, int maxlength);

    public native bool GetValueEx(int client, char buffer[MHUD_MAX_VALUE]);

    public native MHudPreference WithMetadata(char[] key, char[] value);
    public native MHudPreference WithMetadataCell(char[] key, any value);

    public native MHudPreference HandleInput(MHudPreferenceInputHandler handler);
    public native MHudPreference HandleDisplay(MHudPreferenceDisplayHandler handler);
    public native MHudPreference HandleGetNext(MHudPreferenceGetNextHandler handler);

    public native bool SetValue(int client, char value[MHUD_MAX_VALUE]);

    public bool GetValue(int client, char buffer[MHUD_MAX_VALUE])
    {
        StringMap valueCache;
        this.Super.GetValue("valueCache", valueCache);

        char szClientIdx[12];
        IntToString(client, szClientIdx, sizeof(szClientIdx));

        char value[MHUD_MAX_VALUE];
        bool hasCache = valueCache.GetString(szClientIdx, value, sizeof(value));

        if (!hasCache)
        {
            // This will set the cached value
            return this.GetValueEx(client, buffer);
        }

        buffer = value;
        return true;
    }
}

// =====[ STOCKS ]=====

stock void MHud_PrintToChat(int client, const char[] format, any ...)
{
    char buffer[256];
    VFormat(buffer, sizeof(buffer), format, 3);

    SetGlobalTransTarget(client);
    PrintToChat(client, "%s %s", MHUD_TAG_COLOR, buffer);
}

// =====[ HANDLERS ]=====

#tryinclude <movementhud/helpers>
#tryinclude <movementhud/builtins>
#tryinclude <movementhud/preference-xy>
#tryinclude <movementhud/preference-rgb>
#tryinclude <movementhud/preference-bool>
#tryinclude <movementhud/preference-enum>

// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_MovementHUD =
{
    name = "MovementHUD",
    file = "movementhud.smx",
    #if defined REQUIRE_PLUGIN
    required = 1,
    #else
    required = 0,
    #endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_MovementHUD_SetNTVOptional()
{
    MarkNativeAsOptional("MHud_IsReady");
    MarkNativeAsOptional("MHud_DisposeResources");

    MarkNativeAsOptional("MHudPreference.Find");
    MarkNativeAsOptional("MHudPreference.Create");
    MarkNativeAsOptional("MHudPreference.HandleInput");
    MarkNativeAsOptional("MHudPreference.HandleDisplay");
    MarkNativeAsOptional("MHudPreference.HandleGetNext");

    MarkNativeAsOptional("MHudPreference.GetId");
    MarkNativeAsOptional("MHudPreference.GetName");

    MarkNativeAsOptional("MHudPreference.GetValueEx");
    MarkNativeAsOptional("MHudPreference.SetValue");

    MarkNativeAsOptional("MHudPreference.WithMetadata");
    MarkNativeAsOptional("MHudPreference.WithMetadataCell");
}
#endif
