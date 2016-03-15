//========================================================================
// GLFW 3.1 Win32 - www.glfw.org
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
#include <string.h>
#include <limits.h>
#include <malloc.h>

// These constants are missing on MinGW
#ifndef EDS_ROTATEDMODE
 #define EDS_ROTATEDMODE 0x00000004
#endif
#ifndef DISPLAY_DEVICE_ACTIVE
 #define DISPLAY_DEVICE_ACTIVE 0x00000001
#endif


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Change the current video mode
//
GLboolean _glfwSetVideoMode(_GLFWmonitor* monitor, const GLFWvidmode* desired)
{
    GLFWvidmode current;
    const GLFWvidmode* best;
    DEVMODEW dm;

    best = _glfwChooseVideoMode(monitor, desired);
    _glfwPlatformGetVideoMode(monitor, &current);
    if (_glfwCompareVideoModes(&current, best) == 0)
        return GL_TRUE;

    ZeroMemory(&dm, sizeof(dm));
    dm.dmSize = sizeof(DEVMODEW);
    dm.dmFields           = DM_PELSWIDTH | DM_PELSHEIGHT | DM_BITSPERPEL |
                            DM_DISPLAYFREQUENCY;
    dm.dmPelsWidth        = best->width;
    dm.dmPelsHeight       = best->height;
    dm.dmBitsPerPel       = best->redBits + best->greenBits + best->blueBits;
    dm.dmDisplayFrequency = best->refreshRate;

    if (dm.dmBitsPerPel < 15 || dm.dmBitsPerPel >= 24)
        dm.dmBitsPerPel = 32;

    if (ChangeDisplaySettingsExW(monitor->win32.adapterName,
                                 &dm,
                                 NULL,
                                 CDS_FULLSCREEN,
                                 NULL) != DISP_CHANGE_SUCCESSFUL)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to set video mode");
        return GL_FALSE;
    }

    monitor->win32.modeChanged = GL_TRUE;
    return GL_TRUE;
}

