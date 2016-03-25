//========================================================================
// GLFW 3.2 Wayland - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2014 Jonas Ådahl <jadahl@gmail.com>
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>


struct _GLFWvidmodeWayland
{
    GLFWvidmode         base;
    uint32_t            flags;
};

static void geometry(void* data,
                     struct wl_output* output,
                     int32_t x,
                     int32_t y,
                     int32_t physicalWidth,
                     int32_t physicalHeight,
                     int32_t subpixel,
                     const char* make,
                     const char* model,
                     int32_t transform)
{
    struct _GLFWmonitor *monitor = data;

    monitor->wl.x = x;
    monitor->wl.y = y;
    monitor->widthMM = physicalWidth;
    monitor->heightMM = physicalHeight;
}

static void mode(void* data,
                 struct wl_output* output,
                 uint32_t flags,
                 int32_t width,
                 int32_t height,
                 int32_t refresh)
{
    struct _GLFWmonitor *monitor = data;
    _GLFWvidmodeWayland mode = { { 0 }, };

    mode.base.width = width;
    mode.base.height = height;
    mode.base.refreshRate = refresh / 1000;
    mode.flags = flags;

    if (monitor->wl.modesCount + 1 >= monitor->wl.modesSize)
    {
        int size = monitor->wl.modesSize * 2;
        _GLFWvidmodeWayland* modes =
            realloc(monitor->wl.modes,
                    size * sizeof(_GLFWvidmodeWayland));
        monitor->wl.modes = modes;
        monitor->wl.modesSize = size;
    }

    monitor->wl.modes[monitor->wl.modesCount++] = mode;
}

static void done(void* data,
                 struct wl_output* output)
{
    struct _GLFWmonitor *monitor = data;

    monitor->wl.done = GLFW_TRUE;
}

static void scale(void* data,
                  struct wl_output* output,
                  int32_t factor)
{
    struct _GLFWmonitor *monitor = data;

    monitor->wl.scale = factor;
}

static const struct wl_output_listener output_listener = {
    geometry,
    mode,
    done,
    scale,
};


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwAddOutputWayland(uint32_t name, uint32_t version)
{
    _GLFWmonitor *monitor;
    struct wl_output *output;
    char name_str[80];

    memset(name_str, 0, 80 * sizeof(char));
    snprintf(name_str, 79, "wl_output@%u", name);

    if (version < 2)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Unsupported output interface version");
        return;
    }

    monitor = _glfwAllocMonitor(name_str, 0, 0);

    output = wl_registry_bind(_glfw.wl.registry,
                              name,
                              &wl_output_interface,
                              2);
    if (!output)
    {
        _glfwFreeMonitor(monitor);
        return;
    }

    monitor->wl.modes = calloc(4, sizeof(_GLFWvidmodeWayland));
    monitor->wl.modesSize = 4;

    monitor->wl.scale = 1;

    monitor->wl.output = output;
    wl_output_add_listener(output, &output_listener, monitor);

    if (_glfw.wl.monitorsCount + 1 >= _glfw.wl.monitorsSize)
    {
        _GLFWmonitor** monitors = _glfw.wl.monitors;
        int size = _glfw.wl.monitorsSize * 2;

        monitors = realloc(monitors, size * sizeof(_GLFWmonitor*));

        _glfw.wl.monitors = monitors;
        _glfw.wl.monitorsSize = size;
    }

    _glfw.wl.monitors[_glfw.wl.monitorsCount++] = monitor;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

_GLFWmonitor** _glfwPlatformGetMonitors(int* count)
{
    _GLFWmonitor** monitors;
    _GLFWmonitor* monitor;
    int i, monitorsCount = _glfw.wl.monitorsCount;

    if (_glfw.wl.monitorsCount == 0)
        goto err;

    monitors = calloc(monitorsCount, sizeof(_GLFWmonitor*));

    for (i = 0; i < monitorsCount; i++)
    {
        _GLFWmonitor* origMonitor = _glfw.wl.monitors[i];
        monitor = calloc(1, sizeof(_GLFWmonitor));

        monitor->modes =
            _glfwPlatformGetVideoModes(origMonitor,
                                       &origMonitor->wl.modesCount);
        *monitor = *_glfw.wl.monitors[i];
        monitors[i] = monitor;
    }

    *count = monitorsCount;
    return monitors;

err:
    *count = 0;
    return NULL;
}

GLFWbool _glfwPlatformIsSameMonitor(_GLFWmonitor* first, _GLFWmonitor* second)
{
    return first->wl.output == second->wl.output;
}

void _glfwPlatformGetMonitorPos(_GLFWmonitor* monitor, int* xpos, int* ypos)
{
    if (xpos)
        *xpos = monitor->wl.x;
    if (ypos)
        *ypos = monitor->wl.y;
}

GLFWvidmode* _glfwPlatformGetVideoModes(_GLFWmonitor* monitor, int* found)
{
    GLFWvidmode *modes;
    int i, modesCount = monitor->wl.modesCount;

    modes = calloc(modesCount, sizeof(GLFWvidmode));

    for (i = 0;  i < modesCount;  i++)
        modes[i] = monitor->wl.modes[i].base;

    *found = modesCount;
    return modes;
}

void _glfwPlatformGetVideoMode(_GLFWmonitor* monitor, GLFWvidmode* mode)
{
    int i;

    for (i = 0;  i < monitor->wl.modesCount;  i++)
    {
        if (monitor->wl.modes[i].flags & WL_OUTPUT_MODE_CURRENT)
        {
            *mode = monitor->wl.modes[i].base;
            return;
        }
    }
}

void _glfwPlatformGetGammaRamp(_GLFWmonitor* monitor, GLFWgammaramp* ramp)
{
    // TODO
    fprintf(stderr, "_glfwPlatformGetGammaRamp not implemented yet\n");
}

void _glfwPlatformSetGammaRamp(_GLFWmonitor* monitor, const GLFWgammaramp* ramp)
{
    // TODO
    fprintf(stderr, "_glfwPlatformSetGammaRamp not implemented yet\n");
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI struct wl_output* glfwGetWaylandMonitor(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return monitor->wl.output;
}

