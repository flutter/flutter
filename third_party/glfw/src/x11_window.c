//========================================================================
// GLFW 3.2 X11 - www.glfw.org
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

#include <X11/cursorfont.h>
#include <X11/Xmd.h>

#include <sys/select.h>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <assert.h>

// Action for EWMH client messages
#define _NET_WM_STATE_REMOVE        0
#define _NET_WM_STATE_ADD           1
#define _NET_WM_STATE_TOGGLE        2

// Additional mouse button names for XButtonEvent
#define Button6            6
#define Button7            7


// Wait for data to arrive
//
void selectDisplayConnection(struct timeval* timeout)
{
    fd_set fds;
    int result;
    const int fd = ConnectionNumber(_glfw.x11.display);

    FD_ZERO(&fds);
    FD_SET(fd, &fds);

    // NOTE: We use select instead of an X function like XNextEvent, as the
    //       wait inside those are guarded by the mutex protecting the display
    //       struct, locking out other threads from using X (including GLX)
    // NOTE: Only retry on EINTR if there is no timeout, as select is not
    //       required to update it for the time elapsed
    // TODO: Update timeout value manually
    do
    {
        result = select(fd + 1, &fds, NULL, NULL, timeout);
    }
    while (result == -1 && errno == EINTR && timeout == NULL);
}

// Returns whether the window is iconified
//
static int getWindowState(_GLFWwindow* window)
{
    int result = WithdrawnState;
    struct {
        CARD32 state;
        Window icon;
    } *state = NULL;

    if (_glfwGetWindowPropertyX11(window->x11.handle,
                                  _glfw.x11.WM_STATE,
                                  _glfw.x11.WM_STATE,
                                  (unsigned char**) &state) >= 2)
    {
        result = state->state;
    }

    XFree(state);
    return result;
}

// Returns whether the event is a selection event
//
static Bool isFrameExtentsEvent(Display* display, XEvent* event, XPointer pointer)
{
    _GLFWwindow* window = (_GLFWwindow*) pointer;
    return event->type == PropertyNotify &&
           event->xproperty.state == PropertyNewValue &&
           event->xproperty.window == window->x11.handle &&
           event->xproperty.atom == _glfw.x11.NET_FRAME_EXTENTS;
}

// Translates a GLFW standard cursor to a font cursor shape
//
static int translateCursorShape(int shape)
{
    switch (shape)
    {
        case GLFW_ARROW_CURSOR:
            return XC_left_ptr;
        case GLFW_IBEAM_CURSOR:
            return XC_xterm;
        case GLFW_CROSSHAIR_CURSOR:
            return XC_crosshair;
        case GLFW_HAND_CURSOR:
            return XC_hand1;
        case GLFW_HRESIZE_CURSOR:
            return XC_sb_h_double_arrow;
        case GLFW_VRESIZE_CURSOR:
            return XC_sb_v_double_arrow;
    }

    return 0;
}

// Translates an X event modifier state mask
//
static int translateState(int state)
{
    int mods = 0;

    if (state & ShiftMask)
        mods |= GLFW_MOD_SHIFT;
    if (state & ControlMask)
        mods |= GLFW_MOD_CONTROL;
    if (state & Mod1Mask)
        mods |= GLFW_MOD_ALT;
    if (state & Mod4Mask)
        mods |= GLFW_MOD_SUPER;

    return mods;
}

// Translates an X11 key code to a GLFW key token
//
static int translateKey(int scancode)
{
    // Use the pre-filled LUT (see createKeyTables() in x11_init.c)
    if (scancode < 0 || scancode > 255)
        return GLFW_KEY_UNKNOWN;

    return _glfw.x11.publicKeys[scancode];
}

// Return the GLFW window corresponding to the specified X11 window
//
static _GLFWwindow* findWindowByHandle(Window handle)
{
    _GLFWwindow* window;

    if (XFindContext(_glfw.x11.display,
                     handle,
                     _glfw.x11.context,
                     (XPointer*) &window) != 0)
    {
        return NULL;
    }

    return window;
}

// Sends an EWMH or ICCCM event to the window manager
//
static void sendEventToWM(_GLFWwindow* window, Atom type,
                          long a, long b, long c, long d, long e)
{
    XEvent event;
    memset(&event, 0, sizeof(event));

    event.type = ClientMessage;
    event.xclient.window = window->x11.handle;
    event.xclient.format = 32; // Data is 32-bit longs
    event.xclient.message_type = type;
    event.xclient.data.l[0] = a;
    event.xclient.data.l[1] = b;
    event.xclient.data.l[2] = c;
    event.xclient.data.l[3] = d;
    event.xclient.data.l[4] = e;

    XSendEvent(_glfw.x11.display, _glfw.x11.root,
               False,
               SubstructureNotifyMask | SubstructureRedirectMask,
               &event);
}

// Updates the normal hints according to the window settings
//
static void updateNormalHints(_GLFWwindow* window)
{
    XSizeHints* hints = XAllocSizeHints();

    if (!window->monitor)
    {
        if (window->resizable)
        {
            if (window->minwidth != GLFW_DONT_CARE &&
                window->minwidth != GLFW_DONT_CARE &&
                window->maxwidth != GLFW_DONT_CARE &&
                window->maxwidth != GLFW_DONT_CARE)
            {
                hints->flags |= (PMinSize | PMaxSize);
                hints->min_width  = window->minwidth;
                hints->min_height = window->minheight;
                hints->max_width  = window->maxwidth;
                hints->max_height = window->maxheight;
            }

            if (window->numer != GLFW_DONT_CARE &&
                window->denom != GLFW_DONT_CARE)
            {
                hints->flags |= PAspect;
                hints->min_aspect.x = hints->max_aspect.x = window->numer;
                hints->min_aspect.y = hints->max_aspect.y = window->denom;
            }
        }
        else
        {
            int width, height;
            _glfwPlatformGetWindowSize(window, &width, &height);

            hints->flags |= (PMinSize | PMaxSize);
            hints->min_width  = hints->max_width  = width;
            hints->min_height = hints->max_height = height;
        }
    }

    XSetWMNormalHints(_glfw.x11.display, window->x11.handle, hints);
    XFree(hints);
}

// Updates the full screen status of the window
//
static void updateWindowMode(_GLFWwindow* window)
{
    updateNormalHints(window);

    if (window->monitor)
    {
        if (_glfw.x11.xinerama.available &&
            _glfw.x11.NET_WM_FULLSCREEN_MONITORS)
        {
            sendEventToWM(window,
                          _glfw.x11.NET_WM_FULLSCREEN_MONITORS,
                          window->monitor->x11.index,
                          window->monitor->x11.index,
                          window->monitor->x11.index,
                          window->monitor->x11.index,
                          0);
        }

        if (_glfw.x11.NET_WM_STATE && _glfw.x11.NET_WM_STATE_FULLSCREEN)
        {
            sendEventToWM(window,
                          _glfw.x11.NET_WM_STATE,
                          _NET_WM_STATE_ADD,
                          _glfw.x11.NET_WM_STATE_FULLSCREEN,
                          0, 1, 0);
        }
        else
        {
            // This is the butcher's way of removing window decorations
            // Setting the override-redirect attribute on a window makes the
            // window manager ignore the window completely (ICCCM, section 4)
            // The good thing is that this makes undecorated full screen windows
            // easy to do; the bad thing is that we have to do everything
            // manually and some things (like iconify/restore) won't work at
            // all, as those are tasks usually performed by the window manager

            XSetWindowAttributes attributes;
            attributes.override_redirect = True;
            XChangeWindowAttributes(_glfw.x11.display,
                                    window->x11.handle,
                                    CWOverrideRedirect,
                                    &attributes);

            window->x11.overrideRedirect = GLFW_TRUE;
        }

        if (_glfw.x11.NET_WM_BYPASS_COMPOSITOR)
        {
            const unsigned long value = 1;

            XChangeProperty(_glfw.x11.display,  window->x11.handle,
                            _glfw.x11.NET_WM_BYPASS_COMPOSITOR, XA_CARDINAL, 32,
                            PropModeReplace, (unsigned char*) &value, 1);
        }
    }
    else
    {
        if (_glfw.x11.xinerama.available &&
            _glfw.x11.NET_WM_FULLSCREEN_MONITORS)
        {
            XDeleteProperty(_glfw.x11.display, window->x11.handle,
                            _glfw.x11.NET_WM_FULLSCREEN_MONITORS);
        }

        if (_glfw.x11.NET_WM_STATE && _glfw.x11.NET_WM_STATE_FULLSCREEN)
        {
            sendEventToWM(window,
                          _glfw.x11.NET_WM_STATE,
                          _NET_WM_STATE_REMOVE,
                          _glfw.x11.NET_WM_STATE_FULLSCREEN,
                          0, 1, 0);
        }
        else
        {
            XSetWindowAttributes attributes;
            attributes.override_redirect = False;
            XChangeWindowAttributes(_glfw.x11.display,
                                    window->x11.handle,
                                    CWOverrideRedirect,
                                    &attributes);

            window->x11.overrideRedirect = GLFW_FALSE;
        }

        if (_glfw.x11.NET_WM_BYPASS_COMPOSITOR)
        {
            XDeleteProperty(_glfw.x11.display, window->x11.handle,
                            _glfw.x11.NET_WM_BYPASS_COMPOSITOR);
        }
    }
}

