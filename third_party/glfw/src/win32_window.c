//========================================================================
// GLFW 3.1 Win32 - www.glfw.org
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
#include <malloc.h>
#include <string.h>
#include <windowsx.h>
#include <shellapi.h>

#define _GLFW_KEY_INVALID -2

#define _GLFW_WNDCLASSNAME L"GLFW30"


// Returns the window style for the specified window
//
static DWORD getWindowStyle(const _GLFWwindow* window)
{
    DWORD style = WS_CLIPSIBLINGS | WS_CLIPCHILDREN;

    if (window->decorated && !window->monitor)
    {
        style |= WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;

        if (window->resizable)
            style |= WS_MAXIMIZEBOX | WS_SIZEBOX;
    }
    else
        style |= WS_POPUP;

    return style;
}

// Returns the extended window style for the specified window
//
static DWORD getWindowExStyle(const _GLFWwindow* window)
{
    DWORD style = WS_EX_APPWINDOW;

    if (window->decorated && !window->monitor)
        style |= WS_EX_WINDOWEDGE;

    return style;
}

// Updates the cursor clip rect
//
static void updateClipRect(_GLFWwindow* window)
{
    RECT clipRect;
    GetClientRect(window->win32.handle, &clipRect);
    ClientToScreen(window->win32.handle, (POINT*) &clipRect.left);
    ClientToScreen(window->win32.handle, (POINT*) &clipRect.right);
    ClipCursor(&clipRect);
}

// Hide the mouse cursor
//
static void hideCursor(_GLFWwindow* window)
{
    POINT pos;

    ClipCursor(NULL);

    if (GetCursorPos(&pos))
    {
        if (WindowFromPoint(pos) == window->win32.handle)
            SetCursor(NULL);
    }
}

// Disable the mouse cursor
//
static void disableCursor(_GLFWwindow* window)
{
    POINT pos;

    updateClipRect(window);

    if (GetCursorPos(&pos))
    {
        if (WindowFromPoint(pos) == window->win32.handle)
            SetCursor(NULL);
    }
}

// Restores the mouse cursor
//
static void restoreCursor(_GLFWwindow* window)
{
    POINT pos;

    ClipCursor(NULL);

    if (GetCursorPos(&pos))
    {
        if (WindowFromPoint(pos) == window->win32.handle)
        {
            if (window->cursor)
                SetCursor(window->cursor->win32.handle);
            else
                SetCursor(LoadCursorW(NULL, IDC_ARROW));
        }
    }
}

// Translates a GLFW standard cursor to a resource ID
//
static LPWSTR translateCursorShape(int shape)
{
    switch (shape)
    {
        case GLFW_ARROW_CURSOR:
            return IDC_ARROW;
        case GLFW_IBEAM_CURSOR:
            return IDC_IBEAM;
        case GLFW_CROSSHAIR_CURSOR:
            return IDC_CROSS;
        case GLFW_HAND_CURSOR:
            return IDC_HAND;
        case GLFW_HRESIZE_CURSOR:
            return IDC_SIZEWE;
        case GLFW_VRESIZE_CURSOR:
            return IDC_SIZENS;
    }

    return NULL;
}

// Retrieves and translates modifier keys
//
static int getKeyMods(void)
{
    int mods = 0;

    if (GetKeyState(VK_SHIFT) & (1 << 31))
        mods |= GLFW_MOD_SHIFT;
    if (GetKeyState(VK_CONTROL) & (1 << 31))
        mods |= GLFW_MOD_CONTROL;
    if (GetKeyState(VK_MENU) & (1 << 31))
        mods |= GLFW_MOD_ALT;
    if ((GetKeyState(VK_LWIN) | GetKeyState(VK_RWIN)) & (1 << 31))
        mods |= GLFW_MOD_SUPER;

    return mods;
}

// Retrieves and translates modifier keys
//
static int getAsyncKeyMods(void)
{
    int mods = 0;

    if (GetAsyncKeyState(VK_SHIFT) & (1 << 31))
        mods |= GLFW_MOD_SHIFT;
    if (GetAsyncKeyState(VK_CONTROL) & (1 << 31))
        mods |= GLFW_MOD_CONTROL;
    if (GetAsyncKeyState(VK_MENU) & (1 << 31))
        mods |= GLFW_MOD_ALT;
    if ((GetAsyncKeyState(VK_LWIN) | GetAsyncKeyState(VK_RWIN)) & (1 << 31))
        mods |= GLFW_MOD_SUPER;

    return mods;
}

