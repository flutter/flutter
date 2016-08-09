//========================================================================
// GLFW 3.2 WGL - www.glfw.org
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


#define WGL_NUMBER_PIXEL_FORMATS_ARB 0x2000
#define WGL_SUPPORT_OPENGL_ARB 0x2010
#define WGL_DRAW_TO_WINDOW_ARB 0x2001
#define WGL_PIXEL_TYPE_ARB 0x2013
#define WGL_TYPE_RGBA_ARB 0x202b
#define WGL_ACCELERATION_ARB 0x2003
#define WGL_NO_ACCELERATION_ARB 0x2025
#define WGL_RED_BITS_ARB 0x2015
#define WGL_RED_SHIFT_ARB 0x2016
#define WGL_GREEN_BITS_ARB 0x2017
#define WGL_GREEN_SHIFT_ARB 0x2018
#define WGL_BLUE_BITS_ARB 0x2019
#define WGL_BLUE_SHIFT_ARB 0x201a
#define WGL_ALPHA_BITS_ARB 0x201b
#define WGL_ALPHA_SHIFT_ARB 0x201c
#define WGL_ACCUM_BITS_ARB 0x201d
#define WGL_ACCUM_RED_BITS_ARB 0x201e
#define WGL_ACCUM_GREEN_BITS_ARB 0x201f
#define WGL_ACCUM_BLUE_BITS_ARB 0x2020
#define WGL_ACCUM_ALPHA_BITS_ARB 0x2021
#define WGL_DEPTH_BITS_ARB 0x2022
#define WGL_STENCIL_BITS_ARB 0x2023
#define WGL_AUX_BUFFERS_ARB 0x2024
#define WGL_STEREO_ARB 0x2012
#define WGL_DOUBLE_BUFFER_ARB 0x2011
#define WGL_SAMPLES_ARB 0x2042
#define WGL_FRAMEBUFFER_SRGB_CAPABLE_ARB 0x20a9
#define WGL_CONTEXT_DEBUG_BIT_ARB 0x00000001
#define WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB 0x00000002
#define WGL_CONTEXT_PROFILE_MASK_ARB 0x9126
#define WGL_CONTEXT_CORE_PROFILE_BIT_ARB 0x00000001
#define WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB 0x00000002
#define WGL_CONTEXT_MAJOR_VERSION_ARB 0x2091
#define WGL_CONTEXT_MINOR_VERSION_ARB 0x2092
#define WGL_CONTEXT_FLAGS_ARB 0x2094
#define WGL_CONTEXT_ES2_PROFILE_BIT_EXT 0x00000004
#define WGL_CONTEXT_ROBUST_ACCESS_BIT_ARB 0x00000004
#define WGL_LOSE_CONTEXT_ON_RESET_ARB 0x8252
#define WGL_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB 0x8256
#define WGL_NO_RESET_NOTIFICATION_ARB 0x8261
#define WGL_CONTEXT_RELEASE_BEHAVIOR_ARB 0x2097
#define WGL_CONTEXT_RELEASE_BEHAVIOR_NONE_ARB 0
#define WGL_CONTEXT_RELEASE_BEHAVIOR_FLUSH_ARB 0x2098

typedef BOOL (WINAPI * PFNWGLSWAPINTERVALEXTPROC)(int);
typedef BOOL (WINAPI * PFNWGLGETPIXELFORMATATTRIBIVARBPROC)(HDC,int,int,UINT,const int*,int*);
typedef const char* (WINAPI * PFNWGLGETEXTENSIONSSTRINGEXTPROC)(void);
typedef const char* (WINAPI * PFNWGLGETEXTENSIONSSTRINGARBPROC)(HDC);
typedef HGLRC (WINAPI * PFNWGLCREATECONTEXTATTRIBSARBPROC)(HDC,HGLRC,const int*);

typedef HGLRC (WINAPI * WGLCREATECONTEXT_T)(HDC);
typedef BOOL (WINAPI * WGLDELETECONTEXT_T)(HGLRC);
typedef PROC (WINAPI * WGLGETPROCADDRESS_T)(LPCSTR);
typedef BOOL (WINAPI * WGLMAKECURRENT_T)(HDC,HGLRC);
typedef BOOL (WINAPI * WGLSHARELISTS_T)(HGLRC,HGLRC);

// opengl32.dll function pointer typedefs
#define wglCreateContext _glfw.wgl.CreateContext
#define wglDeleteContext _glfw.wgl.DeleteContext
#define wglGetProcAddress _glfw.wgl.GetProcAddress
#define wglMakeCurrent _glfw.wgl.MakeCurrent
#define wglShareLists _glfw.wgl.ShareLists

#define _GLFW_RECREATION_NOT_NEEDED 0
#define _GLFW_RECREATION_REQUIRED   1
#define _GLFW_RECREATION_IMPOSSIBLE 2

#define _GLFW_PLATFORM_FBCONFIG                 int             wgl
#define _GLFW_PLATFORM_CONTEXT_STATE            _GLFWcontextWGL wgl
#define _GLFW_PLATFORM_LIBRARY_CONTEXT_STATE    _GLFWlibraryWGL wgl


// WGL-specific per-context data
//
typedef struct _GLFWcontextWGL
{
    HDC       dc;
    HGLRC     handle;
    int       interval;

} _GLFWcontextWGL;


// WGL-specific global data
//
typedef struct _GLFWlibraryWGL
{
    HINSTANCE                           instance;
    WGLCREATECONTEXT_T                  CreateContext;
    WGLDELETECONTEXT_T                  DeleteContext;
    WGLGETPROCADDRESS_T                 GetProcAddress;
    WGLMAKECURRENT_T                    MakeCurrent;
    WGLSHARELISTS_T                     ShareLists;

    GLFWbool                            extensionsLoaded;

    PFNWGLSWAPINTERVALEXTPROC           SwapIntervalEXT;
    PFNWGLGETPIXELFORMATATTRIBIVARBPROC GetPixelFormatAttribivARB;
    PFNWGLGETEXTENSIONSSTRINGEXTPROC    GetExtensionsStringEXT;
    PFNWGLGETEXTENSIONSSTRINGARBPROC    GetExtensionsStringARB;
    PFNWGLCREATECONTEXTATTRIBSARBPROC   CreateContextAttribsARB;
    GLFWbool                            EXT_swap_control;
    GLFWbool                            ARB_multisample;
    GLFWbool                            ARB_framebuffer_sRGB;
    GLFWbool                            EXT_framebuffer_sRGB;
    GLFWbool                            ARB_pixel_format;
    GLFWbool                            ARB_create_context;
    GLFWbool                            ARB_create_context_profile;
    GLFWbool                            EXT_create_context_es2_profile;
    GLFWbool                            ARB_create_context_robustness;
    GLFWbool                            ARB_context_flush_control;

} _GLFWlibraryWGL;


GLFWbool _glfwInitWGL(void);
void _glfwTerminateWGL(void);
GLFWbool _glfwCreateContextWGL(_GLFWwindow* window,
                               const _GLFWctxconfig* ctxconfig,
                               const _GLFWfbconfig* fbconfig);
void _glfwDestroyContextWGL(_GLFWwindow* window);
int _glfwAnalyzeContextWGL(_GLFWwindow* window,
                           const _GLFWctxconfig* ctxconfig,
                           const _GLFWfbconfig* fbconfig);

#endif // _glfw3_wgl_context_h_
