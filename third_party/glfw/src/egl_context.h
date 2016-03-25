//========================================================================
// GLFW 3.2 EGL - www.glfw.org
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

#ifndef _glfw3_egl_context_h_
#define _glfw3_egl_context_h_

#if defined(_GLFW_USE_EGLPLATFORM_H)
 #include <EGL/eglplatform.h>
#elif defined(_GLFW_WIN32)
 #define EGLAPIENTRY __stdcall
typedef HDC EGLNativeDisplayType;
typedef HWND EGLNativeWindowType;
#elif defined(_GLFW_X11)
 #define EGLAPIENTRY
typedef Display* EGLNativeDisplayType;
typedef Window EGLNativeWindowType;
#elif defined(_GLFW_WAYLAND)
 #define EGLAPIENTRY
typedef struct wl_display* EGLNativeDisplayType;
typedef struct wl_egl_window* EGLNativeWindowType;
#elif defined(_GLFW_MIR)
 #define EGLAPIENTRY
typedef MirEGLNativeDisplayType EGLNativeDisplayType;
typedef MirEGLNativeWindowType EGLNativeWindowType;
#else
 #error "No supported EGL platform selected"
#endif

#define EGL_SUCCESS	0x3000
#define EGL_NOT_INITIALIZED	0x3001
#define EGL_BAD_ACCESS 0x3002
#define EGL_BAD_ALLOC 0x3003
#define EGL_BAD_ATTRIBUTE 0x3004
#define EGL_BAD_CONFIG 0x3005
#define EGL_BAD_CONTEXT	0x3006
#define EGL_BAD_CURRENT_SURFACE	0x3007
#define EGL_BAD_DISPLAY	0x3008
#define EGL_BAD_MATCH 0x3009
#define EGL_BAD_NATIVE_PIXMAP 0x300a
#define EGL_BAD_NATIVE_WINDOW 0x300b
#define EGL_BAD_PARAMETER 0x300c
#define EGL_BAD_SURFACE	0x300d
#define EGL_CONTEXT_LOST 0x300e
#define EGL_COLOR_BUFFER_TYPE 0x303f
#define EGL_RGB_BUFFER 0x308e
#define EGL_SURFACE_TYPE 0x3033
#define EGL_WINDOW_BIT 0x0004
#define EGL_RENDERABLE_TYPE	0x3040
#define EGL_OPENGL_ES_BIT 0x0001
#define EGL_OPENGL_ES2_BIT 0x0004
#define EGL_OPENGL_BIT 0x0008
#define EGL_ALPHA_SIZE 0x3021
#define EGL_BLUE_SIZE 0x3022
#define EGL_GREEN_SIZE 0x3023
#define EGL_RED_SIZE 0x3024
#define EGL_DEPTH_SIZE 0x3025
#define EGL_STENCIL_SIZE 0x3026
#define EGL_SAMPLES	0x3031
#define EGL_OPENGL_ES_API 0x30a0
#define EGL_OPENGL_API 0x30a2
#define EGL_NONE 0x3038
#define EGL_EXTENSIONS 0x3055
#define EGL_CONTEXT_CLIENT_VERSION 0x3098
#define EGL_NATIVE_VISUAL_ID 0x302e
#define EGL_NO_SURFACE ((EGLSurface) 0)
#define EGL_NO_DISPLAY ((EGLDisplay) 0)
#define EGL_NO_CONTEXT ((EGLContext) 0)
#define EGL_DEFAULT_DISPLAY ((EGLNativeDisplayType) 0)

#define EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE_BIT_KHR 0x00000002
#define EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT_KHR 0x00000001
#define EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT_KHR 0x00000002
#define EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR 0x00000001
#define EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY_KHR 0x31bd
#define EGL_NO_RESET_NOTIFICATION_KHR 0x31be
#define EGL_LOSE_CONTEXT_ON_RESET_KHR 0x31bf
#define EGL_CONTEXT_OPENGL_ROBUST_ACCESS_BIT_KHR 0x00000004
#define EGL_CONTEXT_MAJOR_VERSION_KHR 0x3098
#define EGL_CONTEXT_MINOR_VERSION_KHR 0x30fb
#define EGL_CONTEXT_OPENGL_PROFILE_MASK_KHR 0x30fd
#define EGL_CONTEXT_FLAGS_KHR 0x30fc
#define EGL_CONTEXT_OPENGL_NO_ERROR_KHR 0x31b3
#define EGL_GL_COLORSPACE_KHR 0x309d
#define EGL_GL_COLORSPACE_SRGB_KHR 0x3089

typedef int EGLint;
typedef unsigned int EGLBoolean;
typedef unsigned int EGLenum;
typedef void* EGLConfig;
typedef void* EGLContext;
typedef void* EGLDisplay;
typedef void* EGLSurface;