// Splits and translates a text/uri-list into separate file paths
// NOTE: This function destroys the provided string
//
static char** parseUriList(char* text, int* count)
{
    const char* prefix = "file://";
    char** paths = NULL;
    char* line;

    *count = 0;

    while ((line = strtok(text, "\r\n")))
    {
        text = NULL;

        if (line[0] == '#')
            continue;

        if (strncmp(line, prefix, strlen(prefix)) == 0)
            line += strlen(prefix);

        (*count)++;

        char* path = calloc(strlen(line) + 1, 1);
        paths = realloc(paths, *count * sizeof(char*));
        paths[*count - 1] = path;

        while (*line)
        {
            if (line[0] == '%' && line[1] && line[2])
            {
                const char digits[3] = { line[1], line[2], '\0' };
                *path = strtol(digits, NULL, 16);
                line += 2;
            }
            else
                *path = *line;

            path++;
            line++;
        }
    }

    return paths;
}

// Create the X11 window (and its colormap)
//
static GLFWbool createWindow(_GLFWwindow* window,
                             const _GLFWwndconfig* wndconfig,
                             Visual* visual, int depth)
{
    // Every window needs a colormap
    // Create one based on the visual used by the current context
    // TODO: Decouple this from context creation

    window->x11.colormap = XCreateColormap(_glfw.x11.display,
                                           _glfw.x11.root,
                                           visual,
                                           AllocNone);

    // Create the actual window
    {
        XSetWindowAttributes wa;
        const unsigned long wamask = CWBorderPixel | CWColormap | CWEventMask;

        wa.colormap = window->x11.colormap;
        wa.border_pixel = 0;
        wa.event_mask = StructureNotifyMask | KeyPressMask | KeyReleaseMask |
                        PointerMotionMask | ButtonPressMask | ButtonReleaseMask |
                        ExposureMask | FocusChangeMask | VisibilityChangeMask |
                        EnterWindowMask | LeaveWindowMask | PropertyChangeMask;

        _glfwGrabErrorHandlerX11();

        window->x11.handle = XCreateWindow(_glfw.x11.display,
                                           _glfw.x11.root,
                                           0, 0,
                                           wndconfig->width, wndconfig->height,
                                           0,      // Border width
                                           depth,  // Color depth
                                           InputOutput,
                                           visual,
                                           wamask,
                                           &wa);

        _glfwReleaseErrorHandlerX11();

        if (!window->x11.handle)
        {
            _glfwInputErrorX11(GLFW_PLATFORM_ERROR,
                               "X11: Failed to create window");
            return GLFW_FALSE;
        }

        XSaveContext(_glfw.x11.display,
                     window->x11.handle,
                     _glfw.x11.context,
                     (XPointer) window);
    }

    if (!wndconfig->decorated)
    {
        struct
        {
            unsigned long flags;
            unsigned long functions;
            unsigned long decorations;
            long input_mode;
            unsigned long status;
        } hints;

        hints.flags = 2;       // Set decorations
        hints.decorations = 0; // No decorations

        XChangeProperty(_glfw.x11.display, window->x11.handle,
                        _glfw.x11.MOTIF_WM_HINTS,
                        _glfw.x11.MOTIF_WM_HINTS, 32,
                        PropModeReplace,
                        (unsigned char*) &hints,
                        sizeof(hints) / sizeof(long));
    }

    if (wndconfig->floating)
    {
        if (_glfw.x11.NET_WM_STATE && _glfw.x11.NET_WM_STATE_ABOVE)
        {
            Atom value = _glfw.x11.NET_WM_STATE_ABOVE;
            XChangeProperty(_glfw.x11.display, window->x11.handle,
                            _glfw.x11.NET_WM_STATE, XA_ATOM, 32,
                            PropModeReplace, (unsigned char*) &value, 1);
        }
    }

    if (wndconfig->maximized && !window->monitor)
    {
        if (_glfw.x11.NET_WM_STATE &&
            _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT &&
            _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ)
        {
            const Atom states[2] =
            {
                _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT,
                _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ
            };

            XChangeProperty(_glfw.x11.display, window->x11.handle,
                            _glfw.x11.NET_WM_STATE, XA_ATOM, 32,
                            PropModeReplace, (unsigned char*) &states, 2);
        }
    }

    // Declare the WM protocols supported by GLFW
    {
        int count = 0;
        Atom protocols[2];

        // The WM_DELETE_WINDOW ICCCM protocol
        // Basic window close notification protocol
        if (_glfw.x11.WM_DELETE_WINDOW)
            protocols[count++] = _glfw.x11.WM_DELETE_WINDOW;

        // The _NET_WM_PING EWMH protocol
        // Tells the WM to ping the GLFW window and flag the application as
        // unresponsive if the WM doesn't get a reply within a few seconds
        if (_glfw.x11.NET_WM_PING)
            protocols[count++] = _glfw.x11.NET_WM_PING;

        if (count > 0)
        {
            XSetWMProtocols(_glfw.x11.display, window->x11.handle,
                            protocols, count);
        }
    }

    if (_glfw.x11.NET_WM_PID)
    {
        const pid_t pid = getpid();

        XChangeProperty(_glfw.x11.display,  window->x11.handle,
                        _glfw.x11.NET_WM_PID, XA_CARDINAL, 32,
                        PropModeReplace,
                        (unsigned char*) &pid, 1);
    }

    if (_glfw.x11.NET_WM_WINDOW_TYPE && _glfw.x11.NET_WM_WINDOW_TYPE_NORMAL)
    {
        Atom type = _glfw.x11.NET_WM_WINDOW_TYPE_NORMAL;
        XChangeProperty(_glfw.x11.display,  window->x11.handle,
                        _glfw.x11.NET_WM_WINDOW_TYPE, XA_ATOM, 32,
                        PropModeReplace, (unsigned char*) &type, 1);
    }

    // Set ICCCM WM_HINTS property
    {
        XWMHints* hints = XAllocWMHints();
        if (!hints)
        {
            _glfwInputError(GLFW_OUT_OF_MEMORY,
                            "X11: Failed to allocate WM hints");
            return GLFW_FALSE;
        }

        hints->flags = StateHint;
        hints->initial_state = NormalState;

        XSetWMHints(_glfw.x11.display, window->x11.handle, hints);
        XFree(hints);
    }

    updateNormalHints(window);

    // Set ICCCM WM_CLASS property
    // HACK: Until a mechanism for specifying the application name is added, the
    //       initial window title is used as the window class name
    if (strlen(wndconfig->title))
    {
        XClassHint* hint = XAllocClassHint();
        hint->res_name = (char*) wndconfig->title;
        hint->res_class = (char*) wndconfig->title;

        XSetClassHint(_glfw.x11.display, window->x11.handle, hint);
        XFree(hint);
    }

    if (_glfw.x11.XdndAware)
    {
        // Announce support for Xdnd (drag and drop)
        const Atom version = 5;
        XChangeProperty(_glfw.x11.display, window->x11.handle,
                        _glfw.x11.XdndAware, XA_ATOM, 32,
                        PropModeReplace, (unsigned char*) &version, 1);
    }

    _glfwPlatformSetWindowTitle(window, wndconfig->title);

    if (_glfw.x11.im)
    {
        window->x11.ic = XCreateIC(_glfw.x11.im,
                                   XNInputStyle,
                                   XIMPreeditNothing | XIMStatusNothing,
                                   XNClientWindow,
                                   window->x11.handle,
                                   XNFocusWindow,
                                   window->x11.handle,
                                   NULL);
    }

    _glfwPlatformGetWindowPos(window, &window->x11.xpos, &window->x11.ypos);
    _glfwPlatformGetWindowSize(window, &window->x11.width, &window->x11.height);

    return GLFW_TRUE;
}

