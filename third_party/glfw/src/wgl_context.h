//========================================================================
// GLFW 3.1 WGL - www.glfw.org
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

#ifndef _glfw3_wgl_context_h_
#define _glfw3_wgl_context_h_

// This path may need to be changed if you build GLFW using your own setup
// We ship and use our own copy of wglext.h since GLFW uses fairly new
// extensions and not all operating systems come with an up-to-date version
#include "../deps/GL/wglext.h"

// opengl32.dll function pointer typedefs
typedef HGLRC (WINAPI * WGLCREATECONTEXT_T)(HDC);
typedef BOOL (WINAPI * WGLDELETECONTEXT_T)(HGLRC);
typedef PROC (WINAPI * WGLGETPROCADDRESS_T)(LPCSTR);
typedef BOOL (WINAPI * WGLMAKECURRENT_T)(HDC,HGLRC);
typedef BOOL (WINAPI * WGLSHARELISTS_T)(HGLRC,HGLRC);
#define _glfw_wglCreateContext _glfw.wgl.opengl32.CreateContext
#define _glfw_wglDeleteContext _glfw.wgl.opengl32.DeleteContext
#define _glfw_wglGetProcAddress _glfw.wgl.opengl32.GetProcAddress
#define _glfw_wglMakeCurrent _glfw.wgl.opengl32.MakeCurrent
#define _glfw_wglShareLists _glfw.wgl.opengl32.ShareLists

#define _GLFW_PLATFORM_FBCONFIG                 int             wgl
#define _GLFW_PLATFORM_CONTEXT_STATE            _GLFWcontextWGL wgl
#define _GLFW_PLATFORM_LIBRARY_CONTEXT_STATE    _GLFWlibraryWGL wgl


// WGL-specific per-context data
//
typedef struct _GLFWcontextWGL
{
    HDC       dc;              // Private GDI device context
    HGLRC     context;         // Permanent rendering context
    int       interval;

    // WGL extensions (context specific)
    PFNWGLSWAPINTERVALEXTPROC           SwapIntervalEXT;
    PFNWGLGETPIXELFORMATATTRIBIVARBPROC GetPixelFormatAttribivARB;
    PFNWGLGETEXTENSIONSSTRINGEXTPROC    GetExtensionsStringEXT;
    PFNWGLGETEXTENSIONSSTRINGARBPROC    GetExtensionsStringARB;
    PFNWGLCREATECONTEXTATTRIBSARBPROC   CreateContextAttribsARB;
    GLboolean                           EXT_swap_control;
    GLboolean                           ARB_multisample;
    GLboolean                           ARB_framebuffer_sRGB;
    GLboolean                           EXT_framebuffer_sRGB;
    GLboolean                           ARB_pixel_format;
    GLboolean                           ARB_create_context;
    GLboolean                           ARB_create_context_profile;
    GLboolean                           EXT_create_context_es2_profile;
    GLboolean                           ARB_create_context_robustness;
    GLboolean                           ARB_context_flush_control;

} _GLFWcontextWGL;


// WGL-specific global data
//
typedef struct _GLFWlibraryWGL
{
    struct {
        HINSTANCE           instance;
        WGLCREATECONTEXT_T  CreateContext;
        WGLDELETECONTEXT_T  DeleteContext;
        WGLGETPROCADDRESS_T GetProcAddress;
        WGLMAKECURRENT_T    MakeCurrent;
        WGLSHARELISTS_T     ShareLists;
    } opengl32;

} _GLFWlibraryWGL;


int _glfwInitContextAPI(void);
void _glfwTerminateContextAPI(void);
int _glfwCreateContext(_GLFWwindow* window,
                       const _GLFWctxconfig* ctxconfig,
                       const _GLFWfbconfig* fbconfig);
void _glfwDestroyContext(_GLFWwindow* window);
int _glfwAnalyzeContext(const _GLFWwindow* window,
                        const _GLFWctxconfig* ctxconfig,
                        const _GLFWfbconfig* fbconfig);

#endif // _glfw3_wgl_context_h_
