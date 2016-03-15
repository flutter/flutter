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

#ifndef _glfw3_x11_platform_h_
#define _glfw3_x11_platform_h_

#include <unistd.h>
#include <signal.h>
#include <stdint.h>

#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <X11/Xatom.h>
#include <X11/Xcursor/Xcursor.h>

// The XRandR extension provides mode setting and gamma control
#include <X11/extensions/Xrandr.h>

// The Xkb extension provides improved keyboard support
#include <X11/XKBlib.h>

// The Xinerama extension provides legacy monitor indices
#include <X11/extensions/Xinerama.h>

#if defined(_GLFW_HAS_XINPUT)
 // The XInput2 extension provides improved input events
 #include <X11/extensions/XInput2.h>
#endif

#if defined(_GLFW_HAS_XF86VM)
 // The Xf86VidMode extension provides fallback gamma control
 #include <X11/extensions/xf86vmode.h>
#endif

#include "posix_tls.h"
#include "posix_time.h"
#include "linux_joystick.h"
#include "xkb_unicode.h"

#if defined(_GLFW_GLX)
 #define _GLFW_X11_CONTEXT_VISUAL window->glx.visual
 #include "glx_context.h"
#elif defined(_GLFW_EGL)
 #define _GLFW_X11_CONTEXT_VISUAL window->egl.visual
 #define _GLFW_EGL_NATIVE_WINDOW  window->x11.handle
 #define _GLFW_EGL_NATIVE_DISPLAY _glfw.x11.display
 #include "egl_context.h"
#else
 #error "No supported context creation API selected"
#endif

#define _GLFW_PLATFORM_WINDOW_STATE         _GLFWwindowX11  x11
#define _GLFW_PLATFORM_LIBRARY_WINDOW_STATE _GLFWlibraryX11 x11
#define _GLFW_PLATFORM_MONITOR_STATE        _GLFWmonitorX11 x11
#define _GLFW_PLATFORM_CURSOR_STATE         _GLFWcursorX11  x11


// X11-specific per-window data
//
typedef struct _GLFWwindowX11
{
    Colormap        colormap;
    Window          handle;
    XIC             ic;

    // Cached position and size used to filter out duplicate events
    int             width, height;
    int             xpos, ypos;

    // The last received cursor position, regardless of source
    double          cursorPosX, cursorPosY;
    // The last position the cursor was warped to by GLFW
    int             warpPosX, warpPosY;

    // The information from the last KeyPress event
    struct {
        unsigned int keycode;
        Time         time;
    } last;

} _GLFWwindowX11;


// X11-specific global data
//
typedef struct _GLFWlibraryX11
{
    Display*        display;
    int             screen;
    Window          root;

    // Invisible cursor for hidden cursor mode
    Cursor          cursor;
    // Context for mapping window XIDs to _GLFWwindow pointers
    XContext        context;
    // XIM input method
    XIM             im;
    // Most recent error code received by X error handler
    int             errorCode;
    // Clipboard string (while the selection is owned)
    char*           clipboardString;
    // X11 keycode to GLFW key LUT
    short int       publicKeys[256];

    // Window manager atoms
    Atom            WM_PROTOCOLS;
    Atom            WM_STATE;
    Atom            WM_DELETE_WINDOW;
    Atom            NET_WM_NAME;
    Atom            NET_WM_ICON_NAME;
    Atom            NET_WM_PID;
    Atom            NET_WM_PING;
    Atom            NET_WM_STATE;
    Atom            NET_WM_STATE_ABOVE;
    Atom            NET_WM_STATE_FULLSCREEN;
    Atom            NET_WM_BYPASS_COMPOSITOR;
    Atom            NET_WM_FULLSCREEN_MONITORS;
    Atom            NET_ACTIVE_WINDOW;
    Atom            NET_FRAME_EXTENTS;
    Atom            NET_REQUEST_FRAME_EXTENTS;
    Atom            MOTIF_WM_HINTS;

    // Xdnd (drag and drop) atoms
    Atom            XdndAware;
    Atom            XdndEnter;
    Atom            XdndPosition;
    Atom            XdndStatus;
    Atom            XdndActionCopy;
    Atom            XdndDrop;
    Atom            XdndLeave;
    Atom            XdndFinished;
    Atom            XdndSelection;

    // Selection (clipboard) atoms
    Atom            TARGETS;
    Atom            MULTIPLE;
    Atom            CLIPBOARD;
    Atom            CLIPBOARD_MANAGER;
    Atom            SAVE_TARGETS;
    Atom            NULL_;
    Atom            UTF8_STRING;
    Atom            COMPOUND_STRING;
    Atom            ATOM_PAIR;
    Atom            GLFW_SELECTION;

    struct {
        GLboolean   available;
        int         eventBase;
        int         errorBase;
        int         major;
        int         minor;
        GLboolean   gammaBroken;
        GLboolean   monitorBroken;
    } randr;

    struct {
        GLboolean   available;
        GLboolean   detectable;
        int         majorOpcode;
        int         eventBase;
        int         errorBase;
        int         major;
        int         minor;
    } xkb;

    struct {
        int         count;
        int         timeout;
        int         interval;
        int         blanking;
        int         exposure;
    } saver;

    struct {
        Window      source;
    } xdnd;

    struct {
        GLboolean   available;
        int         major;
        int         minor;
    } xinerama;

#if defined(_GLFW_HAS_XINPUT)
    struct {
        GLboolean   available;
        int         majorOpcode;
        int         eventBase;
        int         errorBase;
        int         major;
        int         minor;
    } xi;
#endif /*_GLFW_HAS_XINPUT*/

#if defined(_GLFW_HAS_XF86VM)
    struct {
        GLboolean   available;
        int         eventBase;
        int         errorBase;
    } vidmode;
#endif /*_GLFW_HAS_XF86VM*/

} _GLFWlibraryX11;


// X11-specific per-monitor data
//
typedef struct _GLFWmonitorX11
{
    RROutput        output;
    RRCrtc          crtc;
    RRMode          oldMode;

    // Index of corresponding Xinerama screen,
    // for EWMH full screen window placement
    int             index;

} _GLFWmonitorX11;


// X11-specific per-cursor data
//
typedef struct _GLFWcursorX11
{
    Cursor handle;

} _GLFWcursorX11;


GLboolean _glfwSetVideoMode(_GLFWmonitor* monitor, const GLFWvidmode* desired);
void _glfwRestoreVideoMode(_GLFWmonitor* monitor);

Cursor _glfwCreateCursor(const GLFWimage* image, int xhot, int yhot);

unsigned long _glfwGetWindowProperty(Window window,
                                     Atom property,
                                     Atom type,
                                     unsigned char** value);

void _glfwGrabXErrorHandler(void);
void _glfwReleaseXErrorHandler(void);
void _glfwInputXError(int error, const char* message);

#endif // _glfw3_x11_platform_h_
