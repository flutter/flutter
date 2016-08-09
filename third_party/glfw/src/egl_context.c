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

#include "internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>


// Return a description of the specified EGL error
//
static const char* getErrorString(EGLint error)
{
    switch (error)
    {
        case EGL_SUCCESS:
            return "Success";
        case EGL_NOT_INITIALIZED:
            return "EGL is not or could not be initialized";
        case EGL_BAD_ACCESS:
            return "EGL cannot access a requested resource";
        case EGL_BAD_ALLOC:
            return "EGL failed to allocate resources for the requested operation";
        case EGL_BAD_ATTRIBUTE:
            return "An unrecognized attribute or attribute value was passed in the attribute list";
        case EGL_BAD_CONTEXT:
            return "An EGLContext argument does not name a valid EGL rendering context";
        case EGL_BAD_CONFIG:
            return "An EGLConfig argument does not name a valid EGL frame buffer configuration";
        case EGL_BAD_CURRENT_SURFACE:
            return "The current surface of the calling thread is a window, pixel buffer or pixmap that is no longer valid";
        case EGL_BAD_DISPLAY:
            return "An EGLDisplay argument does not name a valid EGL display connection";
        case EGL_BAD_SURFACE:
            return "An EGLSurface argument does not name a valid surface configured for GL rendering";
        case EGL_BAD_MATCH:
            return "Arguments are inconsistent";
        case EGL_BAD_PARAMETER:
            return "One or more argument values are invalid";
        case EGL_BAD_NATIVE_PIXMAP:
            return "A NativePixmapType argument does not refer to a valid native pixmap";
        case EGL_BAD_NATIVE_WINDOW:
            return "A NativeWindowType argument does not refer to a valid native window";
        case EGL_CONTEXT_LOST:
            return "The application must destroy all contexts and reinitialise";
        default:
            return "ERROR: UNKNOWN EGL ERROR";
    }
}

// Returns the specified attribute of the specified EGLConfig
//
static int getConfigAttrib(EGLConfig config, int attrib)
{
    int value;
    eglGetConfigAttrib(_glfw.egl.display, config, attrib, &value);
    return value;
}

// Return a list of available and usable framebuffer configs
//
static GLFWbool chooseFBConfigs(const _GLFWctxconfig* ctxconfig,
                                const _GLFWfbconfig* desired,
                                EGLConfig* result)
{
    EGLConfig* nativeConfigs;
    _GLFWfbconfig* usableConfigs;
    const _GLFWfbconfig* closest;
    int i, nativeCount, usableCount;

    eglGetConfigs(_glfw.egl.display, NULL, 0, &nativeCount);
    if (!nativeCount)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "EGL: No EGLConfigs returned");
        return GLFW_FALSE;
    }

    nativeConfigs = calloc(nativeCount, sizeof(EGLConfig));
    eglGetConfigs(_glfw.egl.display, nativeConfigs, nativeCount, &nativeCount);

    usableConfigs = calloc(nativeCount, sizeof(_GLFWfbconfig));
    usableCount = 0;

    for (i = 0;  i < nativeCount;  i++)
    {
        const EGLConfig n = nativeConfigs[i];
        _GLFWfbconfig* u = usableConfigs + usableCount;

        // Only consider RGB(A) EGLConfigs
        if (!(getConfigAttrib(n, EGL_COLOR_BUFFER_TYPE) & EGL_RGB_BUFFER))
            continue;

        // Only consider window EGLConfigs
        if (!(getConfigAttrib(n, EGL_SURFACE_TYPE) & EGL_WINDOW_BIT))
            continue;

#if defined(_GLFW_X11)
        // Only consider EGLConfigs with associated Visuals
        if (!getConfigAttrib(n, EGL_NATIVE_VISUAL_ID))
            continue;
#endif // _GLFW_X11

        if (ctxconfig->api == GLFW_OPENGL_ES_API)
        {
            if (ctxconfig->major == 1)
            {
                if (!(getConfigAttrib(n, EGL_RENDERABLE_TYPE) & EGL_OPENGL_ES_BIT))
                    continue;
            }
            else
            {
                if (!(getConfigAttrib(n, EGL_RENDERABLE_TYPE) & EGL_OPENGL_ES2_BIT))
                    continue;
            }
        }
        else if (ctxconfig->api == GLFW_OPENGL_API)
        {
            if (!(getConfigAttrib(n, EGL_RENDERABLE_TYPE) & EGL_OPENGL_BIT))
                continue;
        }

        u->redBits = getConfigAttrib(n, EGL_RED_SIZE);
        u->greenBits = getConfigAttrib(n, EGL_GREEN_SIZE);
        u->blueBits = getConfigAttrib(n, EGL_BLUE_SIZE);

        u->alphaBits = getConfigAttrib(n, EGL_ALPHA_SIZE);
        u->depthBits = getConfigAttrib(n, EGL_DEPTH_SIZE);
        u->stencilBits = getConfigAttrib(n, EGL_STENCIL_SIZE);

        u->samples = getConfigAttrib(n, EGL_SAMPLES);
        u->doublebuffer = GLFW_TRUE;

        u->egl = n;
        usableCount++;
    }

    closest = _glfwChooseFBConfig(desired, usableConfigs, usableCount);
    if (closest)
        *result = closest->egl;

    free(nativeConfigs);
    free(usableConfigs);

    return closest ? GLFW_TRUE : GLFW_FALSE;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize EGL
