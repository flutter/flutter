//========================================================================
// GLFW 3.1 - www.glfw.org
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
#if defined(_MSC_VER)
 #include <malloc.h>
#endif

// Internal key state used for sticky keys
#define _GLFW_STICK 3


// Sets the cursor mode for the specified window
//
static void setCursorMode(_GLFWwindow* window, int newMode)
{
    const int oldMode = window->cursorMode;

    if (newMode != GLFW_CURSOR_NORMAL &&
        newMode != GLFW_CURSOR_HIDDEN &&
        newMode != GLFW_CURSOR_DISABLED)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid cursor mode");
        return;
    }

    if (oldMode == newMode)
        return;

    window->cursorMode = newMode;

    if (_glfw.cursorWindow == window)
    {
        if (oldMode == GLFW_CURSOR_DISABLED)
        {
            _glfwPlatformSetCursorPos(window,
                                      _glfw.cursorPosX,
                                      _glfw.cursorPosY);
        }
        else if (newMode == GLFW_CURSOR_DISABLED)
        {
            int width, height;

            _glfwPlatformGetCursorPos(window,
                                      &_glfw.cursorPosX,
                                      &_glfw.cursorPosY);

            window->cursorPosX = _glfw.cursorPosX;
            window->cursorPosY = _glfw.cursorPosY;

            _glfwPlatformGetWindowSize(window, &width, &height);
            _glfwPlatformSetCursorPos(window, width / 2, height / 2);
        }

        _glfwPlatformApplyCursorMode(window);
    }
}

// Set sticky keys mode for the specified window
//
static void setStickyKeys(_GLFWwindow* window, int enabled)
{
    if (window->stickyKeys == enabled)
        return;

    if (!enabled)
    {
        int i;

        // Release all sticky keys
        for (i = 0;  i <= GLFW_KEY_LAST;  i++)
        {
            if (window->keys[i] == _GLFW_STICK)
                window->keys[i] = GLFW_RELEASE;
        }
    }

    window->stickyKeys = enabled;
}

// Set sticky mouse buttons mode for the specified window
//
static void setStickyMouseButtons(_GLFWwindow* window, int enabled)
{
    if (window->stickyMouseButtons == enabled)
        return;

    if (!enabled)
    {
        int i;

        // Release all sticky mouse buttons
        for (i = 0;  i <= GLFW_MOUSE_BUTTON_LAST;  i++)
        {
            if (window->mouseButtons[i] == _GLFW_STICK)
                window->mouseButtons[i] = GLFW_RELEASE;
        }
    }

    window->stickyMouseButtons = enabled;
}


//////////////////////////////////////////////////////////////////////////
//////                         GLFW event API                       //////
//////////////////////////////////////////////////////////////////////////

void _glfwInputKey(_GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (key >= 0 && key <= GLFW_KEY_LAST)
    {
        GLboolean repeated = GL_FALSE;

        if (action == GLFW_RELEASE && window->keys[key] == GLFW_RELEASE)
            return;

        if (action == GLFW_PRESS && window->keys[key] == GLFW_PRESS)
            repeated = GL_TRUE;

        if (action == GLFW_RELEASE && window->stickyKeys)
            window->keys[key] = _GLFW_STICK;
        else
            window->keys[key] = (char) action;

        if (repeated)
            action = GLFW_REPEAT;
    }

    if (window->callbacks.key)
        window->callbacks.key((GLFWwindow*) window, key, scancode, action, mods);
}

void _glfwInputChar(_GLFWwindow* window, unsigned int codepoint, int mods, int plain)
{
    if (codepoint < 32 || (codepoint > 126 && codepoint < 160))
        return;

    if (window->callbacks.charmods)
        window->callbacks.charmods((GLFWwindow*) window, codepoint, mods);

    if (plain)
    {
        if (window->callbacks.character)
            window->callbacks.character((GLFWwindow*) window, codepoint);
    }
}

void _glfwInputScroll(_GLFWwindow* window, double xoffset, double yoffset)
{
    if (window->callbacks.scroll)
        window->callbacks.scroll((GLFWwindow*) window, xoffset, yoffset);
}

void _glfwInputMouseClick(_GLFWwindow* window, int button, int action, int mods)
{
    if (button < 0 || button > GLFW_MOUSE_BUTTON_LAST)
        return;

    // Register mouse button action
    if (action == GLFW_RELEASE && window->stickyMouseButtons)
        window->mouseButtons[button] = _GLFW_STICK;
    else
        window->mouseButtons[button] = (char) action;

    if (window->callbacks.mouseButton)
        window->callbacks.mouseButton((GLFWwindow*) window, button, action, mods);
}

void _glfwInputCursorMotion(_GLFWwindow* window, double x, double y)
{
    if (window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        if (x == 0.0 && y == 0.0)
            return;

        window->cursorPosX += x;
        window->cursorPosY += y;

        x = window->cursorPosX;
        y = window->cursorPosY;
    }

    if (window->callbacks.cursorPos)
        window->callbacks.cursorPos((GLFWwindow*) window, x, y);
}