// Translates a Windows key to the corresponding GLFW key
//
static int translateKey(WPARAM wParam, LPARAM lParam)
{
    if (wParam == VK_CONTROL)
    {
        // The CTRL keys require special handling

        MSG next;
        DWORD time;

        // Is this an extended key (i.e. right key)?
        if (lParam & 0x01000000)
            return GLFW_KEY_RIGHT_CONTROL;

        // Here is a trick: "Alt Gr" sends LCTRL, then RALT. We only
        // want the RALT message, so we try to see if the next message
        // is a RALT message. In that case, this is a false LCTRL!
        time = GetMessageTime();

        if (PeekMessageW(&next, NULL, 0, 0, PM_NOREMOVE))
        {
            if (next.message == WM_KEYDOWN ||
                next.message == WM_SYSKEYDOWN ||
                next.message == WM_KEYUP ||
                next.message == WM_SYSKEYUP)
            {
                if (next.wParam == VK_MENU &&
                    (next.lParam & 0x01000000) &&
                    next.time == time)
                {
                    // Next message is a RALT down message, which
                    // means that this is not a proper LCTRL message
                    return _GLFW_KEY_INVALID;
                }
            }
        }

        return GLFW_KEY_LEFT_CONTROL;
    }

    return _glfw.win32.publicKeys[HIWORD(lParam) & 0x1FF];
}

// Enter full screen mode
//
static GLboolean enterFullscreenMode(_GLFWwindow* window)
{
    GLFWvidmode mode;
    GLboolean status;
    int xpos, ypos;

    status = _glfwSetVideoMode(window->monitor, &window->videoMode);

    _glfwPlatformGetVideoMode(window->monitor, &mode);
    _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);

    SetWindowPos(window->win32.handle, HWND_TOPMOST,
                 xpos, ypos, mode.width, mode.height, SWP_NOCOPYBITS);

    return status;
}

// Leave full screen mode
//
static void leaveFullscreenMode(_GLFWwindow* window)
{
    _glfwRestoreVideoMode(window->monitor);
}