// Returns whether the event is a selection event
//
static Bool isSelectionEvent(Display* display, XEvent* event, XPointer pointer)
{
    return event->type == SelectionRequest ||
           event->type == SelectionNotify ||
           event->type == SelectionClear;
}

// Set the specified property to the selection converted to the requested target
//
static Atom writeTargetToProperty(const XSelectionRequestEvent* request)
{
    int i;
    const Atom formats[] = { _glfw.x11.UTF8_STRING,
                             _glfw.x11.COMPOUND_STRING,
                             XA_STRING };
    const int formatCount = sizeof(formats) / sizeof(formats[0]);

    if (request->property == None)
    {
        // The requester is a legacy client (ICCCM section 2.2)
        // We don't support legacy clients, so fail here
        return None;
    }

    if (request->target == _glfw.x11.TARGETS)
    {
        // The list of supported targets was requested

        const Atom targets[] = { _glfw.x11.TARGETS,
                                 _glfw.x11.MULTIPLE,
                                 _glfw.x11.UTF8_STRING,
                                 _glfw.x11.COMPOUND_STRING,
                                 XA_STRING };

        XChangeProperty(_glfw.x11.display,
                        request->requestor,
                        request->property,
                        XA_ATOM,
                        32,
                        PropModeReplace,
                        (unsigned char*) targets,
                        sizeof(targets) / sizeof(targets[0]));

        return request->property;
    }

    if (request->target == _glfw.x11.MULTIPLE)
    {
        // Multiple conversions were requested

        Atom* targets;
        unsigned long i, count;

        count = _glfwGetWindowPropertyX11(request->requestor,
                                          request->property,
                                          _glfw.x11.ATOM_PAIR,
                                          (unsigned char**) &targets);

        for (i = 0;  i < count;  i += 2)
        {
            int j;

            for (j = 0;  j < formatCount;  j++)
            {
                if (targets[i] == formats[j])
                    break;
            }

            if (j < formatCount)
            {
                XChangeProperty(_glfw.x11.display,
                                request->requestor,
                                targets[i + 1],
                                targets[i],
                                8,
                                PropModeReplace,
                                (unsigned char*) _glfw.x11.clipboardString,
                                strlen(_glfw.x11.clipboardString));
            }
            else
                targets[i + 1] = None;
        }

        XChangeProperty(_glfw.x11.display,
                        request->requestor,
                        request->property,
                        _glfw.x11.ATOM_PAIR,
                        32,
                        PropModeReplace,
                        (unsigned char*) targets,
                        count);

        XFree(targets);

        return request->property;
    }

    if (request->target == _glfw.x11.SAVE_TARGETS)
    {
        // The request is a check whether we support SAVE_TARGETS
        // It should be handled as a no-op side effect target

        XChangeProperty(_glfw.x11.display,
                        request->requestor,
                        request->property,
                        _glfw.x11.NULL_,
                        32,
                        PropModeReplace,
                        NULL,
                        0);

        return request->property;
    }

    // Conversion to a data target was requested

    for (i = 0;  i < formatCount;  i++)
    {
        if (request->target == formats[i])
        {
            // The requested target is one we support

            XChangeProperty(_glfw.x11.display,
                            request->requestor,
                            request->property,
                            request->target,
                            8,
                            PropModeReplace,
                            (unsigned char*) _glfw.x11.clipboardString,
                            strlen(_glfw.x11.clipboardString));

            return request->property;
        }
    }

    // The requested target is not supported

    return None;
}

static void handleSelectionClear(XEvent* event)
{
    free(_glfw.x11.clipboardString);
    _glfw.x11.clipboardString = NULL;
}

static void handleSelectionRequest(XEvent* event)
{
    const XSelectionRequestEvent* request = &event->xselectionrequest;

    XEvent reply;
    memset(&reply, 0, sizeof(reply));

    reply.xselection.property = writeTargetToProperty(request);
    reply.xselection.type = SelectionNotify;
    reply.xselection.display = request->display;
    reply.xselection.requestor = request->requestor;
    reply.xselection.selection = request->selection;
    reply.xselection.target = request->target;
    reply.xselection.time = request->time;

    XSendEvent(_glfw.x11.display, request->requestor, False, 0, &reply);
}

static void pushSelectionToManager(_GLFWwindow* window)
{
    XConvertSelection(_glfw.x11.display,
                      _glfw.x11.CLIPBOARD_MANAGER,
                      _glfw.x11.SAVE_TARGETS,
                      None,
                      window->x11.handle,
                      CurrentTime);

    for (;;)
    {
        XEvent event;

        while (XCheckIfEvent(_glfw.x11.display, &event, isSelectionEvent, NULL))
        {
            switch (event.type)
            {
                case SelectionRequest:
                    handleSelectionRequest(&event);
                    break;

                case SelectionClear:
                    handleSelectionClear(&event);
                    break;

                case SelectionNotify:
                {
                    if (event.xselection.target == _glfw.x11.SAVE_TARGETS)
                    {
                        // This means one of two things; either the selection was
                        // not owned, which means there is no clipboard manager, or
                        // the transfer to the clipboard manager has completed
                        // In either case, it means we are done here
                        return;
                    }

                    break;
                }
            }
        }

        selectDisplayConnection(NULL);
    }
}

// Make the specified window and its video mode active on its monitor
//
static GLFWbool acquireMonitor(_GLFWwindow* window)
{
    GLFWbool status;

    if (_glfw.x11.saver.count == 0)
    {
        // Remember old screen saver settings
        XGetScreenSaver(_glfw.x11.display,
                        &_glfw.x11.saver.timeout,
                        &_glfw.x11.saver.interval,
                        &_glfw.x11.saver.blanking,
                        &_glfw.x11.saver.exposure);

        // Disable screen saver
        XSetScreenSaver(_glfw.x11.display, 0, 0, DontPreferBlanking,
                        DefaultExposures);
    }

    if (!window->monitor->window)
        _glfw.x11.saver.count++;

    status = _glfwSetVideoModeX11(window->monitor, &window->videoMode);

    if (window->x11.overrideRedirect)
    {
        int xpos, ypos;
        GLFWvidmode mode;

        // Manually position the window over its monitor
        _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);
        _glfwPlatformGetVideoMode(window->monitor, &mode);

        XMoveResizeWindow(_glfw.x11.display, window->x11.handle,
                          xpos, ypos, mode.width, mode.height);
    }

    _glfwInputMonitorWindowChange(window->monitor, window);
    return status;
}

// Remove the window and restore the original video mode
//
static void releaseMonitor(_GLFWwindow* window)
{
    if (window->monitor->window != window)
        return;

    _glfwInputMonitorWindowChange(window->monitor, NULL);
    _glfwRestoreVideoModeX11(window->monitor);

    _glfw.x11.saver.count--;

    if (_glfw.x11.saver.count == 0)
    {
        // Restore old screen saver settings
        XSetScreenSaver(_glfw.x11.display,
                        _glfw.x11.saver.timeout,
                        _glfw.x11.saver.interval,
                        _glfw.x11.saver.blanking,
                        _glfw.x11.saver.exposure);
    }
}

// Decode a Unicode code point from a UTF-8 stream
// Based on cutef8 by Jeff Bezanson (Public Domain)
//
#if defined(X_HAVE_UTF8_STRING)
static unsigned int decodeUTF8(const char** s)
{
    unsigned int ch = 0, count = 0;
    static const unsigned int offsets[] =
    {
        0x00000000u, 0x00003080u, 0x000e2080u,
        0x03c82080u, 0xfa082080u, 0x82082080u
    };

    do
    {
        ch = (ch << 6) + (unsigned char) **s;
        (*s)++;
        count++;
    } while ((**s & 0xc0) == 0x80);

    assert(count <= 6);
    return ch - offsets[count - 1];
}
#endif /*X_HAVE_UTF8_STRING*/

