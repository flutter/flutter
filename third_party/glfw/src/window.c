//========================================================================
// GLFW 3.1 - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2002-2006 Marcus Geelnard
// Copyright (c) 2006-2010 Camilla Berglund <elmindreda@elmindreda.org>
// Copyright (c) 2012 Torsten Walluhn <tw@mad-cad.net>
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

#include <string.h>
#include <stdlib.h>


//////////////////////////////////////////////////////////////////////////
//////                         GLFW event API                       //////
//////////////////////////////////////////////////////////////////////////

void _glfwInputWindowFocus(_GLFWwindow* window, GLboolean focused)
{
    if (focused)
    {
        _glfw.cursorWindow = window;

        if (window->callbacks.focus)
            window->callbacks.focus((GLFWwindow*) window, focused);
    }
    else
    {
        int i;

        _glfw.cursorWindow = NULL;

        if (window->callbacks.focus)
            window->callbacks.focus((GLFWwindow*) window, focused);

        // Release all pressed keyboard keys
        for (i = 0;  i <= GLFW_KEY_LAST;  i++)
        {
            if (window->keys[i] == GLFW_PRESS)
                _glfwInputKey(window, i, 0, GLFW_RELEASE, 0);
        }

        // Release all pressed mouse buttons
        for (i = 0;  i <= GLFW_MOUSE_BUTTON_LAST;  i++)
        {
            if (window->mouseButtons[i] == GLFW_PRESS)
                _glfwInputMouseClick(window, i, GLFW_RELEASE, 0);
        }
    }
}

void _glfwInputWindowPos(_GLFWwindow* window, int x, int y)
{
    if (window->callbacks.pos)
        window->callbacks.pos((GLFWwindow*) window, x, y);
}

void _glfwInputWindowSize(_GLFWwindow* window, int width, int height)
{
    if (window->callbacks.size)
        window->callbacks.size((GLFWwindow*) window, width, height);
}

void _glfwInputWindowIconify(_GLFWwindow* window, int iconified)
{
    if (window->callbacks.iconify)
        window->callbacks.iconify((GLFWwindow*) window, iconified);
}

void _glfwInputFramebufferSize(_GLFWwindow* window, int width, int height)
{
    if (window->callbacks.fbsize)
        window->callbacks.fbsize((GLFWwindow*) window, width, height);
}

void _glfwInputWindowDamage(_GLFWwindow* window)
{
    if (window->callbacks.refresh)
        window->callbacks.refresh((GLFWwindow*) window);
}

