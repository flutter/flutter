//========================================================================
// GLFW 3.2 Win32 - www.glfw.org
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
#include <malloc.h>
#include <string.h>
#include <windowsx.h>
#include <shellapi.h>

#define _GLFW_KEY_INVALID -2

// Returns the window style for the specified window
//
static DWORD getWindowStyle(const _GLFWwindow* window)
{
    DWORD style = WS_CLIPSIBLINGS | WS_CLIPCHILDREN;

    if (window->monitor)
        style |= WS_POPUP;
    else
    {
        if (window->decorated)
        {
            style |= WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;

            if (window->resizable)
                style |= WS_MAXIMIZEBOX | WS_THICKFRAME;
        }
        else
            style |= WS_POPUP;
    }

    return style;
}

// Returns the extended window style for the specified window
//
static DWORD getWindowExStyle(const _GLFWwindow* window)
{
    DWORD style = WS_EX_APPWINDOW;

    if (window->monitor || window->floating)
        style |= WS_EX_TOPMOST;

    return style;
}

// Returns the image whose area most closely matches the desired one
//
static const GLFWimage* chooseImage(int count, const GLFWimage* images,
                                    int width, int height)
{
    int i, leastDiff = INT_MAX;
    const GLFWimage* closest = NULL;

    for (i = 0;  i < count;  i++)
    {
        const int currDiff = abs(images[i].width * images[i].height -
                                 width * height);
        if (currDiff < leastDiff)
        {
            closest = images + i;
            leastDiff = currDiff;
        }
    }

    return closest;
}

// Creates an RGBA icon or cursor
//
static HICON createIcon(const GLFWimage* image,
                        int xhot, int yhot, GLFWbool icon)
{
    int i;
    HDC dc;
    HICON handle;
    HBITMAP color, mask;
    BITMAPV5HEADER bi;
    ICONINFO ii;
    unsigned char* target = NULL;
    unsigned char* source = image->pixels;

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
    color = CreateDIBSection(dc,
                             (BITMAPINFO*) &bi,
                             DIB_RGB_COLORS,
                             (void**) &target,
                             NULL,
                             (DWORD) 0);
    ReleaseDC(NULL, dc);

    if (!color)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to create RGBA bitmap");
        return NULL;
    }

    mask = CreateBitmap(image->width, image->height, 1, 1, NULL);
    if (!mask)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to create mask bitmap");
        DeleteObject(color);
        return NULL;
    }

    for (i = 0;  i < image->width * image->height;  i++)
    {
        target[0] = source[2];
        target[1] = source[1];
        target[2] = source[0];
        target[3] = source[3];
        target += 4;
        source += 4;
    }

    ZeroMemory(&ii, sizeof(ii));
    ii.fIcon    = icon;
    ii.xHotspot = xhot;
    ii.yHotspot = yhot;
    ii.hbmMask  = mask;
    ii.hbmColor = color;

    handle = CreateIconIndirect(&ii);

    DeleteObject(color);
    DeleteObject(mask);

    if (!handle)
    {
        if (icon)
            _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to create icon");
        else
            _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to create cursor");
    }

    return handle;
}

// Translate client window size to full window size according to styles
//
static void getFullWindowSize(DWORD style, DWORD exStyle,
                              int clientWidth, int clientHeight,
                              int* fullWidth, int* fullHeight)
{
    RECT rect = { 0, 0, clientWidth, clientHeight };
    AdjustWindowRectEx(&rect, style, FALSE, exStyle);
    *fullWidth = rect.right - rect.left;
    *fullHeight = rect.bottom - rect.top;
}