// Process the specified X event
//
static void processEvent(XEvent *event)
{
    _GLFWwindow* window = NULL;
    int keycode = 0;
    Bool filtered = False;

    // HACK: Save scancode as some IMs clear the field in XFilterEvent
    if (event->type == KeyPress || event->type == KeyRelease)
        keycode = event->xkey.keycode;

    if (_glfw.x11.im)
        filtered = XFilterEvent(event, None);

    if (_glfw.x11.randr.available)
    {
        if (event->type == _glfw.x11.randr.eventBase + RRNotify)
        {
            XRRUpdateConfiguration(event);
            _glfwInputMonitorChange();
            return;
        }
    }

    if (event->type != GenericEvent)
    {
        window = findWindowByHandle(event->xany.window);
        if (window == NULL)
        {
            // This is an event for a window that has already been destroyed
            return;
        }
    }

    switch (event->type)
    {
        case KeyPress:
        {
            const int key = translateKey(keycode);
            const int mods = translateState(event->xkey.state);
            const int plain = !(mods & (GLFW_MOD_CONTROL | GLFW_MOD_ALT));

            if (window->x11.ic)
            {
                // HACK: Ignore duplicate key press events generated by ibus
                //       Corresponding release events are filtered out by the
                //       GLFW key repeat logic
                if (window->x11.last.keycode != keycode ||
                    window->x11.last.time != event->xkey.time)
                {
                    if (keycode)
                        _glfwInputKey(window, key, keycode, GLFW_PRESS, mods);
                }

                window->x11.last.keycode = keycode;
                window->x11.last.time = event->xkey.time;

                if (!filtered)
                {
                    int count;
                    Status status;
#if defined(X_HAVE_UTF8_STRING)
                    char buffer[100];
                    char* chars = buffer;

                    count = Xutf8LookupString(window->x11.ic,
                                              &event->xkey,
                                              buffer, sizeof(buffer) - 1,
                                              NULL, &status);

                    if (status == XBufferOverflow)
                    {
                        chars = calloc(count + 1, 1);
                        count = Xutf8LookupString(window->x11.ic,
                                                  &event->xkey,
                                                  chars, count,
                                                  NULL, &status);
                    }

                    if (status == XLookupChars || status == XLookupBoth)
                    {
                        const char* c = chars;
                        chars[count] = '\0';
                        while (c - chars < count)
                            _glfwInputChar(window, decodeUTF8(&c), mods, plain);
                    }
#else /*X_HAVE_UTF8_STRING*/
                    wchar_t buffer[16];
                    wchar_t* chars = buffer;

                    count = XwcLookupString(window->x11.ic,
                                            &event->xkey,
                                            buffer, sizeof(buffer) / sizeof(wchar_t),
                                            NULL, &status);

                    if (status == XBufferOverflow)
                    {
                        chars = calloc(count, sizeof(wchar_t));
                        count = XwcLookupString(window->x11.ic,
                                                &event->xkey,
                                                chars, count,
                                                NULL, &status);
                    }

                    if (status == XLookupChars || status == XLookupBoth)
                    {
                        int i;
                        for (i = 0;  i < count;  i++)
                            _glfwInputChar(window, chars[i], mods, plain);
                    }
#endif /*X_HAVE_UTF8_STRING*/

                    if (chars != buffer)
                        free(chars);
                }
            }
            else
            {
                KeySym keysym;
                XLookupString(&event->xkey, NULL, 0, &keysym, NULL);

                _glfwInputKey(window, key, keycode, GLFW_PRESS, mods);

                const long character = _glfwKeySym2Unicode(keysym);
                if (character != -1)
                    _glfwInputChar(window, character, mods, plain);
            }

            return;
        }

        case KeyRelease:
        {
            const int key = translateKey(keycode);
            const int mods = translateState(event->xkey.state);

            if (!_glfw.x11.xkb.detectable)
            {
                // HACK: Key repeat events will arrive as KeyRelease/KeyPress
                //       pairs with similar or identical time stamps
                //       The key repeat logic in _glfwInputKey expects only key
                //       presses to repeat, so detect and discard release events
                if (XEventsQueued(_glfw.x11.display, QueuedAfterReading))
                {
                    XEvent next;
                    XPeekEvent(_glfw.x11.display, &next);

                    if (next.type == KeyPress &&
                        next.xkey.window == event->xkey.window &&
                        next.xkey.keycode == keycode)
                    {
                        // HACK: The time of repeat events sometimes doesn't
                        //       match that of the press event, so add an
                        //       epsilon
                        //       Toshiyuki Takahashi can press a button
                        //       16 times per second so it's fairly safe to
                        //       assume that no human is pressing the key 50
                        //       times per second (value is ms)
                        if ((next.xkey.time - event->xkey.time) < 20)
                        {
                            // This is very likely a server-generated key repeat
                            // event, so ignore it
                            return;
                        }
                    }
                }
            }

            _glfwInputKey(window, key, keycode, GLFW_RELEASE, mods);
            return;
        }

        case ButtonPress:
        {
            const int mods = translateState(event->xbutton.state);

            if (event->xbutton.button == Button1)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS, mods);
            else if (event->xbutton.button == Button2)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_MIDDLE, GLFW_PRESS, mods);
            else if (event->xbutton.button == Button3)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_RIGHT, GLFW_PRESS, mods);

            // Modern X provides scroll events as mouse button presses
            else if (event->xbutton.button == Button4)
                _glfwInputScroll(window, 0.0, 1.0);
            else if (event->xbutton.button == Button5)
                _glfwInputScroll(window, 0.0, -1.0);
            else if (event->xbutton.button == Button6)
                _glfwInputScroll(window, 1.0, 0.0);
            else if (event->xbutton.button == Button7)
                _glfwInputScroll(window, -1.0, 0.0);

            else
            {
                // Additional buttons after 7 are treated as regular buttons
                // We subtract 4 to fill the gap left by scroll input above
                _glfwInputMouseClick(window,
                                     event->xbutton.button - Button1 - 4,
                                     GLFW_PRESS,
                                     mods);
            }

            return;
        }

        case ButtonRelease:
        {
            const int mods = translateState(event->xbutton.state);

            if (event->xbutton.button == Button1)
            {
                _glfwInputMouseClick(window,
                                     GLFW_MOUSE_BUTTON_LEFT,
                                     GLFW_RELEASE,
                                     mods);
            }
            else if (event->xbutton.button == Button2)
            {
                _glfwInputMouseClick(window,
                                     GLFW_MOUSE_BUTTON_MIDDLE,
                                     GLFW_RELEASE,
                                     mods);
            }
            else if (event->xbutton.button == Button3)
            {
                _glfwInputMouseClick(window,
                                     GLFW_MOUSE_BUTTON_RIGHT,
                                     GLFW_RELEASE,
                                     mods);
            }
            else if (event->xbutton.button > Button7)
            {
                // Additional buttons after 7 are treated as regular buttons
                // We subtract 4 to fill the gap left by scroll input above
                _glfwInputMouseClick(window,
                                     event->xbutton.button - Button1 - 4,
                                     GLFW_RELEASE,
                                     mods);
            }

            return;
        }

        case EnterNotify:
        {
            // HACK: This is a workaround for WMs (KWM, Fluxbox) that otherwise
            //       ignore the defined cursor for hidden cursor mode
            if (window->cursorMode == GLFW_CURSOR_HIDDEN)
                _glfwPlatformSetCursorMode(window, GLFW_CURSOR_HIDDEN);

            _glfwInputCursorEnter(window, GLFW_TRUE);
            return;
        }

        case LeaveNotify:
        {
            _glfwInputCursorEnter(window, GLFW_FALSE);
            return;
        }

        case MotionNotify:
        {
            const int x = event->xmotion.x;
            const int y = event->xmotion.y;

            if (x != window->x11.warpPosX || y != window->x11.warpPosY)
            {
                // The cursor was moved by something other than GLFW

                if (window->cursorMode == GLFW_CURSOR_DISABLED)
                {
                    if (_glfw.cursorWindow != window)
                        return;

                    _glfwInputCursorMotion(window,
                                           x - window->x11.cursorPosX,
                                           y - window->x11.cursorPosY);
                }
                else
                    _glfwInputCursorMotion(window, x, y);
            }

            window->x11.cursorPosX = x;
            window->x11.cursorPosY = y;
            return;
        }

        case ConfigureNotify:
        {
            if (event->xconfigure.width != window->x11.width ||
                event->xconfigure.height != window->x11.height)
            {
                _glfwInputFramebufferSize(window,
                                          event->xconfigure.width,
                                          event->xconfigure.height);

                _glfwInputWindowSize(window,
                                     event->xconfigure.width,
                                     event->xconfigure.height);

                window->x11.width = event->xconfigure.width;
                window->x11.height = event->xconfigure.height;
            }

            if (event->xconfigure.x != window->x11.xpos ||
                event->xconfigure.y != window->x11.ypos)
            {
                if (window->x11.overrideRedirect || event->xany.send_event)
                {
                    _glfwInputWindowPos(window,
                                        event->xconfigure.x,
                                        event->xconfigure.y);

                    window->x11.xpos = event->xconfigure.x;
                    window->x11.ypos = event->xconfigure.y;
                }
            }

            return;
        }

        case ClientMessage:
        {
            // Custom client message, probably from the window manager

            if (filtered)
                return;

            if (event->xclient.message_type == None)
                return;

            if (event->xclient.message_type == _glfw.x11.WM_PROTOCOLS)
            {
                const Atom protocol = event->xclient.data.l[0];
                if (protocol == None)
                    return;

                if (protocol == _glfw.x11.WM_DELETE_WINDOW)
                {
                    // The window manager was asked to close the window, for example by
                    // the user pressing a 'close' window decoration button
                    _glfwInputWindowCloseRequest(window);
                }
                else if (protocol == _glfw.x11.NET_WM_PING)
                {
                    // The window manager is pinging the application to ensure it's
                    // still responding to events

                    XEvent reply = *event;
                    reply.xclient.window = _glfw.x11.root;

                    XSendEvent(_glfw.x11.display, _glfw.x11.root,
                               False,
                               SubstructureNotifyMask | SubstructureRedirectMask,
                               &reply);
                }
            }
            else if (event->xclient.message_type == _glfw.x11.XdndEnter)
            {
                // A drag operation has entered the window
                // TODO: Check if UTF-8 string is supported by the source
            }
            else if (event->xclient.message_type == _glfw.x11.XdndDrop)
            {
                // The drag operation has finished dropping on
                // the window, ask to convert it to a UTF-8 string
                _glfw.x11.xdnd.source = event->xclient.data.l[0];
                XConvertSelection(_glfw.x11.display,
                                  _glfw.x11.XdndSelection,
                                  _glfw.x11.UTF8_STRING,
                                  _glfw.x11.XdndSelection,
                                  window->x11.handle, CurrentTime);
            }
            else if (event->xclient.message_type == _glfw.x11.XdndPosition)
            {
                // The drag operation has moved over the window
                const int absX = (event->xclient.data.l[2] >> 16) & 0xFFFF;
                const int absY = (event->xclient.data.l[2]) & 0xFFFF;
                int x, y;

                _glfwPlatformGetWindowPos(window, &x, &y);
                _glfwInputCursorMotion(window, absX - x, absY - y);

                // Reply that we are ready to copy the dragged data
                XEvent reply;
                memset(&reply, 0, sizeof(reply));

                reply.type = ClientMessage;
                reply.xclient.window = event->xclient.data.l[0];
                reply.xclient.message_type = _glfw.x11.XdndStatus;
                reply.xclient.format = 32;
                reply.xclient.data.l[0] = window->x11.handle;
                reply.xclient.data.l[1] = 1; // Always accept the dnd with no rectangle
                reply.xclient.data.l[2] = 0; // Specify an empty rectangle
                reply.xclient.data.l[3] = 0;
                reply.xclient.data.l[4] = _glfw.x11.XdndActionCopy;

                XSendEvent(_glfw.x11.display, event->xclient.data.l[0],
                           False, NoEventMask, &reply);
                XFlush(_glfw.x11.display);
            }

            return;
        }

        case SelectionNotify:
        {
            if (event->xselection.property)
            {
                // The converted data from the drag operation has arrived
                char* data;
                const int result =
                    _glfwGetWindowPropertyX11(event->xselection.requestor,
                                              event->xselection.property,
                                              event->xselection.target,
                                              (unsigned char**) &data);

                if (result)
                {
                    int i, count;
                    char** paths = parseUriList(data, &count);

                    _glfwInputDrop(window, count, (const char**) paths);

                    for (i = 0;  i < count;  i++)
                        free(paths[i]);
                    free(paths);
                }

                XFree(data);

                XEvent reply;
                memset(&reply, 0, sizeof(reply));

                reply.type = ClientMessage;
                reply.xclient.window = _glfw.x11.xdnd.source;
                reply.xclient.message_type = _glfw.x11.XdndFinished;
                reply.xclient.format = 32;
                reply.xclient.data.l[0] = window->x11.handle;
                reply.xclient.data.l[1] = result;
                reply.xclient.data.l[2] = _glfw.x11.XdndActionCopy;

                // Reply that all is well
                XSendEvent(_glfw.x11.display, _glfw.x11.xdnd.source,
                           False, NoEventMask, &reply);
                XFlush(_glfw.x11.display);
            }

            return;
        }

        case FocusIn:
        {
            if (event->xfocus.mode == NotifyGrab ||
                event->xfocus.mode == NotifyUngrab)
            {
                // Ignore focus events from popup indicator windows, window menu
                // key chords and window dragging
                return;
            }

            if (window->x11.ic)
                XSetICFocus(window->x11.ic);

            if (window->cursorMode == GLFW_CURSOR_DISABLED)
                _glfwPlatformSetCursorMode(window, GLFW_CURSOR_DISABLED);

            _glfwInputWindowFocus(window, GLFW_TRUE);
            return;
        }

        case FocusOut:
        {
            if (event->xfocus.mode == NotifyGrab ||
                event->xfocus.mode == NotifyUngrab)
            {
                // Ignore focus events from popup indicator windows, window menu
                // key chords and window dragging
                return;
            }

            if (window->x11.ic)
                XUnsetICFocus(window->x11.ic);

            if (window->cursorMode == GLFW_CURSOR_DISABLED)
                _glfwPlatformSetCursorMode(window, GLFW_CURSOR_NORMAL);

            if (window->monitor && window->autoIconify)
                _glfwPlatformIconifyWindow(window);

            _glfwInputWindowFocus(window, GLFW_FALSE);
            return;
        }

        case Expose:
        {
            _glfwInputWindowDamage(window);
            return;
        }

        case PropertyNotify:
        {
            if (event->xproperty.atom == _glfw.x11.WM_STATE &&
                event->xproperty.state == PropertyNewValue)
            {
                const int state = getWindowState(window);
                if (state == IconicState)
                {
                    if (window->monitor)
                        releaseMonitor(window);

                    _glfwInputWindowIconify(window, GLFW_TRUE);
                }
                else if (state == NormalState)
                {
                    if (window->monitor)
                        acquireMonitor(window);

                    _glfwInputWindowIconify(window, GLFW_FALSE);
                }
            }

            return;
        }

        case SelectionClear:
        {
            handleSelectionClear(event);
            return;
        }

        case SelectionRequest:
        {
            handleSelectionRequest(event);
            return;
        }

        case DestroyNotify:
            return;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Retrieve a single window property of the specified type
