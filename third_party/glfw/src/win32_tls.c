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

GLFWbool _glfwInitThreadLocalStorageWin32(void)
{
    _glfw.win32_tls.context = TlsAlloc();
    if (_glfw.win32_tls.context == TLS_OUT_OF_INDEXES)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Win32: Failed to allocate TLS index");
        return GLFW_FALSE;
    }

    _glfw.win32_tls.allocated = GLFW_TRUE;
    return GLFW_TRUE;
}

void _glfwTerminateThreadLocalStorageWin32(void)
{
    if (_glfw.win32_tls.allocated)
        TlsFree(_glfw.win32_tls.context);
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwPlatformSetCurrentContext(_GLFWwindow* context)
{
    TlsSetValue(_glfw.win32_tls.context, context);
}

_GLFWwindow* _glfwPlatformGetCurrentContext(void)
{
    return TlsGetValue(_glfw.win32_tls.context);
}

