//========================================================================
// GLFW 3.2 GLX - www.glfw.org
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

#include <string.h>
#include <stdlib.h>
#include <assert.h>

#ifndef GLXBadProfileARB
 #define GLXBadProfileARB 13
#endif


// Returns the specified attribute of the specified GLXFBConfig
//
static int getFBConfigAttrib(GLXFBConfig fbconfig, int attrib)
{
    int value;
    glXGetFBConfigAttrib(_glfw.x11.display, fbconfig, attrib, &value);
    return value;
}

// Return a list of available and usable framebuffer configs
//
static GLFWbool chooseFBConfig(const _GLFWfbconfig* desired, GLXFBConfig* result)
{
    GLXFBConfig* nativeConfigs;
    _GLFWfbconfig* usableConfigs;
    const _GLFWfbconfig* closest;
    int i, nativeCount, usableCount;
    const char* vendor;
    GLFWbool trustWindowBit = GLFW_TRUE;

    // HACK: This is a (hopefully temporary) workaround for Chromium
    //       (VirtualBox GL) not setting the window bit on any GLXFBConfigs
    vendor = glXGetClientString(_glfw.x11.display, GLX_VENDOR);
    if (strcmp(vendor, "Chromium") == 0)
        trustWindowBit = GLFW_FALSE;

    nativeConfigs =
        glXGetFBConfigs(_glfw.x11.display, _glfw.x11.screen, &nativeCount);
    if (!nativeCount)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "GLX: No GLXFBConfigs returned");
        return GLFW_FALSE;
    }

    usableConfigs = calloc(nativeCount, sizeof(_GLFWfbconfig));
    usableCount = 0;

    for (i = 0;  i < nativeCount;  i++)
    {
        const GLXFBConfig n = nativeConfigs[i];
        _GLFWfbconfig* u = usableConfigs + usableCount;

        // Only consider RGBA GLXFBConfigs
        if (!(getFBConfigAttrib(n, GLX_RENDER_TYPE) & GLX_RGBA_BIT))
            continue;

        // Only consider window GLXFBConfigs
        if (!(getFBConfigAttrib(n, GLX_DRAWABLE_TYPE) & GLX_WINDOW_BIT))
        {
            if (trustWindowBit)
                continue;
        }

        u->redBits = getFBConfigAttrib(n, GLX_RED_SIZE);
        u->greenBits = getFBConfigAttrib(n, GLX_GREEN_SIZE);
        u->blueBits = getFBConfigAttrib(n, GLX_BLUE_SIZE);

        u->alphaBits = getFBConfigAttrib(n, GLX_ALPHA_SIZE);
        u->depthBits = getFBConfigAttrib(n, GLX_DEPTH_SIZE);
        u->stencilBits = getFBConfigAttrib(n, GLX_STENCIL_SIZE);

        u->accumRedBits = getFBConfigAttrib(n, GLX_ACCUM_RED_SIZE);
        u->accumGreenBits = getFBConfigAttrib(n, GLX_ACCUM_GREEN_SIZE);
        u->accumBlueBits = getFBConfigAttrib(n, GLX_ACCUM_BLUE_SIZE);
        u->accumAlphaBits = getFBConfigAttrib(n, GLX_ACCUM_ALPHA_SIZE);

        u->auxBuffers = getFBConfigAttrib(n, GLX_AUX_BUFFERS);

        if (getFBConfigAttrib(n, GLX_STEREO))
            u->stereo = GLFW_TRUE;
        if (getFBConfigAttrib(n, GLX_DOUBLEBUFFER))
            u->doublebuffer = GLFW_TRUE;

        if (_glfw.glx.ARB_multisample)
            u->samples = getFBConfigAttrib(n, GLX_SAMPLES);

        if (_glfw.glx.ARB_framebuffer_sRGB || _glfw.glx.EXT_framebuffer_sRGB)
            u->sRGB = getFBConfigAttrib(n, GLX_FRAMEBUFFER_SRGB_CAPABLE_ARB);

        u->glx = n;
        usableCount++;
    }

    closest = _glfwChooseFBConfig(desired, usableConfigs, usableCount);
    if (closest)
        *result = closest->glx;

    XFree(nativeConfigs);
    free(usableConfigs);

    return closest ? GLFW_TRUE : GLFW_FALSE;
}

