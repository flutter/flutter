//========================================================================
// GLFW 3.1 EGL - www.glfw.org
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

#if defined(_GLFW_WIN32)
 #define _glfw_dlopen(name) LoadLibraryA(name)
 #define _glfw_dlclose(handle) FreeLibrary((HMODULE) handle)
 #define _glfw_dlsym(handle, name) GetProcAddress((HMODULE) handle, name)
#else
 #include <dlfcn.h>
 #define _glfw_dlopen(name) dlopen(name, RTLD_LAZY | RTLD_LOCAL)
 #define _glfw_dlclose(handle) dlclose(handle)
 #define _glfw_dlsym(handle, name) dlsym(handle, name)
#endif

#include <EGL/egl.h>

// This path may need to be changed if you build GLFW using your own setup
// We ship and use our own copy of eglext.h since GLFW uses fairly new
// extensions and not all operating systems come with an up-to-date version
#include "../deps/EGL/eglext.h"

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
#define _glfw_eglGetConfigAttrib _glfw.egl.GetConfigAttrib
#define _glfw_eglGetConfigs _glfw.egl.GetConfigs
#define _glfw_eglGetDisplay _glfw.egl.GetDisplay
#define _glfw_eglGetError _glfw.egl.GetError
#define _glfw_eglInitialize _glfw.egl.Initialize
#define _glfw_eglTerminate _glfw.egl.Terminate
#define _glfw_eglBindAPI _glfw.egl.BindAPI
#define _glfw_eglCreateContext _glfw.egl.CreateContext
#define _glfw_eglDestroySurface _glfw.egl.DestroySurface
#define _glfw_eglDestroyContext _glfw.egl.DestroyContext
#define _glfw_eglCreateWindowSurface _glfw.egl.CreateWindowSurface
#define _glfw_eglMakeCurrent _glfw.egl.MakeCurrent
#define _glfw_eglSwapBuffers _glfw.egl.SwapBuffers
#define _glfw_eglSwapInterval _glfw.egl.SwapInterval
#define _glfw_eglQueryString _glfw.egl.QueryString
#define _glfw_eglGetProcAddress _glfw.egl.GetProcAddress

#define _GLFW_PLATFORM_FBCONFIG                 EGLConfig       egl
#define _GLFW_PLATFORM_CONTEXT_STATE            _GLFWcontextEGL egl
#define _GLFW_PLATFORM_LIBRARY_CONTEXT_STATE    _GLFWlibraryEGL egl


// EGL-specific per-context data
//
typedef struct _GLFWcontextEGL
{
   EGLConfig        config;
   EGLContext       context;
   EGLSurface       surface;

#if defined(_GLFW_X11)
   XVisualInfo*     visual;
#endif

   void*            client;

} _GLFWcontextEGL;


// EGL-specific global data
//
typedef struct _GLFWlibraryEGL
{
    EGLDisplay      display;
    EGLint          major, minor;

    GLboolean       KHR_create_context;

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


int _glfwInitContextAPI(void);
void _glfwTerminateContextAPI(void);
int _glfwCreateContext(_GLFWwindow* window,
                       const _GLFWctxconfig* ctxconfig,
                       const _GLFWfbconfig* fbconfig);
void _glfwDestroyContext(_GLFWwindow* window);
int _glfwAnalyzeContext(const _GLFWwindow* window,
                        const _GLFWctxconfig* ctxconfig,
                        const _GLFWfbconfig* fbconfig);

#endif // _glfw3_egl_context_h_