//
GLFWbool _glfwInitEGL(void)
{
    int i;
    const char* sonames[] =
    {
#if defined(_GLFW_WIN32)
        "libEGL.dll",
        "EGL.dll",
#elif defined(_GLFW_COCOA)
        "libEGL.dylib",
#else
        "libEGL.so.1",
#endif
        NULL
    };

    for (i = 0;  sonames[i];  i++)
    {
        _glfw.egl.handle = _glfw_dlopen(sonames[i]);
        if (_glfw.egl.handle)
            break;
    }

    if (!_glfw.egl.handle)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "EGL: Failed to load EGL");
        return GLFW_FALSE;
    }

    _glfw.egl.GetConfigAttrib = (PFNEGLGETCONFIGATTRIBPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglGetConfigAttrib");
    _glfw.egl.GetConfigs = (PFNEGLGETCONFIGSPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglGetConfigs");
    _glfw.egl.GetDisplay = (PFNEGLGETDISPLAYPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglGetDisplay");
    _glfw.egl.GetError = (PFNEGLGETERRORPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglGetError");
    _glfw.egl.Initialize = (PFNEGLINITIALIZEPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglInitialize");
    _glfw.egl.Terminate = (PFNEGLTERMINATEPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglTerminate");
    _glfw.egl.BindAPI = (PFNEGLBINDAPIPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglBindAPI");
    _glfw.egl.CreateContext = (PFNEGLCREATECONTEXTPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglCreateContext");
    _glfw.egl.DestroySurface = (PFNEGLDESTROYSURFACEPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglDestroySurface");
    _glfw.egl.DestroyContext = (PFNEGLDESTROYCONTEXTPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglDestroyContext");
    _glfw.egl.CreateWindowSurface = (PFNEGLCREATEWINDOWSURFACEPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglCreateWindowSurface");
    _glfw.egl.MakeCurrent = (PFNEGLMAKECURRENTPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglMakeCurrent");
    _glfw.egl.SwapBuffers = (PFNEGLSWAPBUFFERSPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglSwapBuffers");
    _glfw.egl.SwapInterval = (PFNEGLSWAPINTERVALPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglSwapInterval");
    _glfw.egl.QueryString = (PFNEGLQUERYSTRINGPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglQueryString");
    _glfw.egl.GetProcAddress = (PFNEGLGETPROCADDRESSPROC)
        _glfw_dlsym(_glfw.egl.handle, "eglGetProcAddress");

    _glfw.egl.display = eglGetDisplay(_GLFW_EGL_NATIVE_DISPLAY);
    if (_glfw.egl.display == EGL_NO_DISPLAY)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "EGL: Failed to get EGL display: %s",
                        getErrorString(eglGetError()));
        return GLFW_FALSE;
    }

    if (!eglInitialize(_glfw.egl.display, &_glfw.egl.major, &_glfw.egl.minor))
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "EGL: Failed to initialize EGL: %s",
                        getErrorString(eglGetError()));
        return GLFW_FALSE;
    }

    _glfw.egl.KHR_create_context =
        _glfwPlatformExtensionSupported("EGL_KHR_create_context");
    _glfw.egl.KHR_create_context_no_error =
        _glfwPlatformExtensionSupported("EGL_KHR_create_context_no_error");
    _glfw.egl.KHR_gl_colorspace =
        _glfwPlatformExtensionSupported("EGL_KHR_gl_colorspace");

    return GLFW_TRUE;
}

// Terminate EGL
//
void _glfwTerminateEGL(void)
{
    if (_glfw.egl.handle)
    {
        eglTerminate(_glfw.egl.display);
        _glfw_dlclose(_glfw.egl.handle);
        _glfw.egl.handle = NULL;
    }
}

#define setEGLattrib(attribName, attribValue) \
{ \
    attribs[index++] = attribName; \
    attribs[index++] = attribValue; \
    assert((size_t) index < sizeof(attribs) / sizeof(attribs[0])); \
}

// Create the OpenGL or OpenGL ES context
//
GLFWbool _glfwCreateContextEGL(_GLFWwindow* window,
                               const _GLFWctxconfig* ctxconfig,
                               const _GLFWfbconfig* fbconfig)
{
    EGLint attribs[40];
    EGLConfig config;
    EGLContext share = NULL;

    if (ctxconfig->share)
        share = ctxconfig->share->context.egl.handle;

    if (!chooseFBConfigs(ctxconfig, fbconfig, &config))
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "EGL: Failed to find a suitable EGLConfig");
        return GLFW_FALSE;
    }

    if (ctxconfig->api == GLFW_OPENGL_ES_API)
    {
        if (!eglBindAPI(EGL_OPENGL_ES_API))
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "EGL: Failed to bind OpenGL ES: %s",
                            getErrorString(eglGetError()));
            return GLFW_FALSE;
        }
    }
    else
    {
        if (!eglBindAPI(EGL_OPENGL_API))
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "EGL: Failed to bind OpenGL: %s",
                            getErrorString(eglGetError()));
            return GLFW_FALSE;
        }
    }

    if (_glfw.egl.KHR_create_context)
    {
        int index = 0, mask = 0, flags = 0;

        if (ctxconfig->api == GLFW_OPENGL_API)
        {
            if (ctxconfig->forward)
                flags |= EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE_BIT_KHR;

            if (ctxconfig->profile == GLFW_OPENGL_CORE_PROFILE)
                mask |= EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT_KHR;
            else if (ctxconfig->profile == GLFW_OPENGL_COMPAT_PROFILE)
                mask |= EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT_KHR;

            if (_glfw.egl.KHR_create_context_no_error)
            {
                if (ctxconfig->noerror)
                    flags |= EGL_CONTEXT_OPENGL_NO_ERROR_KHR;
            }
        }

        if (ctxconfig->debug)
            flags |= EGL_CONTEXT_OPENGL_DEBUG_BIT_KHR;

        if (ctxconfig->robustness)
        {
            if (ctxconfig->robustness == GLFW_NO_RESET_NOTIFICATION)
            {
                setEGLattrib(EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY_KHR,
                             EGL_NO_RESET_NOTIFICATION_KHR);
            }
            else if (ctxconfig->robustness == GLFW_LOSE_CONTEXT_ON_RESET)
            {
                setEGLattrib(EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY_KHR,
                             EGL_LOSE_CONTEXT_ON_RESET_KHR);
            }

            flags |= EGL_CONTEXT_OPENGL_ROBUST_ACCESS_BIT_KHR;
        }

        if (ctxconfig->major != 1 || ctxconfig->minor != 0)
        {
            setEGLattrib(EGL_CONTEXT_MAJOR_VERSION_KHR, ctxconfig->major);
            setEGLattrib(EGL_CONTEXT_MINOR_VERSION_KHR, ctxconfig->minor);
        }

        if (mask)
            setEGLattrib(EGL_CONTEXT_OPENGL_PROFILE_MASK_KHR, mask);

        if (flags)
            setEGLattrib(EGL_CONTEXT_FLAGS_KHR, flags);

        setEGLattrib(EGL_NONE, EGL_NONE);
    }
    else
    {
        int index = 0;

        if (ctxconfig->api == GLFW_OPENGL_ES_API)
            setEGLattrib(EGL_CONTEXT_CLIENT_VERSION, ctxconfig->major);

        setEGLattrib(EGL_NONE, EGL_NONE);
    }

    // Context release behaviors (GL_KHR_context_flush_control) are not yet
    // supported on EGL but are not a hard constraint, so ignore and continue

    window->context.egl.handle = eglCreateContext(_glfw.egl.display,
                                                  config, share, attribs);

    if (window->context.egl.handle == EGL_NO_CONTEXT)
    {
        _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                        "EGL: Failed to create context: %s",
                        getErrorString(eglGetError()));
        return GLFW_FALSE;
    }

    // Set up attributes for surface creation
    {
        int index = 0;

        if (fbconfig->sRGB)
        {
            if (_glfw.egl.KHR_gl_colorspace)
            {
                setEGLattrib(EGL_GL_COLORSPACE_KHR, EGL_GL_COLORSPACE_SRGB_KHR);
            }
        }

        setEGLattrib(EGL_NONE, EGL_NONE);
    }

    window->context.egl.surface =
        eglCreateWindowSurface(_glfw.egl.display,
                               config,
                               _GLFW_EGL_NATIVE_WINDOW,
                               attribs);
    if (window->context.egl.surface == EGL_NO_SURFACE)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "EGL: Failed to create window surface: %s",
                        getErrorString(eglGetError()));
        return GLFW_FALSE;
    }

    window->context.egl.config = config;

    // Load the appropriate client library
    {
        int i;
        const char** sonames;
        const char* es1sonames[] =
        {
#if defined(_GLFW_WIN32)
            "GLESv1_CM.dll",
            "libGLES_CM.dll",
#elif defined(_GLFW_COCOA)
            "libGLESv1_CM.dylib",
#else
            "libGLESv1_CM.so.1",
            "libGLES_CM.so.1",
#endif
            NULL
        };
        const char* es2sonames[] =
        {
#if defined(_GLFW_WIN32)
            "GLESv2.dll",
            "libGLESv2.dll",
#elif defined(_GLFW_COCOA)
            "libGLESv2.dylib",
#else
            "libGLESv2.so.2",
#endif
            NULL
        };
        const char* glsonames[] =
        {
#if defined(_GLFW_WIN32)
#elif defined(_GLFW_COCOA)
#else
            "libGL.so.1",
#endif
            NULL
        };

        if (ctxconfig->api == GLFW_OPENGL_ES_API)
        {
            if (ctxconfig->major == 1)
                sonames = es1sonames;
            else
                sonames = es2sonames;
        }
        else
            sonames = glsonames;

        for (i = 0;  sonames[i];  i++)
        {
            window->context.egl.client = _glfw_dlopen(sonames[i]);
            if (window->context.egl.client)
                break;
        }

        if (!window->context.egl.client)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "EGL: Failed to load client library");
            return GLFW_FALSE;
        }
    }

    return GLFW_TRUE;
}