// Create the OpenGL context using legacy API
//
static GLXContext createLegacyContext(_GLFWwindow* window,
                                      GLXFBConfig fbconfig,
                                      GLXContext share)
{
    return glXCreateNewContext(_glfw.x11.display,
                               fbconfig,
                               GLX_RGBA_TYPE,
                               share,
                               True);
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize GLX
//
GLFWbool _glfwInitGLX(void)
{
    int i;
    const char* sonames[] =
    {
#if defined(__CYGWIN__)
        "libGL-1.so",
#else
        "libGL.so.1",
        "libGL.so",
#endif
        NULL
    };


    for (i = 0;  sonames[i];  i++)
    {
        _glfw.glx.handle = dlopen(sonames[i], RTLD_LAZY | RTLD_GLOBAL);
        if (_glfw.glx.handle)
            break;
    }

    if (!_glfw.glx.handle)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "GLX: Failed to load GLX");
        return GLFW_FALSE;
    }

    _glfw.glx.GetFBConfigs =
        dlsym(_glfw.glx.handle, "glXGetFBConfigs");
    _glfw.glx.GetFBConfigAttrib =
        dlsym(_glfw.glx.handle, "glXGetFBConfigAttrib");
    _glfw.glx.GetClientString =
        dlsym(_glfw.glx.handle, "glXGetClientString");
    _glfw.glx.QueryExtension =
        dlsym(_glfw.glx.handle, "glXQueryExtension");
    _glfw.glx.QueryVersion =
        dlsym(_glfw.glx.handle, "glXQueryVersion");
    _glfw.glx.DestroyContext =
        dlsym(_glfw.glx.handle, "glXDestroyContext");
    _glfw.glx.MakeCurrent =
        dlsym(_glfw.glx.handle, "glXMakeCurrent");
    _glfw.glx.SwapBuffers =
        dlsym(_glfw.glx.handle, "glXSwapBuffers");
    _glfw.glx.QueryExtensionsString =
        dlsym(_glfw.glx.handle, "glXQueryExtensionsString");
    _glfw.glx.CreateNewContext =
        dlsym(_glfw.glx.handle, "glXCreateNewContext");
    _glfw.glx.CreateWindow =
        dlsym(_glfw.glx.handle, "glXCreateWindow");
    _glfw.glx.DestroyWindow =
        dlsym(_glfw.glx.handle, "glXDestroyWindow");
    _glfw.glx.GetProcAddress =
        dlsym(_glfw.glx.handle, "glXGetProcAddress");
    _glfw.glx.GetProcAddressARB =
        dlsym(_glfw.glx.handle, "glXGetProcAddressARB");
    _glfw.glx.GetVisualFromFBConfig =
        dlsym(_glfw.glx.handle, "glXGetVisualFromFBConfig");

    if (!glXQueryExtension(_glfw.x11.display,
                           &_glfw.glx.errorBase,
                           &_glfw.glx.eventBase))
    {
        _glfwInputError(GLFW_API_UNAVAILABLE, "GLX: GLX extension not found");
        return GLFW_FALSE;
    }

    if (!glXQueryVersion(_glfw.x11.display, &_glfw.glx.major, &_glfw.glx.minor))
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "GLX: Failed to query GLX version");
        return GLFW_FALSE;
    }

    if (_glfw.glx.major == 1 && _glfw.glx.minor < 3)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "GLX: GLX version 1.3 is required");
        return GLFW_FALSE;
    }

    if (_glfwPlatformExtensionSupported("GLX_EXT_swap_control"))
    {
        _glfw.glx.SwapIntervalEXT = (PFNGLXSWAPINTERVALEXTPROC)
            _glfwPlatformGetProcAddress("glXSwapIntervalEXT");

        if (_glfw.glx.SwapIntervalEXT)
            _glfw.glx.EXT_swap_control = GLFW_TRUE;
    }

    if (_glfwPlatformExtensionSupported("GLX_SGI_swap_control"))
    {
        _glfw.glx.SwapIntervalSGI = (PFNGLXSWAPINTERVALSGIPROC)
            _glfwPlatformGetProcAddress("glXSwapIntervalSGI");

        if (_glfw.glx.SwapIntervalSGI)
            _glfw.glx.SGI_swap_control = GLFW_TRUE;
    }

    if (_glfwPlatformExtensionSupported("GLX_MESA_swap_control"))
    {
        _glfw.glx.SwapIntervalMESA = (PFNGLXSWAPINTERVALMESAPROC)
            _glfwPlatformGetProcAddress("glXSwapIntervalMESA");

        if (_glfw.glx.SwapIntervalMESA)
            _glfw.glx.MESA_swap_control = GLFW_TRUE;
    }

    if (_glfwPlatformExtensionSupported("GLX_ARB_multisample"))
        _glfw.glx.ARB_multisample = GLFW_TRUE;

    if (_glfwPlatformExtensionSupported("GLX_ARB_framebuffer_sRGB"))
        _glfw.glx.ARB_framebuffer_sRGB = GLFW_TRUE;

    if (_glfwPlatformExtensionSupported("GLX_EXT_framebuffer_sRGB"))
        _glfw.glx.EXT_framebuffer_sRGB = GLFW_TRUE;

    if (_glfwPlatformExtensionSupported("GLX_ARB_create_context"))
    {
        _glfw.glx.CreateContextAttribsARB = (PFNGLXCREATECONTEXTATTRIBSARBPROC)
            _glfwPlatformGetProcAddress("glXCreateContextAttribsARB");

        if (_glfw.glx.CreateContextAttribsARB)
            _glfw.glx.ARB_create_context = GLFW_TRUE;
    }

    if (_glfwPlatformExtensionSupported("GLX_ARB_create_context_robustness"))
        _glfw.glx.ARB_create_context_robustness = GLFW_TRUE;

    if (_glfwPlatformExtensionSupported("GLX_ARB_create_context_profile"))
        _glfw.glx.ARB_create_context_profile = GLFW_TRUE;

    if (_glfwPlatformExtensionSupported("GLX_EXT_create_context_es2_profile"))
        _glfw.glx.EXT_create_context_es2_profile = GLFW_TRUE;

    if (_glfwPlatformExtensionSupported("GLX_ARB_context_flush_control"))
        _glfw.glx.ARB_context_flush_control = GLFW_TRUE;

    return GLFW_TRUE;
}

