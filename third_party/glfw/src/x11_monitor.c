//========================================================================
// GLFW 3.1 X11 - www.glfw.org
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

#include <limits.h>
#include <stdlib.h>
#include <string.h>


// Check whether the display mode should be included in enumeration
//
static GLboolean modeIsGood(const XRRModeInfo* mi)
{
    return (mi->modeFlags & RR_Interlace) == 0;
}

// Calculates the refresh rate, in Hz, from the specified RandR mode info
//
static int calculateRefreshRate(const XRRModeInfo* mi)
{
    if (mi->hTotal && mi->vTotal)
        return (int) ((double) mi->dotClock / ((double) mi->hTotal * (double) mi->vTotal));
    else
        return 0;
}

// Returns the mode info for a RandR mode XID
//
static const XRRModeInfo* getModeInfo(const XRRScreenResources* sr, RRMode id)
{
    int i;

    for (i = 0;  i < sr->nmode;  i++)
    {
        if (sr->modes[i].id == id)
            return sr->modes + i;
    }

    return NULL;
}

// Convert RandR mode info to GLFW video mode
//
static GLFWvidmode vidmodeFromModeInfo(const XRRModeInfo* mi,
                                       const XRRCrtcInfo* ci)
{
    GLFWvidmode mode;

    if (ci->rotation == RR_Rotate_90 || ci->rotation == RR_Rotate_270)
    {
        mode.width  = mi->height;
        mode.height = mi->width;
    }
    else
    {
        mode.width  = mi->width;
        mode.height = mi->height;
    }

    mode.refreshRate = calculateRefreshRate(mi);

    _glfwSplitBPP(DefaultDepth(_glfw.x11.display, _glfw.x11.screen),
                  &mode.redBits, &mode.greenBits, &mode.blueBits);

    return mode;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Set the current video mode for the specified monitor
//
GLboolean _glfwSetVideoMode(_GLFWmonitor* monitor, const GLFWvidmode* desired)
{
    if (_glfw.x11.randr.available && !_glfw.x11.randr.monitorBroken)
    {
        XRRScreenResources* sr;
        XRRCrtcInfo* ci;
        XRROutputInfo* oi;
        GLFWvidmode current;
        const GLFWvidmode* best;
        RRMode native = None;
        int i;

        best = _glfwChooseVideoMode(monitor, desired);
        _glfwPlatformGetVideoMode(monitor, &current);
        if (_glfwCompareVideoModes(&current, best) == 0)
            return GL_TRUE;

        sr = XRRGetScreenResources(_glfw.x11.display, _glfw.x11.root);
        ci = XRRGetCrtcInfo(_glfw.x11.display, sr, monitor->x11.crtc);
        oi = XRRGetOutputInfo(_glfw.x11.display, sr, monitor->x11.output);

        for (i = 0;  i < oi->nmode;  i++)
        {
            const XRRModeInfo* mi = getModeInfo(sr, oi->modes[i]);
            if (!modeIsGood(mi))
                continue;

            const GLFWvidmode mode = vidmodeFromModeInfo(mi, ci);
            if (_glfwCompareVideoModes(best, &mode) == 0)
            {
                native = mi->id;
                break;
            }
        }

        if (native)
        {
            if (monitor->x11.oldMode == None)
                monitor->x11.oldMode = ci->mode;

            XRRSetCrtcConfig(_glfw.x11.display,
                             sr, monitor->x11.crtc,
                             CurrentTime,
                             ci->x, ci->y,
                             native,
                             ci->rotation,
                             ci->outputs,
                             ci->noutput);
        }

        XRRFreeOutputInfo(oi);
        XRRFreeCrtcInfo(ci);
        XRRFreeScreenResources(sr);

        if (!native)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Monitor mode list changed");
            return GL_FALSE;
        }
    }

    return GL_TRUE;
}