#undef setEGLattrib

// Destroy the OpenGL context
//
void _glfwDestroyContextEGL(_GLFWwindow* window)
{
#if defined(_GLFW_X11)
    // NOTE: Do not unload libGL.so.1 while the X11 display is still open,
    //       as it will make XCloseDisplay segfault
    if (window->context.api != GLFW_OPENGL_API)
#endif // _GLFW_X11
    {
        if (window->context.egl.client)
        {
            _glfw_dlclose(window->context.egl.client);
            window->context.egl.client = NULL;
        }
    }

    if (window->context.egl.surface)
    {
        eglDestroySurface(_glfw.egl.display, window->context.egl.surface);
        window->context.egl.surface = EGL_NO_SURFACE;
    }

    if (window->context.egl.handle)
    {
        eglDestroyContext(_glfw.egl.display, window->context.egl.handle);
        window->context.egl.handle = EGL_NO_CONTEXT;
    }
}

// Returns the Visual and depth of the chosen EGLConfig
//
#if defined(_GLFW_X11)
GLFWbool _glfwChooseVisualEGL(const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig,
                              Visual** visual, int* depth)
{
    XVisualInfo* result;
    XVisualInfo desired;
    EGLConfig native;
    EGLint visualID = 0, count = 0;
    const long vimask = VisualScreenMask | VisualIDMask;

    if (!chooseFBConfigs(ctxconfig, fbconfig, &native))
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "EGL: Failed to find a suitable EGLConfig");
        return GLFW_FALSE;
    }

    eglGetConfigAttrib(_glfw.egl.display, native,
                       EGL_NATIVE_VISUAL_ID, &visualID);

    desired.screen = _glfw.x11.screen;
    desired.visualid = visualID;

    result = XGetVisualInfo(_glfw.x11.display, vimask, &desired, &count);
    if (!result)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "EGL: Failed to retrieve Visual for EGLConfig");
        return GLFW_FALSE;
    }

    *visual = result->visual;
    *depth = result->depth;

    XFree(result);
    return GLFW_TRUE;
}
#endif // _GLFW_X11


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwPlatformMakeContextCurrent(_GLFWwindow* window)
{
    if (window)
    {
        if (!eglMakeCurrent(_glfw.egl.display,
                            window->context.egl.surface,
                            window->context.egl.surface,
                            window->context.egl.handle))
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "EGL: Failed to make context current: %s",
                            getErrorString(eglGetError()));
            return;
        }
    }
    else
    {
        if (!eglMakeCurrent(_glfw.egl.display,
                            EGL_NO_SURFACE,
                            EGL_NO_SURFACE,
                            EGL_NO_CONTEXT))
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "EGL: Failed to clear current context: %s",
                            getErrorString(eglGetError()));
            return;
        }
    }

    _glfwPlatformSetCurrentContext(window);
}