// Terminate GLX
//
void _glfwTerminateGLX(void)
{
    // NOTE: This function must not call any X11 functions, as it is called
    //       after XCloseDisplay (see _glfwPlatformTerminate for details)

    if (_glfw.glx.handle)
    {
        dlclose(_glfw.glx.handle);
        _glfw.glx.handle = NULL;
    }
}

#define setGLXattrib(attribName, attribValue) \
{ \
    attribs[index++] = attribName; \
    attribs[index++] = attribValue; \
    assert((size_t) index < sizeof(attribs) / sizeof(attribs[0])); \
}

// Create the OpenGL or OpenGL ES context
//
GLFWbool _glfwCreateContextGLX(_GLFWwindow* window,
                               const _GLFWctxconfig* ctxconfig,
                               const _GLFWfbconfig* fbconfig)
{
    int attribs[40];
    GLXFBConfig native = NULL;
    GLXContext share = NULL;

    if (ctxconfig->share)
        share = ctxconfig->share->context.glx.handle;

    if (!chooseFBConfig(fbconfig, &native))
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "GLX: Failed to find a suitable GLXFBConfig");
        return GLFW_FALSE;
    }

    if (ctxconfig->api == GLFW_OPENGL_ES_API)
    {
        if (!_glfw.glx.ARB_create_context ||
            !_glfw.glx.ARB_create_context_profile ||
            !_glfw.glx.EXT_create_context_es2_profile)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "GLX: OpenGL ES requested but GLX_EXT_create_context_es2_profile is unavailable");
            return GLFW_FALSE;
        }
    }

    if (ctxconfig->forward)
    {
        if (!_glfw.glx.ARB_create_context)
        {
            _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                            "GLX: Forward compatibility requested but GLX_ARB_create_context_profile is unavailable");
            return GLFW_FALSE;
        }
    }

    if (ctxconfig->profile)
    {
        if (!_glfw.glx.ARB_create_context ||
            !_glfw.glx.ARB_create_context_profile)
        {
            _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                            "GLX: An OpenGL profile requested but GLX_ARB_create_context_profile is unavailable");
            return GLFW_FALSE;
        }
    }

    _glfwGrabErrorHandlerX11();

    if (_glfw.glx.ARB_create_context)
    {
        int index = 0, mask = 0, flags = 0;

        if (ctxconfig->api == GLFW_OPENGL_API)
        {
            if (ctxconfig->forward)
                flags |= GLX_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB;

            if (ctxconfig->profile == GLFW_OPENGL_CORE_PROFILE)
                mask |= GLX_CONTEXT_CORE_PROFILE_BIT_ARB;
            else if (ctxconfig->profile == GLFW_OPENGL_COMPAT_PROFILE)
                mask |= GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB;
        }
        else
            mask |= GLX_CONTEXT_ES2_PROFILE_BIT_EXT;

        if (ctxconfig->debug)
            flags |= GLX_CONTEXT_DEBUG_BIT_ARB;
        if (ctxconfig->noerror)
            flags |= GL_CONTEXT_FLAG_NO_ERROR_BIT_KHR;

        if (ctxconfig->robustness)
        {
            if (_glfw.glx.ARB_create_context_robustness)
            {
                if (ctxconfig->robustness == GLFW_NO_RESET_NOTIFICATION)
                {
                    setGLXattrib(GLX_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB,
                                 GLX_NO_RESET_NOTIFICATION_ARB);
                }
                else if (ctxconfig->robustness == GLFW_LOSE_CONTEXT_ON_RESET)
                {
                    setGLXattrib(GLX_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB,
                                 GLX_LOSE_CONTEXT_ON_RESET_ARB);
                }

                flags |= GLX_CONTEXT_ROBUST_ACCESS_BIT_ARB;
            }
        }

        if (ctxconfig->release)
        {
            if (_glfw.glx.ARB_context_flush_control)
            {
                if (ctxconfig->release == GLFW_RELEASE_BEHAVIOR_NONE)
                {
                    setGLXattrib(GLX_CONTEXT_RELEASE_BEHAVIOR_ARB,
                                 GLX_CONTEXT_RELEASE_BEHAVIOR_NONE_ARB);
                }
                else if (ctxconfig->release == GLFW_RELEASE_BEHAVIOR_FLUSH)
                {
                    setGLXattrib(GLX_CONTEXT_RELEASE_BEHAVIOR_ARB,
                                 GLX_CONTEXT_RELEASE_BEHAVIOR_FLUSH_ARB);
                }
            }
        }

        // NOTE: Only request an explicitly versioned context when necessary, as
        //       explicitly requesting version 1.0 does not always return the
        //       highest version supported by the driver
        if (ctxconfig->major != 1 || ctxconfig->minor != 0)
        {
            setGLXattrib(GLX_CONTEXT_MAJOR_VERSION_ARB, ctxconfig->major);
            setGLXattrib(GLX_CONTEXT_MINOR_VERSION_ARB, ctxconfig->minor);
        }

        if (mask)
            setGLXattrib(GLX_CONTEXT_PROFILE_MASK_ARB, mask);

        if (flags)
            setGLXattrib(GLX_CONTEXT_FLAGS_ARB, flags);

        setGLXattrib(None, None);

        window->context.glx.handle =
            _glfw.glx.CreateContextAttribsARB(_glfw.x11.display,
                                              native,
                                              share,
                                              True,
                                              attribs);

        // HACK: This is a fallback for broken versions of the Mesa
        //       implementation of GLX_ARB_create_context_profile that fail
        //       default 1.0 context creation with a GLXBadProfileARB error in
        //       violation of the extension spec
        if (!window->context.glx.handle)
        {
            if (_glfw.x11.errorCode == _glfw.glx.errorBase + GLXBadProfileARB &&
                ctxconfig->api == GLFW_OPENGL_API &&
                ctxconfig->profile == GLFW_OPENGL_ANY_PROFILE &&
                ctxconfig->forward == GLFW_FALSE)
            {
                window->context.glx.handle =
                    createLegacyContext(window, native, share);
            }
        }
    }
    else
        window->context.glx.handle = createLegacyContext(window, native, share);

    _glfwReleaseErrorHandlerX11();

    if (!window->context.glx.handle)
    {
        _glfwInputErrorX11(GLFW_VERSION_UNAVAILABLE, "GLX: Failed to create context");
        return GLFW_FALSE;
    }

    window->context.glx.window =
        glXCreateWindow(_glfw.x11.display, native, window->x11.handle, NULL);
    if (!window->context.glx.window)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "GLX: Failed to create window");
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

