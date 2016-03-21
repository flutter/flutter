//========================================================================
// GLFW 3.1 Wayland - www.glfw.org
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

#ifndef _glfw3_wayland_platform_h_
#define _glfw3_wayland_platform_h_

#include <wayland-client.h>
#include <xkbcommon/xkbcommon.h>

#include "posix_tls.h"
#include "posix_time.h"
#include "linux_joystick.h"
#include "xkb_unicode.h"

#if defined(_GLFW_EGL)
 #include "egl_context.h"
#else
 #error "The Wayland backend depends on EGL platform support"
#endif

#define _GLFW_EGL_NATIVE_WINDOW         window->wl.native
#define _GLFW_EGL_NATIVE_DISPLAY        _glfw.wl.display

#define _GLFW_PLATFORM_WINDOW_STATE         _GLFWwindowWayland  wl
#define _GLFW_PLATFORM_LIBRARY_WINDOW_STATE _GLFWlibraryWayland wl
#define _GLFW_PLATFORM_MONITOR_STATE        _GLFWmonitorWayland wl
#define _GLFW_PLATFORM_CURSOR_STATE         _GLFWcursorWayland  wl


// Wayland-specific video mode data
//
typedef struct _GLFWvidmodeWayland _GLFWvidmodeWayland;


// Wayland-specific per-window data
//
typedef struct _GLFWwindowWayland
{
    int                         width, height;
    GLboolean                   visible;
    struct wl_surface*          surface;
    struct wl_egl_window*       native;
    struct wl_shell_surface*    shell_surface;
    struct wl_callback*         callback;
    _GLFWcursor*                currentCursor;
    double                      cursorPosX, cursorPosY;
} _GLFWwindowWayland;


// Wayland-specific global data
//
typedef struct _GLFWlibraryWayland
{
    struct wl_display*          display;
    struct wl_registry*         registry;
    struct wl_compositor*       compositor;
    struct wl_shell*            shell;
    struct wl_shm*              shm;
    struct wl_seat*             seat;
    struct wl_pointer*          pointer;
    struct wl_keyboard*         keyboard;

    struct wl_cursor_theme*     cursorTheme;
    struct wl_cursor*           defaultCursor;
    struct wl_surface*          cursorSurface;
    uint32_t                    pointerSerial;

    _GLFWmonitor**              monitors;
    int                         monitorsCount;
    int                         monitorsSize;

    struct {
        struct xkb_context*     context;
        struct xkb_keymap*      keymap;
        struct xkb_state*       state;
        xkb_mod_mask_t          control_mask;
        xkb_mod_mask_t          alt_mask;
        xkb_mod_mask_t          shift_mask;
        xkb_mod_mask_t          super_mask;
        unsigned int            modifiers;
    } xkb;

    _GLFWwindow*                pointerFocus;
    _GLFWwindow*                keyboardFocus;

} _GLFWlibraryWayland;


// Wayland-specific per-monitor data
//
typedef struct _GLFWmonitorWayland
{
    struct wl_output*           output;

    _GLFWvidmodeWayland*        modes;
    int                         modesCount;
    int                         modesSize;
    GLboolean                   done;

    int                         x;
    int                         y;

} _GLFWmonitorWayland;


// Wayland-specific per-cursor data
//
typedef struct _GLFWcursorWayland
{
    struct wl_buffer*           buffer;
    int                         width, height;
    int                         xhot, yhot;
} _GLFWcursorWayland;


void _glfwAddOutput(uint32_t name, uint32_t version);

#endif // _glfw3_wayland_platform_h_
