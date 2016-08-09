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


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialise timer
//
void _glfwInitTimerWin32(void)
{
    GLFWuint64 frequency;

    if (QueryPerformanceFrequency((LARGE_INTEGER*) &frequency))
    {
        _glfw.win32_time.hasPC = GLFW_TRUE;
        _glfw.win32_time.frequency = frequency;
    }
    else
    {
        _glfw.win32_time.hasPC = GLFW_FALSE;
        _glfw.win32_time.frequency = 1000;
    }
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

GLFWuint64 _glfwPlatformGetTimerValue(void)
{
    if (_glfw.win32_time.hasPC)
    {
        GLFWuint64 value;
        QueryPerformanceCounter((LARGE_INTEGER*) &value);
        return value;
    }
    else
        return (GLFWuint64) _glfw_timeGetTime();
}

GLFWuint64 _glfwPlatformGetTimerFrequency(void)
{
    return _glfw.win32_time.frequency;
}

