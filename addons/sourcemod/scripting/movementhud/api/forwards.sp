static GlobalForward OnReady;

static GlobalForward OnDrawKeys;
static GlobalForward OnDrawSpeed;
static GlobalForward OnDrawIndicators;

static GlobalForward OnPreferenceCreated;
static GlobalForward OnPreferenceDeleted;
static GlobalForward OnPreferenceValueSet;

static GlobalForward OnMovementTakeoff;

public void OnAskPluginLoad2_Forwards()
{
    OnReady = new GlobalForward("MHud_OnReady", ET_Ignore);

    OnDrawKeys = new GlobalForward("MHud_OnDrawKeys", ET_Ignore, Param_Cell, Param_Array, Param_Array);
    OnDrawSpeed = new GlobalForward("MHud_OnDrawSpeed", ET_Ignore, Param_Cell, Param_Array, Param_Array);
    OnDrawIndicators = new GlobalForward("MHud_OnDrawIndicators", ET_Ignore, Param_Cell, Param_Array, Param_Array);

    OnPreferenceCreated = new GlobalForward("MHud_OnPreferenceCreated", ET_Single, Param_String);
    OnPreferenceDeleted = new GlobalForward("MHud_OnPreferenceDeleted", ET_Single, Param_String);
    OnPreferenceValueSet = new GlobalForward("MHud_OnPreferenceValueSet", ET_Ignore, Param_Cell, Param_String, Param_String);

    OnMovementTakeoff = new GlobalForward("MHud_Movement_OnTakeoff", ET_Single, Param_Cell, Param_Cell, Param_CellByRef, Param_FloatByRef);
}

// =====[ PUBLIC ]=====

void Call_OnReady()
{
    Call_StartForward(OnReady);
    Call_Finish();
}

void Call_OnDrawKeys(int client, float pos[2], int color[3])
{
    Call_StartForward(OnDrawKeys);
    Call_PushCell(client);
    Call_PushArrayEx(pos, sizeof(pos), SM_PARAM_COPYBACK);
    Call_PushArrayEx(color, sizeof(color), SM_PARAM_COPYBACK);
    Call_Finish();
}

void Call_OnDrawSpeed(int client, float pos[2], int color[3])
{
    Call_StartForward(OnDrawSpeed);
    Call_PushCell(client);
    Call_PushArrayEx(pos, sizeof(pos), SM_PARAM_COPYBACK);
    Call_PushArrayEx(color, sizeof(color), SM_PARAM_COPYBACK);
    Call_Finish();
}

void Call_OnDrawIndicators(int client, float pos[2], int color[3])
{
    Call_StartForward(OnDrawIndicators);
    Call_PushCell(client);
    Call_PushArrayEx(pos, sizeof(pos), SM_PARAM_COPYBACK);
    Call_PushArrayEx(color, sizeof(color), SM_PARAM_COPYBACK);
    Call_Finish();
}

void Call_OnMovementTakeoff(int client, bool didJump, bool &didPerf, float &takeoffSpeed)
{
	Call_StartForward(OnMovementTakeoff);
	Call_PushCell(client);
	Call_PushCell(didJump);
	Call_PushCellRef(didPerf);
	Call_PushFloatRef(takeoffSpeed);
	Call_Finish();
}

void Call_OnPreferenceCreated(char id[MHUD_MAX_ID])
{
    Call_StartForward(OnPreferenceCreated);
    Call_PushString(id);
    Call_Finish();
}

void Call_OnPreferenceDeleted(char id[MHUD_MAX_ID])
{
    Call_StartForward(OnPreferenceDeleted);
    Call_PushString(id);
    Call_Finish();
}

void Call_OnPreferenceValueSet(int client, char id[MHUD_MAX_ID], char value[MHUD_MAX_VALUE])
{
    Call_StartForward(OnPreferenceValueSet);
    Call_PushCell(client);
    Call_PushString(id);
    Call_PushString(value);
    Call_Finish();
}
