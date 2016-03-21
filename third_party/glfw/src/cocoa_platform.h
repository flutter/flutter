//========================================================================
// GLFW 3.1 OS X - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2009-2010 Camilla Berglund <elmindreda@elmindreda.org>
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

#ifndef _glfw3_cocoa_platform_h_
#define _glfw3_cocoa_platform_h_

#include <stdint.h>

#if defined(__OBJC__)
#import <Cocoa/Cocoa.h>
#else
#include <ApplicationServices/ApplicationServices.h>
typedef void* id;
#endif

#include "posix_tls.h"
#include "iokit_joystick.h"

#if defined(_GLFW_NSGL)
 #include "nsgl_context.h"
#else
 #error "The Cocoa backend depends on NSGL platform support"
#endif

#define _GLFW_PLATFORM_WINDOW_STATE         _GLFWwindowNS  ns
#define _GLFW_PLATFORM_LIBRARY_WINDOW_STATE _GLFWlibraryNS ns
#define _GLFW_PLATFORM_LIBRARY_TIME_STATE   _GLFWtimeNS    ns_time
#define _GLFW_PLATFORM_MONITOR_STATE        _GLFWmonitorNS ns
#define _GLFW_PLATFORM_CURSOR_STATE         _GLFWcursorNS  ns


// Cocoa-specific per-window data
//
typedef struct _GLFWwindowNS
{
    id              object;
    id              delegate;
    id              view;
    unsigned int    modifierFlags;

    // The total sum of the distances the cursor has been warped
    // since the last cursor motion event was processed
    // This is kept to counteract Cocoa doing the same internally
    double          warpDeltaX, warpDeltaY;

} _GLFWwindowNS;


// Cocoa-specific global data
//
typedef struct _GLFWlibraryNS
{
    CGEventSourceRef eventSource;
    id              delegate;
    id              autoreleasePool;
    id              cursor;

    short int       publicKeys[256];
    char*           clipboardString;

} _GLFWlibraryNS;


// Cocoa-specific per-monitor data
//
typedef struct _GLFWmonitorNS
{
    CGDirectDisplayID   displayID;
    CGDisplayModeRef    previousMode;
    uint32_t            unitNumber;

} _GLFWmonitorNS;


// Cocoa-specific per-cursor data
//
typedef struct _GLFWcursorNS
{
    id              object;

} _GLFWcursorNS;


// Cocoa-specific global timer data
//
typedef struct _GLFWtimeNS
{
    double          base;
    double          resolution;

} _GLFWtimeNS;


void _glfwInitTimer(void);

GLboolean _glfwSetVideoMode(_GLFWmonitor* monitor, const GLFWvidmode* desired);
void _glfwRestoreVideoMode(_GLFWmonitor* monitor);

#endif // _glfw3_cocoa_platform_h_