// Inspired by fghGetWindowProperty from freeglut
//
unsigned long _glfwGetWindowPropertyX11(Window window,
                                        Atom property,
                                        Atom type,
                                        unsigned char** value)
{
    Atom actualType;
    int actualFormat;
    unsigned long itemCount, bytesAfter;

    XGetWindowProperty(_glfw.x11.display,
                       window,
                       property,
                       0,
                       LONG_MAX,
                       False,
                       type,
                       &actualType,
                       &actualFormat,
                       &itemCount,
                       &bytesAfter,
                       value);

    if (type != AnyPropertyType && actualType != type)
        return 0;

    return itemCount;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformCreateWindow(_GLFWwindow* window,
                              const _GLFWwndconfig* wndconfig,
                              const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig)
{
    Visual* visual;
    int depth;

    if (ctxconfig->api == GLFW_NO_API)
    {
        visual = DefaultVisual(_glfw.x11.display, _glfw.x11.screen);
        depth = DefaultDepth(_glfw.x11.display, _glfw.x11.screen);
    }
    else
    {
#if defined(_GLFW_GLX)
        if (!_glfwChooseVisualGLX(ctxconfig, fbconfig, &visual, &depth))
            return GLFW_FALSE;
#elif defined(_GLFW_EGL)
        if (!_glfwChooseVisualEGL(ctxconfig, fbconfig, &visual, &depth))
            return GLFW_FALSE;
#endif
    }

    if (!createWindow(window, wndconfig, visual, depth))
        return GLFW_FALSE;

    if (ctxconfig->api != GLFW_NO_API)
    {
#if defined(_GLFW_GLX)
        if (!_glfwCreateContextGLX(window, ctxconfig, fbconfig))
            return GLFW_FALSE;
#elif defined(_GLFW_EGL)
        if (!_glfwCreateContextEGL(window, ctxconfig, fbconfig))
            return GLFW_FALSE;
#endif
    }

    if (window->monitor)
    {
        _glfwPlatformShowWindow(window);
        updateWindowMode(window);
        if (!acquireMonitor(window))
            return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    if (window->monitor)
        releaseMonitor(window);

    if (window->x11.ic)
    {
        XDestroyIC(window->x11.ic);
        window->x11.ic = NULL;
    }

    if (window->context.api != GLFW_NO_API)
    {
#if defined(_GLFW_GLX)
        _glfwDestroyContextGLX(window);
#elif defined(_GLFW_EGL)
        _glfwDestroyContextEGL(window);
#endif
    }

    if (window->x11.handle)
    {
        if (XGetSelectionOwner(_glfw.x11.display, _glfw.x11.CLIPBOARD) ==
            window->x11.handle)
        {
            pushSelectionToManager(window);
        }

        XDeleteContext(_glfw.x11.display, window->x11.handle, _glfw.x11.context);
        XUnmapWindow(_glfw.x11.display, window->x11.handle);
        XDestroyWindow(_glfw.x11.display, window->x11.handle);
        window->x11.handle = (Window) 0;
    }

    if (window->x11.colormap)
    {
        XFreeColormap(_glfw.x11.display, window->x11.colormap);
        window->x11.colormap = (Colormap) 0;
    }

    XFlush(_glfw.x11.display);
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char* title)
{
#if defined(X_HAVE_UTF8_STRING)
    Xutf8SetWMProperties(_glfw.x11.display,
                         window->x11.handle,
                         title, title,
                         NULL, 0,
                         NULL, NULL, NULL);
#else
    // This may be a slightly better fallback than using XStoreName and
    // XSetIconName, which always store their arguments using STRING
    XmbSetWMProperties(_glfw.x11.display,
                       window->x11.handle,
                       title, title,
                       NULL, 0,
                       NULL, NULL, NULL);
#endif

    if (_glfw.x11.NET_WM_NAME)
    {
        XChangeProperty(_glfw.x11.display,  window->x11.handle,
                        _glfw.x11.NET_WM_NAME, _glfw.x11.UTF8_STRING, 8,
                        PropModeReplace,
                        (unsigned char*) title, strlen(title));
    }

    if (_glfw.x11.NET_WM_ICON_NAME)
    {
        XChangeProperty(_glfw.x11.display,  window->x11.handle,
                        _glfw.x11.NET_WM_ICON_NAME, _glfw.x11.UTF8_STRING, 8,
                        PropModeReplace,
                        (unsigned char*) title, strlen(title));
    }

    XFlush(_glfw.x11.display);
}

void _glfwPlatformSetWindowIcon(_GLFWwindow* window,
                                int count, const GLFWimage* images)
{
    if (count)
    {
        int i, j, longCount = 0;

        for (i = 0;  i < count;  i++)
            longCount += 2 + images[i].width * images[i].height;

        long* icon = calloc(longCount, sizeof(long));
        long* target = icon;

        for (i = 0;  i < count;  i++)
        {
            *target++ = images[i].width;
            *target++ = images[i].height;

            for (j = 0;  j < images[i].width * images[i].height;  j++)
            {
                *target++ = (images[i].pixels[j * 4 + 0] << 16) |
                            (images[i].pixels[j * 4 + 1] <<  8) |
                            (images[i].pixels[j * 4 + 2] <<  0) |
                            (images[i].pixels[j * 4 + 3] << 24);
            }
        }

        XChangeProperty(_glfw.x11.display, window->x11.handle,
                        _glfw.x11.NET_WM_ICON,
                        XA_CARDINAL, 32,
                        PropModeReplace,
                        (unsigned char*) icon,
                        longCount);

        free(icon);
    }
    else
    {
        XDeleteProperty(_glfw.x11.display, window->x11.handle,
                        _glfw.x11.NET_WM_ICON);
    }

    XFlush(_glfw.x11.display);
}

void _glfwPlatformGetWindowPos(_GLFWwindow* window, int* xpos, int* ypos)
{
    Window child;
    int x, y;

    XTranslateCoordinates(_glfw.x11.display, window->x11.handle, _glfw.x11.root,
                          0, 0, &x, &y, &child);

    if (child)
    {
        int left, top;
        XTranslateCoordinates(_glfw.x11.display, window->x11.handle, child,
                              0, 0, &left, &top, &child);

        x -= left;
        y -= top;
    }

    if (xpos)
        *xpos = x;
    if (ypos)
        *ypos = y;
}

void _glfwPlatformSetWindowPos(_GLFWwindow* window, int xpos, int ypos)
{
    // HACK: Explicitly setting PPosition to any value causes some WMs, notably
    //       Compiz and Metacity, to honor the position of unmapped windows
    if (!_glfwPlatformWindowVisible(window))
    {
        long supplied;
        XSizeHints* hints = XAllocSizeHints();

        if (XGetWMNormalHints(_glfw.x11.display, window->x11.handle, hints, &supplied))
        {
            hints->flags |= PPosition;
            hints->x = hints->y = 0;

            XSetWMNormalHints(_glfw.x11.display, window->x11.handle, hints);
        }

        XFree(hints);
    }

    XMoveWindow(_glfw.x11.display, window->x11.handle, xpos, ypos);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformGetWindowSize(_GLFWwindow* window, int* width, int* height)
{
    XWindowAttributes attribs;
    XGetWindowAttributes(_glfw.x11.display, window->x11.handle, &attribs);

    if (width)
        *width = attribs.width;
    if (height)
        *height = attribs.height;
}

void _glfwPlatformSetWindowSize(_GLFWwindow* window, int width, int height)
{
    if (window->monitor)
    {
        if (window->monitor->window == window)
            acquireMonitor(window);
    }
    else
    {
        if (!window->resizable)
            updateNormalHints(window);

        XResizeWindow(_glfw.x11.display, window->x11.handle, width, height);
    }

    XFlush(_glfw.x11.display);
}

void _glfwPlatformSetWindowSizeLimits(_GLFWwindow* window,
                                      int minwidth, int minheight,
                                      int maxwidth, int maxheight)
{
    updateNormalHints(window);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformSetWindowAspectRatio(_GLFWwindow* window, int numer, int denom)
{
    updateNormalHints(window);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height)
{
    _glfwPlatformGetWindowSize(window, width, height);
}

void _glfwPlatformGetWindowFrameSize(_GLFWwindow* window,
                                     int* left, int* top,
                                     int* right, int* bottom)
{
    long* extents = NULL;

    if (window->monitor || !window->decorated)
        return;

    if (_glfw.x11.NET_FRAME_EXTENTS == None)
        return;

    if (!_glfwPlatformWindowVisible(window) &&
        _glfw.x11.NET_REQUEST_FRAME_EXTENTS)
    {
        GLFWuint64 base;
        XEvent event;

        // Ensure _NET_FRAME_EXTENTS is set, allowing glfwGetWindowFrameSize to
        // function before the window is mapped
        sendEventToWM(window, _glfw.x11.NET_REQUEST_FRAME_EXTENTS,
                      0, 0, 0, 0, 0);

        base = _glfwPlatformGetTimerValue();

        // HACK: Poll with timeout for the required reply instead of blocking
        //       This is done because some window managers (at least Unity,
        //       Fluxbox and Xfwm) failed to send the required reply
        //       They have been fixed but broken versions are still in the wild
        //       If you are affected by this and your window manager is NOT
        //       listed above, PLEASE report it to their and our issue trackers
        while (!XCheckIfEvent(_glfw.x11.display,
                              &event,
                              isFrameExtentsEvent,
                              (XPointer) window))
        {
            double remaining;
            struct timeval timeout;

            remaining = 0.5 - (_glfwPlatformGetTimerValue() - base) /
                (double) _glfwPlatformGetTimerFrequency();
            if (remaining <= 0.0)
            {
                _glfwInputError(GLFW_PLATFORM_ERROR,
                                "X11: The window manager has a broken _NET_REQUEST_FRAME_EXTENTS implementation; please report this issue");
                return;
            }

            timeout.tv_sec = 0;
            timeout.tv_usec = (long) (remaining * 1e6);
            selectDisplayConnection(&timeout);
        }
    }

    if (_glfwGetWindowPropertyX11(window->x11.handle,
                                  _glfw.x11.NET_FRAME_EXTENTS,
                                  XA_CARDINAL,
                                  (unsigned char**) &extents) == 4)
    {
        if (left)
            *left = extents[0];
        if (top)
            *top = extents[2];
        if (right)
            *right = extents[1];
        if (bottom)
            *bottom = extents[3];
    }

    if (extents)
        XFree(extents);
}

void _glfwPlatformIconifyWindow(_GLFWwindow* window)
{
    if (window->x11.overrideRedirect)
    {
        // Override-redirect windows cannot be iconified or restored, as those
        // tasks are performed by the window manager
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "X11: Iconification of full screen windows requires a WM that supports EWMH full screen");
        return;
    }

    XIconifyWindow(_glfw.x11.display, window->x11.handle, _glfw.x11.screen);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformRestoreWindow(_GLFWwindow* window)
{
    if (window->x11.overrideRedirect)
    {
        // Override-redirect windows cannot be iconified or restored, as those
        // tasks are performed by the window manager
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "X11: Iconification of full screen windows requires a WM that supports EWMH full screen");
        return;
    }

    if (_glfwPlatformWindowIconified(window))
        XMapWindow(_glfw.x11.display, window->x11.handle);
    else
    {
        if (_glfw.x11.NET_WM_STATE &&
            _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT &&
            _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ)
        {
            sendEventToWM(window,
                          _glfw.x11.NET_WM_STATE,
                          _NET_WM_STATE_REMOVE,
                          _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT,
                          _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ,
                          1, 0);
        }
    }

    XFlush(_glfw.x11.display);
}

void _glfwPlatformMaximizeWindow(_GLFWwindow* window)
{
    if (_glfw.x11.NET_WM_STATE &&
        _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT &&
        _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ)
    {
        sendEventToWM(window,
                      _glfw.x11.NET_WM_STATE,
                      _NET_WM_STATE_ADD,
                      _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT,
                      _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ,
                      1, 0);
        XFlush(_glfw.x11.display);
    }
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    XMapWindow(_glfw.x11.display, window->x11.handle);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    XUnmapWindow(_glfw.x11.display, window->x11.handle);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformFocusWindow(_GLFWwindow* window)
{
    if (_glfw.x11.NET_ACTIVE_WINDOW)
        sendEventToWM(window, _glfw.x11.NET_ACTIVE_WINDOW, 1, 0, 0, 0, 0);
    else
    {
        XRaiseWindow(_glfw.x11.display, window->x11.handle);
        XSetInputFocus(_glfw.x11.display, window->x11.handle,
                       RevertToParent, CurrentTime);
    }

    XFlush(_glfw.x11.display);
}

void _glfwPlatformSetWindowMonitor(_GLFWwindow* window,
                                   _GLFWmonitor* monitor,
                                   int xpos, int ypos,
                                   int width, int height,
                                   int refreshRate)
{
    if (window->monitor == monitor)
    {
        if (monitor)
        {
            if (monitor->window == window)
                acquireMonitor(window);
        }
        else
        {
            XMoveResizeWindow(_glfw.x11.display, window->x11.handle,
                              xpos, ypos, width, height);
        }

        return;
    }

    if (window->monitor)
        releaseMonitor(window);

    _glfwInputWindowMonitorChange(window, monitor);
    updateWindowMode(window);

    if (window->monitor)
    {
        XMapRaised(_glfw.x11.display, window->x11.handle);
        acquireMonitor(window);
    }
    else
    {
        XMoveResizeWindow(_glfw.x11.display, window->x11.handle,
                          xpos, ypos, width, height);
    }

    XFlush(_glfw.x11.display);
}

int _glfwPlatformWindowFocused(_GLFWwindow* window)
{
    Window focused;
    int state;

    XGetInputFocus(_glfw.x11.display, &focused, &state);
    return window->x11.handle == focused;
}

int _glfwPlatformWindowIconified(_GLFWwindow* window)
{
    return getWindowState(window) == IconicState;
}

int _glfwPlatformWindowVisible(_GLFWwindow* window)
{
    XWindowAttributes wa;
    XGetWindowAttributes(_glfw.x11.display, window->x11.handle, &wa);
    return wa.map_state == IsViewable;
}

int _glfwPlatformWindowMaximized(_GLFWwindow* window)
{
    Atom* states;
    unsigned long i;
    GLFWbool maximized = GLFW_FALSE;
    const unsigned long count =
        _glfwGetWindowPropertyX11(window->x11.handle,
                                  _glfw.x11.NET_WM_STATE,
                                  XA_ATOM,
                                  (unsigned char**) &states);

    for (i = 0;  i < count;  i++)
    {
        if (states[i] == _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT ||
            states[i] == _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ)
        {
            maximized = GLFW_TRUE;
            break;
        }
    }

    XFree(states);
    return maximized;
}

void _glfwPlatformPollEvents(void)
{
    int count = XPending(_glfw.x11.display);
    while (count--)
    {
        XEvent event;
        XNextEvent(_glfw.x11.display, &event);
        processEvent(&event);
    }

    _GLFWwindow* window = _glfw.cursorWindow;
    if (window && window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        int width, height;
        _glfwPlatformGetWindowSize(window, &width, &height);
        _glfwPlatformSetCursorPos(window, width / 2, height / 2);
    }
}

void _glfwPlatformWaitEvents(void)
{
    while (!XPending(_glfw.x11.display))
        selectDisplayConnection(NULL);

    _glfwPlatformPollEvents();
}

void _glfwPlatformWaitEventsTimeout(double timeout)
{
    const double deadline = timeout + _glfwPlatformGetTimerValue() /
        (double) _glfwPlatformGetTimerFrequency();

    while (!XPending(_glfw.x11.display))
    {
        const double remaining = deadline - _glfwPlatformGetTimerValue() /
            (double) _glfwPlatformGetTimerFrequency();
        if (remaining <= 0.0)
            return;

        const long seconds = (long) remaining;
        const long microseconds = (long) ((remaining - seconds) * 1e6);
        struct timeval tv = { seconds, microseconds };

        selectDisplayConnection(&tv);
    }

    _glfwPlatformPollEvents();
}

void _glfwPlatformPostEmptyEvent(void)
{
    XEvent event;
    _GLFWwindow* window = _glfw.windowListHead;

    memset(&event, 0, sizeof(event));
    event.type = ClientMessage;
    event.xclient.window = window->x11.handle;
    event.xclient.format = 32; // Data is 32-bit longs
    event.xclient.message_type = _glfw.x11.NULL_;

    XSendEvent(_glfw.x11.display, window->x11.handle, False, 0, &event);
    XFlush(_glfw.x11.display);
}

void _glfwPlatformGetCursorPos(_GLFWwindow* window, double* xpos, double* ypos)
{
    Window root, child;
    int rootX, rootY, childX, childY;
    unsigned int mask;

    XQueryPointer(_glfw.x11.display, window->x11.handle,
                  &root, &child,
                  &rootX, &rootY, &childX, &childY,
                  &mask);

    if (xpos)
        *xpos = childX;
    if (ypos)
        *ypos = childY;
}

void _glfwPlatformSetCursorPos(_GLFWwindow* window, double x, double y)
{
    // Store the new position so it can be recognized later
    window->x11.warpPosX = (int) x;
    window->x11.warpPosY = (int) y;

    XWarpPointer(_glfw.x11.display, None, window->x11.handle,
                 0,0,0,0, (int) x, (int) y);
}

void _glfwPlatformSetCursorMode(_GLFWwindow* window, int mode)
{
    if (mode == GLFW_CURSOR_DISABLED)
    {
        XGrabPointer(_glfw.x11.display, window->x11.handle, True,
                     ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
                     GrabModeAsync, GrabModeAsync,
                     window->x11.handle, _glfw.x11.cursor, CurrentTime);
    }
    else
    {
        XUngrabPointer(_glfw.x11.display, CurrentTime);

        if (mode == GLFW_CURSOR_NORMAL)
        {
            if (window->cursor)
            {
                XDefineCursor(_glfw.x11.display, window->x11.handle,
                              window->cursor->x11.handle);
            }
            else
                XUndefineCursor(_glfw.x11.display, window->x11.handle);
        }
        else
        {
            XDefineCursor(_glfw.x11.display, window->x11.handle,
                          _glfw.x11.cursor);
        }
    }
}

const char* _glfwPlatformGetKeyName(int key, int scancode)
{
    KeySym keysym;
    int extra;

    if (!_glfw.x11.xkb.available)
        return NULL;

    if (key != GLFW_KEY_UNKNOWN)
        scancode = _glfw.x11.nativeKeys[key];

    if (!_glfwIsPrintable(_glfw.x11.publicKeys[scancode]))
        return NULL;

    keysym = XkbKeycodeToKeysym(_glfw.x11.display, scancode, 0, 0);
    if (keysym == NoSymbol)
      return NULL;

    XkbTranslateKeySym(_glfw.x11.display, &keysym, 0,
                       _glfw.x11.keyName, sizeof(_glfw.x11.keyName),
                       &extra);

    if (!strlen(_glfw.x11.keyName))
        return NULL;

    return _glfw.x11.keyName;
}

int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    cursor->x11.handle = _glfwCreateCursorX11(image, xhot, yhot);
    if (!cursor->x11.handle)
        return GLFW_FALSE;

    return GLFW_TRUE;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    cursor->x11.handle = XCreateFontCursor(_glfw.x11.display,
                                           translateCursorShape(shape));
    if (!cursor->x11.handle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "X11: Failed to create standard cursor");
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

void _glfwPlatformDestroyCursor(_GLFWcursor* cursor)
{
    if (cursor->x11.handle)
        XFreeCursor(_glfw.x11.display, cursor->x11.handle);
}

void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor)
{
    if (window->cursorMode == GLFW_CURSOR_NORMAL)
    {
        if (cursor)
            XDefineCursor(_glfw.x11.display, window->x11.handle, cursor->x11.handle);
        else
            XUndefineCursor(_glfw.x11.display, window->x11.handle);

        XFlush(_glfw.x11.display);
    }
}

void _glfwPlatformSetClipboardString(_GLFWwindow* window, const char* string)
{
    free(_glfw.x11.clipboardString);
    _glfw.x11.clipboardString = strdup(string);

    XSetSelectionOwner(_glfw.x11.display,
                       _glfw.x11.CLIPBOARD,
                       window->x11.handle, CurrentTime);

    if (XGetSelectionOwner(_glfw.x11.display, _glfw.x11.CLIPBOARD) !=
        window->x11.handle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "X11: Failed to become owner of clipboard selection");
    }
}

const char* _glfwPlatformGetClipboardString(_GLFWwindow* window)
{
    size_t i;
    const Atom formats[] = { _glfw.x11.UTF8_STRING,
                             _glfw.x11.COMPOUND_STRING,
                             XA_STRING };
    const size_t formatCount = sizeof(formats) / sizeof(formats[0]);

    if (findWindowByHandle(XGetSelectionOwner(_glfw.x11.display,
                                              _glfw.x11.CLIPBOARD)))
    {
        // Instead of doing a large number of X round-trips just to put this
        // string into a window property and then read it back, just return it
        return _glfw.x11.clipboardString;
    }

    free(_glfw.x11.clipboardString);
    _glfw.x11.clipboardString = NULL;

    for (i = 0;  i < formatCount;  i++)
    {
        char* data;
        XEvent event;

        XConvertSelection(_glfw.x11.display,
                          _glfw.x11.CLIPBOARD,
                          formats[i],
                          _glfw.x11.GLFW_SELECTION,
                          window->x11.handle, CurrentTime);

        // XCheckTypedEvent is used instead of XIfEvent in order not to lock
        // other threads out from the display during the entire wait period
        while (!XCheckTypedEvent(_glfw.x11.display, SelectionNotify, &event))
            selectDisplayConnection(NULL);

        if (event.xselection.property == None)
            continue;

        if (_glfwGetWindowPropertyX11(event.xselection.requestor,
                                      event.xselection.property,
                                      event.xselection.target,
                                      (unsigned char**) &data))
        {
            _glfw.x11.clipboardString = strdup(data);
        }

        XFree(data);

        XDeleteProperty(_glfw.x11.display,
                        event.xselection.requestor,
                        event.xselection.property);

        if (_glfw.x11.clipboardString)
            break;
    }

    if (_glfw.x11.clipboardString == NULL)
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "X11: Failed to convert clipboard to string");
    }

    return _glfw.x11.clipboardString;
}