void _glfwInputWindowCloseRequest(_GLFWwindow* window)
{
    window->closed = GL_TRUE;

    if (window->callbacks.close)
        window->callbacks.close((GLFWwindow*) window);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW public API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI GLFWwindow* glfwCreateWindow(int width, int height,
                                     const char* title,
                                     GLFWmonitor* monitor,
                                     GLFWwindow* share)
{
    _GLFWfbconfig fbconfig;
    _GLFWctxconfig ctxconfig;
    _GLFWwndconfig wndconfig;
    _GLFWwindow* window;
    _GLFWwindow* previous;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (width <= 0 || height <= 0)
    {
        _glfwInputError(GLFW_INVALID_VALUE, "Invalid window size");
        return NULL;
    }

    fbconfig  = _glfw.hints.framebuffer;
    ctxconfig = _glfw.hints.context;
    wndconfig = _glfw.hints.window;

    wndconfig.width   = width;
    wndconfig.height  = height;
    wndconfig.title   = title;
    wndconfig.monitor = (_GLFWmonitor*) monitor;
    ctxconfig.share   = (_GLFWwindow*) share;

    if (wndconfig.monitor)
    {
        wndconfig.resizable = GL_TRUE;
        wndconfig.visible   = GL_TRUE;
        wndconfig.focused   = GL_TRUE;
    }

    // Check the OpenGL bits of the window config
    if (!_glfwIsValidContextConfig(&ctxconfig))
        return NULL;

    window = calloc(1, sizeof(_GLFWwindow));
    window->next = _glfw.windowListHead;
    _glfw.windowListHead = window;

    window->videoMode.width       = width;
    window->videoMode.height      = height;
    window->videoMode.redBits     = fbconfig.redBits;
    window->videoMode.greenBits   = fbconfig.greenBits;
    window->videoMode.blueBits    = fbconfig.blueBits;
    window->videoMode.refreshRate = _glfw.hints.refreshRate;

    window->monitor     = wndconfig.monitor;
    window->resizable   = wndconfig.resizable;
    window->decorated   = wndconfig.decorated;
    window->autoIconify = wndconfig.autoIconify;
    window->floating    = wndconfig.floating;
    window->cursorMode  = GLFW_CURSOR_NORMAL;

    // Save the currently current context so it can be restored later
    previous = _glfwPlatformGetCurrentContext();

    // Open the actual window and create its context
    if (!_glfwPlatformCreateWindow(window, &wndconfig, &ctxconfig, &fbconfig))
    {
        glfwDestroyWindow((GLFWwindow*) window);
        _glfwPlatformMakeContextCurrent(previous);
        return NULL;
    }

    _glfwPlatformMakeContextCurrent(window);

    // Retrieve the actual (as opposed to requested) context attributes
    if (!_glfwRefreshContextAttribs(&ctxconfig))
    {
        glfwDestroyWindow((GLFWwindow*) window);
        _glfwPlatformMakeContextCurrent(previous);
        return NULL;
    }

    // Verify the context against the requested parameters
    if (!_glfwIsValidContext(&ctxconfig))
    {
        glfwDestroyWindow((GLFWwindow*) window);
        _glfwPlatformMakeContextCurrent(previous);
        return NULL;
    }

    // Clearing the front buffer to black to avoid garbage pixels left over
    // from previous uses of our bit of VRAM
    window->Clear(GL_COLOR_BUFFER_BIT);
    _glfwPlatformSwapBuffers(window);

    // Restore the previously current context (or NULL)
    _glfwPlatformMakeContextCurrent(previous);

    if (wndconfig.monitor)
    {
        int width, height;
        _glfwPlatformGetWindowSize(window, &width, &height);

        window->cursorPosX = width / 2;
        window->cursorPosY = height / 2;

        _glfwPlatformSetCursorPos(window, window->cursorPosX, window->cursorPosY);
    }
    else
    {
        if (wndconfig.visible)
        {
            if (wndconfig.focused)
                _glfwPlatformShowWindow(window);
            else
                _glfwPlatformUnhideWindow(window);
        }
    }

    return (GLFWwindow*) window;
}

void glfwDefaultWindowHints(void)
{
    _GLFW_REQUIRE_INIT();

    memset(&_glfw.hints, 0, sizeof(_glfw.hints));

    // The default is OpenGL with minimum version 1.0
    _glfw.hints.context.api   = GLFW_OPENGL_API;
    _glfw.hints.context.major = 1;
    _glfw.hints.context.minor = 0;

    // The default is a focused, visible, resizable window with decorations
    _glfw.hints.window.resizable   = GL_TRUE;
    _glfw.hints.window.visible     = GL_TRUE;
    _glfw.hints.window.decorated   = GL_TRUE;
    _glfw.hints.window.focused     = GL_TRUE;
    _glfw.hints.window.autoIconify = GL_TRUE;

    // The default is 24 bits of color, 24 bits of depth and 8 bits of stencil,
    // double buffered
    _glfw.hints.framebuffer.redBits      = 8;
    _glfw.hints.framebuffer.greenBits    = 8;
    _glfw.hints.framebuffer.blueBits     = 8;
    _glfw.hints.framebuffer.alphaBits    = 8;
    _glfw.hints.framebuffer.depthBits    = 24;
    _glfw.hints.framebuffer.stencilBits  = 8;
    _glfw.hints.framebuffer.doublebuffer = GL_TRUE;

    // The default is to select the highest available refresh rate
    _glfw.hints.refreshRate = GLFW_DONT_CARE;
}

GLFWAPI void glfwWindowHint(int target, int hint)
{
    _GLFW_REQUIRE_INIT();

    switch (target)
    {
        case GLFW_RED_BITS:
            _glfw.hints.framebuffer.redBits = hint;
            break;
        case GLFW_GREEN_BITS:
            _glfw.hints.framebuffer.greenBits = hint;
            break;
        case GLFW_BLUE_BITS:
            _glfw.hints.framebuffer.blueBits = hint;
            break;
        case GLFW_ALPHA_BITS:
            _glfw.hints.framebuffer.alphaBits = hint;
            break;
        case GLFW_DEPTH_BITS:
            _glfw.hints.framebuffer.depthBits = hint;
            break;
        case GLFW_STENCIL_BITS:
            _glfw.hints.framebuffer.stencilBits = hint;
            break;
        case GLFW_ACCUM_RED_BITS:
            _glfw.hints.framebuffer.accumRedBits = hint;
            break;
        case GLFW_ACCUM_GREEN_BITS:
            _glfw.hints.framebuffer.accumGreenBits = hint;
            break;
        case GLFW_ACCUM_BLUE_BITS:
            _glfw.hints.framebuffer.accumBlueBits = hint;
            break;
        case GLFW_ACCUM_ALPHA_BITS:
            _glfw.hints.framebuffer.accumAlphaBits = hint;
            break;
        case GLFW_AUX_BUFFERS:
            _glfw.hints.framebuffer.auxBuffers = hint;
            break;
        case GLFW_STEREO:
            _glfw.hints.framebuffer.stereo = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_DOUBLEBUFFER:
            _glfw.hints.framebuffer.doublebuffer = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_SAMPLES:
            _glfw.hints.framebuffer.samples = hint;
            break;
        case GLFW_SRGB_CAPABLE:
            _glfw.hints.framebuffer.sRGB = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_RESIZABLE:
            _glfw.hints.window.resizable = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_DECORATED:
            _glfw.hints.window.decorated = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_FOCUSED:
            _glfw.hints.window.focused = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_AUTO_ICONIFY:
            _glfw.hints.window.autoIconify = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_FLOATING:
            _glfw.hints.window.floating = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_VISIBLE:
            _glfw.hints.window.visible = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_CLIENT_API:
            _glfw.hints.context.api = hint;
            break;
        case GLFW_CONTEXT_VERSION_MAJOR:
            _glfw.hints.context.major = hint;
            break;
        case GLFW_CONTEXT_VERSION_MINOR:
            _glfw.hints.context.minor = hint;
            break;
        case GLFW_CONTEXT_ROBUSTNESS:
            _glfw.hints.context.robustness = hint;
            break;
        case GLFW_OPENGL_FORWARD_COMPAT:
            _glfw.hints.context.forward = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_OPENGL_DEBUG_CONTEXT:
            _glfw.hints.context.debug = hint ? GL_TRUE : GL_FALSE;
            break;
        case GLFW_OPENGL_PROFILE:
            _glfw.hints.context.profile = hint;
            break;
        case GLFW_CONTEXT_RELEASE_BEHAVIOR:
            _glfw.hints.context.release = hint;
            break;
        case GLFW_REFRESH_RATE:
            _glfw.hints.refreshRate = hint;
            break;
        default:
            _glfwInputError(GLFW_INVALID_ENUM, "Invalid window hint");
            break;
    }
}

GLFWAPI void glfwDestroyWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    // Allow closing of NULL (to match the behavior of free)
    if (window == NULL)
        return;

    // Clear all callbacks to avoid exposing a half torn-down window object
    memset(&window->callbacks, 0, sizeof(window->callbacks));

    // The window's context must not be current on another thread when the
    // window is destroyed
    if (window == _glfwPlatformGetCurrentContext())
        _glfwPlatformMakeContextCurrent(NULL);

    // Clear the focused window pointer if this is the focused window
    if (_glfw.cursorWindow == window)
        _glfw.cursorWindow = NULL;

    _glfwPlatformDestroyWindow(window);

    // Unlink window from global linked list
    {
        _GLFWwindow** prev = &_glfw.windowListHead;

        while (*prev != window)
            prev = &((*prev)->next);

        *prev = window->next;
    }

    free(window);
}