// EGL function pointer typedefs
typedef EGLBoolean (EGLAPIENTRY * PFNEGLGETCONFIGATTRIBPROC)(EGLDisplay,EGLConfig,EGLint,EGLint*);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLGETCONFIGSPROC)(EGLDisplay,EGLConfig*,EGLint,EGLint*);
typedef EGLDisplay (EGLAPIENTRY * PFNEGLGETDISPLAYPROC)(EGLNativeDisplayType);
typedef EGLint (EGLAPIENTRY * PFNEGLGETERRORPROC)(void);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLINITIALIZEPROC)(EGLDisplay,EGLint*,EGLint*);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLTERMINATEPROC)(EGLDisplay);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLBINDAPIPROC)(EGLenum);
typedef EGLContext (EGLAPIENTRY * PFNEGLCREATECONTEXTPROC)(EGLDisplay,EGLConfig,EGLContext,const EGLint*);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLDESTROYSURFACEPROC)(EGLDisplay,EGLSurface);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLDESTROYCONTEXTPROC)(EGLDisplay,EGLContext);
typedef EGLSurface (EGLAPIENTRY * PFNEGLCREATEWINDOWSURFACEPROC)(EGLDisplay,EGLConfig,EGLNativeWindowType,const EGLint*);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLMAKECURRENTPROC)(EGLDisplay,EGLSurface,EGLSurface,EGLContext);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLSWAPBUFFERSPROC)(EGLDisplay,EGLSurface);
typedef EGLBoolean (EGLAPIENTRY * PFNEGLSWAPINTERVALPROC)(EGLDisplay,EGLint);
typedef const char* (EGLAPIENTRY * PFNEGLQUERYSTRINGPROC)(EGLDisplay,EGLint);
typedef GLFWglproc (EGLAPIENTRY * PFNEGLGETPROCADDRESSPROC)(const char*);
#define eglGetConfigAttrib _glfw.egl.GetConfigAttrib
#define eglGetConfigs _glfw.egl.GetConfigs
#define eglGetDisplay _glfw.egl.GetDisplay
#define eglGetError _glfw.egl.GetError
#define eglInitialize _glfw.egl.Initialize
#define eglTerminate _glfw.egl.Terminate
#define eglBindAPI _glfw.egl.BindAPI
#define eglCreateContext _glfw.egl.CreateContext
#define eglDestroySurface _glfw.egl.DestroySurface
#define eglDestroyContext _glfw.egl.DestroyContext
#define eglCreateWindowSurface _glfw.egl.CreateWindowSurface
#define eglMakeCurrent _glfw.egl.MakeCurrent
#define eglSwapBuffers _glfw.egl.SwapBuffers
#define eglSwapInterval _glfw.egl.SwapInterval
#define eglQueryString _glfw.egl.QueryString
#define eglGetProcAddress _glfw.egl.GetProcAddress

#define _GLFW_PLATFORM_FBCONFIG                 EGLConfig       egl
#define _GLFW_PLATFORM_CONTEXT_STATE            _GLFWcontextEGL egl
#define _GLFW_PLATFORM_LIBRARY_CONTEXT_STATE    _GLFWlibraryEGL egl


// EGL-specific per-context data
//
typedef struct _GLFWcontextEGL
{
   EGLConfig        config;
   EGLContext       handle;
   EGLSurface       surface;

   void*            client;

} _GLFWcontextEGL;


// EGL-specific global data
//
typedef struct _GLFWlibraryEGL
{
    EGLDisplay      display;
    EGLint          major, minor;

    GLFWbool        KHR_create_context;
    GLFWbool        KHR_create_context_no_error;
    GLFWbool        KHR_gl_colorspace;

    void*           handle;

    PFNEGLGETCONFIGATTRIBPROC       GetConfigAttrib;
    PFNEGLGETCONFIGSPROC            GetConfigs;
    PFNEGLGETDISPLAYPROC            GetDisplay;
    PFNEGLGETERRORPROC              GetError;
    PFNEGLINITIALIZEPROC            Initialize;
    PFNEGLTERMINATEPROC             Terminate;
    PFNEGLBINDAPIPROC               BindAPI;
    PFNEGLCREATECONTEXTPROC         CreateContext;
    PFNEGLDESTROYSURFACEPROC        DestroySurface;
    PFNEGLDESTROYCONTEXTPROC        DestroyContext;
    PFNEGLCREATEWINDOWSURFACEPROC   CreateWindowSurface;
    PFNEGLMAKECURRENTPROC           MakeCurrent;
    PFNEGLSWAPBUFFERSPROC           SwapBuffers;
    PFNEGLSWAPINTERVALPROC          SwapInterval;
    PFNEGLQUERYSTRINGPROC           QueryString;
    PFNEGLGETPROCADDRESSPROC        GetProcAddress;

} _GLFWlibraryEGL;


GLFWbool _glfwInitEGL(void);
void _glfwTerminateEGL(void);
GLFWbool _glfwCreateContextEGL(_GLFWwindow* window,
                               const _GLFWctxconfig* ctxconfig,
                               const _GLFWfbconfig* fbconfig);
void _glfwDestroyContextEGL(_GLFWwindow* window);
#if defined(_GLFW_X11)
GLFWbool _glfwChooseVisualEGL(const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig,
                              Visual** visual, int* depth);
#endif /*_GLFW_X11*/

#endif // _glfw3_egl_context_h_
