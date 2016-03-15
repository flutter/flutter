//========================================================================
// GLFW 3.1 WinMM - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2002-2006 Marcus Geelnard
// Copyright (c) 2006-2010 Camilla Berglund <elmindreda@elmindreda.org>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================

#include "internal.h"

#include <stdlib.h>


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Convert axis value to the [-1,1] range
//
static float normalizeAxis(DWORD pos, DWORD min, DWORD max)
{
    float fpos = (float) pos;
    float fmin = (float) min;
    float fmax = (float) max;

    return (2.f * (fpos - fmin) / (fmax - fmin)) - 1.f;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize joystick interface
//
void _glfwInitJoysticks(void)
{
}

// Close all opened joystick handles
//
void _glfwTerminateJoysticks(void)
{
    int i;

    for (i = 0;  i < GLFW_JOYSTICK_LAST;  i++)
        free(_glfw.winmm_js[i].name);
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformJoystickPresent(int joy)
{
    JOYINFO ji;

    if (_glfw_joyGetPos(joy, &ji) != JOYERR_NOERROR)
        return GL_FALSE;

    return GL_TRUE;
}

const float* _glfwPlatformGetJoystickAxes(int joy, int* count)
{
    JOYCAPS jc;
    JOYINFOEX ji;
    float* axes = _glfw.winmm_js[joy].axes;

    if (_glfw_joyGetDevCaps(joy, &jc, sizeof(JOYCAPS)) != JOYERR_NOERROR)
        return NULL;

    ji.dwSize = sizeof(JOYINFOEX);
    ji.dwFlags = JOY_RETURNX | JOY_RETURNY | JOY_RETURNZ |
                 JOY_RETURNR | JOY_RETURNU | JOY_RETURNV;
    if (_glfw_joyGetPosEx(joy, &ji) != JOYERR_NOERROR)
        return NULL;

    axes[(*count)++] = normalizeAxis(ji.dwXpos, jc.wXmin, jc.wXmax);
    axes[(*count)++] = normalizeAxis(ji.dwYpos, jc.wYmin, jc.wYmax);

    if (jc.wCaps & JOYCAPS_HASZ)
        axes[(*count)++] = normalizeAxis(ji.dwZpos, jc.wZmin, jc.wZmax);

    if (jc.wCaps & JOYCAPS_HASR)
        axes[(*count)++] = normalizeAxis(ji.dwRpos, jc.wRmin, jc.wRmax);

    if (jc.wCaps & JOYCAPS_HASU)
        axes[(*count)++] = normalizeAxis(ji.dwUpos, jc.wUmin, jc.wUmax);

    if (jc.wCaps & JOYCAPS_HASV)
        axes[(*count)++] = normalizeAxis(ji.dwVpos, jc.wVmin, jc.wVmax);

    return axes;
}

const unsigned char* _glfwPlatformGetJoystickButtons(int joy, int* count)
{
    JOYCAPS jc;
    JOYINFOEX ji;
    unsigned char* buttons = _glfw.winmm_js[joy].buttons;

    if (_glfw_joyGetDevCaps(joy, &jc, sizeof(JOYCAPS)) != JOYERR_NOERROR)
        return NULL;

    ji.dwSize = sizeof(JOYINFOEX);
    ji.dwFlags = JOY_RETURNBUTTONS | JOY_RETURNPOV;
    if (_glfw_joyGetPosEx(joy, &ji) != JOYERR_NOERROR)
        return NULL;

    while (*count < (int) jc.wNumButtons)
    {
        buttons[*count] = (unsigned char)
            (ji.dwButtons & (1UL << *count) ? GLFW_PRESS : GLFW_RELEASE);
        (*count)++;
    }

    // Virtual buttons - Inject data from hats
    // Each hat is exposed as 4 buttons which exposes 8 directions with
    // concurrent button presses
    // NOTE: this API exposes only one hat

    if ((jc.wCaps & JOYCAPS_HASPOV) && (jc.wCaps & JOYCAPS_POV4DIR))
    {
        int i, value = ji.dwPOV / 100 / 45;

        // Bit fields of button presses for each direction, including nil
        const int directions[9] = { 1, 3, 2, 6, 4, 12, 8, 9, 0 };

        if (value < 0 || value > 8)
            value = 8;

        for (i = 0;  i < 4;  i++)
        {
            if (directions[value] & (1 << i))
                buttons[(*count)++] = GLFW_PRESS;
            else
                buttons[(*count)++] = GLFW_RELEASE;
        }
    }

    return buttons;
}

const char* _glfwPlatformGetJoystickName(int joy)
{
    JOYCAPS jc;

    if (_glfw_joyGetDevCaps(joy, &jc, sizeof(JOYCAPS)) != JOYERR_NOERROR)
        return NULL;

    free(_glfw.winmm_js[joy].name);
    _glfw.winmm_js[joy].name = _glfwCreateUTF8FromWideString(jc.szPname);

    return _glfw.winmm_js[joy].name;
}