// Enforce the client rect aspect ratio based on which edge is being dragged
//
static void applyAspectRatio(_GLFWwindow* window, int edge, RECT* area)
{
    int xoff, yoff;
    const float ratio = (float) window->numer / (float) window->denom;

    getFullWindowSize(getWindowStyle(window), getWindowExStyle(window),
                      0, 0, &xoff, &yoff);

    if (edge == WMSZ_LEFT  || edge == WMSZ_BOTTOMLEFT ||
        edge == WMSZ_RIGHT || edge == WMSZ_BOTTOMRIGHT)
    {
        area->bottom = area->top + yoff +
            (int) ((area->right - area->left - xoff) / ratio);
    }
    else if (edge == WMSZ_TOPLEFT || edge == WMSZ_TOPRIGHT)
    {
        area->top = area->bottom - yoff -
            (int) ((area->right - area->left - xoff) / ratio);
    }
    else if (edge == WMSZ_TOP || edge == WMSZ_BOTTOM)
    {
        area->right = area->left + xoff +
            (int) ((area->bottom - area->top - yoff) * ratio);
    }
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

// Make the specified window and its video mode active on its monitor
//
static GLFWbool acquireMonitor(_GLFWwindow* window)
{
    GLFWvidmode mode;
    GLFWbool status;
    int xpos, ypos;

    status = _glfwSetVideoModeWin32(window->monitor, &window->videoMode);

    _glfwPlatformGetVideoMode(window->monitor, &mode);
    _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);

    SetWindowPos(window->win32.handle, HWND_TOPMOST,
                 xpos, ypos, mode.width, mode.height,
                 SWP_NOACTIVATE | SWP_NOCOPYBITS);

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
    _glfwRestoreVideoModeWin32(window->monitor);
}