char** _glfwPlatformGetRequiredInstanceExtensions(unsigned int* count)
{
    char** extensions;

    *count = 0;

    if (!_glfw.vk.KHR_xcb_surface || !_glfw.x11.x11xcb.handle)
    {
        if (!_glfw.vk.KHR_xlib_surface)
            return NULL;
    }

    extensions = calloc(2, sizeof(char*));
    extensions[0] = strdup("VK_KHR_surface");

    if (_glfw.vk.KHR_xcb_surface && _glfw.x11.x11xcb.handle)
        extensions[1] = strdup("VK_KHR_xcb_surface");
    else
        extensions[1] = strdup("VK_KHR_xlib_surface");

    *count = 2;
    return extensions;
}

int _glfwPlatformGetPhysicalDevicePresentationSupport(VkInstance instance,
                                                      VkPhysicalDevice device,
                                                      unsigned int queuefamily)
{
    VisualID visualID = XVisualIDFromVisual(DefaultVisual(_glfw.x11.display,
                                                          _glfw.x11.screen));

    if (_glfw.vk.KHR_xcb_surface && _glfw.x11.x11xcb.handle)
    {
        PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR vkGetPhysicalDeviceXcbPresentationSupportKHR =
            (PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR)
            vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXcbPresentationSupportKHR");
        if (!vkGetPhysicalDeviceXcbPresentationSupportKHR)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "X11: Vulkan instance missing VK_KHR_xcb_surface extension");
            return GLFW_FALSE;
        }

        xcb_connection_t* connection =
            _glfw.x11.x11xcb.XGetXCBConnection(_glfw.x11.display);
        if (!connection)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Failed to retrieve XCB connection");
            return GLFW_FALSE;
        }

        return vkGetPhysicalDeviceXcbPresentationSupportKHR(device,
                                                            queuefamily,
                                                            connection,
                                                            visualID);
    }
    else
    {
        PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR vkGetPhysicalDeviceXlibPresentationSupportKHR =
            (PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR)
            vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXlibPresentationSupportKHR");
        if (!vkGetPhysicalDeviceXlibPresentationSupportKHR)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "X11: Vulkan instance missing VK_KHR_xlib_surface extension");
            return GLFW_FALSE;
        }

        return vkGetPhysicalDeviceXlibPresentationSupportKHR(device,
                                                             queuefamily,
                                                             _glfw.x11.display,
                                                             visualID);
    }
}

