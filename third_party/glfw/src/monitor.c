//========================================================================
// GLFW 3.1 - www.glfw.org
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

#include <math.h>
#include <float.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>


// Lexical comparison function for GLFW video modes, used by qsort
//
static int compareVideoModes(const void* firstPtr, const void* secondPtr)
{
    int firstBPP, secondBPP, firstSize, secondSize;
    const GLFWvidmode* first = firstPtr;
    const GLFWvidmode* second = secondPtr;

    // First sort on color bits per pixel
    firstBPP = first->redBits + first->greenBits + first->blueBits;
    secondBPP = second->redBits + second->greenBits + second->blueBits;
    if (firstBPP != secondBPP)
        return firstBPP - secondBPP;

    // Then sort on screen area, in pixels
    firstSize = first->width * first->height;
    secondSize = second->width * second->height;
    if (firstSize != secondSize)
        return firstSize - secondSize;

    // Lastly sort on refresh rate
    return first->refreshRate - second->refreshRate;
}

// Retrieves the available modes for the specified monitor
//
static int refreshVideoModes(_GLFWmonitor* monitor)
{
    int modeCount;
    GLFWvidmode* modes;

    if (monitor->modes)
        return GL_TRUE;

    modes = _glfwPlatformGetVideoModes(monitor, &modeCount);
    if (!modes)
        return GL_FALSE;

    qsort(modes, modeCount, sizeof(GLFWvidmode), compareVideoModes);

    free(monitor->modes);
    monitor->modes = modes;
    monitor->modeCount = modeCount;

    return GL_TRUE;
}


//////////////////////////////////////////////////////////////////////////
//////                         GLFW event API                       //////
//////////////////////////////////////////////////////////////////////////

void _glfwInputMonitorChange(void)
{
    int i, j, monitorCount = _glfw.monitorCount;
    _GLFWmonitor** monitors = _glfw.monitors;

    _glfw.monitors = _glfwPlatformGetMonitors(&_glfw.monitorCount);

    // Re-use still connected monitor objects

    for (i = 0;  i < _glfw.monitorCount;  i++)
    {
        for (j = 0;  j < monitorCount;  j++)
        {
            if (_glfwPlatformIsSameMonitor(_glfw.monitors[i], monitors[j]))
            {
                _glfwFreeMonitor(_glfw.monitors[i]);
                _glfw.monitors[i] = monitors[j];
                break;
            }
        }
    }

    // Find and report disconnected monitors (not in the new list)

    for (i = 0;  i < monitorCount;  i++)
    {
        _GLFWwindow* window;

        for (j = 0;  j < _glfw.monitorCount;  j++)
        {
            if (monitors[i] == _glfw.monitors[j])
                break;
        }

        if (j < _glfw.monitorCount)
            continue;

        for (window = _glfw.windowListHead;  window;  window = window->next)
        {
            if (window->monitor == monitors[i])
                window->monitor = NULL;
        }

        if (_glfw.callbacks.monitor)
            _glfw.callbacks.monitor((GLFWmonitor*) monitors[i], GLFW_DISCONNECTED);
    }

    // Find and report newly connected monitors (not in the old list)
    // Re-used monitor objects are then removed from the old list to avoid
    // having them destroyed at the end of this function

    for (i = 0;  i < _glfw.monitorCount;  i++)
    {
        for (j = 0;  j < monitorCount;  j++)
        {
            if (_glfw.monitors[i] == monitors[j])
            {
                monitors[j] = NULL;
                break;
            }
        }

        if (j < monitorCount)
            continue;

        if (_glfw.callbacks.monitor)
            _glfw.callbacks.monitor((GLFWmonitor*) _glfw.monitors[i], GLFW_CONNECTED);
    }

    _glfwFreeMonitors(monitors, monitorCount);
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

_GLFWmonitor* _glfwAllocMonitor(const char* name, int widthMM, int heightMM)
{
    _GLFWmonitor* monitor = calloc(1, sizeof(_GLFWmonitor));
    monitor->name = strdup(name);
    monitor->widthMM = widthMM;
    monitor->heightMM = heightMM;

    return monitor;
}

void _glfwFreeMonitor(_GLFWmonitor* monitor)
{
    if (monitor == NULL)
        return;

    _glfwFreeGammaArrays(&monitor->originalRamp);
    _glfwFreeGammaArrays(&monitor->currentRamp);

    free(monitor->modes);
    free(monitor->name);
    free(monitor);
}

void _glfwAllocGammaArrays(GLFWgammaramp* ramp, unsigned int size)
{
    ramp->red = calloc(size, sizeof(unsigned short));
    ramp->green = calloc(size, sizeof(unsigned short));
    ramp->blue = calloc(size, sizeof(unsigned short));
    ramp->size = size;
}

void _glfwFreeGammaArrays(GLFWgammaramp* ramp)
{
    free(ramp->red);
    free(ramp->green);
    free(ramp->blue);

    memset(ramp, 0, sizeof(GLFWgammaramp));
}

void _glfwFreeMonitors(_GLFWmonitor** monitors, int count)
{
    int i;

    for (i = 0;  i < count;  i++)
        _glfwFreeMonitor(monitors[i]);

    free(monitors);
}

const GLFWvidmode* _glfwChooseVideoMode(_GLFWmonitor* monitor,
                                        const GLFWvidmode* desired)
{
    int i;
    unsigned int sizeDiff, leastSizeDiff = UINT_MAX;
    unsigned int rateDiff, leastRateDiff = UINT_MAX;
    unsigned int colorDiff, leastColorDiff = UINT_MAX;
    const GLFWvidmode* current;
    const GLFWvidmode* closest = NULL;

    if (!refreshVideoModes(monitor))
        return NULL;

    for (i = 0;  i < monitor->modeCount;  i++)
    {
        current = monitor->modes + i;

        colorDiff = 0;

        if (desired->redBits != GLFW_DONT_CARE)
            colorDiff += abs(current->redBits - desired->redBits);
        if (desired->greenBits != GLFW_DONT_CARE)
            colorDiff += abs(current->greenBits - desired->greenBits);
        if (desired->blueBits != GLFW_DONT_CARE)
            colorDiff += abs(current->blueBits - desired->blueBits);

        sizeDiff = abs((current->width - desired->width) *
                       (current->width - desired->width) +
                       (current->height - desired->height) *
                       (current->height - desired->height));

        if (desired->refreshRate != GLFW_DONT_CARE)
            rateDiff = abs(current->refreshRate - desired->refreshRate);
        else
            rateDiff = UINT_MAX - current->refreshRate;

        if ((colorDiff < leastColorDiff) ||
            (colorDiff == leastColorDiff && sizeDiff < leastSizeDiff) ||
            (colorDiff == leastColorDiff && sizeDiff == leastSizeDiff && rateDiff < leastRateDiff))
        {
            closest = current;
            leastSizeDiff = sizeDiff;
            leastRateDiff = rateDiff;
            leastColorDiff = colorDiff;
        }
    }

    return closest;
}

int _glfwCompareVideoModes(const GLFWvidmode* first, const GLFWvidmode* second)
{
    return compareVideoModes(first, second);
}

void _glfwSplitBPP(int bpp, int* red, int* green, int* blue)
{
    int delta;

    // We assume that by 32 the user really meant 24
    if (bpp == 32)
        bpp = 24;

    // Convert "bits per pixel" to red, green & blue sizes

    *red = *green = *blue = bpp / 3;
    delta = bpp - (*red * 3);
    if (delta >= 1)
        *green = *green + 1;

    if (delta == 2)
        *red = *red + 1;
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW public API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI GLFWmonitor** glfwGetMonitors(int* count)
{
    *count = 0;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    *count = _glfw.monitorCount;
    return (GLFWmonitor**) _glfw.monitors;
}

GLFWAPI GLFWmonitor* glfwGetPrimaryMonitor(void)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (!_glfw.monitorCount)
        return NULL;

    return (GLFWmonitor*) _glfw.monitors[0];
}

GLFWAPI void glfwGetMonitorPos(GLFWmonitor* handle, int* xpos, int* ypos)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;

    if (xpos)
        *xpos = 0;
    if (ypos)
        *ypos = 0;

    _GLFW_REQUIRE_INIT();

    _glfwPlatformGetMonitorPos(monitor, xpos, ypos);
}