// Restore the previously saved (original) video mode
//
void _glfwRestoreVideoMode(_GLFWmonitor* monitor)
{
    if (monitor->win32.modeChanged)
    {
        ChangeDisplaySettingsExW(monitor->win32.adapterName,
                                 NULL, NULL, CDS_FULLSCREEN, NULL);
        monitor->win32.modeChanged = GL_FALSE;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

_GLFWmonitor** _glfwPlatformGetMonitors(int* count)
{
    int found = 0;
    _GLFWmonitor** monitors = NULL;
    DWORD adapterIndex, displayIndex;

    *count = 0;

    for (adapterIndex = 0;  ;  adapterIndex++)
    {
        DISPLAY_DEVICEW adapter;

        ZeroMemory(&adapter, sizeof(DISPLAY_DEVICEW));
        adapter.cb = sizeof(DISPLAY_DEVICEW);

        if (!EnumDisplayDevicesW(NULL, adapterIndex, &adapter, 0))
            break;

        if (!(adapter.StateFlags & DISPLAY_DEVICE_ACTIVE))
            continue;

        for (displayIndex = 0;  ;  displayIndex++)
        {
            DISPLAY_DEVICEW display;
            _GLFWmonitor* monitor;
            char* name;
            HDC dc;

            ZeroMemory(&display, sizeof(DISPLAY_DEVICEW));
            display.cb = sizeof(DISPLAY_DEVICEW);

            if (!EnumDisplayDevicesW(adapter.DeviceName, displayIndex, &display, 0))
                break;

            name = _glfwCreateUTF8FromWideString(display.DeviceString);
            if (!name)
            {
                _glfwInputError(GLFW_PLATFORM_ERROR,
                                "Win32: Failed to convert string to UTF-8");
                continue;
            }

            dc = CreateDCW(L"DISPLAY", adapter.DeviceName, NULL, NULL);

            monitor = _glfwAllocMonitor(name,
                                        GetDeviceCaps(dc, HORZSIZE),
                                        GetDeviceCaps(dc, VERTSIZE));

            DeleteDC(dc);
            free(name);

            if (adapter.StateFlags & DISPLAY_DEVICE_MODESPRUNED)
                monitor->win32.modesPruned = GL_TRUE;

            wcscpy(monitor->win32.adapterName, adapter.DeviceName);
            wcscpy(monitor->win32.displayName, display.DeviceName);

            WideCharToMultiByte(CP_UTF8, 0,
                                adapter.DeviceName, -1,
                                monitor->win32.publicAdapterName,
                                sizeof(monitor->win32.publicAdapterName),
                                NULL, NULL);

            WideCharToMultiByte(CP_UTF8, 0,
                                display.DeviceName, -1,
                                monitor->win32.publicDisplayName,
                                sizeof(monitor->win32.publicDisplayName),
                                NULL, NULL);

            found++;
            monitors = realloc(monitors, sizeof(_GLFWmonitor*) * found);
            monitors[found - 1] = monitor;

            if (adapter.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE &&
                displayIndex == 0)
            {
                _GLFW_SWAP_POINTERS(monitors[0], monitors[found - 1]);
            }
        }
    }

    *count = found;
    return monitors;
}

GLboolean _glfwPlatformIsSameMonitor(_GLFWmonitor* first, _GLFWmonitor* second)
{
    return wcscmp(first->win32.displayName, second->win32.displayName) == 0;
}

void _glfwPlatformGetMonitorPos(_GLFWmonitor* monitor, int* xpos, int* ypos)
{
    DEVMODEW settings;
    ZeroMemory(&settings, sizeof(DEVMODEW));
    settings.dmSize = sizeof(DEVMODEW);

    EnumDisplaySettingsExW(monitor->win32.adapterName,
                           ENUM_CURRENT_SETTINGS,
                           &settings,
                           EDS_ROTATEDMODE);

    if (xpos)
        *xpos = settings.dmPosition.x;
    if (ypos)
        *ypos = settings.dmPosition.y;
}

GLFWvidmode* _glfwPlatformGetVideoModes(_GLFWmonitor* monitor, int* count)
{
    int modeIndex = 0, size = 0;
    GLFWvidmode* result = NULL;

    *count = 0;

    for (;;)
    {
        int i;
        GLFWvidmode mode;
        DEVMODEW dm;

        ZeroMemory(&dm, sizeof(DEVMODEW));
        dm.dmSize = sizeof(DEVMODEW);

        if (!EnumDisplaySettingsW(monitor->win32.adapterName, modeIndex, &dm))
            break;

        modeIndex++;

        // Skip modes with less than 15 BPP
        if (dm.dmBitsPerPel < 15)
            continue;

        mode.width  = dm.dmPelsWidth;
        mode.height = dm.dmPelsHeight;
        mode.refreshRate = dm.dmDisplayFrequency;
        _glfwSplitBPP(dm.dmBitsPerPel,
                      &mode.redBits,
                      &mode.greenBits,
                      &mode.blueBits);

        for (i = 0;  i < *count;  i++)
        {
            if (_glfwCompareVideoModes(result + i, &mode) == 0)
                break;
        }

        // Skip duplicate modes
        if (i < *count)
            continue;

        if (monitor->win32.modesPruned)
        {
            // Skip modes not supported by the connected displays
            if (ChangeDisplaySettingsExW(monitor->win32.adapterName,
                                         &dm,
                                         NULL,
                                         CDS_TEST,
                                         NULL) != DISP_CHANGE_SUCCESSFUL)
            {
                continue;
            }
        }

        if (*count == size)
        {
            if (*count)
                size *= 2;
            else
                size = 128;

            result = (GLFWvidmode*) realloc(result, size * sizeof(GLFWvidmode));
        }

        (*count)++;
        result[*count - 1] = mode;
    }

    return result;
}

void _glfwPlatformGetVideoMode(_GLFWmonitor* monitor, GLFWvidmode* mode)
{
    DEVMODEW dm;

    ZeroMemory(&dm, sizeof(DEVMODEW));
    dm.dmSize = sizeof(DEVMODEW);

    EnumDisplaySettingsW(monitor->win32.adapterName, ENUM_CURRENT_SETTINGS, &dm);

    mode->width  = dm.dmPelsWidth;
    mode->height = dm.dmPelsHeight;
    mode->refreshRate = dm.dmDisplayFrequency;
    _glfwSplitBPP(dm.dmBitsPerPel,
                  &mode->redBits,
                  &mode->greenBits,
                  &mode->blueBits);
}

void _glfwPlatformGetGammaRamp(_GLFWmonitor* monitor, GLFWgammaramp* ramp)
{
    HDC dc;
    WORD values[768];

    dc = CreateDCW(L"DISPLAY", monitor->win32.adapterName, NULL, NULL);
    GetDeviceGammaRamp(dc, values);
    DeleteDC(dc);

    _glfwAllocGammaArrays(ramp, 256);

    memcpy(ramp->red,   values +   0, 256 * sizeof(unsigned short));
    memcpy(ramp->green, values + 256, 256 * sizeof(unsigned short));
    memcpy(ramp->blue,  values + 512, 256 * sizeof(unsigned short));
}

void _glfwPlatformSetGammaRamp(_GLFWmonitor* monitor, const GLFWgammaramp* ramp)
{
    HDC dc;
    WORD values[768];

    if (ramp->size != 256)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Gamma ramp size must be 256");
        return;
    }

    memcpy(values +   0, ramp->red,   256 * sizeof(unsigned short));
    memcpy(values + 256, ramp->green, 256 * sizeof(unsigned short));
    memcpy(values + 512, ramp->blue,  256 * sizeof(unsigned short));

    dc = CreateDCW(L"DISPLAY", monitor->win32.adapterName, NULL, NULL);
    SetDeviceGammaRamp(dc, values);
    DeleteDC(dc);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI const char* glfwGetWin32Adapter(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return monitor->win32.publicAdapterName;
}

GLFWAPI const char* glfwGetWin32Monitor(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return monitor->win32.publicDisplayName;
}