void _glfwPlatformSwapBuffers(_GLFWwindow* window)
{
    if (window != _glfwPlatformGetCurrentContext())
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "EGL: The context must be current on the calling thread when swapping buffers");
        return;
    }

    eglSwapBuffers(_glfw.egl.display, window->context.egl.surface);
}

void _glfwPlatformSwapInterval(int interval)
{
    eglSwapInterval(_glfw.egl.display, interval);
}

int _glfwPlatformExtensionSupported(const char* extension)
{
    const char* extensions = eglQueryString(_glfw.egl.display, EGL_EXTENSIONS);
    if (extensions)
    {
        if (_glfwStringInExtensionString(extension, extensions))
            return GLFW_TRUE;
    }

    return GLFW_FALSE;
}

GLFWglproc _glfwPlatformGetProcAddress(const char* procname)
{
    _GLFWwindow* window = _glfwPlatformGetCurrentContext();

    if (window->context.egl.client)
    {
        GLFWglproc proc = (GLFWglproc) _glfw_dlsym(window->context.egl.client,
                                                   procname);
        if (proc)
            return proc;
    }

    return eglGetProcAddress(procname);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI EGLDisplay glfwGetEGLDisplay(void)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(EGL_NO_DISPLAY);
    return _glfw.egl.display;
}

GLFWAPI EGLContext glfwGetEGLContext(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(EGL_NO_CONTEXT);

    if (window->context.api == GLFW_NO_API)
    {
        _glfwInputError(GLFW_NO_WINDOW_CONTEXT, NULL);
        return EGL_NO_CONTEXT;
    }

    return window->context.egl.handle;
}

GLFWAPI EGLSurface glfwGetEGLSurface(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(EGL_NO_SURFACE);

    if (window->context.api == GLFW_NO_API)
    {
        _glfwInputError(GLFW_NO_WINDOW_CONTEXT, NULL);
        return EGL_NO_SURFACE;
    }

    return window->context.egl.surface;
}