GLFWAPI int glfwWindowShouldClose(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(0);
    return window->closed;
}

GLFWAPI void glfwSetWindowShouldClose(GLFWwindow* handle, int value)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT();
    window->closed = value;
}

GLFWAPI void glfwSetWindowTitle(GLFWwindow* handle, const char* title)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT();
    _glfwPlatformSetWindowTitle(window, title);
}

GLFWAPI void glfwGetWindowPos(GLFWwindow* handle, int* xpos, int* ypos)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    if (xpos)
        *xpos = 0;
    if (ypos)
        *ypos = 0;

    _GLFW_REQUIRE_INIT();
    _glfwPlatformGetWindowPos(window, xpos, ypos);
}

GLFWAPI void glfwSetWindowPos(GLFWwindow* handle, int xpos, int ypos)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    if (window->monitor)
    {
        _glfwInputError(GLFW_INVALID_VALUE,
                        "Full screen windows cannot be moved");
        return;
    }

    _glfwPlatformSetWindowPos(window, xpos, ypos);
}

GLFWAPI void glfwGetWindowSize(GLFWwindow* handle, int* width, int* height)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    if (width)
        *width = 0;
    if (height)
        *height = 0;

    _GLFW_REQUIRE_INIT();
    _glfwPlatformGetWindowSize(window, width, height);
}

GLFWAPI void glfwSetWindowSize(GLFWwindow* handle, int width, int height)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    if (window->monitor)
    {
        window->videoMode.width  = width;
        window->videoMode.height = height;
    }

    _glfwPlatformSetWindowSize(window, width, height);
}

GLFWAPI void glfwGetFramebufferSize(GLFWwindow* handle, int* width, int* height)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    if (width)
        *width = 0;
    if (height)
        *height = 0;

    _GLFW_REQUIRE_INIT();
    _glfwPlatformGetFramebufferSize(window, width, height);
}