void _glfwInputCursorEnter(_GLFWwindow* window, int entered)
{
    if (window->callbacks.cursorEnter)
        window->callbacks.cursorEnter((GLFWwindow*) window, entered);
}

void _glfwInputDrop(_GLFWwindow* window, int count, const char** paths)
{
    if (window->callbacks.drop)
        window->callbacks.drop((GLFWwindow*) window, count, paths);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW public API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI int glfwGetInputMode(GLFWwindow* handle, int mode)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT_OR_RETURN(0);

    switch (mode)
    {
        case GLFW_CURSOR:
            return window->cursorMode;
        case GLFW_STICKY_KEYS:
            return window->stickyKeys;
        case GLFW_STICKY_MOUSE_BUTTONS:
            return window->stickyMouseButtons;
        default:
            _glfwInputError(GLFW_INVALID_ENUM, "Invalid input mode");
            return 0;
    }
}

GLFWAPI void glfwSetInputMode(GLFWwindow* handle, int mode, int value)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    switch (mode)
    {
        case GLFW_CURSOR:
            setCursorMode(window, value);
            break;
        case GLFW_STICKY_KEYS:
            setStickyKeys(window, value ? GL_TRUE : GL_FALSE);
            break;
        case GLFW_STICKY_MOUSE_BUTTONS:
            setStickyMouseButtons(window, value ? GL_TRUE : GL_FALSE);
            break;
        default:
            _glfwInputError(GLFW_INVALID_ENUM, "Invalid input mode");
            break;
    }
}

GLFWAPI int glfwGetKey(GLFWwindow* handle, int key)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT_OR_RETURN(GLFW_RELEASE);

    if (key < 0 || key > GLFW_KEY_LAST)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid key");
        return GLFW_RELEASE;
    }

    if (window->keys[key] == _GLFW_STICK)
    {
        // Sticky mode: release key now
        window->keys[key] = GLFW_RELEASE;
        return GLFW_PRESS;
    }

    return (int) window->keys[key];
}

GLFWAPI int glfwGetMouseButton(GLFWwindow* handle, int button)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT_OR_RETURN(GLFW_RELEASE);

    if (button < 0 || button > GLFW_MOUSE_BUTTON_LAST)
    {
        _glfwInputError(GLFW_INVALID_ENUM,
                        "Invalid mouse button");
        return GLFW_RELEASE;
    }

    if (window->mouseButtons[button] == _GLFW_STICK)
    {
        // Sticky mode: release mouse button now
        window->mouseButtons[button] = GLFW_RELEASE;
        return GLFW_PRESS;
    }

    return (int) window->mouseButtons[button];
}

GLFWAPI void glfwGetCursorPos(GLFWwindow* handle, double* xpos, double* ypos)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    if (xpos)
        *xpos = 0;
    if (ypos)
        *ypos = 0;

    _GLFW_REQUIRE_INIT();

    if (window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        if (xpos)
            *xpos = window->cursorPosX;
        if (ypos)
            *ypos = window->cursorPosY;
    }
    else
        _glfwPlatformGetCursorPos(window, xpos, ypos);
}

GLFWAPI void glfwSetCursorPos(GLFWwindow* handle, double xpos, double ypos)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;

    _GLFW_REQUIRE_INIT();

    if (_glfw.cursorWindow != window)
        return;

    if (window->cursorMode == GLFW_CURSOR_DISABLED)
    {
        // Only update the accumulated position if the cursor is disabled
        window->cursorPosX = xpos;
        window->cursorPosY = ypos;
    }
    else
    {
        // Update system cursor position
        _glfwPlatformSetCursorPos(window, xpos, ypos);
    }
}

GLFWAPI GLFWcursor* glfwCreateCursor(const GLFWimage* image, int xhot, int yhot)
{
    _GLFWcursor* cursor;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    cursor = calloc(1, sizeof(_GLFWcursor));
    cursor->next = _glfw.cursorListHead;
    _glfw.cursorListHead = cursor;

    if (!_glfwPlatformCreateCursor(cursor, image, xhot, yhot))
    {
        glfwDestroyCursor((GLFWcursor*) cursor);
        return NULL;
    }

    return (GLFWcursor*) cursor;
}

GLFWAPI GLFWcursor* glfwCreateStandardCursor(int shape)
{
    _GLFWcursor* cursor;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (shape != GLFW_ARROW_CURSOR &&
        shape != GLFW_IBEAM_CURSOR &&
        shape != GLFW_CROSSHAIR_CURSOR &&
        shape != GLFW_HAND_CURSOR &&
        shape != GLFW_HRESIZE_CURSOR &&
        shape != GLFW_VRESIZE_CURSOR)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid standard cursor");
        return NULL;
    }

    cursor = calloc(1, sizeof(_GLFWcursor));
    cursor->next = _glfw.cursorListHead;
    _glfw.cursorListHead = cursor;

    if (!_glfwPlatformCreateStandardCursor(cursor, shape))
    {
        glfwDestroyCursor((GLFWcursor*) cursor);
        return NULL;
    }

    return (GLFWcursor*) cursor;
}