// Window callback function (handles window messages)
//
static LRESULT CALLBACK windowProc(HWND hWnd, UINT uMsg,
                                   WPARAM wParam, LPARAM lParam)
{
    _GLFWwindow* window = (_GLFWwindow*) GetWindowLongPtrW(hWnd, 0);
    if (!window)
    {
        // This is the message handling for the hidden helper window

        switch (uMsg)
        {
            case WM_NCCREATE:
            {
                CREATESTRUCTW* cs = (CREATESTRUCTW*) lParam;
                SetWindowLongPtrW(hWnd, 0, (LONG_PTR) cs->lpCreateParams);
                break;
            }

            case WM_DISPLAYCHANGE:
            {
                _glfwInputMonitorChange();
                return 0;
            }
        }

        return DefWindowProcW(hWnd, uMsg, wParam, lParam);
    }

    switch (uMsg)
    {
        case WM_SETFOCUS:
        {
            if (window->cursorMode == GLFW_CURSOR_DISABLED)
                _glfwPlatformSetCursorMode(window, GLFW_CURSOR_DISABLED);

            _glfwInputWindowFocus(window, GLFW_TRUE);
            return 0;
        }

        case WM_KILLFOCUS:
        {
            if (window->cursorMode == GLFW_CURSOR_DISABLED)
                _glfwPlatformSetCursorMode(window, GLFW_CURSOR_NORMAL);

            if (window->monitor && window->autoIconify)
                _glfwPlatformIconifyWindow(window);

            _glfwInputWindowFocus(window, GLFW_FALSE);
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

        case WM_CHAR:
        case WM_SYSCHAR:
        case WM_UNICHAR:
        {
            const GLFWbool plain = (uMsg != WM_SYSCHAR);

            if (uMsg == WM_UNICHAR && wParam == UNICODE_NOCHAR)
            {
                // WM_UNICHAR is not sent by Windows, but is sent by some
                // third-party input method engine
                // Returning TRUE here announces support for this message
                return TRUE;
            }

            _glfwInputChar(window, (unsigned int) wParam, getKeyMods(), plain);
            return 0;
        }

        case WM_KEYDOWN:
        case WM_SYSKEYDOWN:
        case WM_KEYUP:
        case WM_SYSKEYUP:
        {
            const int key = translateKey(wParam, lParam);
            const int scancode = (lParam >> 16) & 0x1ff;
            const int action = ((lParam >> 31) & 1) ? GLFW_RELEASE : GLFW_PRESS;
            const int mods = getKeyMods();

            if (key == _GLFW_KEY_INVALID)
                break;

            if (action == GLFW_RELEASE && wParam == VK_SHIFT)
            {
                // Release both Shift keys on Shift up event, as only one event
                // is sent even if both keys are released
                _glfwInputKey(window, GLFW_KEY_LEFT_SHIFT, scancode, action, mods);
                _glfwInputKey(window, GLFW_KEY_RIGHT_SHIFT, scancode, action, mods);
            }
            else if (wParam == VK_SNAPSHOT)
            {
                // Key down is not reported for the Print Screen key
                _glfwInputKey(window, key, scancode, GLFW_PRESS, mods);
                _glfwInputKey(window, key, scancode, GLFW_RELEASE, mods);
            }
            else
                _glfwInputKey(window, key, scancode, action, mods);

            break;
        }

        case WM_LBUTTONDOWN:
        case WM_RBUTTONDOWN:
        case WM_MBUTTONDOWN:
        case WM_XBUTTONDOWN:
        case WM_LBUTTONUP:
        case WM_RBUTTONUP:
        case WM_MBUTTONUP:
        case WM_XBUTTONUP:
        {
            int button, action;

            if (uMsg == WM_LBUTTONDOWN || uMsg == WM_LBUTTONUP)
                button = GLFW_MOUSE_BUTTON_LEFT;
            else if (uMsg == WM_RBUTTONDOWN || uMsg == WM_RBUTTONUP)
                button = GLFW_MOUSE_BUTTON_RIGHT;
            else if (uMsg == WM_MBUTTONDOWN || uMsg == WM_MBUTTONUP)
                button = GLFW_MOUSE_BUTTON_MIDDLE;
            else if (GET_XBUTTON_WPARAM(wParam) == XBUTTON1)
                button = GLFW_MOUSE_BUTTON_4;
            else
                button = GLFW_MOUSE_BUTTON_5;

            if (uMsg == WM_LBUTTONDOWN || uMsg == WM_RBUTTONDOWN ||
                uMsg == WM_MBUTTONDOWN || uMsg == WM_XBUTTONDOWN)
            {
                action = GLFW_PRESS;
                SetCapture(hWnd);
            }
            else
            {
                action = GLFW_RELEASE;
                ReleaseCapture();
            }

            _glfwInputMouseClick(window, button, action, getKeyMods());

            if (uMsg == WM_XBUTTONDOWN || uMsg == WM_XBUTTONUP)
                return TRUE;

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

                window->win32.cursorTracked = GLFW_TRUE;
                _glfwInputCursorEnter(window, GLFW_TRUE);
            }

            return 0;
        }

        case WM_MOUSELEAVE:
        {
            window->win32.cursorTracked = GLFW_FALSE;
            _glfwInputCursorEnter(window, GLFW_FALSE);
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
                window->win32.iconified = GLFW_TRUE;
                if (window->monitor)
                    releaseMonitor(window);

                _glfwInputWindowIconify(window, GLFW_TRUE);
            }
            else if (window->win32.iconified &&
                     (wParam == SIZE_RESTORED || wParam == SIZE_MAXIMIZED))
            {
                window->win32.iconified = GLFW_FALSE;
                if (window->monitor)
                    acquireMonitor(window);

                _glfwInputWindowIconify(window, GLFW_FALSE);
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

        case WM_SIZING:
        {
            if (window->numer == GLFW_DONT_CARE ||
                window->denom == GLFW_DONT_CARE)
            {
                break;
            }

            applyAspectRatio(window, (int) wParam, (RECT*) lParam);
            return TRUE;
        }

        case WM_GETMINMAXINFO:
        {
            int xoff, yoff;
            MINMAXINFO* mmi = (MINMAXINFO*) lParam;

            if (window->monitor)
                break;

            getFullWindowSize(getWindowStyle(window), getWindowExStyle(window),
                              0, 0, &xoff, &yoff);

            if (window->minwidth != GLFW_DONT_CARE &&
                window->minheight != GLFW_DONT_CARE)
            {
                mmi->ptMinTrackSize.x = window->minwidth + xoff;
                mmi->ptMinTrackSize.y = window->minheight + yoff;
            }

            if (window->maxwidth != GLFW_DONT_CARE &&
                window->maxheight != GLFW_DONT_CARE)
            {
                mmi->ptMaxTrackSize.x = window->maxwidth + xoff;
                mmi->ptMaxTrackSize.y = window->maxheight + yoff;
            }

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

        case WM_DPICHANGED:
        {
            RECT* rect = (RECT*) lParam;
            SetWindowPos(window->win32.handle,
                         HWND_TOP,
                         rect->left,
                         rect->top,
                         rect->right - rect->left,
                         rect->bottom - rect->top,
                         SWP_NOACTIVATE | SWP_NOZORDER);
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
                paths[i] = _glfwCreateUTF8FromWideStringWin32(buffer);

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

    return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

// Creates the GLFW window and rendering context
//
static int createWindow(_GLFWwindow* window, const _GLFWwndconfig* wndconfig)
{
    int xpos, ypos, fullWidth, fullHeight;
    WCHAR* wideTitle;
    DWORD style = getWindowStyle(window);
    DWORD exStyle = getWindowExStyle(window);

    if (window->monitor)
    {
        GLFWvidmode mode;

        // NOTE: This window placement is temporary and approximate, as the
        //       correct position and size cannot be known until the monitor
        //       video mode has been set
        _glfwPlatformGetMonitorPos(window->monitor, &xpos, &ypos);
        _glfwPlatformGetVideoMode(window->monitor, &mode);
        fullWidth  = mode.width;
        fullHeight = mode.height;
    }
    else
    {
        xpos = CW_USEDEFAULT;
        ypos = CW_USEDEFAULT;

        if (wndconfig->maximized)
            style |= WS_MAXIMIZE;

        getFullWindowSize(style, exStyle,
                          wndconfig->width, wndconfig->height,
                          &fullWidth, &fullHeight);
    }

    wideTitle = _glfwCreateWideStringFromUTF8Win32(wndconfig->title);
    if (!wideTitle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to convert window title to UTF-16");
        return GLFW_FALSE;
    }

    window->win32.handle = CreateWindowExW(exStyle,
                                           _GLFW_WNDCLASSNAME,
                                           wideTitle,
                                           style,
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
        return GLFW_FALSE;
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

    DragAcceptFiles(window->win32.handle, TRUE);

    return GLFW_TRUE;
}

// Destroys the GLFW window and rendering context
//
static void destroyWindow(_GLFWwindow* window)
{
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
GLFWbool _glfwRegisterWindowClassWin32(void)
{
    WNDCLASSEXW wc;

    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize        = sizeof(wc);
    wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wc.lpfnWndProc   = (WNDPROC) windowProc;
    wc.cbWndExtra    = sizeof(void*) + sizeof(int); // Make room for one pointer
    wc.hInstance     = GetModuleHandleW(NULL);
    wc.hCursor       = LoadCursorW(NULL, IDC_ARROW);
    wc.lpszClassName = _GLFW_WNDCLASSNAME;

    // Load user-provided icon if available
    wc.hIcon = LoadImageW(GetModuleHandleW(NULL),
                          L"GLFW_ICON", IMAGE_ICON,
                          0, 0, LR_DEFAULTSIZE | LR_SHARED);
    if (!wc.hIcon)
    {
        // No user-provided icon found, load default icon
        wc.hIcon = LoadImageW(NULL,
                              IDI_APPLICATION, IMAGE_ICON,
                              0, 0, LR_DEFAULTSIZE | LR_SHARED);
    }

    if (!RegisterClassExW(&wc))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to register window class");
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

// Unregisters the GLFW window class
//
void _glfwUnregisterWindowClassWin32(void)
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

    if (!createWindow(window, wndconfig))
        return GLFW_FALSE;

    if (ctxconfig->api != GLFW_NO_API)
    {
#if defined(_GLFW_WGL)
        if (!_glfwCreateContextWGL(window, ctxconfig, fbconfig))
            return GLFW_FALSE;

        status = _glfwAnalyzeContextWGL(window, ctxconfig, fbconfig);

        if (status == _GLFW_RECREATION_IMPOSSIBLE)
            return GLFW_FALSE;

        if (status == _GLFW_RECREATION_REQUIRED)
        {
            // Some window hints require us to re-create the context using WGL
            // extensions retrieved through the current context, as we cannot
            // check for WGL extensions or retrieve WGL entry points before we
            // have a current context (actually until we have implicitly loaded
            // the vendor ICD)

            // Yes, this is strange, and yes, this is the proper way on WGL

            // As Windows only allows you to set the pixel format once for
            // a window, we need to destroy the current window and create a new
            // one to be able to use the new pixel format

            // Technically, it may be possible to keep the old window around if
            // we're just creating an OpenGL 3.0+ context with the same pixel
            // format, but it's not worth the added code complexity

            // First we clear the current context (the one we just created)
            // This is usually done by glfwDestroyWindow, but as we're not doing
            // full GLFW window destruction, it's duplicated here
            _glfwPlatformMakeContextCurrent(NULL);

            // Next destroy the Win32 window and WGL context (without resetting
            // or destroying the GLFW window object)
            _glfwDestroyContextWGL(window);
            destroyWindow(window);

            // ...and then create them again, this time with better APIs
            if (!createWindow(window, wndconfig))
                return GLFW_FALSE;
            if (!_glfwCreateContextWGL(window, ctxconfig, fbconfig))
                return GLFW_FALSE;
        }
#elif defined(_GLFW_EGL)
        if (!_glfwCreateContextEGL(window, ctxconfig, fbconfig))
            return GLFW_FALSE;
#endif
    }

    if (window->monitor)
    {
        _glfwPlatformShowWindow(window);
        _glfwPlatformFocusWindow(window);
        if (!acquireMonitor(window))
            return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    if (window->monitor)
        releaseMonitor(window);

    if (window->context.api != GLFW_NO_API)
    {
#if defined(_GLFW_WGL)
        _glfwDestroyContextWGL(window);
#elif defined(_GLFW_EGL)
        _glfwDestroyContextEGL(window);
#endif
    }

    destroyWindow(window);

    if (window->win32.bigIcon)
        DestroyIcon(window->win32.bigIcon);

    if (window->win32.smallIcon)
        DestroyIcon(window->win32.smallIcon);
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char* title)
{
    WCHAR* wideTitle = _glfwCreateWideStringFromUTF8Win32(title);
    if (!wideTitle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to convert window title to UTF-16");
        return;
    }

    SetWindowTextW(window->win32.handle, wideTitle);
    free(wideTitle);
}

void _glfwPlatformSetWindowIcon(_GLFWwindow* window,
                                int count, const GLFWimage* images)
{
    HICON bigIcon = NULL, smallIcon = NULL;

    if (count)
    {
        const GLFWimage* bigImage = chooseImage(count, images,
                                                GetSystemMetrics(SM_CXICON),
                                                GetSystemMetrics(SM_CYICON));
        const GLFWimage* smallImage = chooseImage(count, images,
                                                  GetSystemMetrics(SM_CXSMICON),
                                                  GetSystemMetrics(SM_CYSMICON));

        bigIcon = createIcon(bigImage, 0, 0, GLFW_TRUE);
        smallIcon = createIcon(smallImage, 0, 0, GLFW_TRUE);
    }
    else
    {
        bigIcon = (HICON) GetClassLongPtrW(window->win32.handle, GCLP_HICON);
        smallIcon = (HICON) GetClassLongPtrW(window->win32.handle, GCLP_HICONSM);
    }

    SendMessage(window->win32.handle, WM_SETICON, ICON_BIG, (LPARAM) bigIcon);
    SendMessage(window->win32.handle, WM_SETICON, ICON_SMALL, (LPARAM) smallIcon);

    if (window->win32.bigIcon)
        DestroyIcon(window->win32.bigIcon);

    if (window->win32.smallIcon)
        DestroyIcon(window->win32.smallIcon);

    if (count)
    {
        window->win32.bigIcon = bigIcon;
        window->win32.smallIcon = smallIcon;
    }
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
    {
        if (window->monitor->window == window)
            acquireMonitor(window);
    }
    else
    {
        RECT rect = { 0, 0, width, height };
        AdjustWindowRectEx(&rect, getWindowStyle(window),
                           FALSE, getWindowExStyle(window));
        SetWindowPos(window->win32.handle, HWND_TOP,
                     0, 0, rect.right - rect.left, rect.bottom - rect.top,
                     SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOZORDER);
    }
}

void _glfwPlatformSetWindowSizeLimits(_GLFWwindow* window,
                                      int minwidth, int minheight,
                                      int maxwidth, int maxheight)
{
    RECT area;

    if ((minwidth == GLFW_DONT_CARE || minheight == GLFW_DONT_CARE) &&
        (maxwidth == GLFW_DONT_CARE || maxheight == GLFW_DONT_CARE))
    {
        return;
    }

    GetWindowRect(window->win32.handle, &area);
    MoveWindow(window->win32.handle,
               area.left, area.top,
               area.right - area.left,
               area.bottom - area.top, TRUE);
}

void _glfwPlatformSetWindowAspectRatio(_GLFWwindow* window, int numer, int denom)
{
    RECT area;

    if (numer == GLFW_DONT_CARE || denom == GLFW_DONT_CARE)
        return;

    GetWindowRect(window->win32.handle, &area);
    applyAspectRatio(window, WMSZ_BOTTOMRIGHT, &area);
    MoveWindow(window->win32.handle,
               area.left, area.top,
               area.right - area.left,
               area.bottom - area.top, TRUE);
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

void _glfwPlatformMaximizeWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_MAXIMIZE);
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_SHOW);
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    ShowWindow(window->win32.handle, SW_HIDE);
}

void _glfwPlatformFocusWindow(_GLFWwindow* window)
{
    BringWindowToTop(window->win32.handle);
    SetForegroundWindow(window->win32.handle);
    SetFocus(window->win32.handle);
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
            RECT rect = { xpos, ypos, xpos + width, ypos + height };
            AdjustWindowRectEx(&rect, getWindowStyle(window),
                               FALSE, getWindowExStyle(window));
            SetWindowPos(window->win32.handle, HWND_TOP,
                         rect.left, rect.top,
                         rect.right - rect.left, rect.bottom - rect.top,
                         SWP_NOCOPYBITS | SWP_NOACTIVATE | SWP_NOZORDER);
        }

        return;
    }

    if (window->monitor)
        releaseMonitor(window);

    _glfwInputWindowMonitorChange(window, monitor);

    if (monitor)
    {
        GLFWvidmode mode;
        DWORD style = GetWindowLongPtrW(window->win32.handle, GWL_STYLE);
        UINT flags = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOCOPYBITS;

        if (window->decorated)
        {
            style &= ~WS_OVERLAPPEDWINDOW;
            style |= getWindowStyle(window);
            SetWindowLongPtrW(window->win32.handle, GWL_STYLE, style);

            flags |= SWP_FRAMECHANGED;
        }

        _glfwPlatformGetVideoMode(monitor, &mode);
        _glfwPlatformGetMonitorPos(monitor, &xpos, &ypos);

        SetWindowPos(window->win32.handle, HWND_TOPMOST,
                     xpos, ypos, mode.width, mode.height,
                     flags);

        acquireMonitor(window);
    }
    else
    {
        HWND after;
        RECT rect = { xpos, ypos, xpos + width, ypos + height };
        DWORD style = GetWindowLongPtrW(window->win32.handle, GWL_STYLE);
        UINT flags = SWP_NOACTIVATE | SWP_NOCOPYBITS;

        if (window->decorated)
        {
            style &= ~WS_POPUP;
            style |= getWindowStyle(window);
            SetWindowLongPtrW(window->win32.handle, GWL_STYLE, style);

            flags |= SWP_FRAMECHANGED;
        }

        if (window->floating)
            after = HWND_TOPMOST;
        else
            after = HWND_NOTOPMOST;

        AdjustWindowRectEx(&rect, getWindowStyle(window),
                           FALSE, getWindowExStyle(window));
        SetWindowPos(window->win32.handle, after,
                     rect.left, rect.top,
                     rect.right - rect.left, rect.bottom - rect.top,
                     flags);
    }
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

int _glfwPlatformWindowMaximized(_GLFWwindow* window)
{
    return IsZoomed(window->win32.handle);
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

void _glfwPlatformWaitEventsTimeout(double timeout)
{
    MsgWaitForMultipleObjects(0, NULL, FALSE, (DWORD) (timeout * 1e3), QS_ALLEVENTS);

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

void _glfwPlatformSetCursorMode(_GLFWwindow* window, int mode)
{
    POINT pos;

    if (mode == GLFW_CURSOR_DISABLED)
        updateClipRect(window);
    else
        ClipCursor(NULL);

    if (!GetCursorPos(&pos))
        return;

    if (WindowFromPoint(pos) != window->win32.handle)
        return;

    if (mode == GLFW_CURSOR_NORMAL)
    {
        if (window->cursor)
            SetCursor(window->cursor->win32.handle);
        else
            SetCursor(LoadCursorW(NULL, IDC_ARROW));
    }
    else
        SetCursor(NULL);
}

const char* _glfwPlatformGetKeyName(int key, int scancode)
{
    WCHAR name[16];

    if (key != GLFW_KEY_UNKNOWN)
        scancode = _glfw.win32.nativeKeys[key];

    if (!_glfwIsPrintable(_glfw.win32.publicKeys[scancode]))
        return NULL;

    if (!GetKeyNameTextW(scancode << 16, name, sizeof(name) / sizeof(WCHAR)))
        return NULL;

    if (!WideCharToMultiByte(CP_UTF8, 0, name, -1,
                             _glfw.win32.keyName,
                             sizeof(_glfw.win32.keyName),
                             NULL, NULL))
    {
        return NULL;
    }

    return _glfw.win32.keyName;
}

int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    cursor->win32.handle = (HCURSOR) createIcon(image, xhot, yhot, GLFW_FALSE);
    if (!cursor->win32.handle)
        return GLFW_FALSE;

    return GLFW_TRUE;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    cursor->win32.handle =
        CopyCursor(LoadCursorW(NULL, translateCursorShape(shape)));
    if (!cursor->win32.handle)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to create standard cursor");
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

void _glfwPlatformDestroyCursor(_GLFWcursor* cursor)
{
    if (cursor->win32.handle)
        DestroyIcon((HICON) cursor->win32.handle);
}

void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor)
{
    RECT area;
    POINT pos;

    if (_glfw.cursorWindow != window)
        return;

    if (window->cursorMode != GLFW_CURSOR_NORMAL)
        return;

    if (!GetCursorPos(&pos))
        return;

    if (WindowFromPoint(pos) != window->win32.handle)
        return;

    GetClientRect(window->win32.handle, &area);
    ClientToScreen(window->win32.handle, (POINT*) &area.left);
    ClientToScreen(window->win32.handle, (POINT*) &area.right);

    if (!PtInRect(&area, pos))
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

    wideString = _glfwCreateWideStringFromUTF8Win32(string);
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

    if (!OpenClipboard(_glfw.win32.helperWindow))
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

    if (!OpenClipboard(_glfw.win32.helperWindow))
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
        _glfwCreateUTF8FromWideStringWin32(GlobalLock(stringHandle));

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

char** _glfwPlatformGetRequiredInstanceExtensions(unsigned int* count)
{
    char** extensions;

    *count = 0;

    if (!_glfw.vk.KHR_win32_surface)
        return NULL;

    extensions = calloc(2, sizeof(char*));
    extensions[0] = strdup("VK_KHR_surface");
    extensions[1] = strdup("VK_KHR_win32_surface");

    *count = 2;
    return extensions;
}

int _glfwPlatformGetPhysicalDevicePresentationSupport(VkInstance instance,
                                                      VkPhysicalDevice device,
                                                      unsigned int queuefamily)
{
    PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR vkGetPhysicalDeviceWin32PresentationSupportKHR =
        (PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR)
        vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR");
    if (!vkGetPhysicalDeviceWin32PresentationSupportKHR)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Win32: Vulkan instance missing VK_KHR_win32_surface extension");
        return GLFW_FALSE;
    }

    return vkGetPhysicalDeviceWin32PresentationSupportKHR(device, queuefamily);
}

VkResult _glfwPlatformCreateWindowSurface(VkInstance instance,
                                          _GLFWwindow* window,
                                          const VkAllocationCallbacks* allocator,
                                          VkSurfaceKHR* surface)
{
    VkResult err;
    VkWin32SurfaceCreateInfoKHR sci;
    PFN_vkCreateWin32SurfaceKHR vkCreateWin32SurfaceKHR;

    vkCreateWin32SurfaceKHR = (PFN_vkCreateWin32SurfaceKHR)
        vkGetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR");
    if (!vkCreateWin32SurfaceKHR)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Win32: Vulkan instance missing VK_KHR_win32_surface extension");
        return VK_ERROR_EXTENSION_NOT_PRESENT;
    }

    memset(&sci, 0, sizeof(sci));
    sci.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
    sci.hinstance = GetModuleHandle(NULL);
    sci.hwnd = window->win32.handle;

    err = vkCreateWin32SurfaceKHR(instance, &sci, allocator, surface);
    if (err)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to create Vulkan surface: %s",
                        _glfwGetVulkanResultString(err));
    }

    return err;
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