// Window callback function (handles window events)
//
static LRESULT CALLBACK windowProc(HWND hWnd, UINT uMsg,
                                   WPARAM wParam, LPARAM lParam)
{
    _GLFWwindow* window = (_GLFWwindow*) GetWindowLongPtrW(hWnd, 0);

    switch (uMsg)
    {
        case WM_NCCREATE:
        {
            CREATESTRUCTW* cs = (CREATESTRUCTW*) lParam;
            SetWindowLongPtrW(hWnd, 0, (LONG_PTR) cs->lpCreateParams);
            break;
        }

        case WM_SETFOCUS:
        {
            if (window->cursorMode != GLFW_CURSOR_NORMAL)
                _glfwPlatformApplyCursorMode(window);

            _glfwInputWindowFocus(window, GL_TRUE);
            return 0;
        }

        case WM_KILLFOCUS:
        {
            if (window->cursorMode != GLFW_CURSOR_NORMAL)
                restoreCursor(window);

            if (window->monitor && window->autoIconify)
                _glfwPlatformIconifyWindow(window);

            _glfwInputWindowFocus(window, GL_FALSE);
            return 0;
        }

        case WM_SYSCOMMAND:
        {
            switch (wParam & 0xfff0)
            {
                case SC_SCREENSAVE:
                case SC_MONITORPOWER:
                {
                    if (window->monitor)
                    {
                        // We are running in full screen mode, so disallow
                        // screen saver and screen blanking
                        return 0;
                    }
                    else
                        break;
                }

                // User trying to access application menu using ALT?
                case SC_KEYMENU:
                    return 0;
            }
            break;
        }

        case WM_CLOSE:
        {
            _glfwInputWindowCloseRequest(window);
            return 0;
        }

        case WM_KEYDOWN:
        case WM_SYSKEYDOWN:
        {
            const int scancode = (lParam >> 16) & 0x1ff;
            const int key = translateKey(wParam, lParam);
            if (key == _GLFW_KEY_INVALID)
                break;

            _glfwInputKey(window, key, scancode, GLFW_PRESS, getKeyMods());
            break;
        }

        case WM_CHAR:
        {
            _glfwInputChar(window, (unsigned int) wParam, getKeyMods(), GL_TRUE);
            return 0;
        }

        case WM_SYSCHAR:
        {
            _glfwInputChar(window, (unsigned int) wParam, getKeyMods(), GL_FALSE);
            return 0;
        }

        case WM_UNICHAR:
        {
            // This message is not sent by Windows, but is sent by some
            // third-party input method engines

            if (wParam == UNICODE_NOCHAR)
            {
                // Returning TRUE here announces support for this message
                return TRUE;
            }

            _glfwInputChar(window, (unsigned int) wParam, getKeyMods(), GL_TRUE);
            return FALSE;
        }

        case WM_KEYUP:
        case WM_SYSKEYUP:
        {
            const int mods = getKeyMods();
            const int scancode = (lParam >> 16) & 0x1ff;
            const int key = translateKey(wParam, lParam);
            if (key == _GLFW_KEY_INVALID)
                break;

            if (wParam == VK_SHIFT)
            {
                // Release both Shift keys on Shift up event, as only one event
                // is sent even if both keys are released
                _glfwInputKey(window, GLFW_KEY_LEFT_SHIFT, scancode, GLFW_RELEASE, mods);
                _glfwInputKey(window, GLFW_KEY_RIGHT_SHIFT, scancode, GLFW_RELEASE, mods);
            }
            else if (wParam == VK_SNAPSHOT)
            {
                // Key down is not reported for the print screen key
                _glfwInputKey(window, key, scancode, GLFW_PRESS, mods);
                _glfwInputKey(window, key, scancode, GLFW_RELEASE, mods);
            }
            else
                _glfwInputKey(window, key, scancode, GLFW_RELEASE, mods);

            break;
        }

        case WM_LBUTTONDOWN:
        case WM_RBUTTONDOWN:
        case WM_MBUTTONDOWN:
        case WM_XBUTTONDOWN:
        {
            const int mods = getKeyMods();

            SetCapture(hWnd);

            if (uMsg == WM_LBUTTONDOWN)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS, mods);
            else if (uMsg == WM_RBUTTONDOWN)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_RIGHT, GLFW_PRESS, mods);
            else if (uMsg == WM_MBUTTONDOWN)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_MIDDLE, GLFW_PRESS, mods);
            else
            {
                if (HIWORD(wParam) == XBUTTON1)
                    _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_4, GLFW_PRESS, mods);
                else if (HIWORD(wParam) == XBUTTON2)
                    _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_5, GLFW_PRESS, mods);

                return TRUE;
            }

            return 0;
        }

        case WM_LBUTTONUP:
        case WM_RBUTTONUP:
        case WM_MBUTTONUP:
        case WM_XBUTTONUP:
        {
            const int mods = getKeyMods();

            ReleaseCapture();

            if (uMsg == WM_LBUTTONUP)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_LEFT, GLFW_RELEASE, mods);
            else if (uMsg == WM_RBUTTONUP)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_RIGHT, GLFW_RELEASE, mods);
            else if (uMsg == WM_MBUTTONUP)
                _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_MIDDLE, GLFW_RELEASE, mods);
            else
            {
                if (HIWORD(wParam) == XBUTTON1)
                    _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_4, GLFW_RELEASE, mods);
                else if (HIWORD(wParam) == XBUTTON2)
                    _glfwInputMouseClick(window, GLFW_MOUSE_BUTTON_5, GLFW_RELEASE, mods);

                return TRUE;
            }

            return 0;
        }

        case WM_MOUSEMOVE:
        {
            const int x = GET_X_LPARAM(lParam);
            const int y = GET_Y_LPARAM(lParam);

            if (window->cursorMode == GLFW_CURSOR_DISABLED)
            {
                if (_glfw.cursorWindow != window)
                    break;

                _glfwInputCursorMotion(window,
                                       x - window->win32.cursorPosX,
                                       y - window->win32.cursorPosY);
            }
            else
                _glfwInputCursorMotion(window, x, y);

            window->win32.cursorPosX = x;
            window->win32.cursorPosY = y;

            if (!window->win32.cursorTracked)
            {
                TRACKMOUSEEVENT tme;
                ZeroMemory(&tme, sizeof(tme));
                tme.cbSize = sizeof(tme);
                tme.dwFlags = TME_LEAVE;
                tme.hwndTrack = window->win32.handle;
                TrackMouseEvent(&tme);

                window->win32.cursorTracked = GL_TRUE;
                _glfwInputCursorEnter(window, GL_TRUE);
            }

            return 0;
        }

        case WM_MOUSELEAVE:
        {
            window->win32.cursorTracked = GL_FALSE;
            _glfwInputCursorEnter(window, GL_FALSE);
            return 0;
        }

        case WM_MOUSEWHEEL:
        {
            _glfwInputScroll(window, 0.0, (SHORT) HIWORD(wParam) / (double) WHEEL_DELTA);
            return 0;
        }

        case WM_MOUSEHWHEEL:
        {
            // This message is only sent on Windows Vista and later
            // NOTE: The X-axis is inverted for consistency with OS X and X11.
            _glfwInputScroll(window, -((SHORT) HIWORD(wParam) / (double) WHEEL_DELTA), 0.0);
            return 0;
        }

        case WM_SIZE:
        {
            if (_glfw.cursorWindow == window)
            {
                if (window->cursorMode == GLFW_CURSOR_DISABLED)
                    updateClipRect(window);
            }

            if (!window->win32.iconified && wParam == SIZE_MINIMIZED)
            {
                window->win32.iconified = GL_TRUE;
                if (window->monitor)
                    leaveFullscreenMode(window);

                _glfwInputWindowIconify(window, GL_TRUE);
            }
            else if (window->win32.iconified &&
                     (wParam == SIZE_RESTORED || wParam == SIZE_MAXIMIZED))
            {
                window->win32.iconified = GL_FALSE;
                if (window->monitor)
                    enterFullscreenMode(window);

                _glfwInputWindowIconify(window, GL_FALSE);
            }

            _glfwInputFramebufferSize(window, LOWORD(lParam), HIWORD(lParam));
            _glfwInputWindowSize(window, LOWORD(lParam), HIWORD(lParam));
            return 0;
        }

        case WM_MOVE:
        {
            if (_glfw.cursorWindow == window)
            {
                if (window->cursorMode == GLFW_CURSOR_DISABLED)
                    updateClipRect(window);
            }

            // NOTE: This cannot use LOWORD/HIWORD recommended by MSDN, as
            // those macros do not handle negative window positions correctly
            _glfwInputWindowPos(window,
                                GET_X_LPARAM(lParam),
                                GET_Y_LPARAM(lParam));
            return 0;
        }

        case WM_PAINT:
        {
            _glfwInputWindowDamage(window);
            break;
        }

        case WM_ERASEBKGND:
        {
            return TRUE;
        }

        case WM_SETCURSOR:
        {
            if (_glfw.cursorWindow == window && LOWORD(lParam) == HTCLIENT)
            {
                if (window->cursorMode == GLFW_CURSOR_HIDDEN ||
                    window->cursorMode == GLFW_CURSOR_DISABLED)
                {
                    SetCursor(NULL);
                    return TRUE;
                }
                else if (window->cursor)
                {
                    SetCursor(window->cursor->win32.handle);
                    return TRUE;
                }
            }

            break;
        }

        case WM_DEVICECHANGE:
        {
            if (DBT_DEVNODES_CHANGED == wParam)
            {
                _glfwInputMonitorChange();
                return TRUE;
            }
            break;
        }

        case WM_DROPFILES:
        {
            HDROP drop = (HDROP) wParam;
            POINT pt;
            int i;

            const int count = DragQueryFileW(drop, 0xffffffff, NULL, 0);
            char** paths = calloc(count, sizeof(char*));

            // Move the mouse to the position of the drop
            DragQueryPoint(drop, &pt);
            _glfwInputCursorMotion(window, pt.x, pt.y);

            for (i = 0;  i < count;  i++)
            {
                const UINT length = DragQueryFileW(drop, i, NULL, 0);
                WCHAR* buffer = calloc(length + 1, sizeof(WCHAR));

                DragQueryFileW(drop, i, buffer, length + 1);
                paths[i] = _glfwCreateUTF8FromWideString(buffer);

                free(buffer);
            }

            _glfwInputDrop(window, count, (const char**) paths);

            for (i = 0;  i < count;  i++)
                free(paths[i]);
            free(paths);

            DragFinish(drop);
            return 0;
        }
    }

    return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

