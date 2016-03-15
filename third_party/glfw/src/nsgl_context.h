//========================================================================
// GLFW 3.1 OS X - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2009-2010 Camilla Berglund <elmindreda@elmindreda.org>
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

#ifndef _glfw3_nsgl_context_h_
#define _glfw3_nsgl_context_h_

#define _GLFW_PLATFORM_FBCONFIG
#define _GLFW_PLATFORM_CONTEXT_STATE            _GLFWcontextNSGL nsgl
#define _GLFW_PLATFORM_LIBRARY_CONTEXT_STATE    _GLFWlibraryNSGL nsgl


// NSGL-specific per-context data
//
typedef struct _GLFWcontextNSGL
{
    id           pixelFormat;
    id	         context;

} _GLFWcontextNSGL;


// NSGL-specific global data
//
typedef struct _GLFWlibraryNSGL
{
    // dlopen handle for OpenGL.framework (for glfwGetProcAddress)
    void*           framework;

} _GLFWlibraryNSGL;


int _glfwInitContextAPI(void);
void _glfwTerminateContextAPI(void);
int _glfwCreateContext(_GLFWwindow* window,
                       const _GLFWctxconfig* ctxconfig,
                       const _GLFWfbconfig* fbconfig);
void _glfwDestroyContext(_GLFWwindow* window);

#endif // _glfw3_nsgl_context_h_
