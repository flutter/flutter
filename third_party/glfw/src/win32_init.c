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

#include <stdlib.h>
#include <malloc.h>


#if defined(_GLFW_USE_HYBRID_HPG) || defined(_GLFW_USE_OPTIMUS_HPG)

// Applications exporting this symbol with this value will be automatically
// directed to the high-performance GPU on Nvidia Optimus systems with
// up-to-date drivers
//
__declspec(dllexport) DWORD NvOptimusEnablement = 1;

// Applications exporting this symbol with this value will be automatically
// directed to the high-performance GPU on AMD PowerXpress systems with
// up-to-date drivers
//
__declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;

#endif // _GLFW_USE_HYBRID_HPG

#if defined(_GLFW_BUILD_DLL)

// GLFW DLL entry point
//
BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved)
{
    return TRUE;
}

#endif // _GLFW_BUILD_DLL

// Load necessary libraries (DLLs)
//
static GLFWbool loadLibraries(void)
{
    _glfw.win32.winmm.instance = LoadLibraryA("winmm.dll");
    if (!_glfw.win32.winmm.instance)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to load winmm.dll");
        return GLFW_FALSE;
    }

    _glfw.win32.winmm.joyGetDevCaps = (JOYGETDEVCAPS_T)
        GetProcAddress(_glfw.win32.winmm.instance, "joyGetDevCapsW");
    _glfw.win32.winmm.joyGetPos = (JOYGETPOS_T)
        GetProcAddress(_glfw.win32.winmm.instance, "joyGetPos");
    _glfw.win32.winmm.joyGetPosEx = (JOYGETPOSEX_T)
        GetProcAddress(_glfw.win32.winmm.instance, "joyGetPosEx");
    _glfw.win32.winmm.timeGetTime = (TIMEGETTIME_T)
        GetProcAddress(_glfw.win32.winmm.instance, "timeGetTime");

    _glfw.win32.user32.instance = LoadLibraryA("user32.dll");
    if (!_glfw.win32.user32.instance)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Failed to load user32.dll");
        return GLFW_FALSE;
    }

    _glfw.win32.user32.SetProcessDPIAware = (SETPROCESSDPIAWARE_T)
        GetProcAddress(_glfw.win32.user32.instance, "SetProcessDPIAware");
    _glfw.win32.user32.ChangeWindowMessageFilterEx = (CHANGEWINDOWMESSAGEFILTEREX_T)
        GetProcAddress(_glfw.win32.user32.instance, "ChangeWindowMessageFilterEx");

    _glfw.win32.dwmapi.instance = LoadLibraryA("dwmapi.dll");
    if (_glfw.win32.dwmapi.instance)
    {
        _glfw.win32.dwmapi.DwmIsCompositionEnabled = (DWMISCOMPOSITIONENABLED_T)
            GetProcAddress(_glfw.win32.dwmapi.instance, "DwmIsCompositionEnabled");
        _glfw.win32.dwmapi.DwmFlush = (DWMFLUSH_T)
            GetProcAddress(_glfw.win32.dwmapi.instance, "DwmFlush");
    }

    _glfw.win32.shcore.instance = LoadLibraryA("shcore.dll");
    if (_glfw.win32.shcore.instance)
    {
        _glfw.win32.shcore.SetProcessDpiAwareness = (SETPROCESSDPIAWARENESS_T)
            GetProcAddress(_glfw.win32.shcore.instance, "SetProcessDpiAwareness");
    }

    return GLFW_TRUE;
}

// Unload used libraries (DLLs)
//
static void freeLibraries(void)
{
    if (_glfw.win32.winmm.instance)
        FreeLibrary(_glfw.win32.winmm.instance);

    if (_glfw.win32.user32.instance)
        FreeLibrary(_glfw.win32.user32.instance);

    if (_glfw.win32.dwmapi.instance)
        FreeLibrary(_glfw.win32.dwmapi.instance);

    if (_glfw.win32.shcore.instance)
        FreeLibrary(_glfw.win32.shcore.instance);
}