// Translate client window size to full window size (including window borders)
//
static void getFullWindowSize(_GLFWwindow* window,
                              int clientWidth, int clientHeight,
                              int* fullWidth, int* fullHeight)
{
    RECT rect = { 0, 0, clientWidth, clientHeight };
    AdjustWindowRectEx(&rect, getWindowStyle(window),
                       FALSE, getWindowExStyle(window));
    *fullWidth = rect.right - rect.left;
    *fullHeight = rect.bottom - rect.top;
}

// Creates the GLFW window and rendering context
//
static int createWindow(_GLFWwindow* window,
                        const _GLFWwndconfig* wndconfig,
                        const _GLFWctxconfig* ctxconfig,
                        const _GLFWfbconfig* fbconfig)
{
    int xpos, ypos, fullWidth, fullHeight;
    WCHAR* wideTitle;

    if (wndconfig->monitor)
    {
        GLFWvidmode mode;

        // NOTE: This window placement is temporary and approximate, as the
        //       correct position and size cannot be known until the monitor
        //       video mode has been set
        _glfwPlatformGetMonitorPos(wndconfig->monitor, &xpos, &ypos);
        _glfwPlatformGetVideoMode(wndconfig->monitor, &mode);
        fullWidth  = mode.width;
        fullHeight = mode.height;
    }
    else
    {
        xpos = CW_USEDEFAULT;
        ypos = CW_USEDEFAULT;

        getFullWindowSize(window,
                          wndconfig->width, wndconfig->height,
                          &fullWidth, &fullHeight);
    }

    wideTitle = _glfwCreateWideStringFromUTF8(wndconfig->title);
    if (!wideTitle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to convert window title to UTF-16");
        return GL_FALSE;
    }

    window->win32.handle = CreateWindowExW(getWindowExStyle(window),
                                           _GLFW_WNDCLASSNAME,
                                           wideTitle,
                                           getWindowStyle(window),
                                           xpos, ypos,
                                           fullWidth, fullHeight,
                                           NULL, // No parent window
                                           NULL, // No window menu
                                           GetModuleHandleW(NULL),
                                           window); // Pass object to WM_CREATE

    free(wideTitle);

    if (!window->win32.handle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to create window");
        return GL_FALSE;
    }

    if (_glfw_ChangeWindowMessageFilterEx)
    {
        _glfw_ChangeWindowMessageFilterEx(window->win32.handle,
                                          WM_DROPFILES, MSGFLT_ALLOW, NULL);
        _glfw_ChangeWindowMessageFilterEx(window->win32.handle,
                                          WM_COPYDATA, MSGFLT_ALLOW, NULL);
        _glfw_ChangeWindowMessageFilterEx(window->win32.handle,
                                          WM_COPYGLOBALDATA, MSGFLT_ALLOW, NULL);
    }

    if (wndconfig->floating && !wndconfig->monitor)
    {
        SetWindowPos(window->win32.handle,
                     HWND_TOPMOST,
                     0, 0, 0, 0,
                     SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE);
    }

    DragAcceptFiles(window->win32.handle, TRUE);

    if (!_glfwCreateContext(window, ctxconfig, fbconfig))
        return GL_FALSE;

    return GL_TRUE;
}

