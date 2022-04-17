void GetColorBySpeed(float speed, int rgb[3])
{
    int x = RoundFloat(speed / 50.0) * 32;
    if (x >= 256)
    {
        rgb = { 0, 255, 0 };
        return;
    }

    rgb[0] = (255 - x);
    rgb[1] = x;
    rgb[2] = 0;
}

int GetSpectedOrSelf(int client)
{
    int team = GetClientTeam(client);
    if (team != 1) // not spectating, replace with define/enum please
    {
        return client;
    }

    // TODO: Enum for this?
    int mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if (mode != 4 && mode != 5) // Not first or third person
    {
        return client;
    }

    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    if (target == -1) // not spectating anyone
    {
        return client;
    }

    return target;
}

void StripColorBytes(char[] buffer, int maxlength)
{
    int pos = 0;
    char[] output = new char[maxlength];

    int len = strlen(buffer);

    for (int i = 0; i < len; i++)
    {
        bool isColor = buffer[i] >= '\x01' && buffer[i] <= '\x10';
        if (!isColor)
        {
            output[pos++] = buffer[i];
        }
    }

    strcopy(buffer, maxlength, output);
}