GLFWAPI void glfwDestroyCursor(GLFWcursor* handle)
{
    _GLFWcursor* cursor = (_GLFWcursor*) handle;

    _GLFW_REQUIRE_INIT();

    if (cursor == NULL)
        return;

    // Make sure the cursor is not being used by any window
    {
        _GLFWwindow* window;

        for (window = _glfw.windowListHead;  window;  window = window->next)
        {
            if (window->cursor == cursor)
                glfwSetCursor((GLFWwindow*) window, NULL);
        }
    }

    _glfwPlatformDestroyCursor(cursor);

    // Unlink cursor from global linked list
    {
        _GLFWcursor** prev = &_glfw.cursorListHead;

        while (*prev != cursor)
            prev = &((*prev)->next);

        *prev = cursor->next;
    }

    free(cursor);
}

GLFWAPI void glfwSetCursor(GLFWwindow* windowHandle, GLFWcursor* cursorHandle)
{
    _GLFWwindow* window = (_GLFWwindow*) windowHandle;
    _GLFWcursor* cursor = (_GLFWcursor*) cursorHandle;

    _GLFW_REQUIRE_INIT();

    _glfwPlatformSetCursor(window, cursor);

    window->cursor = cursor;
}

GLFWAPI GLFWkeyfun glfwSetKeyCallback(GLFWwindow* handle, GLFWkeyfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.key, cbfun);
    return cbfun;
}

GLFWAPI GLFWcharfun glfwSetCharCallback(GLFWwindow* handle, GLFWcharfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.character, cbfun);
    return cbfun;
}

GLFWAPI GLFWcharmodsfun glfwSetCharModsCallback(GLFWwindow* handle, GLFWcharmodsfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.charmods, cbfun);
    return cbfun;
}

GLFWAPI GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* handle,
                                                      GLFWmousebuttonfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.mouseButton, cbfun);
    return cbfun;
}

GLFWAPI GLFWcursorposfun glfwSetCursorPosCallback(GLFWwindow* handle,
                                                  GLFWcursorposfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.cursorPos, cbfun);
    return cbfun;
}

GLFWAPI GLFWcursorenterfun glfwSetCursorEnterCallback(GLFWwindow* handle,
                                                      GLFWcursorenterfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.cursorEnter, cbfun);
    return cbfun;
}

GLFWAPI GLFWscrollfun glfwSetScrollCallback(GLFWwindow* handle,
                                            GLFWscrollfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.scroll, cbfun);
    return cbfun;
}

GLFWAPI GLFWdropfun glfwSetDropCallback(GLFWwindow* handle, GLFWdropfun cbfun)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    _GLFW_SWAP_POINTERS(window->callbacks.drop, cbfun);
    return cbfun;
}

GLFWAPI int glfwJoystickPresent(int joy)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(0);

    if (joy < 0 || joy > GLFW_JOYSTICK_LAST)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid joystick");
        return 0;
    }

    return _glfwPlatformJoystickPresent(joy);
}

GLFWAPI const float* glfwGetJoystickAxes(int joy, int* count)
{
    *count = 0;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (joy < 0 || joy > GLFW_JOYSTICK_LAST)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid joystick");
        return NULL;
    }

    return _glfwPlatformGetJoystickAxes(joy, count);
}

GLFWAPI const unsigned char* glfwGetJoystickButtons(int joy, int* count)
{
    *count = 0;

    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (joy < 0 || joy > GLFW_JOYSTICK_LAST)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid joystick");
        return NULL;
    }

    return _glfwPlatformGetJoystickButtons(joy, count);
}

GLFWAPI const char* glfwGetJoystickName(int joy)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (joy < 0 || joy > GLFW_JOYSTICK_LAST)
    {
        _glfwInputError(GLFW_INVALID_ENUM, "Invalid joystick");
        return NULL;
    }

    return _glfwPlatformGetJoystickName(joy);
}

GLFWAPI void glfwSetClipboardString(GLFWwindow* handle, const char* string)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT();
    _glfwPlatformSetClipboardString(window, string);
}

GLFWAPI const char* glfwGetClipboardString(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return _glfwPlatformGetClipboardString(window);
}

GLFWAPI double glfwGetTime(void)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(0.0);
    return _glfwPlatformGetTime();
}

GLFWAPI void glfwSetTime(double time)
{
    _GLFW_REQUIRE_INIT();

    if (time != time || time < 0.0 || time > 18446744073.0)
    {
        _glfwInputError(GLFW_INVALID_VALUE, "Invalid time");
        return;
    }

    _glfwPlatformSetTime(time);
}