// Create key code translation tables
//
static void createKeyTables(void)
{
    int scancode;

    memset(_glfw.win32.publicKeys, -1, sizeof(_glfw.win32.publicKeys));
    memset(_glfw.win32.nativeKeys, -1, sizeof(_glfw.win32.nativeKeys));

    _glfw.win32.publicKeys[0x00B] = GLFW_KEY_0;
    _glfw.win32.publicKeys[0x002] = GLFW_KEY_1;
    _glfw.win32.publicKeys[0x003] = GLFW_KEY_2;
    _glfw.win32.publicKeys[0x004] = GLFW_KEY_3;
    _glfw.win32.publicKeys[0x005] = GLFW_KEY_4;
    _glfw.win32.publicKeys[0x006] = GLFW_KEY_5;
    _glfw.win32.publicKeys[0x007] = GLFW_KEY_6;
    _glfw.win32.publicKeys[0x008] = GLFW_KEY_7;
    _glfw.win32.publicKeys[0x009] = GLFW_KEY_8;
    _glfw.win32.publicKeys[0x00A] = GLFW_KEY_9;
    _glfw.win32.publicKeys[0x01E] = GLFW_KEY_A;
    _glfw.win32.publicKeys[0x030] = GLFW_KEY_B;
    _glfw.win32.publicKeys[0x02E] = GLFW_KEY_C;
    _glfw.win32.publicKeys[0x020] = GLFW_KEY_D;
    _glfw.win32.publicKeys[0x012] = GLFW_KEY_E;
    _glfw.win32.publicKeys[0x021] = GLFW_KEY_F;
    _glfw.win32.publicKeys[0x022] = GLFW_KEY_G;
    _glfw.win32.publicKeys[0x023] = GLFW_KEY_H;
    _glfw.win32.publicKeys[0x017] = GLFW_KEY_I;
    _glfw.win32.publicKeys[0x024] = GLFW_KEY_J;
    _glfw.win32.publicKeys[0x025] = GLFW_KEY_K;
    _glfw.win32.publicKeys[0x026] = GLFW_KEY_L;
    _glfw.win32.publicKeys[0x032] = GLFW_KEY_M;
    _glfw.win32.publicKeys[0x031] = GLFW_KEY_N;
    _glfw.win32.publicKeys[0x018] = GLFW_KEY_O;
    _glfw.win32.publicKeys[0x019] = GLFW_KEY_P;
    _glfw.win32.publicKeys[0x010] = GLFW_KEY_Q;
    _glfw.win32.publicKeys[0x013] = GLFW_KEY_R;
    _glfw.win32.publicKeys[0x01F] = GLFW_KEY_S;
    _glfw.win32.publicKeys[0x014] = GLFW_KEY_T;
    _glfw.win32.publicKeys[0x016] = GLFW_KEY_U;
    _glfw.win32.publicKeys[0x02F] = GLFW_KEY_V;
    _glfw.win32.publicKeys[0x011] = GLFW_KEY_W;
    _glfw.win32.publicKeys[0x02D] = GLFW_KEY_X;
    _glfw.win32.publicKeys[0x015] = GLFW_KEY_Y;
    _glfw.win32.publicKeys[0x02C] = GLFW_KEY_Z;

    _glfw.win32.publicKeys[0x028] = GLFW_KEY_APOSTROPHE;
    _glfw.win32.publicKeys[0x02B] = GLFW_KEY_BACKSLASH;
    _glfw.win32.publicKeys[0x033] = GLFW_KEY_COMMA;
    _glfw.win32.publicKeys[0x00D] = GLFW_KEY_EQUAL;
    _glfw.win32.publicKeys[0x029] = GLFW_KEY_GRAVE_ACCENT;
    _glfw.win32.publicKeys[0x01A] = GLFW_KEY_LEFT_BRACKET;
    _glfw.win32.publicKeys[0x00C] = GLFW_KEY_MINUS;
    _glfw.win32.publicKeys[0x034] = GLFW_KEY_PERIOD;
    _glfw.win32.publicKeys[0x01B] = GLFW_KEY_RIGHT_BRACKET;
    _glfw.win32.publicKeys[0x027] = GLFW_KEY_SEMICOLON;
    _glfw.win32.publicKeys[0x035] = GLFW_KEY_SLASH;
    _glfw.win32.publicKeys[0x056] = GLFW_KEY_WORLD_2;

    _glfw.win32.publicKeys[0x00E] = GLFW_KEY_BACKSPACE;
    _glfw.win32.publicKeys[0x153] = GLFW_KEY_DELETE;
    _glfw.win32.publicKeys[0x14F] = GLFW_KEY_END;
    _glfw.win32.publicKeys[0x01C] = GLFW_KEY_ENTER;
    _glfw.win32.publicKeys[0x001] = GLFW_KEY_ESCAPE;
    _glfw.win32.publicKeys[0x147] = GLFW_KEY_HOME;
    _glfw.win32.publicKeys[0x152] = GLFW_KEY_INSERT;
    _glfw.win32.publicKeys[0x15D] = GLFW_KEY_MENU;
    _glfw.win32.publicKeys[0x151] = GLFW_KEY_PAGE_DOWN;
    _glfw.win32.publicKeys[0x149] = GLFW_KEY_PAGE_UP;
    _glfw.win32.publicKeys[0x045] = GLFW_KEY_PAUSE;
    _glfw.win32.publicKeys[0x146] = GLFW_KEY_PAUSE;
    _glfw.win32.publicKeys[0x039] = GLFW_KEY_SPACE;
    _glfw.win32.publicKeys[0x00F] = GLFW_KEY_TAB;
    _glfw.win32.publicKeys[0x03A] = GLFW_KEY_CAPS_LOCK;
    _glfw.win32.publicKeys[0x145] = GLFW_KEY_NUM_LOCK;
    _glfw.win32.publicKeys[0x046] = GLFW_KEY_SCROLL_LOCK;
    _glfw.win32.publicKeys[0x03B] = GLFW_KEY_F1;
    _glfw.win32.publicKeys[0x03C] = GLFW_KEY_F2;
    _glfw.win32.publicKeys[0x03D] = GLFW_KEY_F3;
    _glfw.win32.publicKeys[0x03E] = GLFW_KEY_F4;
    _glfw.win32.publicKeys[0x03F] = GLFW_KEY_F5;
    _glfw.win32.publicKeys[0x040] = GLFW_KEY_F6;
    _glfw.win32.publicKeys[0x041] = GLFW_KEY_F7;
    _glfw.win32.publicKeys[0x042] = GLFW_KEY_F8;
    _glfw.win32.publicKeys[0x043] = GLFW_KEY_F9;
    _glfw.win32.publicKeys[0x044] = GLFW_KEY_F10;
    _glfw.win32.publicKeys[0x057] = GLFW_KEY_F11;
    _glfw.win32.publicKeys[0x058] = GLFW_KEY_F12;
    _glfw.win32.publicKeys[0x064] = GLFW_KEY_F13;
    _glfw.win32.publicKeys[0x065] = GLFW_KEY_F14;
    _glfw.win32.publicKeys[0x066] = GLFW_KEY_F15;
    _glfw.win32.publicKeys[0x067] = GLFW_KEY_F16;
    _glfw.win32.publicKeys[0x068] = GLFW_KEY_F17;
    _glfw.win32.publicKeys[0x069] = GLFW_KEY_F18;
    _glfw.win32.publicKeys[0x06A] = GLFW_KEY_F19;
    _glfw.win32.publicKeys[0x06B] = GLFW_KEY_F20;
    _glfw.win32.publicKeys[0x06C] = GLFW_KEY_F21;
    _glfw.win32.publicKeys[0x06D] = GLFW_KEY_F22;
    _glfw.win32.publicKeys[0x06E] = GLFW_KEY_F23;
    _glfw.win32.publicKeys[0x076] = GLFW_KEY_F24;
    _glfw.win32.publicKeys[0x038] = GLFW_KEY_LEFT_ALT;
    _glfw.win32.publicKeys[0x01D] = GLFW_KEY_LEFT_CONTROL;
    _glfw.win32.publicKeys[0x02A] = GLFW_KEY_LEFT_SHIFT;
    _glfw.win32.publicKeys[0x15B] = GLFW_KEY_LEFT_SUPER;
    _glfw.win32.publicKeys[0x137] = GLFW_KEY_PRINT_SCREEN;
    _glfw.win32.publicKeys[0x138] = GLFW_KEY_RIGHT_ALT;
    _glfw.win32.publicKeys[0x11D] = GLFW_KEY_RIGHT_CONTROL;
    _glfw.win32.publicKeys[0x036] = GLFW_KEY_RIGHT_SHIFT;
    _glfw.win32.publicKeys[0x15C] = GLFW_KEY_RIGHT_SUPER;
    _glfw.win32.publicKeys[0x150] = GLFW_KEY_DOWN;
    _glfw.win32.publicKeys[0x14B] = GLFW_KEY_LEFT;
    _glfw.win32.publicKeys[0x14D] = GLFW_KEY_RIGHT;
    _glfw.win32.publicKeys[0x148] = GLFW_KEY_UP;

    _glfw.win32.publicKeys[0x052] = GLFW_KEY_KP_0;
    _glfw.win32.publicKeys[0x04F] = GLFW_KEY_KP_1;
    _glfw.win32.publicKeys[0x050] = GLFW_KEY_KP_2;
    _glfw.win32.publicKeys[0x051] = GLFW_KEY_KP_3;
    _glfw.win32.publicKeys[0x04B] = GLFW_KEY_KP_4;
    _glfw.win32.publicKeys[0x04C] = GLFW_KEY_KP_5;
    _glfw.win32.publicKeys[0x04D] = GLFW_KEY_KP_6;
    _glfw.win32.publicKeys[0x047] = GLFW_KEY_KP_7;
    _glfw.win32.publicKeys[0x048] = GLFW_KEY_KP_8;
    _glfw.win32.publicKeys[0x049] = GLFW_KEY_KP_9;
    _glfw.win32.publicKeys[0x04E] = GLFW_KEY_KP_ADD;
    _glfw.win32.publicKeys[0x053] = GLFW_KEY_KP_DECIMAL;
    _glfw.win32.publicKeys[0x135] = GLFW_KEY_KP_DIVIDE;
    _glfw.win32.publicKeys[0x11C] = GLFW_KEY_KP_ENTER;
    _glfw.win32.publicKeys[0x037] = GLFW_KEY_KP_MULTIPLY;
    _glfw.win32.publicKeys[0x04A] = GLFW_KEY_KP_SUBTRACT;

    for (scancode = 0;  scancode < 512;  scancode++)
    {
        if (_glfw.win32.publicKeys[scancode] > 0)
            _glfw.win32.nativeKeys[_glfw.win32.publicKeys[scancode]] = scancode;
    }
}