// Destroys the GLFW window and rendering context
//
static void destroyWindow(_GLFWwindow* window)
{
    _glfwDestroyContext(window);

    if (window->win32.handle)
    {
        DestroyWindow(window->win32.handle);
        window->win32.handle = NULL;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Registers the GLFW window class
//
GLboolean _glfwRegisterWindowClass(void)
{
    WNDCLASSW wc;

    wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc   = (WNDPROC) windowProc;
    wc.cbClsExtra    = 0;                           // No extra class data
    wc.cbWndExtra    = sizeof(void*) + sizeof(int); // Make room for one pointer
    wc.hInstance     = GetModuleHandleW(NULL);
    wc.hCursor       = LoadCursorW(NULL, IDC_ARROW);
    wc.hbrBackground = NULL;                        // No background
    wc.lpszMenuName  = NULL;                        // No menu
    wc.lpszClassName = _GLFW_WNDCLASSNAME;

    // Load user-provided icon if available
    wc.hIcon = LoadIconW(GetModuleHandleW(NULL), L"GLFW_ICON");
    if (!wc.hIcon)
    {
        // No user-provided icon found, load default icon
        wc.hIcon = LoadIconW(NULL, IDI_WINLOGO);
    }

    if (!RegisterClassW(&wc))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to register window class");
        return GL_FALSE;
    }

    return GL_TRUE;
}

// Unregisters the GLFW window class
//
void _glfwUnregisterWindowClass(void)
{
    UnregisterClassW(_GLFW_WNDCLASSNAME, GetModuleHandleW(NULL));
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformCreateWindow(_GLFWwindow* window,
                              const _GLFWwndconfig* wndconfig,
                              const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig)
{
    int status;

    if (!createWindow(window, wndconfig, ctxconfig, fbconfig))
        return GL_FALSE;

    status = _glfwAnalyzeContext(window, ctxconfig, fbconfig);

    if (status == _GLFW_RECREATION_IMPOSSIBLE)
        return GL_FALSE;

    if (status == _GLFW_RECREATION_REQUIRED)
    {
        // Some window hints require us to re-create the context using WGL
        // extensions retrieved through the current context, as we cannot check
        // for WGL extensions or retrieve WGL entry points before we have a
        // current context (actually until we have implicitly loaded the ICD)

        // Yes, this is strange, and yes, this is the proper way on Win32

        // As Windows only allows you to set the pixel format once for a
        // window, we need to destroy the current window and create a new one
        // to be able to use the new pixel format

        // Technically, it may be possible to keep the old window around if
        // we're just creating an OpenGL 3.0+ context with the same pixel
        // format, but it's not worth the added code complexity

        // First we clear the current context (the one we just created)
        // This is usually done by glfwDestroyWindow, but as we're not doing
        // full GLFW window destruction, it's duplicated here
        _glfwPlatformMakeContextCurrent(NULL);

        // Next destroy the Win32 window and WGL context (without resetting or
        // destroying the GLFW window object)
        destroyWindow(window);

        // ...and then create them again, this time with better APIs
        if (!createWindow(window, wndconfig, ctxconfig, fbconfig))
            return GL_FALSE;
    }

    if (window->monitor)
    {
        _glfwPlatformShowWindow(window);
        if (!enterFullscreenMode(window))
            return GL_FALSE;
    }

    return GL_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    if (window->monitor)
        leaveFullscreenMode(window);

    destroyWindow(window);
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char* title)
{
    WCHAR* wideTitle = _glfwCreateWideStringFromUTF8(title);
    if (!wideTitle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to convert window title to UTF-16");
        return;
    }

    SetWindowTextW(window->win32.handle, wideTitle);
    free(wideTitle);
}

void _glfwPlatformGetWindowPos(_GLFWwindow* window, int* xpos, int* ypos)
{
    POINT pos = { 0, 0 };
    ClientToScreen(window->win32.handle, &pos);

    if (xpos)
        *xpos = pos.x;
    if (ypos)
        *ypos = pos.y;
}

void _glfwPlatformSetWindowPos(_GLFWwindow* window, int xpos, int ypos)
{
    RECT rect = { xpos, ypos, xpos, ypos };
    AdjustWindowRectEx(&rect, getWindowStyle(window),
                       FALSE, getWindowExStyle(window));
    SetWindowPos(window->win32.handle, NULL, rect.left, rect.top, 0, 0,
                 SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOSIZE);
}

void _glfwPlatformGetWindowSize(_GLFWwindow* window, int* width, int* height)
{
    RECT area;
    GetClientRect(window->win32.handle, &area);

    if (width)
        *width = area.right;
    if (height)
        *height = area.bottom;
}

void _glfwPlatformSetWindowSize(_GLFWwindow* window, int width, int height)
{
    if (window->monitor)
        enterFullscreenMode(window);
    else
    {
        int fullWidth, fullHeight;
        getFullWindowSize(window, width, height, &fullWidth, &fullHeight);

        SetWindowPos(window->win32.handle, HWND_TOP,
                     0, 0, fullWidth, fullHeight,
                     SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOZORDER);
    }
}

void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height)
{
    _glfwPlatformGetWindowSize(window, width, height);
}

void _glfwPlatformGetWindowFrameSize(_GLFWwindow* window,
                                     int* left, int* top,
                                     int* right, int* bottom)
{
    RECT rect;
    int width, height;

    _glfwPlatformGetWindowSize(window, &width, &height);
    SetRect(&rect, 0, 0, width, height);
    AdjustWindowRectEx(&rect, getWindowStyle(window),
                       FALSE, getWindowExStyle(window));

    if (left)
        *left = -rect.left;
    if (top)
        *top = -rect.top;
    if (right)
        *right = rect.right - width;
    if (bottom)
        *bottom = rect.bottom - height;
}

void _glfwPlatformIconifyWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_MINIMIZE);
}

