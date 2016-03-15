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

#ifndef _glfw3_win32_platform_h_
#define _glfw3_win32_platform_h_

// We don't need all the fancy stuff
#ifndef NOMINMAX
 #define NOMINMAX
#endif

#ifndef VC_EXTRALEAN
 #define VC_EXTRALEAN
#endif

#ifndef WIN32_LEAN_AND_MEAN
 #define WIN32_LEAN_AND_MEAN
#endif

// This is a workaround for the fact that glfw3.h needs to export APIENTRY (for
// example to allow applications to correctly declare a GL_ARB_debug_output
// callback) but windows.h assumes no one will define APIENTRY before it does
#undef APIENTRY

// GLFW on Windows is Unicode only and does not work in MBCS mode
#ifndef UNICODE
 #define UNICODE
#endif

// GLFW requires Windows XP or later
#if WINVER < 0x0501
 #undef WINVER
 #define WINVER 0x0501
#endif
#if _WIN32_WINNT < 0x0501
 #undef _WIN32_WINNT
 #define _WIN32_WINNT 0x0501
#endif

#include <windows.h>
#include <mmsystem.h>
#include <dbt.h>

#if defined(_MSC_VER)
 #include <malloc.h>
 #define strdup _strdup
#endif

// HACK: Define macros that some older windows.h variants don't
#ifndef WM_MOUSEHWHEEL
 #define WM_MOUSEHWHEEL 0x020E
#endif
#ifndef WM_DWMCOMPOSITIONCHANGED
 #define WM_DWMCOMPOSITIONCHANGED 0x031E
#endif
#ifndef WM_COPYGLOBALDATA
 #define WM_COPYGLOBALDATA 0x0049
#endif
#ifndef WM_UNICHAR
 #define WM_UNICHAR 0x0109
#endif
#ifndef UNICODE_NOCHAR
 #define UNICODE_NOCHAR 0xFFFF
#endif

#if WINVER < 0x0601
typedef struct tagCHANGEFILTERSTRUCT
{
    DWORD cbSize;
    DWORD ExtStatus;

} CHANGEFILTERSTRUCT, *PCHANGEFILTERSTRUCT;
#ifndef MSGFLT_ALLOW
 #define MSGFLT_ALLOW 1
#endif
#endif /*Windows 7*/

// winmm.dll function pointer typedefs
typedef MMRESULT (WINAPI * JOYGETDEVCAPS_T)(UINT,LPJOYCAPS,UINT);
typedef MMRESULT (WINAPI * JOYGETPOS_T)(UINT,LPJOYINFO);
typedef MMRESULT (WINAPI * JOYGETPOSEX_T)(UINT,LPJOYINFOEX);
typedef DWORD (WINAPI * TIMEGETTIME_T)(void);
#define _glfw_joyGetDevCaps _glfw.win32.winmm.joyGetDevCaps
#define _glfw_joyGetPos _glfw.win32.winmm.joyGetPos
#define _glfw_joyGetPosEx _glfw.win32.winmm.joyGetPosEx
#define _glfw_timeGetTime _glfw.win32.winmm.timeGetTime

// user32.dll function pointer typedefs
typedef BOOL (WINAPI * SETPROCESSDPIAWARE_T)(void);
typedef BOOL (WINAPI * CHANGEWINDOWMESSAGEFILTEREX_T)(HWND,UINT,DWORD,PCHANGEFILTERSTRUCT);
#define _glfw_SetProcessDPIAware _glfw.win32.user32.SetProcessDPIAware
#define _glfw_ChangeWindowMessageFilterEx _glfw.win32.user32.ChangeWindowMessageFilterEx

// dwmapi.dll function pointer typedefs
typedef HRESULT (WINAPI * DWMISCOMPOSITIONENABLED_T)(BOOL*);
typedef HRESULT (WINAPI * DWMFLUSH_T)(VOID);
#define _glfw_DwmIsCompositionEnabled _glfw.win32.dwmapi.DwmIsCompositionEnabled
#define _glfw_DwmFlush _glfw.win32.dwmapi.DwmFlush