VkResult _glfwPlatformCreateWindowSurface(VkInstance instance,
                                          _GLFWwindow* window,
                                          const VkAllocationCallbacks* allocator,
                                          VkSurfaceKHR* surface)
{
    if (_glfw.vk.KHR_xcb_surface && _glfw.x11.x11xcb.handle)
    {
        VkResult err;
        VkXcbSurfaceCreateInfoKHR sci;
        PFN_vkCreateXcbSurfaceKHR vkCreateXcbSurfaceKHR;

        xcb_connection_t* connection =
            _glfw.x11.x11xcb.XGetXCBConnection(_glfw.x11.display);
        if (!connection)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Failed to retrieve XCB connection");
            return VK_ERROR_EXTENSION_NOT_PRESENT;
        }

        vkCreateXcbSurfaceKHR = (PFN_vkCreateXcbSurfaceKHR)
            vkGetInstanceProcAddr(instance, "vkCreateXcbSurfaceKHR");
        if (!vkCreateXcbSurfaceKHR)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "X11: Vulkan instance missing VK_KHR_xcb_surface extension");
            return VK_ERROR_EXTENSION_NOT_PRESENT;
        }

        memset(&sci, 0, sizeof(sci));
        sci.sType = VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
        sci.connection = connection;
        sci.window = window->x11.handle;

        err = vkCreateXcbSurfaceKHR(instance, &sci, allocator, surface);
        if (err)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Failed to create Vulkan XCB surface: %s",
                            _glfwGetVulkanResultString(err));
        }

        return err;
    }
    else
    {
        VkResult err;
        VkXlibSurfaceCreateInfoKHR sci;
        PFN_vkCreateXlibSurfaceKHR vkCreateXlibSurfaceKHR;

        vkCreateXlibSurfaceKHR = (PFN_vkCreateXlibSurfaceKHR)
            vkGetInstanceProcAddr(instance, "vkCreateXlibSurfaceKHR");
        if (!vkCreateXlibSurfaceKHR)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "X11: Vulkan instance missing VK_KHR_xlib_surface extension");
            return VK_ERROR_EXTENSION_NOT_PRESENT;
        }

        memset(&sci, 0, sizeof(sci));
        sci.sType = VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR;
        sci.dpy = _glfw.x11.display;
        sci.window = window->x11.handle;

        err = vkCreateXlibSurfaceKHR(instance, &sci, allocator, surface);
        if (err)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Failed to create Vulkan X11 surface: %s",
                            _glfwGetVulkanResultString(err));
        }

        return err;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI Display* glfwGetX11Display(void)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return _glfw.x11.display;
}

GLFWAPI Window glfwGetX11Window(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(None);
    return window->x11.handle;
}