#undef setGLXattrib

// Destroy the OpenGL context
//
void _glfwDestroyContextGLX(_GLFWwindow* window)
{
    if (window->context.glx.window)
    {
        glXDestroyWindow(_glfw.x11.display, window->context.glx.window);
        window->context.glx.window = None;
    }

    if (window->context.glx.handle)
    {
        glXDestroyContext(_glfw.x11.display, window->context.glx.handle);
        window->context.glx.handle = NULL;
    }
}

// Returns the Visual and depth of the chosen GLXFBConfig
//
GLFWbool _glfwChooseVisualGLX(const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig,
                              Visual** visual, int* depth)
{
    GLXFBConfig native;
    XVisualInfo* result;

    if (!chooseFBConfig(fbconfig, &native))
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "GLX: Failed to find a suitable GLXFBConfig");
        return GLFW_FALSE;
    }

    result = glXGetVisualFromFBConfig(_glfw.x11.display, native);
    if (!result)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "GLX: Failed to retrieve Visual for GLXFBConfig");
        return GLFW_FALSE;
    }

    *visual = result->visual;
    *depth = result->depth;

    XFree(result);
    return GLFW_TRUE;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwPlatformMakeContextCurrent(_GLFWwindow* window)
{
    if (window)
    {
        if (!glXMakeCurrent(_glfw.x11.display,
                            window->context.glx.window,
                            window->context.glx.handle))
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "GLX: Failed to make context current");
            return;
        }
    }
    else
    {
        if (!glXMakeCurrent(_glfw.x11.display, None, NULL))
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "GLX: Failed to clear current context");
            return;
        }
    }

    _glfwPlatformSetCurrentContext(window);
}