GLFWAPI void glfwGetMonitorPhysicalSize(GLFWmonitor* handle, int* widthMM, int* heightMM)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;

    if (widthMM)
        *widthMM = 0;
    if (heightMM)
        *heightMM = 0;

    _GLFW_REQUIRE_INIT();

    if (widthMM)
        *widthMM = monitor->widthMM;
    if (heightMM)
        *heightMM = monitor->heightMM;
}

GLFWAPI const char* glfwGetMonitorName(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return monitor->name;
}

GLFWAPI GLFWmonitorfun glfwSetMonitorCallback(GLFWmonitorfun cbfun)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(_glfw.callbacks.monitor, cbfun);
    return cbfun;
}

GLFWAPI const GLFWvidmode* glfwGetVideoModes(GLFWmonitor* handle, int* count)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;

    *count = 0;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (!refreshVideoModes(monitor))
        return NULL;

    *count = monitor->modeCount;
    return monitor->modes;
}

GLFWAPI const GLFWvidmode* glfwGetVideoMode(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    _glfwPlatformGetVideoMode(monitor, &monitor->currentMode);
    return &monitor->currentMode;
}

GLFWAPI void glfwSetGamma(GLFWmonitor* handle, float gamma)
{
    int i;
    unsigned short values[256];
    GLFWgammaramp ramp;

    _GLFW_REQUIRE_INIT();

    if (gamma != gamma || gamma <= 0.f || gamma > FLT_MAX)
    {
        _glfwInputError(GLFW_INVALID_VALUE, "Invalid gamma value");
        return;
    }

    for (i = 0;  i < 256;  i++)
    {
        double value;

        // Calculate intensity
        value = i / 255.0;
        // Apply gamma curve
        value = pow(value, 1.0 / gamma) * 65535.0 + 0.5;

        // Clamp to value range
        if (value > 65535.0)
            value = 65535.0;

        values[i] = (unsigned short) value;
    }

    ramp.red = values;
    ramp.green = values;
    ramp.blue = values;
    ramp.size = 256;

    glfwSetGammaRamp(handle, &ramp);
}

GLFWAPI const GLFWgammaramp* glfwGetGammaRamp(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    _glfwFreeGammaArrays(&monitor->currentRamp);
    _glfwPlatformGetGammaRamp(monitor, &monitor->currentRamp);

    return &monitor->currentRamp;
}

GLFWAPI void glfwSetGammaRamp(GLFWmonitor* handle, const GLFWgammaramp* ramp)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;

    _GLFW_REQUIRE_INIT();

    if (!monitor->originalRamp.size)
        _glfwPlatformGetGammaRamp(monitor, &monitor->originalRamp);

    _glfwPlatformSetGammaRamp(monitor, ramp);
}

