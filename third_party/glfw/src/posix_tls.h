//========================================================================
// GLFW 3.2 POSIX - www.glfw.org
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

#ifndef _glfw3_posix_tls_h_
#define _glfw3_posix_tls_h_

#include <pthread.h>

#define _GLFW_PLATFORM_LIBRARY_TLS_STATE _GLFWtlsPOSIX posix_tls


// POSIX-specific global TLS data
//
typedef struct _GLFWtlsPOSIX
{
    GLFWbool        allocated;
    pthread_key_t   context;

} _GLFWtlsPOSIX;


GLFWbool _glfwInitThreadLocalStoragePOSIX(void);
void _glfwTerminateThreadLocalStoragePOSIX(void);

#endif // _glfw3_posix_tls_h_