// Restore the saved (original) video mode for the specified monitor
//
void _glfwRestoreVideoMode(_GLFWmonitor* monitor)
{
    if (_glfw.x11.randr.available && !_glfw.x11.randr.monitorBroken)
    {
        XRRScreenResources* sr;
        XRRCrtcInfo* ci;

        if (monitor->x11.oldMode == None)
            return;

        sr = XRRGetScreenResources(_glfw.x11.display, _glfw.x11.root);
        ci = XRRGetCrtcInfo(_glfw.x11.display, sr, monitor->x11.crtc);

        XRRSetCrtcConfig(_glfw.x11.display,
                         sr, monitor->x11.crtc,
                         CurrentTime,
                         ci->x, ci->y,
                         monitor->x11.oldMode,
                         ci->rotation,
                         ci->outputs,
                         ci->noutput);

        XRRFreeCrtcInfo(ci);
        XRRFreeScreenResources(sr);

        monitor->x11.oldMode = None;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

_GLFWmonitor** _glfwPlatformGetMonitors(int* count)
{
    int i, j, k, found = 0;
    _GLFWmonitor** monitors = NULL;

    *count = 0;

    if (_glfw.x11.randr.available)
    {
        int screenCount = 0;
        XineramaScreenInfo* screens = NULL;
        XRRScreenResources* sr = XRRGetScreenResources(_glfw.x11.display,
                                                       _glfw.x11.root);
        RROutput primary = XRRGetOutputPrimary(_glfw.x11.display,
                                               _glfw.x11.root);

        monitors = calloc(sr->noutput, sizeof(_GLFWmonitor*));

        if (_glfw.x11.xinerama.available)
            screens = XineramaQueryScreens(_glfw.x11.display, &screenCount);

        for (i = 0;  i < sr->ncrtc;  i++)
        {
            XRRCrtcInfo* ci = XRRGetCrtcInfo(_glfw.x11.display,
                                             sr, sr->crtcs[i]);

            for (j = 0;  j < ci->noutput;  j++)
            {
                int widthMM, heightMM;
                _GLFWmonitor* monitor;
                XRROutputInfo* oi = XRRGetOutputInfo(_glfw.x11.display,
                                                     sr, ci->outputs[j]);
                if (oi->connection != RR_Connected)
                {
                    XRRFreeOutputInfo(oi);
                    continue;
                }

                if (ci->rotation == RR_Rotate_90 || ci->rotation == RR_Rotate_270)
                {
                    widthMM  = oi->mm_height;
                    heightMM = oi->mm_width;
                }
                else
                {
                    widthMM  = oi->mm_width;
                    heightMM = oi->mm_height;
                }

                monitor = _glfwAllocMonitor(oi->name, widthMM, heightMM);
                monitor->x11.output = ci->outputs[j];
                monitor->x11.crtc   = oi->crtc;

                for (k = 0;  k < screenCount;  k++)
                {
                    if (screens[k].x_org == ci->x &&
                        screens[k].y_org == ci->y &&
                        screens[k].width == ci->width &&
                        screens[k].height == ci->height)
                    {
                        monitor->x11.index = k;
                        break;
                    }
                }

                XRRFreeOutputInfo(oi);

                found++;
                monitors[found - 1] = monitor;

                if (ci->outputs[j] == primary)
                    _GLFW_SWAP_POINTERS(monitors[0], monitors[found - 1]);
            }

            XRRFreeCrtcInfo(ci);
        }

        XRRFreeScreenResources(sr);

        if (screens)
            XFree(screens);

        if (found == 0)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: RandR monitor support seems broken");

            _glfw.x11.randr.monitorBroken = GL_TRUE;
            free(monitors);
            monitors = NULL;
        }
    }

    if (!monitors)
    {
        monitors = calloc(1, sizeof(_GLFWmonitor*));
        monitors[0] = _glfwAllocMonitor("Display",
                                        DisplayWidthMM(_glfw.x11.display,
                                                       _glfw.x11.screen),
                                        DisplayHeightMM(_glfw.x11.display,
                                                        _glfw.x11.screen));
        found = 1;
    }

    *count = found;
    return monitors;
}

GLboolean _glfwPlatformIsSameMonitor(_GLFWmonitor* first, _GLFWmonitor* second)
{
    return first->x11.crtc == second->x11.crtc;
}

void _glfwPlatformGetMonitorPos(_GLFWmonitor* monitor, int* xpos, int* ypos)
{
    if (_glfw.x11.randr.available && !_glfw.x11.randr.monitorBroken)
    {
        XRRScreenResources* sr;
        XRRCrtcInfo* ci;

        sr = XRRGetScreenResourcesCurrent(_glfw.x11.display, _glfw.x11.root);
        ci = XRRGetCrtcInfo(_glfw.x11.display, sr, monitor->x11.crtc);

        if (xpos)
            *xpos = ci->x;
        if (ypos)
            *ypos = ci->y;

        XRRFreeCrtcInfo(ci);
        XRRFreeScreenResources(sr);
    }
}

GLFWvidmode* _glfwPlatformGetVideoModes(_GLFWmonitor* monitor, int* count)
{
    GLFWvidmode* result;

    *count = 0;

    if (_glfw.x11.randr.available && !_glfw.x11.randr.monitorBroken)
    {
        int i, j;
        XRRScreenResources* sr;
        XRRCrtcInfo* ci;
        XRROutputInfo* oi;

        sr = XRRGetScreenResourcesCurrent(_glfw.x11.display, _glfw.x11.root);
        ci = XRRGetCrtcInfo(_glfw.x11.display, sr, monitor->x11.crtc);
        oi = XRRGetOutputInfo(_glfw.x11.display, sr, monitor->x11.output);

        result = calloc(oi->nmode, sizeof(GLFWvidmode));

        for (i = 0;  i < oi->nmode;  i++)
        {
            const XRRModeInfo* mi = getModeInfo(sr, oi->modes[i]);
            if (!modeIsGood(mi))
                continue;

            const GLFWvidmode mode = vidmodeFromModeInfo(mi, ci);

            for (j = 0;  j < *count;  j++)
            {
                if (_glfwCompareVideoModes(result + j, &mode) == 0)
                    break;
            }

            // Skip duplicate modes
            if (j < *count)
                continue;

            (*count)++;
            result[*count - 1] = mode;
        }

        XRRFreeOutputInfo(oi);
        XRRFreeCrtcInfo(ci);
        XRRFreeScreenResources(sr);
    }
    else
    {
        *count = 1;
        result = calloc(1, sizeof(GLFWvidmode));
        _glfwPlatformGetVideoMode(monitor, result);
    }

    return result;
}

void _glfwPlatformGetVideoMode(_GLFWmonitor* monitor, GLFWvidmode* mode)
{
    if (_glfw.x11.randr.available && !_glfw.x11.randr.monitorBroken)
    {
        XRRScreenResources* sr;
        XRRCrtcInfo* ci;

        sr = XRRGetScreenResourcesCurrent(_glfw.x11.display, _glfw.x11.root);
        ci = XRRGetCrtcInfo(_glfw.x11.display, sr, monitor->x11.crtc);

        *mode = vidmodeFromModeInfo(getModeInfo(sr, ci->mode), ci);

        XRRFreeCrtcInfo(ci);
        XRRFreeScreenResources(sr);
    }
    else
    {
        mode->width = DisplayWidth(_glfw.x11.display, _glfw.x11.screen);
        mode->height = DisplayHeight(_glfw.x11.display, _glfw.x11.screen);
        mode->refreshRate = 0;

        _glfwSplitBPP(DefaultDepth(_glfw.x11.display, _glfw.x11.screen),
                      &mode->redBits, &mode->greenBits, &mode->blueBits);
    }
}

void _glfwPlatformGetGammaRamp(_GLFWmonitor* monitor, GLFWgammaramp* ramp)
{
    if (_glfw.x11.randr.available && !_glfw.x11.randr.gammaBroken)
    {
        const size_t size = XRRGetCrtcGammaSize(_glfw.x11.display,
                                                monitor->x11.crtc);
        XRRCrtcGamma* gamma = XRRGetCrtcGamma(_glfw.x11.display,
                                              monitor->x11.crtc);

        _glfwAllocGammaArrays(ramp, size);

        memcpy(ramp->red, gamma->red, size * sizeof(unsigned short));
        memcpy(ramp->green, gamma->green, size * sizeof(unsigned short));
        memcpy(ramp->blue, gamma->blue, size * sizeof(unsigned short));

        XRRFreeGamma(gamma);
    }
#if defined(_GLFW_HAS_XF86VM)
    else if (_glfw.x11.vidmode.available)
    {
        int size;
        XF86VidModeGetGammaRampSize(_glfw.x11.display, _glfw.x11.screen, &size);

        _glfwAllocGammaArrays(ramp, size);

        XF86VidModeGetGammaRamp(_glfw.x11.display,
                                _glfw.x11.screen,
                                ramp->size, ramp->red, ramp->green, ramp->blue);
    }
#endif /*_GLFW_HAS_XF86VM*/
}

void _glfwPlatformSetGammaRamp(_GLFWmonitor* monitor, const GLFWgammaramp* ramp)
{
    if (_glfw.x11.randr.available && !_glfw.x11.randr.gammaBroken)
    {
        XRRCrtcGamma* gamma = XRRAllocGamma(ramp->size);

        memcpy(gamma->red, ramp->red, ramp->size * sizeof(unsigned short));
        memcpy(gamma->green, ramp->green, ramp->size * sizeof(unsigned short));
        memcpy(gamma->blue, ramp->blue, ramp->size * sizeof(unsigned short));

        XRRSetCrtcGamma(_glfw.x11.display, monitor->x11.crtc, gamma);
        XRRFreeGamma(gamma);
    }
#if defined(_GLFW_HAS_XF86VM)
    else if (_glfw.x11.vidmode.available)
    {
        XF86VidModeSetGammaRamp(_glfw.x11.display,
                                _glfw.x11.screen,
                                ramp->size,
                                (unsigned short*) ramp->red,
                                (unsigned short*) ramp->green,
                                (unsigned short*) ramp->blue);
    }
#endif /*_GLFW_HAS_XF86VM*/
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI RRCrtc glfwGetX11Adapter(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(None);
    return monitor->x11.crtc;
}

GLFWAPI RROutput glfwGetX11Monitor(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(None);
    return monitor->x11.output;
}