#define _GLFW_RECREATION_NOT_NEEDED 0
#define _GLFW_RECREATION_REQUIRED   1
#define _GLFW_RECREATION_IMPOSSIBLE 2

#include "win32_tls.h"
#include "winmm_joystick.h"

#if defined(_GLFW_WGL)
 #include "wgl_context.h"
#elif defined(_GLFW_EGL)
 #define _GLFW_EGL_NATIVE_WINDOW  window->win32.handle
 #define _GLFW_EGL_NATIVE_DISPLAY EGL_DEFAULT_DISPLAY
 #include "egl_context.h"
#else
 #error "No supported context creation API selected"
#endif

#define _GLFW_PLATFORM_WINDOW_STATE         _GLFWwindowWin32  win32
#define _GLFW_PLATFORM_LIBRARY_WINDOW_STATE _GLFWlibraryWin32 win32
#define _GLFW_PLATFORM_LIBRARY_TIME_STATE   _GLFWtimeWin32    win32_time
#define _GLFW_PLATFORM_MONITOR_STATE        _GLFWmonitorWin32 win32
#define _GLFW_PLATFORM_CURSOR_STATE         _GLFWcursorWin32  win32


// Win32-specific per-window data
//
typedef struct _GLFWwindowWin32
{
    HWND                handle;

    GLboolean           cursorTracked;
    GLboolean           iconified;

    // The last received cursor position, regardless of source
    int                 cursorPosX, cursorPosY;

} _GLFWwindowWin32;


// Win32-specific global data
//
typedef struct _GLFWlibraryWin32
{
    DWORD               foregroundLockTimeout;
    char*               clipboardString;
    short int           publicKeys[512];

    // winmm.dll
    struct {
        HINSTANCE       instance;
        JOYGETDEVCAPS_T joyGetDevCaps;
        JOYGETPOS_T     joyGetPos;
        JOYGETPOSEX_T   joyGetPosEx;
        TIMEGETTIME_T   timeGetTime;
    } winmm;

    // user32.dll
    struct {
        HINSTANCE       instance;
        SETPROCESSDPIAWARE_T SetProcessDPIAware;
        CHANGEWINDOWMESSAGEFILTEREX_T ChangeWindowMessageFilterEx;
    } user32;

    // dwmapi.dll
    struct {
        HINSTANCE       instance;
        DWMISCOMPOSITIONENABLED_T DwmIsCompositionEnabled;
        DWMFLUSH_T      DwmFlush;
    } dwmapi;

} _GLFWlibraryWin32;


// Win32-specific per-monitor data
//
typedef struct _GLFWmonitorWin32
{
    // This size matches the static size of DISPLAY_DEVICE.DeviceName
    WCHAR               adapterName[32];
    WCHAR               displayName[32];
    char                publicAdapterName[64];
    char                publicDisplayName[64];
    GLboolean           modesPruned;
    GLboolean           modeChanged;

} _GLFWmonitorWin32;


// Win32-specific per-cursor data
//
typedef struct _GLFWcursorWin32
{
    HCURSOR handle;

} _GLFWcursorWin32;


// Win32-specific global timer data
//
typedef struct _GLFWtimeWin32
{
    GLboolean           hasPC;
    double              resolution;
    unsigned __int64    base;

} _GLFWtimeWin32;


GLboolean _glfwRegisterWindowClass(void);
void _glfwUnregisterWindowClass(void);

BOOL _glfwIsCompositionEnabled(void);

WCHAR* _glfwCreateWideStringFromUTF8(const char* source);
char* _glfwCreateUTF8FromWideString(const WCHAR* source);

void _glfwInitTimer(void);

GLboolean _glfwSetVideoMode(_GLFWmonitor* monitor, const GLFWvidmode* desired);
void _glfwRestoreVideoMode(_GLFWmonitor* monitor);

#endif // _glfw3_win32_platform_h_
