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

#include "internal.h"

#include <linux/input.h>
#include <stdlib.h>
#include <string.h>


// Create key code translation tables
//
static void createKeyTables(void)
{
    memset(_glfw.mir.publicKeys, -1, sizeof(_glfw.mir.publicKeys));

    _glfw.mir.publicKeys[KEY_GRAVE]      = GLFW_KEY_GRAVE_ACCENT;
    _glfw.mir.publicKeys[KEY_1]          = GLFW_KEY_1;
    _glfw.mir.publicKeys[KEY_2]          = GLFW_KEY_2;
    _glfw.mir.publicKeys[KEY_3]          = GLFW_KEY_3;
    _glfw.mir.publicKeys[KEY_4]          = GLFW_KEY_4;
    _glfw.mir.publicKeys[KEY_5]          = GLFW_KEY_5;
    _glfw.mir.publicKeys[KEY_6]          = GLFW_KEY_6;
    _glfw.mir.publicKeys[KEY_7]          = GLFW_KEY_7;
    _glfw.mir.publicKeys[KEY_8]          = GLFW_KEY_8;
    _glfw.mir.publicKeys[KEY_9]          = GLFW_KEY_9;
    _glfw.mir.publicKeys[KEY_0]          = GLFW_KEY_0;
    _glfw.mir.publicKeys[KEY_MINUS]      = GLFW_KEY_MINUS;
    _glfw.mir.publicKeys[KEY_EQUAL]      = GLFW_KEY_EQUAL;
    _glfw.mir.publicKeys[KEY_Q]          = GLFW_KEY_Q;
    _glfw.mir.publicKeys[KEY_W]          = GLFW_KEY_W;
    _glfw.mir.publicKeys[KEY_E]          = GLFW_KEY_E;
    _glfw.mir.publicKeys[KEY_R]          = GLFW_KEY_R;
    _glfw.mir.publicKeys[KEY_T]          = GLFW_KEY_T;
    _glfw.mir.publicKeys[KEY_Y]          = GLFW_KEY_Y;
    _glfw.mir.publicKeys[KEY_U]          = GLFW_KEY_U;
    _glfw.mir.publicKeys[KEY_I]          = GLFW_KEY_I;
    _glfw.mir.publicKeys[KEY_O]          = GLFW_KEY_O;
    _glfw.mir.publicKeys[KEY_P]          = GLFW_KEY_P;
    _glfw.mir.publicKeys[KEY_LEFTBRACE]  = GLFW_KEY_LEFT_BRACKET;
    _glfw.mir.publicKeys[KEY_RIGHTBRACE] = GLFW_KEY_RIGHT_BRACKET;
    _glfw.mir.publicKeys[KEY_A]          = GLFW_KEY_A;
    _glfw.mir.publicKeys[KEY_S]          = GLFW_KEY_S;
    _glfw.mir.publicKeys[KEY_D]          = GLFW_KEY_D;
    _glfw.mir.publicKeys[KEY_F]          = GLFW_KEY_F;
    _glfw.mir.publicKeys[KEY_G]          = GLFW_KEY_G;
    _glfw.mir.publicKeys[KEY_H]          = GLFW_KEY_H;
    _glfw.mir.publicKeys[KEY_J]          = GLFW_KEY_J;
    _glfw.mir.publicKeys[KEY_K]          = GLFW_KEY_K;
    _glfw.mir.publicKeys[KEY_L]          = GLFW_KEY_L;
    _glfw.mir.publicKeys[KEY_SEMICOLON]  = GLFW_KEY_SEMICOLON;
    _glfw.mir.publicKeys[KEY_APOSTROPHE] = GLFW_KEY_APOSTROPHE;
    _glfw.mir.publicKeys[KEY_Z]          = GLFW_KEY_Z;
    _glfw.mir.publicKeys[KEY_X]          = GLFW_KEY_X;
    _glfw.mir.publicKeys[KEY_C]          = GLFW_KEY_C;
    _glfw.mir.publicKeys[KEY_V]          = GLFW_KEY_V;
    _glfw.mir.publicKeys[KEY_B]          = GLFW_KEY_B;
    _glfw.mir.publicKeys[KEY_N]          = GLFW_KEY_N;
    _glfw.mir.publicKeys[KEY_M]          = GLFW_KEY_M;
    _glfw.mir.publicKeys[KEY_COMMA]      = GLFW_KEY_COMMA;
    _glfw.mir.publicKeys[KEY_DOT]        = GLFW_KEY_PERIOD;
    _glfw.mir.publicKeys[KEY_SLASH]      = GLFW_KEY_SLASH;
    _glfw.mir.publicKeys[KEY_BACKSLASH]  = GLFW_KEY_BACKSLASH;
    _glfw.mir.publicKeys[KEY_ESC]        = GLFW_KEY_ESCAPE;
    _glfw.mir.publicKeys[KEY_TAB]        = GLFW_KEY_TAB;
    _glfw.mir.publicKeys[KEY_LEFTSHIFT]  = GLFW_KEY_LEFT_SHIFT;
    _glfw.mir.publicKeys[KEY_RIGHTSHIFT] = GLFW_KEY_RIGHT_SHIFT;
    _glfw.mir.publicKeys[KEY_LEFTCTRL]   = GLFW_KEY_LEFT_CONTROL;
    _glfw.mir.publicKeys[KEY_RIGHTCTRL]  = GLFW_KEY_RIGHT_CONTROL;
    _glfw.mir.publicKeys[KEY_LEFTALT]    = GLFW_KEY_LEFT_ALT;
    _glfw.mir.publicKeys[KEY_RIGHTALT]   = GLFW_KEY_RIGHT_ALT;
    _glfw.mir.publicKeys[KEY_LEFTMETA]   = GLFW_KEY_LEFT_SUPER;
    _glfw.mir.publicKeys[KEY_RIGHTMETA]  = GLFW_KEY_RIGHT_SUPER;
    _glfw.mir.publicKeys[KEY_MENU]       = GLFW_KEY_MENU;
    _glfw.mir.publicKeys[KEY_NUMLOCK]    = GLFW_KEY_NUM_LOCK;
    _glfw.mir.publicKeys[KEY_CAPSLOCK]   = GLFW_KEY_CAPS_LOCK;
    _glfw.mir.publicKeys[KEY_PRINT]      = GLFW_KEY_PRINT_SCREEN;
    _glfw.mir.publicKeys[KEY_SCROLLLOCK] = GLFW_KEY_SCROLL_LOCK;
    _glfw.mir.publicKeys[KEY_PAUSE]      = GLFW_KEY_PAUSE;
    _glfw.mir.publicKeys[KEY_DELETE]     = GLFW_KEY_DELETE;
    _glfw.mir.publicKeys[KEY_BACKSPACE]  = GLFW_KEY_BACKSPACE;
    _glfw.mir.publicKeys[KEY_ENTER]      = GLFW_KEY_ENTER;
    _glfw.mir.publicKeys[KEY_HOME]       = GLFW_KEY_HOME;
    _glfw.mir.publicKeys[KEY_END]        = GLFW_KEY_END;
    _glfw.mir.publicKeys[KEY_PAGEUP]     = GLFW_KEY_PAGE_UP;
    _glfw.mir.publicKeys[KEY_PAGEDOWN]   = GLFW_KEY_PAGE_DOWN;
    _glfw.mir.publicKeys[KEY_INSERT]     = GLFW_KEY_INSERT;
    _glfw.mir.publicKeys[KEY_LEFT]       = GLFW_KEY_LEFT;
    _glfw.mir.publicKeys[KEY_RIGHT]      = GLFW_KEY_RIGHT;
    _glfw.mir.publicKeys[KEY_DOWN]       = GLFW_KEY_DOWN;
    _glfw.mir.publicKeys[KEY_UP]         = GLFW_KEY_UP;
    _glfw.mir.publicKeys[KEY_F1]         = GLFW_KEY_F1;
    _glfw.mir.publicKeys[KEY_F2]         = GLFW_KEY_F2;
    _glfw.mir.publicKeys[KEY_F3]         = GLFW_KEY_F3;
    _glfw.mir.publicKeys[KEY_F4]         = GLFW_KEY_F4;
    _glfw.mir.publicKeys[KEY_F5]         = GLFW_KEY_F5;
    _glfw.mir.publicKeys[KEY_F6]         = GLFW_KEY_F6;
    _glfw.mir.publicKeys[KEY_F7]         = GLFW_KEY_F7;
    _glfw.mir.publicKeys[KEY_F8]         = GLFW_KEY_F8;
    _glfw.mir.publicKeys[KEY_F9]         = GLFW_KEY_F9;
    _glfw.mir.publicKeys[KEY_F10]        = GLFW_KEY_F10;
    _glfw.mir.publicKeys[KEY_F11]        = GLFW_KEY_F11;
    _glfw.mir.publicKeys[KEY_F12]        = GLFW_KEY_F12;
    _glfw.mir.publicKeys[KEY_F13]        = GLFW_KEY_F13;
    _glfw.mir.publicKeys[KEY_F14]        = GLFW_KEY_F14;
    _glfw.mir.publicKeys[KEY_F15]        = GLFW_KEY_F15;
    _glfw.mir.publicKeys[KEY_F16]        = GLFW_KEY_F16;
    _glfw.mir.publicKeys[KEY_F17]        = GLFW_KEY_F17;
    _glfw.mir.publicKeys[KEY_F18]        = GLFW_KEY_F18;
    _glfw.mir.publicKeys[KEY_F19]        = GLFW_KEY_F19;
    _glfw.mir.publicKeys[KEY_F20]        = GLFW_KEY_F20;
    _glfw.mir.publicKeys[KEY_F21]        = GLFW_KEY_F21;
    _glfw.mir.publicKeys[KEY_F22]        = GLFW_KEY_F22;
    _glfw.mir.publicKeys[KEY_F23]        = GLFW_KEY_F23;
    _glfw.mir.publicKeys[KEY_F24]        = GLFW_KEY_F24;
    _glfw.mir.publicKeys[KEY_KPSLASH]    = GLFW_KEY_KP_DIVIDE;
    _glfw.mir.publicKeys[KEY_KPDOT]      = GLFW_KEY_KP_MULTIPLY;
    _glfw.mir.publicKeys[KEY_KPMINUS]    = GLFW_KEY_KP_SUBTRACT;
    _glfw.mir.publicKeys[KEY_KPPLUS]     = GLFW_KEY_KP_ADD;
    _glfw.mir.publicKeys[KEY_KP0]        = GLFW_KEY_KP_0;
    _glfw.mir.publicKeys[KEY_KP1]        = GLFW_KEY_KP_1;
    _glfw.mir.publicKeys[KEY_KP2]        = GLFW_KEY_KP_2;
    _glfw.mir.publicKeys[KEY_KP3]        = GLFW_KEY_KP_3;
    _glfw.mir.publicKeys[KEY_KP4]        = GLFW_KEY_KP_4;
    _glfw.mir.publicKeys[KEY_KP5]        = GLFW_KEY_KP_5;
    _glfw.mir.publicKeys[KEY_KP6]        = GLFW_KEY_KP_6;
    _glfw.mir.publicKeys[KEY_KP7]        = GLFW_KEY_KP_7;
    _glfw.mir.publicKeys[KEY_KP8]        = GLFW_KEY_KP_8;
    _glfw.mir.publicKeys[KEY_KP9]        = GLFW_KEY_KP_9;
    _glfw.mir.publicKeys[KEY_KPCOMMA]    = GLFW_KEY_KP_DECIMAL;
    _glfw.mir.publicKeys[KEY_KPEQUAL]    = GLFW_KEY_KP_EQUAL;
    _glfw.mir.publicKeys[KEY_KPENTER]    = GLFW_KEY_KP_ENTER;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformInit(void)
{
    int error;

    _glfw.mir.connection = mir_connect_sync(NULL, __PRETTY_FUNCTION__);

    if (!mir_connection_is_valid(_glfw.mir.connection))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Unable to connect to server: %s",
                        mir_connection_get_error_message(_glfw.mir.connection));

        return GLFW_FALSE;
    }

    _glfw.mir.display =
        mir_connection_get_egl_native_display(_glfw.mir.connection);

    createKeyTables();

    if (!_glfwInitThreadLocalStoragePOSIX())
        return GLFW_FALSE;

    if (!_glfwInitEGL())
        return GLFW_FALSE;

    if (!_glfwInitJoysticksLinux())
        return GLFW_FALSE;

    _glfwInitTimerPOSIX();

    // Need the default conf for when we set a NULL cursor
    _glfw.mir.default_conf = mir_cursor_configuration_from_name(mir_arrow_cursor_name);

    _glfw.mir.event_queue = calloc(1, sizeof(EventQueue));
    _glfwInitEventQueueMir(_glfw.mir.event_queue);

    error = pthread_mutex_init(&_glfw.mir.event_mutex, NULL);
    if (error)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Failed to create event mutex: %s",
                        strerror(error));
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

void _glfwPlatformTerminate(void)
{
    _glfwTerminateEGL();
    _glfwTerminateJoysticksLinux();
    _glfwTerminateThreadLocalStoragePOSIX();

    _glfwDeleteEventQueueMir(_glfw.mir.event_queue);

    pthread_mutex_destroy(&_glfw.mir.event_mutex);

    mir_connection_release(_glfw.mir.connection);
}

const char* _glfwPlatformGetVersionString(void)
{
    return _GLFW_VERSION_NUMBER " Mir EGL"
#if defined(_POSIX_TIMERS) && defined(_POSIX_MONOTONIC_CLOCK)
        " clock_gettime"
#else
        " gettimeofday"
#endif
#if defined(__linux__)
        " /dev/js"
#endif
#if defined(_GLFW_BUILD_DLL)
        " shared"
#endif
        ;
}

