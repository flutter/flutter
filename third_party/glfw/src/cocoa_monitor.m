//========================================================================
// GLFW 3.2 OS X - www.glfw.org
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
#include <stdlib.h>
#include <limits.h>

#include <IOKit/graphics/IOGraphicsLib.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <CoreVideo/CVBase.h>
#include <CoreVideo/CVDisplayLink.h>
#include <ApplicationServices/ApplicationServices.h>


// Get the name of the specified display
//
static char* getDisplayName(CGDirectDisplayID displayID)
{
    char* name;
    CFDictionaryRef info, names;
    CFStringRef value;
    CFIndex size;

    // NOTE: This uses a deprecated function because Apple has
    //       (as of January 2015) not provided any alternative
    info = IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID),
                                         kIODisplayOnlyPreferredName);
    names = CFDictionaryGetValue(info, CFSTR(kDisplayProductName));

    if (!names || !CFDictionaryGetValueIfPresent(names, CFSTR("en_US"),
                                                 (const void**) &value))
    {
        // This may happen if a desktop Mac is running headless
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Failed to retrieve display name");

        CFRelease(info);
        return strdup("Unknown");
    }

    size = CFStringGetMaximumSizeForEncoding(CFStringGetLength(value),
                                             kCFStringEncodingUTF8);
    name = calloc(size + 1, sizeof(char));
    CFStringGetCString(value, name, size, kCFStringEncodingUTF8);

    CFRelease(info);

    return name;
}

// Check whether the display mode should be included in enumeration
//
static GLFWbool modeIsGood(CGDisplayModeRef mode)
{
    uint32_t flags = CGDisplayModeGetIOFlags(mode);
    if (!(flags & kDisplayModeValidFlag) || !(flags & kDisplayModeSafeFlag))
        return GLFW_FALSE;

    if (flags & kDisplayModeInterlacedFlag)
        return GLFW_FALSE;

    if (flags & kDisplayModeStretchedFlag)
        return GLFW_FALSE;

    CFStringRef format = CGDisplayModeCopyPixelEncoding(mode);
    if (CFStringCompare(format, CFSTR(IO16BitDirectPixels), 0) &&
        CFStringCompare(format, CFSTR(IO32BitDirectPixels), 0))
    {
        CFRelease(format);
        return GLFW_FALSE;
    }

    CFRelease(format);
    return GLFW_TRUE;
}

// Convert Core Graphics display mode to GLFW video mode
//
static GLFWvidmode vidmodeFromCGDisplayMode(CGDisplayModeRef mode,
                                            CVDisplayLinkRef link)
{
    GLFWvidmode result;
    result.width = (int) CGDisplayModeGetWidth(mode);
    result.height = (int) CGDisplayModeGetHeight(mode);
    result.refreshRate = (int) CGDisplayModeGetRefreshRate(mode);

    if (result.refreshRate == 0)
    {
        const CVTime time = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(link);
        if (!(time.flags & kCVTimeIsIndefinite))
            result.refreshRate = (int) (time.timeScale / (double) time.timeValue);
    }

    CFStringRef format = CGDisplayModeCopyPixelEncoding(mode);

    if (CFStringCompare(format, CFSTR(IO16BitDirectPixels), 0) == 0)
    {
        result.redBits = 5;
        result.greenBits = 5;
        result.blueBits = 5;
    }
    else
    {
        result.redBits = 8;
        result.greenBits = 8;
        result.blueBits = 8;
    }

    CFRelease(format);
    return result;
}

// Starts reservation for display fading
//
static CGDisplayFadeReservationToken beginFadeReservation(void)
{
    CGDisplayFadeReservationToken token = kCGDisplayFadeReservationInvalidToken;

    if (CGAcquireDisplayFadeReservation(5, &token) == kCGErrorSuccess)
        CGDisplayFade(token, 0.3, kCGDisplayBlendNormal, kCGDisplayBlendSolidColor, 0.0, 0.0, 0.0, TRUE);

    return token;
}