// Creates a dummy window for behind-the-scenes work
//
static HWND createHelperWindow(void)
{
    HWND window = CreateWindowExW(WS_EX_OVERLAPPEDWINDOW,
                                  _GLFW_WNDCLASSNAME,
                                  L"GLFW helper window",
                                  WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
                                  0, 0, 1, 1,
                                  NULL, NULL,
                                  GetModuleHandleW(NULL),
                                  NULL);
    if (!window)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to create helper window");
        return NULL;
    }

    return window;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Returns a wide string version of the specified UTF-8 string
//
WCHAR* _glfwCreateWideStringFromUTF8Win32(const char* source)
{
    WCHAR* target;
    int length;

    length = MultiByteToWideChar(CP_UTF8, 0, source, -1, NULL, 0);
    if (!length)
        return NULL;

    target = calloc(length, sizeof(WCHAR));

    if (!MultiByteToWideChar(CP_UTF8, 0, source, -1, target, length))
    {
        free(target);
        return NULL;
    }

    return target;
}

// Returns a UTF-8 string version of the specified wide string
//
char* _glfwCreateUTF8FromWideStringWin32(const WCHAR* source)
{
    char* target;
    int length;

    length = WideCharToMultiByte(CP_UTF8, 0, source, -1, NULL, 0, NULL, NULL);
    if (!length)
        return NULL;

    target = calloc(length, sizeof(char));

    if (!WideCharToMultiByte(CP_UTF8, 0, source, -1, target, length, NULL, NULL))
    {
        free(target);
        return NULL;
    }

    return target;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformInit(void)
{
    if (!_glfwInitThreadLocalStorageWin32())
        return GLFW_FALSE;

    // To make SetForegroundWindow work as we want, we need to fiddle
    // with the FOREGROUNDLOCKTIMEOUT system setting (we do this as early
    // as possible in the hope of still being the foreground process)
    SystemParametersInfoW(SPI_GETFOREGROUNDLOCKTIMEOUT, 0,
                          &_glfw.win32.foregroundLockTimeout, 0);
    SystemParametersInfoW(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, UIntToPtr(0),
                          SPIF_SENDCHANGE);

    if (!loadLibraries())
        return GLFW_FALSE;

    createKeyTables();

    if (_glfw_SetProcessDpiAwareness)
        _glfw_SetProcessDpiAwareness(PROCESS_PER_MONITOR_DPI_AWARE);
    else if (_glfw_SetProcessDPIAware)
        _glfw_SetProcessDPIAware();

    if (!_glfwRegisterWindowClassWin32())
        return GLFW_FALSE;

    _glfw.win32.helperWindow = createHelperWindow();
    if (!_glfw.win32.helperWindow)
        return GLFW_FALSE;

    _glfwPlatformPollEvents();

#if defined(_GLFW_WGL)
    if (!_glfwInitWGL())
        return GLFW_FALSE;
#elif defined(_GLFW_EGL)
    if (!_glfwInitEGL())
        return GLFW_FALSE;
#endif

    _glfwInitTimerWin32();
    _glfwInitJoysticksWin32();

    return GLFW_TRUE;
}

void _glfwPlatformTerminate(void)
{
    if (_glfw.win32.helperWindow)
        DestroyWindow(_glfw.win32.helperWindow);

    _glfwUnregisterWindowClassWin32();

    // Restore previous foreground lock timeout system setting
    SystemParametersInfoW(SPI_SETFOREGROUNDLOCKTIMEOUT, 0,
                          UIntToPtr(_glfw.win32.foregroundLockTimeout),
                          SPIF_SENDCHANGE);

    free(_glfw.win32.clipboardString);

#if defined(_GLFW_WGL)
    _glfwTerminateWGL();
#elif defined(_GLFW_EGL)
    _glfwTerminateEGL();
#endif

    _glfwTerminateJoysticksWin32();
    _glfwTerminateThreadLocalStorageWin32();

    freeLibraries();
}

const char* _glfwPlatformGetVersionString(void)
{
    return _GLFW_VERSION_NUMBER " Win32"
#if defined(_GLFW_WGL)
        " WGL"
#elif defined(_GLFW_EGL)
        " EGL"
#endif
#if defined(__MINGW32__)
        " MinGW"
#elif defined(_MSC_VER)
        " VisualC"
#endif
#if defined(_GLFW_USE_HYBRID_HPG) || defined(_GLFW_USE_OPTIMUS_HPG)
        " hybrid-GPU"
#endif
#if defined(_GLFW_BUILD_DLL)
        " DLL"
#endif
        ;
}