GLFWAPI void glfwGetWindowFrameSize(GLFWwindow* handle,
                                    int* left, int* top,
                                    int* right, int* bottom)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    if (left)
        *left = 0;
    if (top)
        *top = 0;
    if (right)
        *right = 0;
    if (bottom)
        *bottom = 0;

    _GLFW_REQUIRE_INIT();
    _glfwPlatformGetWindowFrameSize(window, left, top, right, bottom);
}

GLFWAPI void glfwIconifyWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT();
    _glfwPlatformIconifyWindow(window);
}

GLFWAPI void glfwRestoreWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT();
    _glfwPlatformRestoreWindow(window);
}

GLFWAPI void glfwShowWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    if (window->monitor)
        return;

    _glfwPlatformShowWindow(window);
}

GLFWAPI void glfwHideWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    if (window->monitor)
        return;

    _glfwPlatformHideWindow(window);
}

GLFWAPI int glfwGetWindowAttrib(GLFWwindow* handle, int attrib)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT_OR_RETURN(0);

    switch (attrib)
    {
        case GLFW_FOCUSED:
            return _glfwPlatformWindowFocused(window);
        case GLFW_ICONIFIED:
            return _glfwPlatformWindowIconified(window);
        case GLFW_VISIBLE:
            return _glfwPlatformWindowVisible(window);
        case GLFW_RESIZABLE:
            return window->resizable;
        case GLFW_DECORATED:
            return window->decorated;
        case GLFW_FLOATING:
            return window->floating;
        case GLFW_CLIENT_API:
            return window->context.api;
        case GLFW_CONTEXT_VERSION_MAJOR:
            return window->context.major;
        case GLFW_CONTEXT_VERSION_MINOR:
            return window->context.minor;
        case GLFW_CONTEXT_REVISION:
            return window->context.revision;
        case GLFW_CONTEXT_ROBUSTNESS:
            return window->context.robustness;
        case GLFW_OPENGL_FORWARD_COMPAT:
            return window->context.forward;
        case GLFW_OPENGL_DEBUG_CONTEXT:
            return window->context.debug;
        case GLFW_OPENGL_PROFILE:
            return window->context.profile;
        case GLFW_CONTEXT_RELEASE_BEHAVIOR:
            return window->context.release;
    }

    _glfwInputError(GLFW_INVALID_ENUM, "Invalid window attribute");
    return 0;
}

GLFWAPI GLFWmonitor* glfwGetWindowMonitor(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return (GLFWmonitor*) window->monitor;
}

GLFWAPI void glfwSetWindowUserPointer(GLFWwindow* handle, void* pointer)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT();
    window->userPointer = pointer;
}

GLFWAPI void* glfwGetWindowUserPointer(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return window->userPointer;
}

GLFWAPI GLFWwindowposfun glfwSetWindowPosCallback(GLFWwindow* handle,
                                                  GLFWwindowposfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.pos, cbfun);
    return cbfun;
}

GLFWAPI GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* handle,
                                                    GLFWwindowsizefun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.size, cbfun);
    return cbfun;
}

GLFWAPI GLFWwindowclosefun glfwSetWindowCloseCallback(GLFWwindow* handle,
                                                      GLFWwindowclosefun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.close, cbfun);
    return cbfun;
}

GLFWAPI GLFWwindowrefreshfun glfwSetWindowRefreshCallback(GLFWwindow* handle,
                                                          GLFWwindowrefreshfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.refresh, cbfun);
    return cbfun;
}

GLFWAPI GLFWwindowfocusfun glfwSetWindowFocusCallback(GLFWwindow* handle,
                                                      GLFWwindowfocusfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.focus, cbfun);
    return cbfun;
}

GLFWAPI GLFWwindowiconifyfun glfwSetWindowIconifyCallback(GLFWwindow* handle,
                                                          GLFWwindowiconifyfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.iconify, cbfun);
    return cbfun;
}

GLFWAPI GLFWframebuffersizefun glfwSetFramebufferSizeCallback(GLFWwindow* handle,
                                                              GLFWframebuffersizefun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.fbsize, cbfun);
    return cbfun;
}

GLFWAPI void glfwPollEvents(void)
{
    _GLFW_REQUIRE_INIT();
    _glfwPlatformPollEvents();
}

GLFWAPI void glfwWaitEvents(void)
{
    _GLFW_REQUIRE_INIT();

    if (!_glfw.windowListHead)
        return;

    _glfwPlatformWaitEvents();
}

GLFWAPI void glfwPostEmptyEvent(void)
{
    _GLFW_REQUIRE_INIT();

    if (!_glfw.windowListHead)
        return;

    _glfwPlatformPostEmptyEvent();
}

