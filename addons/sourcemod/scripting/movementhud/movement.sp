int gI_MouseX[MAXPLAYERS + 1];
int gI_Buttons[MAXPLAYERS + 1];
int gI_GroundTicks[MAXPLAYERS + 1];

bool gB_DidJump[MAXPLAYERS + 1];
bool gB_DidPerf[MAXPLAYERS + 1];
bool gB_DidJumpBug[MAXPLAYERS + 1];
bool gB_DidCrouchJump[MAXPLAYERS + 1];

bool gB_DidTakeoff[MAXPLAYERS + 1];
float gF_TakeoffSpeed[MAXPLAYERS + 1];

float gF_CurrentSpeed[MAXPLAYERS + 1];
float gF_LastJumpInput[MAXPLAYERS + 1];

static bool OldOnGround[MAXPLAYERS + 1];
static MoveType OldMoveType[MAXPLAYERS + 1];

// =====[ LISTENERS ]=====

void OnPluginStart_Movement()
{
	HookEvent("player_jump", Event_Jump);
}

void OnClientPutInServer_Movement(int client)
{
    ResetTakeoff(client);

    gI_MouseX[client] = 0;
    gI_Buttons[client] = 0;
    gI_GroundTicks[client] = 0;

    gF_CurrentSpeed[client] = 0.0;
    gF_LastJumpInput[client] = 0.0;

    OldOnGround[client] = false;
    OldMoveType[client] = MOVETYPE_NONE;
}

void OnPlayerRunCmdPost_Movement(int client, int buttons, const int mouse[2])
{
    gI_MouseX[client] = mouse[0];
    gI_Buttons[client] = buttons;
    gF_CurrentSpeed[client] = GetSpeed(client);

    TrackMovement(client);
}

bool JumpedRecently(int client)
{
    return (GetEngineTime() - gF_LastJumpInput[client]) <= 0.10;
}

// =====[ PRIVATE ]=====

public void Event_Jump(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    gB_DidJump[client] = true;
    gB_DidJumpBug[client] = gI_GroundTicks[client] <= 0;
}

static void TrackMovement(int client)
{
    if (IsJumping(client))
    {
        gF_LastJumpInput[client] = GetEngineTime();
    }

    MoveType moveType = GetEntityMoveType(client);

    bool onGround = IsOnGround(client);
    if (onGround)
    {
        ResetTakeoff(client);
        gI_GroundTicks[client]++;
    }
    else
    {
        // Just left a ladder.
        if (moveType != OldMoveType[client]
            && OldMoveType[client] == MOVETYPE_LADDER)
        {
            DoTakeoff(client, false);
        }

        // Jumped or fell off a ledge, probably.
        if (OldOnGround[client] && moveType != MOVETYPE_LADDER)
        {
            DoTakeoff(client, gB_DidJump[client]);
        }

        gI_GroundTicks[client] = 0;
    }

    OldOnGround[client] = onGround;
    OldMoveType[client] = moveType;
}

static bool IsJumping(int client)
{
	return (gI_Buttons[client] & IN_JUMP == IN_JUMP);
}

static bool IsDucking(int client)
{
    return (gI_Buttons[client] & IN_DUCK == IN_DUCK);
}

static bool IsOnGround(int client)
{
	return (GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND);
}

static float GetSpeed(int client)
{
    float vec[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);

    float x = Pow(vec[0], 2.0);
    float y = Pow(vec[1], 2.0);

    return SquareRoot(x + y);
}

static void ResetTakeoff(int client)
{
    gB_DidTakeoff[client] = false;
    gF_TakeoffSpeed[client] = 0.0;

    gB_DidJump[client] = false;
    gB_DidPerf[client] = false;
    gB_DidJumpBug[client] = false;
    gB_DidCrouchJump[client] = false;
}

static void DoTakeoff(int client, bool didJump)
{
    bool didPerf = gI_GroundTicks[client] == 1;
    float takeoffSpeed = gF_CurrentSpeed[client];

    Call_OnMovementTakeoff(client, didJump, didPerf, takeoffSpeed);

    gB_DidPerf[client] = didPerf;
    gB_DidTakeoff[client] = true;
    gF_TakeoffSpeed[client] = takeoffSpeed;

    if (didJump)
    {
        gB_DidCrouchJump[client] = IsDucking(client);
    }
}