// Ends reservation for display fading
//
static void endFadeReservation(CGDisplayFadeReservationToken token)
{
    if (token != kCGDisplayFadeReservationInvalidToken)
    {
        CGDisplayFade(token, 0.5, kCGDisplayBlendSolidColor, kCGDisplayBlendNormal, 0.0, 0.0, 0.0, FALSE);
        CGReleaseDisplayFadeReservation(token);
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Change the current video mode
//
GLFWbool _glfwSetVideoModeNS(_GLFWmonitor* monitor, const GLFWvidmode* desired)
{
    CFArrayRef modes;
    CFIndex count, i;
    CVDisplayLinkRef link;
    CGDisplayModeRef native = NULL;
    GLFWvidmode current;
    const GLFWvidmode* best;

    best = _glfwChooseVideoMode(monitor, desired);
    _glfwPlatformGetVideoMode(monitor, &current);
    if (_glfwCompareVideoModes(&current, best) == 0)
        return GLFW_TRUE;

    CVDisplayLinkCreateWithCGDisplay(monitor->ns.displayID, &link);

    modes = CGDisplayCopyAllDisplayModes(monitor->ns.displayID, NULL);
    count = CFArrayGetCount(modes);

    for (i = 0;  i < count;  i++)
    {
        CGDisplayModeRef dm = (CGDisplayModeRef) CFArrayGetValueAtIndex(modes, i);
        if (!modeIsGood(dm))
            continue;

        const GLFWvidmode mode = vidmodeFromCGDisplayMode(dm, link);
        if (_glfwCompareVideoModes(best, &mode) == 0)
        {
            native = dm;
            break;
        }
    }

    if (native)
    {
        if (monitor->ns.previousMode == NULL)
            monitor->ns.previousMode = CGDisplayCopyDisplayMode(monitor->ns.displayID);

        CGDisplayFadeReservationToken token = beginFadeReservation();
        CGDisplaySetDisplayMode(monitor->ns.displayID, native, NULL);
        endFadeReservation(token);
    }

    CFRelease(modes);
    CVDisplayLinkRelease(link);

    if (!native)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Cocoa: Monitor mode list changed");
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

// Restore the previously saved (original) video mode
//
void _glfwRestoreVideoModeNS(_GLFWmonitor* monitor)
{
    if (monitor->ns.previousMode)
    {
        CGDisplayFadeReservationToken token = beginFadeReservation();
        CGDisplaySetDisplayMode(monitor->ns.displayID,
                                monitor->ns.previousMode, NULL);
        endFadeReservation(token);

        CGDisplayModeRelease(monitor->ns.previousMode);
        monitor->ns.previousMode = NULL;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

_GLFWmonitor** _glfwPlatformGetMonitors(int* count)
{
    uint32_t i, found = 0, displayCount;
    _GLFWmonitor** monitors;
    CGDirectDisplayID* displays;

    *count = 0;

    CGGetOnlineDisplayList(0, NULL, &displayCount);
    displays = calloc(displayCount, sizeof(CGDirectDisplayID));
    monitors = calloc(displayCount, sizeof(_GLFWmonitor*));

    CGGetOnlineDisplayList(displayCount, displays, &displayCount);

    for (i = 0;  i < displayCount;  i++)
    {
        _GLFWmonitor* monitor;

        if (CGDisplayIsAsleep(displays[i]))
            continue;

        const CGSize size = CGDisplayScreenSize(displays[i]);
        char* name = getDisplayName(displays[i]);

        monitor = _glfwAllocMonitor(name, size.width, size.height);
        monitor->ns.displayID  = displays[i];
        monitor->ns.unitNumber = CGDisplayUnitNumber(displays[i]);

        free(name);

        found++;
        monitors[found - 1] = monitor;
    }

    free(displays);

    *count = found;
    return monitors;
}

GLFWbool _glfwPlatformIsSameMonitor(_GLFWmonitor* first, _GLFWmonitor* second)
{
    // HACK: Compare unit numbers instead of display IDs to work around display
    //       replacement on machines with automatic graphics switching
    return first->ns.unitNumber == second->ns.unitNumber;
}

void _glfwPlatformGetMonitorPos(_GLFWmonitor* monitor, int* xpos, int* ypos)
{
    const CGRect bounds = CGDisplayBounds(monitor->ns.displayID);

    if (xpos)
        *xpos = (int) bounds.origin.x;
    if (ypos)
        *ypos = (int) bounds.origin.y;
}

GLFWvidmode* _glfwPlatformGetVideoModes(_GLFWmonitor* monitor, int* count)
{
    CFArrayRef modes;
    CFIndex found, i, j;
    GLFWvidmode* result;
    CVDisplayLinkRef link;

    *count = 0;

    CVDisplayLinkCreateWithCGDisplay(monitor->ns.displayID, &link);

    modes = CGDisplayCopyAllDisplayModes(monitor->ns.displayID, NULL);
    found = CFArrayGetCount(modes);
    result = calloc(found, sizeof(GLFWvidmode));

    for (i = 0;  i < found;  i++)
    {
        CGDisplayModeRef dm = (CGDisplayModeRef) CFArrayGetValueAtIndex(modes, i);
        if (!modeIsGood(dm))
            continue;

        const GLFWvidmode mode = vidmodeFromCGDisplayMode(dm, link);

        for (j = 0;  j < *count;  j++)
        {
            if (_glfwCompareVideoModes(result + j, &mode) == 0)
                break;
        }

        // Skip duplicate modes
        if (i < *count)
            continue;

        (*count)++;
        result[*count - 1] = mode;
    }

    CFRelease(modes);
    CVDisplayLinkRelease(link);
    return result;
}

void _glfwPlatformGetVideoMode(_GLFWmonitor* monitor, GLFWvidmode *mode)
{
    CGDisplayModeRef displayMode;
    CVDisplayLinkRef link;

    CVDisplayLinkCreateWithCGDisplay(monitor->ns.displayID, &link);

    displayMode = CGDisplayCopyDisplayMode(monitor->ns.displayID);
    *mode = vidmodeFromCGDisplayMode(displayMode, link);
    CGDisplayModeRelease(displayMode);

    CVDisplayLinkRelease(link);
}

void _glfwPlatformGetGammaRamp(_GLFWmonitor* monitor, GLFWgammaramp* ramp)
{
    uint32_t i, size = CGDisplayGammaTableCapacity(monitor->ns.displayID);
    CGGammaValue* values = calloc(size * 3, sizeof(CGGammaValue));

    CGGetDisplayTransferByTable(monitor->ns.displayID,
                                size,
                                values,
                                values + size,
                                values + size * 2,
                                &size);

    _glfwAllocGammaArrays(ramp, size);

    for (i = 0; i < size; i++)
    {
        ramp->red[i]   = (unsigned short) (values[i] * 65535);
        ramp->green[i] = (unsigned short) (values[i + size] * 65535);
        ramp->blue[i]  = (unsigned short) (values[i + size * 2] * 65535);
    }

    free(values);
}

void _glfwPlatformSetGammaRamp(_GLFWmonitor* monitor, const GLFWgammaramp* ramp)
{
    int i;
    CGGammaValue* values = calloc(ramp->size * 3, sizeof(CGGammaValue));

    for (i = 0;  i < ramp->size;  i++)
    {
        values[i]                  = ramp->red[i] / 65535.f;
        values[i + ramp->size]     = ramp->green[i] / 65535.f;
        values[i + ramp->size * 2] = ramp->blue[i] / 65535.f;
    }

    CGSetDisplayTransferByTable(monitor->ns.displayID,
                                ramp->size,
                                values,
                                values + ramp->size,
                                values + ramp->size * 2);

    free(values);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* handle)
{
    _GLFWmonitor* monitor = (_GLFWmonitor*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(kCGNullDirectDisplay);
    return monitor->ns.displayID;
}