void _glfwPlatformRestoreWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_RESTORE);
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_SHOW);
    BringWindowToTop(window->win32.handle);
    SetForegroundWindow(window->win32.handle);
    SetFocus(window->win32.handle);
}

void _glfwPlatformUnhideWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_SHOW);
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_HIDE);
}

int _glfwPlatformWindowFocused(_GLFWwindow* window)
{
    return window->win32.handle == GetActiveWindow();
}

int _glfwPlatformWindowIconified(_GLFWwindow* window)
{
    return IsIconic(window->win32.handle);
}

int _glfwPlatformWindowVisible(_GLFWwindow* window)
{
    return IsWindowVisible(window->win32.handle);
}

void _glfwPlatformPollEvents(void)
{
    MSG msg;

    while (PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE))
    {
        if (msg.message == WM_QUIT)
        {
            // Treat WM_QUIT as a close on all windows
            // While GLFW does not itself post WM_QUIT, other processes may post
            // it to this one, for example Task Manager

            _GLFWwindow* window = _glfw.windowListHead;
            while (window)
            {
                _glfwInputWindowCloseRequest(window);
                window = window->next;
            }
        }
        else
        {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }

    if (_glfw.cursorWindow)
    {
        _GLFWwindow* window = _glfw.cursorWindow;

        // LSHIFT/RSHIFT fixup (keys tend to "stick" without this fix)
        // This is the only async event handling in GLFW, but it solves some
        // nasty problems
        {
            const int mods = getAsyncKeyMods();

            // Get current state of left and right shift keys
            const int lshiftDown = (GetAsyncKeyState(VK_LSHIFT) >> 15) & 1;
            const int rshiftDown = (GetAsyncKeyState(VK_RSHIFT) >> 15) & 1;

            // See if this differs from our belief of what has happened
            // (we only have to check for lost key up events)
            if (!lshiftDown && window->keys[GLFW_KEY_LEFT_SHIFT] == 1)
                _glfwInputKey(window, GLFW_KEY_LEFT_SHIFT, 0, GLFW_RELEASE, mods);

            if (!rshiftDown && window->keys[GLFW_KEY_RIGHT_SHIFT] == 1)
                _glfwInputKey(window, GLFW_KEY_RIGHT_SHIFT, 0, GLFW_RELEASE, mods);
        }

        if (window->cursorMode == GLFW_CURSOR_DISABLED)
        {
            int width, height;
            _glfwPlatformGetWindowSize(window, &width, &height);

            // NOTE: Re-center the cursor only if it has moved since the last
            //       call, to avoid breaking glfwWaitEvents with WM_MOUSEMOVE
            if (window->win32.cursorPosX != width / 2 ||
                window->win32.cursorPosY != height / 2)
            {
                _glfwPlatformSetCursorPos(window, width / 2, height / 2);
            }
        }
    }
}

