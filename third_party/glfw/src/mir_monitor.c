//========================================================================
// GLFW 3.1 Mir - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2014-2015 Brandon Schaefer <brandon.schaefer@canonical.com>
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
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

_GLFWmonitor** _glfwPlatformGetMonitors(int* count)
{
    int i, found = 0;
    _GLFWmonitor** monitors = NULL;
    MirDisplayConfiguration* displayConfig =
        mir_connection_create_display_config(_glfw.mir.connection);

    *count = 0;

    for (i = 0;  i < displayConfig->num_outputs;  i++)
    {
        const MirDisplayOutput* out = displayConfig->outputs + i;

        if (out->used &&
            out->connected &&
            out->num_modes &&
            out->current_mode < out->num_modes)
        {
            found++;
            monitors        = realloc(monitors, sizeof(_GLFWmonitor*) * found);
            monitors[i]     = _glfwAllocMonitor("Unknown",
                                                out->physical_width_mm,
                                                out->physical_height_mm);

            monitors[i]->mir.x         = out->position_x;
            monitors[i]->mir.y         = out->position_y;
            monitors[i]->mir.output_id = out->output_id;
            monitors[i]->mir.cur_mode  = out->current_mode;

            monitors[i]->modes = _glfwPlatformGetVideoModes(monitors[i],
                                                            &monitors[i]->modeCount);
        }
    }

    mir_display_config_destroy(displayConfig);

    *count = found;
    return monitors;
}

GLboolean _glfwPlatformIsSameMonitor(_GLFWmonitor* first, _GLFWmonitor* second)
{
    return first->mir.output_id == second->mir.output_id;
}

void _glfwPlatformGetMonitorPos(_GLFWmonitor* monitor, int* xpos, int* ypos)
{
    if (xpos)
        *xpos = monitor->mir.x;
    if (ypos)
        *ypos = monitor->mir.y;
}

void FillInRGBBitsFromPixelFormat(GLFWvidmode* mode, const MirPixelFormat pf)
{
    switch (pf)
    {
      case mir_pixel_format_rgb_565:
          mode->redBits   = 5;
          mode->greenBits = 6;
          mode->blueBits  = 5;
          break;
      case mir_pixel_format_rgba_5551:
          mode->redBits   = 5;
          mode->greenBits = 5;
          mode->blueBits  = 5;
          break;
      case mir_pixel_format_rgba_4444:
          mode->redBits   = 4;
          mode->greenBits = 4;
          mode->blueBits  = 4;
          break;
      case mir_pixel_format_abgr_8888:
      case mir_pixel_format_xbgr_8888:
      case mir_pixel_format_argb_8888:
      case mir_pixel_format_xrgb_8888:
      case mir_pixel_format_bgr_888:
      case mir_pixel_format_rgb_888:
      default:
          mode->redBits   = 8;
          mode->greenBits = 8;
          mode->blueBits  = 8;
          break;
    }
}

GLFWvidmode* _glfwPlatformGetVideoModes(_GLFWmonitor* monitor, int* found)
{
    int i;
    GLFWvidmode* modes = NULL;
    MirDisplayConfiguration* displayConfig =
        mir_connection_create_display_config(_glfw.mir.connection);

    for (i = 0;  i < displayConfig->num_outputs;  i++)
    {
        const MirDisplayOutput* out = displayConfig->outputs + i;
        if (out->output_id != monitor->mir.output_id)
            continue;

        modes = calloc(out->num_modes, sizeof(GLFWvidmode));

        for (*found = 0;  *found < out->num_modes;  (*found)++)
        {
            modes[*found].width  = out->modes[*found].horizontal_resolution;
            modes[*found].height = out->modes[*found].vertical_resolution;
            modes[*found].refreshRate = out->modes[*found].refresh_rate;

            FillInRGBBitsFromPixelFormat(&modes[*found], out->output_formats[*found]);
        }

        break;
    }

    mir_display_config_destroy(displayConfig);

    return modes;
}

void _glfwPlatformGetVideoMode(_GLFWmonitor* monitor, GLFWvidmode* mode)
{
    *mode = monitor->modes[monitor->mir.cur_mode];
}

void _glfwPlatformGetGammaRamp(_GLFWmonitor* monitor, GLFWgammaramp* ramp)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformSetGammaRamp(_GLFWmonitor* monitor, const GLFWgammaramp* ramp)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

