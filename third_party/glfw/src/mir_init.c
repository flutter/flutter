//========================================================================
// GLFW 3.1 Mir - www.glfw.org
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

#include <stdlib.h>
#include <string.h>


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

        return GL_FALSE;
    }

    _glfw.mir.display =
        mir_connection_get_egl_native_display(_glfw.mir.connection);

    if (!_glfwInitContextAPI())
        return GL_FALSE;

    // Need the default conf for when we set a NULL cursor
    _glfw.mir.default_conf = mir_cursor_configuration_from_name(mir_arrow_cursor_name);

    _glfwInitTimer();
    _glfwInitJoysticks();

    _glfw.mir.event_queue = calloc(1, sizeof(EventQueue));
    _glfwInitEventQueue(_glfw.mir.event_queue);

    error = pthread_mutex_init(&_glfw.mir.event_mutex, NULL);
    if (error)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Failed to create event mutex: %s",
                        strerror(error));
        return GL_FALSE;
    }

    return GL_TRUE;
}

void _glfwPlatformTerminate(void)
{
    _glfwTerminateContextAPI();
    _glfwTerminateJoysticks();

    _glfwDeleteEventQueue(_glfw.mir.event_queue);

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

