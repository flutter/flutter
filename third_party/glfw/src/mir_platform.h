//========================================================================
// GLFW 3.2 Mir - www.glfw.org
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

#ifndef _glfw3_mir_platform_h_
#define _glfw3_mir_platform_h_

#include <sys/queue.h>
#include <pthread.h>
#include <dlfcn.h>

#include <mir_toolkit/mir_client_library.h>

typedef VkFlags VkMirSurfaceCreateFlagsKHR;

typedef struct VkMirSurfaceCreateInfoKHR
{
    VkStructureType             sType;
    const void*                 pNext;
    VkMirSurfaceCreateFlagsKHR  flags;
    MirConnection*              connection;
    MirSurface*                 mirSurface;
} VkMirSurfaceCreateInfoKHR;

typedef VkResult (APIENTRY *PFN_vkCreateMirSurfaceKHR)(VkInstance,const VkMirSurfaceCreateInfoKHR*,const VkAllocationCallbacks*,VkSurfaceKHR*);
typedef VkBool32 (APIENTRY *PFN_vkGetPhysicalDeviceMirPresentationSupportKHR)(VkPhysicalDevice,uint32_t,MirConnection*);

#include "posix_tls.h"
#include "posix_time.h"
#include "linux_joystick.h"
#include "xkb_unicode.h"

#if defined(_GLFW_EGL)
 #include "egl_context.h"
#else
 #error "The Mir backend depends on EGL platform support"
#endif

#define _glfw_dlopen(name) dlopen(name, RTLD_LAZY | RTLD_LOCAL)
#define _glfw_dlclose(handle) dlclose(handle)
#define _glfw_dlsym(handle, name) dlsym(handle, name)

#define _GLFW_EGL_NATIVE_WINDOW  ((EGLNativeWindowType) window->mir.window)
#define _GLFW_EGL_NATIVE_DISPLAY ((EGLNativeDisplayType) _glfw.mir.display)

#define _GLFW_PLATFORM_WINDOW_STATE         _GLFWwindowMir  mir
#define _GLFW_PLATFORM_MONITOR_STATE        _GLFWmonitorMir mir
#define _GLFW_PLATFORM_LIBRARY_WINDOW_STATE _GLFWlibraryMir mir
#define _GLFW_PLATFORM_CURSOR_STATE         _GLFWcursorMir  mir


// Mir-specific Event Queue
//
typedef struct EventQueue
{
    TAILQ_HEAD(, EventNode) head;
} EventQueue;

// Mir-specific per-window data
//
typedef struct _GLFWwindowMir
{
    MirSurface*             surface;
    int                     width;
    int                     height;
    MirEGLNativeWindowType  window;

} _GLFWwindowMir;


// Mir-specific per-monitor data
//
typedef struct _GLFWmonitorMir
{
    int cur_mode;
    int output_id;
    int x;
    int y;

} _GLFWmonitorMir;


// Mir-specific global data
//
typedef struct _GLFWlibraryMir
{
    MirConnection*          connection;
    MirEGLNativeDisplayType display;
    MirCursorConfiguration* default_conf;
    EventQueue* event_queue;

    short int       publicKeys[256];

    pthread_mutex_t event_mutex;
    pthread_cond_t  event_cond;

} _GLFWlibraryMir;


// Mir-specific per-cursor data
// TODO: Only system cursors are implemented in Mir atm. Need to wait for support.
//
typedef struct _GLFWcursorMir
{
    MirCursorConfiguration* conf;
    MirBufferStream*        custom_cursor;
} _GLFWcursorMir;


extern void _glfwInitEventQueueMir(EventQueue* queue);
extern void _glfwDeleteEventQueueMir(EventQueue* queue);

#endif // _glfw3_mir_platform_h_