void _glfwPlatformWaitEvents(void)
{
    WaitMessage();

    _glfwPlatformPollEvents();
}

void _glfwPlatformPostEmptyEvent(void)
{
    _GLFWwindow* window = _glfw.windowListHead;
    PostMessage(window->win32.handle, WM_NULL, 0, 0);
}

void _glfwPlatformGetCursorPos(_GLFWwindow* window, double* xpos, double* ypos)
{
    POINT pos;

    if (GetCursorPos(&pos))
    {
        ScreenToClient(window->win32.handle, &pos);

        if (xpos)
            *xpos = pos.x;
        if (ypos)
            *ypos = pos.y;
    }
}

void _glfwPlatformSetCursorPos(_GLFWwindow* window, double xpos, double ypos)
{
    POINT pos = { (int) xpos, (int) ypos };

    // Store the new position so it can be recognized later
    window->win32.cursorPosX = pos.x;
    window->win32.cursorPosY = pos.y;

    ClientToScreen(window->win32.handle, &pos);
    SetCursorPos(pos.x, pos.y);
}

void _glfwPlatformApplyCursorMode(_GLFWwindow* window)
{
    switch (window->cursorMode)
    {
        case GLFW_CURSOR_NORMAL:
            restoreCursor(window);
            break;
        case GLFW_CURSOR_HIDDEN:
            hideCursor(window);
            break;
        case GLFW_CURSOR_DISABLED:
            disableCursor(window);
            break;
    }
}