void _glfwPlatformSwapBuffers(_GLFWwindow* window)
{
    glXSwapBuffers(_glfw.x11.display, window->context.glx.window);
}

void _glfwPlatformSwapInterval(int interval)
{
    _GLFWwindow* window = _glfwPlatformGetCurrentContext();

    if (_glfw.glx.EXT_swap_control)
    {
        _glfw.glx.SwapIntervalEXT(_glfw.x11.display,
                                  window->context.glx.window,
                                  interval);
    }
    else if (_glfw.glx.MESA_swap_control)
        _glfw.glx.SwapIntervalMESA(interval);
    else if (_glfw.glx.SGI_swap_control)
    {
        if (interval > 0)
            _glfw.glx.SwapIntervalSGI(interval);
    }
}

int _glfwPlatformExtensionSupported(const char* extension)
{
    const char* extensions =
        glXQueryExtensionsString(_glfw.x11.display, _glfw.x11.screen);
    if (extensions)
    {
        if (_glfwStringInExtensionString(extension, extensions))
            return GLFW_TRUE;
    }

    return GLFW_FALSE;
}

GLFWglproc _glfwPlatformGetProcAddress(const char* procname)
{
    if (_glfw.glx.GetProcAddress)
        return _glfw.glx.GetProcAddress((const GLubyte*) procname);
    else if (_glfw.glx.GetProcAddressARB)
        return _glfw.glx.GetProcAddressARB((const GLubyte*) procname);
    else
        return dlsym(_glfw.glx.handle, procname);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI GLXContext glfwGetGLXContext(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (window->context.api == GLFW_NO_API)
    {
        _glfwInputError(GLFW_NO_WINDOW_CONTEXT, NULL);
        return NULL;
    }

    return window->context.glx.handle;
}

GLFWAPI GLXWindow glfwGetGLXWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(None);

    if (window->context.api == GLFW_NO_API)
    {
        _glfwInputError(GLFW_NO_WINDOW_CONTEXT, NULL);
        return None;
    }

    return window->context.glx.window;
}

