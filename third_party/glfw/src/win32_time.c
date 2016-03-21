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


// Return raw time
//
static unsigned __int64 getRawTime(void)
{
    if (_glfw.win32_time.hasPC)
    {
        unsigned __int64 time;
        QueryPerformanceCounter((LARGE_INTEGER*) &time);
        return time;
    }
    else
        return (unsigned __int64) _glfw_timeGetTime();
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialise timer
//
void _glfwInitTimer(void)
{
    unsigned __int64 frequency;

    if (QueryPerformanceFrequency((LARGE_INTEGER*) &frequency))
    {
        _glfw.win32_time.hasPC = GL_TRUE;
        _glfw.win32_time.resolution = 1.0 / (double) frequency;
    }
    else
    {
        _glfw.win32_time.hasPC = GL_FALSE;
        _glfw.win32_time.resolution = 0.001; // winmm resolution is 1 ms
    }

    _glfw.win32_time.base = getRawTime();
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

double _glfwPlatformGetTime(void)
{
    return (double) (getRawTime() - _glfw.win32_time.base) *
        _glfw.win32_time.resolution;
}

void _glfwPlatformSetTime(double time)
{
    _glfw.win32_time.base = getRawTime() -
        (unsigned __int64) (time / _glfw.win32_time.resolution);
}