int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    HDC dc;
    HBITMAP bitmap, mask;
    BITMAPV5HEADER bi;
    ICONINFO ii;
    DWORD* target = 0;
    BYTE* source = (BYTE*) image->pixels;
    int i;

    ZeroMemory(&bi, sizeof(bi));
    bi.bV5Size        = sizeof(BITMAPV5HEADER);
    bi.bV5Width       = image->width;
    bi.bV5Height      = -image->height;
    bi.bV5Planes      = 1;
    bi.bV5BitCount    = 32;
    bi.bV5Compression = BI_BITFIELDS;
    bi.bV5RedMask     = 0x00ff0000;
    bi.bV5GreenMask   = 0x0000ff00;
    bi.bV5BlueMask    = 0x000000ff;
    bi.bV5AlphaMask   = 0xff000000;

    dc = GetDC(NULL);
    bitmap = CreateDIBSection(dc, (BITMAPINFO*) &bi, DIB_RGB_COLORS,
                              (void**) &target, NULL, (DWORD) 0);
    ReleaseDC(NULL, dc);

    if (!bitmap)
        return GL_FALSE;

    mask = CreateBitmap(image->width, image->height, 1, 1, NULL);
    if (!mask)
    {
        DeleteObject(bitmap);
        return GL_FALSE;
    }

    for (i = 0;  i < image->width * image->height;  i++, target++, source += 4)
    {
        *target = (source[3] << 24) |
                  (source[0] << 16) |
                  (source[1] <<  8) |
                   source[2];
    }

    ZeroMemory(&ii, sizeof(ii));
    ii.fIcon    = FALSE;
    ii.xHotspot = xhot;
    ii.yHotspot = yhot;
    ii.hbmMask  = mask;
    ii.hbmColor = bitmap;

    cursor->win32.handle = (HCURSOR) CreateIconIndirect(&ii);

    DeleteObject(bitmap);
    DeleteObject(mask);

    if (!cursor->win32.handle)
        return GL_FALSE;

    return GL_TRUE;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    cursor->win32.handle =
        CopyCursor(LoadCursorW(NULL, translateCursorShape(shape)));
    if (!cursor->win32.handle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to create standard cursor");
        return GL_FALSE;
    }

    return GL_TRUE;
}

void _glfwPlatformDestroyCursor(_GLFWcursor* cursor)
{
    if (cursor->win32.handle)
        DestroyIcon((HICON) cursor->win32.handle);
}

void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor)
{
    POINT pos;

    if (_glfw.cursorWindow != window)
        return;

    if (window->cursorMode != GLFW_CURSOR_NORMAL)
        return;

    if (!GetCursorPos(&pos))
        return;

    if (WindowFromPoint(pos) != window->win32.handle)
        return;

    if (cursor)
        SetCursor(cursor->win32.handle);
    else
        SetCursor(LoadCursorW(NULL, IDC_ARROW));
}

void _glfwPlatformSetClipboardString(_GLFWwindow* window, const char* string)
{
    WCHAR* wideString;
    HANDLE stringHandle;
    size_t wideSize;

    wideString = _glfwCreateWideStringFromUTF8(string);
    if (!wideString)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to convert string to UTF-16");
        return;
    }

    wideSize = (wcslen(wideString) + 1) * sizeof(WCHAR);

    stringHandle = GlobalAlloc(GMEM_MOVEABLE, wideSize);
    if (!stringHandle)
    {
        free(wideString);

        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to allocate global handle for clipboard");
        return;
    }

    memcpy(GlobalLock(stringHandle), wideString, wideSize);
    GlobalUnlock(stringHandle);

    if (!OpenClipboard(window->win32.handle))
    {
        GlobalFree(stringHandle);
        free(wideString);

        _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to open clipboard");
        return;
    }

    EmptyClipboard();
    SetClipboardData(CF_UNICODETEXT, stringHandle);
    CloseClipboard();

    free(wideString);
}

const char* _glfwPlatformGetClipboardString(_GLFWwindow* window)
{
    HANDLE stringHandle;

    if (!OpenClipboard(window->win32.handle))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to open clipboard");
        return NULL;
    }

    stringHandle = GetClipboardData(CF_UNICODETEXT);
    if (!stringHandle)
    {
        CloseClipboard();

        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "Win32: Failed to convert clipboard to string");
        return NULL;
    }

    free(_glfw.win32.clipboardString);
    _glfw.win32.clipboardString =
        _glfwCreateUTF8FromWideString(GlobalLock(stringHandle));

    GlobalUnlock(stringHandle);
    CloseClipboard();

    if (!_glfw.win32.clipboardString)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to convert wide string to UTF-8");
        return NULL;
    }

    return _glfw.win32.clipboardString;
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI HWND glfwGetWin32Window(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return window->win32.handle;
}

