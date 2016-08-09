//========================================================================
// GLFW 3.2 - www.glfw.org
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

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>


// The three global variables below comprise all global data in GLFW.
// Any other global variable is a bug.

// Global state shared between compilation units of GLFW
// These are documented in internal.h
//
GLFWbool _glfwInitialized = GLFW_FALSE;
_GLFWlibrary _glfw;

// This is outside of _glfw so it can be initialized and usable before
// glfwInit is called, which lets that function report errors
//
static GLFWerrorfun _glfwErrorCallback = NULL;


// Returns a generic string representation of the specified error
//
static const char* getErrorString(int error)
{
    switch (error)
    {
        case GLFW_NOT_INITIALIZED:
            return "The GLFW library is not initialized";
        case GLFW_NO_CURRENT_CONTEXT:
            return "There is no current context";
        case GLFW_INVALID_ENUM:
            return "Invalid argument for enum parameter";
        case GLFW_INVALID_VALUE:
            return "Invalid value for parameter";
        case GLFW_OUT_OF_MEMORY:
            return "Out of memory";
        case GLFW_API_UNAVAILABLE:
            return "The requested client API is unavailable";
        case GLFW_VERSION_UNAVAILABLE:
            return "The requested client API version is unavailable";
        case GLFW_PLATFORM_ERROR:
            return "A platform-specific error occurred";
        case GLFW_FORMAT_UNAVAILABLE:
            return "The requested format is unavailable";
        case GLFW_NO_WINDOW_CONTEXT:
            return "The specified window has no context";
        default:
            return "ERROR: UNKNOWN GLFW ERROR";
    }
}


//////////////////////////////////////////////////////////////////////////
//////                         GLFW event API                       //////
//////////////////////////////////////////////////////////////////////////

void _glfwInputError(int error, const char* format, ...)
{
    if (_glfwErrorCallback)
    {
        char buffer[8192];
        const char* description;

        if (format)
        {
            int count;
            va_list vl;

            va_start(vl, format);
            count = vsnprintf(buffer, sizeof(buffer), format, vl);
            va_end(vl);

            if (count < 0)
                buffer[sizeof(buffer) - 1] = '\0';

            description = buffer;
        }
        else
            description = getErrorString(error);

        _glfwErrorCallback(error, description);
    }
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW public API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI int glfwInit(void)
{
    if (_glfwInitialized)
        return GLFW_TRUE;

    memset(&_glfw, 0, sizeof(_glfw));

    if (!_glfwPlatformInit())
    {
        _glfwPlatformTerminate();
        return GLFW_FALSE;
    }

    _glfwInitVulkan();

    _glfw.monitors = _glfwPlatformGetMonitors(&_glfw.monitorCount);
    _glfwInitialized = GLFW_TRUE;

    _glfw.timerOffset = _glfwPlatformGetTimerValue();

    // Not all window hints have zero as their default value
    glfwDefaultWindowHints();

    return GLFW_TRUE;
}

GLFWAPI void glfwTerminate(void)
{
    int i;

    if (!_glfwInitialized)
        return;

    memset(&_glfw.callbacks, 0, sizeof(_glfw.callbacks));

    while (_glfw.windowListHead)
        glfwDestroyWindow((GLFWwindow*) _glfw.windowListHead);

    while (_glfw.cursorListHead)
        glfwDestroyCursor((GLFWcursor*) _glfw.cursorListHead);

    for (i = 0;  i < _glfw.monitorCount;  i++)
    {
        _GLFWmonitor* monitor = _glfw.monitors[i];
        if (monitor->originalRamp.size)
            _glfwPlatformSetGammaRamp(monitor, &monitor->originalRamp);
    }

    _glfwTerminateVulkan();

    _glfwFreeMonitors(_glfw.monitors, _glfw.monitorCount);
    _glfw.monitors = NULL;
    _glfw.monitorCount = 0;

    _glfwPlatformTerminate();

    memset(&_glfw, 0, sizeof(_glfw));
    _glfwInitialized = GLFW_FALSE;
}

GLFWAPI void glfwGetVersion(int* major, int* minor, int* rev)
{
    if (major != NULL)
        *major = GLFW_VERSION_MAJOR;

    if (minor != NULL)
        *minor = GLFW_VERSION_MINOR;

    if (rev != NULL)
        *rev = GLFW_VERSION_REVISION;
}

GLFWAPI const char* glfwGetVersionString(void)
{
    return _glfwPlatformGetVersionString();
}

GLFWAPI GLFWerrorfun glfwSetErrorCallback(GLFWerrorfun cbfun)
{
    _GLFW_SWAP_POINTERS(_glfwErrorCallback, cbfun);
    return cbfun;
}

