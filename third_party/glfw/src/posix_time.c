//========================================================================
// GLFW 3.1 POSIX - www.glfw.org
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

#include <sys/time.h>
#include <time.h>

// Return raw time
//
static uint64_t getRawTime(void)
{
#if defined(CLOCK_MONOTONIC)
    if (_glfw.posix_time.monotonic)
    {
        struct timespec ts;

        clock_gettime(CLOCK_MONOTONIC, &ts);
        return (uint64_t) ts.tv_sec * (uint64_t) 1000000000 + (uint64_t) ts.tv_nsec;
    }
    else
#endif
    {
        struct timeval tv;

        gettimeofday(&tv, NULL);
        return (uint64_t) tv.tv_sec * (uint64_t) 1000000 + (uint64_t) tv.tv_usec;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialise timer
//
void _glfwInitTimer(void)
{
#if defined(CLOCK_MONOTONIC)
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0)
    {
        _glfw.posix_time.monotonic = GL_TRUE;
        _glfw.posix_time.resolution = 1e-9;
    }
    else
#endif
    {
        _glfw.posix_time.resolution = 1e-6;
    }

    _glfw.posix_time.base = getRawTime();
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

double _glfwPlatformGetTime(void)
{
    return (double) (getRawTime() - _glfw.posix_time.base) *
        _glfw.posix_time.resolution;
}

void _glfwPlatformSetTime(double time)
{
    _glfw.posix_time.base = getRawTime() -
        (uint64_t) (time / _glfw.posix_time.resolution);
}

