stock int MHud_ClampInt(int value, int min, int max, bool wrapToMin = false)
{
    if (value < min)
    {
        return min;
    }

    if (value > max)
    {
        return wrapToMin ? min : max;
    }

    return value;
}

stock bool MHud_CloseEnough(float value1, float value2, float epsilon = 0.000001)
{
    return FloatAbs(value1 - value2) <= epsilon;
}

stock int MHud_GetNextPresetIndex(const char[] currentValue, char[][][] presets, int numPresets)
{
    int currentIndex = MHud_GetCurrentPresetIndex(currentValue, presets, numPresets);
    return MHud_ClampInt(currentIndex + 1, 0, numPresets - 1, true);
}

stock int MHud_GetCurrentPresetIndex(const char[] currentValue, char[][][] presets, int numPresets)
{
    int currentIndex = -1;
    for (int i = 0; i < numPresets; i++)
    {
        if (StrEqual(presets[i][0], currentValue))
        {
            currentIndex = i;
            break;
        }
    }

    return currentIndex;
}
