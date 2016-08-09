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

#include "internal.h"

#include <stdlib.h>
#include <malloc.h>
#include <assert.h>


// Initialize WGL-specific extensions
//
static void loadExtensions(void)
{
    // Functions for WGL_EXT_extension_string
    // NOTE: These are needed by _glfwPlatformExtensionSupported
    _glfw.wgl.GetExtensionsStringEXT = (PFNWGLGETEXTENSIONSSTRINGEXTPROC)
        wglGetProcAddress("wglGetExtensionsStringEXT");
    _glfw.wgl.GetExtensionsStringARB = (PFNWGLGETEXTENSIONSSTRINGARBPROC)
        wglGetProcAddress("wglGetExtensionsStringARB");

    // Functions for WGL_ARB_create_context
    _glfw.wgl.CreateContextAttribsARB = (PFNWGLCREATECONTEXTATTRIBSARBPROC)
        wglGetProcAddress("wglCreateContextAttribsARB");

    // Functions for WGL_EXT_swap_control
    _glfw.wgl.SwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC)
        wglGetProcAddress("wglSwapIntervalEXT");

    // Functions for WGL_ARB_pixel_format
    _glfw.wgl.GetPixelFormatAttribivARB = (PFNWGLGETPIXELFORMATATTRIBIVARBPROC)
        wglGetProcAddress("wglGetPixelFormatAttribivARB");

    // This needs to include every extension used below except for
    // WGL_ARB_extensions_string and WGL_EXT_extensions_string
    _glfw.wgl.ARB_multisample =
        _glfwPlatformExtensionSupported("WGL_ARB_multisample");
    _glfw.wgl.ARB_framebuffer_sRGB =
        _glfwPlatformExtensionSupported("WGL_ARB_framebuffer_sRGB");
    _glfw.wgl.EXT_framebuffer_sRGB =
        _glfwPlatformExtensionSupported("WGL_EXT_framebuffer_sRGB");
    _glfw.wgl.ARB_create_context =
        _glfwPlatformExtensionSupported("WGL_ARB_create_context");
    _glfw.wgl.ARB_create_context_profile =
        _glfwPlatformExtensionSupported("WGL_ARB_create_context_profile");
    _glfw.wgl.EXT_create_context_es2_profile =
        _glfwPlatformExtensionSupported("WGL_EXT_create_context_es2_profile");
    _glfw.wgl.ARB_create_context_robustness =
        _glfwPlatformExtensionSupported("WGL_ARB_create_context_robustness");
    _glfw.wgl.EXT_swap_control =
        _glfwPlatformExtensionSupported("WGL_EXT_swap_control");
    _glfw.wgl.ARB_pixel_format =
        _glfwPlatformExtensionSupported("WGL_ARB_pixel_format");
    _glfw.wgl.ARB_context_flush_control =
        _glfwPlatformExtensionSupported("WGL_ARB_context_flush_control");

    _glfw.wgl.extensionsLoaded = GLFW_TRUE;
}

// Returns the specified attribute of the specified pixel format
//
static int getPixelFormatAttrib(_GLFWwindow* window, int pixelFormat, int attrib)
{
    int value = 0;

    assert(_glfw.wgl.ARB_pixel_format);

    if (!_glfw.wgl.GetPixelFormatAttribivARB(window->context.wgl.dc,
                                             pixelFormat,
                                             0, 1, &attrib, &value))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "WGL: Failed to retrieve pixel format attribute %i",
                        attrib);
        return 0;
    }

    return value;
}

// Return a list of available and usable framebuffer configs
//
static GLFWbool choosePixelFormat(_GLFWwindow* window,
                                  const _GLFWfbconfig* desired,
                                  int* result)
{
    _GLFWfbconfig* usableConfigs;
    const _GLFWfbconfig* closest;
    int i, nativeCount, usableCount;

    if (_glfw.wgl.ARB_pixel_format)
    {
        nativeCount = getPixelFormatAttrib(window,
                                         1,
                                         WGL_NUMBER_PIXEL_FORMATS_ARB);
    }
    else
    {
        nativeCount = DescribePixelFormat(window->context.wgl.dc,
                                          1,
                                          sizeof(PIXELFORMATDESCRIPTOR),
                                          NULL);
    }

    usableConfigs = calloc(nativeCount, sizeof(_GLFWfbconfig));
    usableCount = 0;

    for (i = 0;  i < nativeCount;  i++)
    {
        const int n = i + 1;
        _GLFWfbconfig* u = usableConfigs + usableCount;

        if (_glfw.wgl.ARB_pixel_format)
        {
            // Get pixel format attributes through "modern" extension

            if (!getPixelFormatAttrib(window, n, WGL_SUPPORT_OPENGL_ARB) ||
                !getPixelFormatAttrib(window, n, WGL_DRAW_TO_WINDOW_ARB))
            {
                continue;
            }

            if (getPixelFormatAttrib(window, n, WGL_PIXEL_TYPE_ARB) !=
                WGL_TYPE_RGBA_ARB)
            {
                continue;
            }

            if (getPixelFormatAttrib(window, n, WGL_ACCELERATION_ARB) ==
                 WGL_NO_ACCELERATION_ARB)
            {
                continue;
            }

            u->redBits = getPixelFormatAttrib(window, n, WGL_RED_BITS_ARB);
            u->greenBits = getPixelFormatAttrib(window, n, WGL_GREEN_BITS_ARB);
            u->blueBits = getPixelFormatAttrib(window, n, WGL_BLUE_BITS_ARB);
            u->alphaBits = getPixelFormatAttrib(window, n, WGL_ALPHA_BITS_ARB);

            u->depthBits = getPixelFormatAttrib(window, n, WGL_DEPTH_BITS_ARB);
            u->stencilBits = getPixelFormatAttrib(window, n, WGL_STENCIL_BITS_ARB);

            u->accumRedBits = getPixelFormatAttrib(window, n, WGL_ACCUM_RED_BITS_ARB);
            u->accumGreenBits = getPixelFormatAttrib(window, n, WGL_ACCUM_GREEN_BITS_ARB);
            u->accumBlueBits = getPixelFormatAttrib(window, n, WGL_ACCUM_BLUE_BITS_ARB);
            u->accumAlphaBits = getPixelFormatAttrib(window, n, WGL_ACCUM_ALPHA_BITS_ARB);

            u->auxBuffers = getPixelFormatAttrib(window, n, WGL_AUX_BUFFERS_ARB);

            if (getPixelFormatAttrib(window, n, WGL_STEREO_ARB))
                u->stereo = GLFW_TRUE;
            if (getPixelFormatAttrib(window, n, WGL_DOUBLE_BUFFER_ARB))
                u->doublebuffer = GLFW_TRUE;

            if (_glfw.wgl.ARB_multisample)
                u->samples = getPixelFormatAttrib(window, n, WGL_SAMPLES_ARB);

            if (_glfw.wgl.ARB_framebuffer_sRGB ||
                _glfw.wgl.EXT_framebuffer_sRGB)
            {
                if (getPixelFormatAttrib(window, n, WGL_FRAMEBUFFER_SRGB_CAPABLE_ARB))
                    u->sRGB = GLFW_TRUE;
            }
        }
        else
        {
            PIXELFORMATDESCRIPTOR pfd;

            // Get pixel format attributes through legacy PFDs

            if (!DescribePixelFormat(window->context.wgl.dc,
                                     n,
                                     sizeof(PIXELFORMATDESCRIPTOR),
                                     &pfd))
            {
                continue;
            }

            if (!(pfd.dwFlags & PFD_DRAW_TO_WINDOW) ||
                !(pfd.dwFlags & PFD_SUPPORT_OPENGL))
            {
                continue;
            }

            if (!(pfd.dwFlags & PFD_GENERIC_ACCELERATED) &&
                (pfd.dwFlags & PFD_GENERIC_FORMAT))
            {
                continue;
            }

            if (pfd.iPixelType != PFD_TYPE_RGBA)
                continue;

            u->redBits = pfd.cRedBits;
            u->greenBits = pfd.cGreenBits;
            u->blueBits = pfd.cBlueBits;
            u->alphaBits = pfd.cAlphaBits;

            u->depthBits = pfd.cDepthBits;
            u->stencilBits = pfd.cStencilBits;

            u->accumRedBits = pfd.cAccumRedBits;
            u->accumGreenBits = pfd.cAccumGreenBits;
            u->accumBlueBits = pfd.cAccumBlueBits;
            u->accumAlphaBits = pfd.cAccumAlphaBits;

            u->auxBuffers = pfd.cAuxBuffers;

            if (pfd.dwFlags & PFD_STEREO)
                u->stereo = GLFW_TRUE;
            if (pfd.dwFlags & PFD_DOUBLEBUFFER)
                u->doublebuffer = GLFW_TRUE;
        }

        u->wgl = n;
        usableCount++;
    }

    if (!usableCount)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "WGL: The driver does not appear to support OpenGL");

        free(usableConfigs);
        return GLFW_FALSE;
    }

    closest = _glfwChooseFBConfig(desired, usableConfigs, usableCount);
    if (!closest)
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "WGL: Failed to find a suitable pixel format");

        free(usableConfigs);
        return GLFW_FALSE;
    }

    *result = closest->wgl;
    free(usableConfigs);

    return GLFW_TRUE;
}

// Returns whether desktop compositing is enabled
//
static GLFWbool isCompositionEnabled(void)
{
    BOOL enabled;

    if (!_glfw_DwmIsCompositionEnabled)
        return FALSE;

    if (_glfw_DwmIsCompositionEnabled(&enabled) != S_OK)
        return FALSE;

    return enabled;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize WGL
//
GLFWbool _glfwInitWGL(void)
{
    _glfw.wgl.instance = LoadLibraryA("opengl32.dll");
    if (!_glfw.wgl.instance)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "WGL: Failed to load opengl32.dll");
        return GLFW_FALSE;
    }

    _glfw.wgl.CreateContext = (WGLCREATECONTEXT_T)
        GetProcAddress(_glfw.wgl.instance, "wglCreateContext");
    _glfw.wgl.DeleteContext = (WGLDELETECONTEXT_T)
        GetProcAddress(_glfw.wgl.instance, "wglDeleteContext");
    _glfw.wgl.GetProcAddress = (WGLGETPROCADDRESS_T)
        GetProcAddress(_glfw.wgl.instance, "wglGetProcAddress");
    _glfw.wgl.MakeCurrent = (WGLMAKECURRENT_T)
        GetProcAddress(_glfw.wgl.instance, "wglMakeCurrent");
    _glfw.wgl.ShareLists = (WGLSHARELISTS_T)
        GetProcAddress(_glfw.wgl.instance, "wglShareLists");

    return GLFW_TRUE;
}

// Terminate WGL
//
void _glfwTerminateWGL(void)
{
    if (_glfw.wgl.instance)
        FreeLibrary(_glfw.wgl.instance);
}

#define setWGLattrib(attribName, attribValue) \
{ \
    attribs[index++] = attribName; \
    attribs[index++] = attribValue; \
    assert((size_t) index < sizeof(attribs) / sizeof(attribs[0])); \
}

// Create the OpenGL or OpenGL ES context
//
GLFWbool _glfwCreateContextWGL(_GLFWwindow* window,
                               const _GLFWctxconfig* ctxconfig,
                               const _GLFWfbconfig* fbconfig)
{
    int attribs[40];
    int pixelFormat = 0;
    PIXELFORMATDESCRIPTOR pfd;
    HGLRC share = NULL;

    if (ctxconfig->api == GLFW_NO_API)
        return GLFW_TRUE;

    if (ctxconfig->share)
        share = ctxconfig->share->context.wgl.handle;

    window->context.wgl.dc = GetDC(window->win32.handle);
    if (!window->context.wgl.dc)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "WGL: Failed to retrieve DC for window");
        return GLFW_FALSE;
    }

    if (!choosePixelFormat(window, fbconfig, &pixelFormat))
        return GLFW_FALSE;

    if (!DescribePixelFormat(window->context.wgl.dc,
                             pixelFormat, sizeof(pfd), &pfd))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "WGL: Failed to retrieve PFD for selected pixel format");
        return GLFW_FALSE;
    }

    if (!SetPixelFormat(window->context.wgl.dc, pixelFormat, &pfd))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "WGL: Failed to set selected pixel format");
        return GLFW_FALSE;
    }

    if (_glfw.wgl.ARB_create_context)
    {
        int index = 0, mask = 0, flags = 0;

        if (ctxconfig->api == GLFW_OPENGL_API)
        {
            if (ctxconfig->forward)
                flags |= WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB;

            if (ctxconfig->profile == GLFW_OPENGL_CORE_PROFILE)
                mask |= WGL_CONTEXT_CORE_PROFILE_BIT_ARB;
            else if (ctxconfig->profile == GLFW_OPENGL_COMPAT_PROFILE)
                mask |= WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB;
        }
        else
            mask |= WGL_CONTEXT_ES2_PROFILE_BIT_EXT;

        if (ctxconfig->debug)
            flags |= WGL_CONTEXT_DEBUG_BIT_ARB;
        if (ctxconfig->noerror)
            flags |= GL_CONTEXT_FLAG_NO_ERROR_BIT_KHR;

        if (ctxconfig->robustness)
        {
            if (_glfw.wgl.ARB_create_context_robustness)
            {
                if (ctxconfig->robustness == GLFW_NO_RESET_NOTIFICATION)
                {
                    setWGLattrib(WGL_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB,
                                 WGL_NO_RESET_NOTIFICATION_ARB);
                }
                else if (ctxconfig->robustness == GLFW_LOSE_CONTEXT_ON_RESET)
                {
                    setWGLattrib(WGL_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB,
                                 WGL_LOSE_CONTEXT_ON_RESET_ARB);
                }

                flags |= WGL_CONTEXT_ROBUST_ACCESS_BIT_ARB;
            }
        }

        if (ctxconfig->release)
        {
            if (_glfw.wgl.ARB_context_flush_control)
            {
                if (ctxconfig->release == GLFW_RELEASE_BEHAVIOR_NONE)
                {
                    setWGLattrib(WGL_CONTEXT_RELEASE_BEHAVIOR_ARB,
                                 WGL_CONTEXT_RELEASE_BEHAVIOR_NONE_ARB);
                }
                else if (ctxconfig->release == GLFW_RELEASE_BEHAVIOR_FLUSH)
                {
                    setWGLattrib(WGL_CONTEXT_RELEASE_BEHAVIOR_ARB,
                                 WGL_CONTEXT_RELEASE_BEHAVIOR_FLUSH_ARB);
                }
            }
        }

        // NOTE: Only request an explicitly versioned context when necessary, as
        //       explicitly requesting version 1.0 does not always return the
        //       highest version supported by the driver
        if (ctxconfig->major != 1 || ctxconfig->minor != 0)
        {
            setWGLattrib(WGL_CONTEXT_MAJOR_VERSION_ARB, ctxconfig->major);
            setWGLattrib(WGL_CONTEXT_MINOR_VERSION_ARB, ctxconfig->minor);
        }

        if (flags)
            setWGLattrib(WGL_CONTEXT_FLAGS_ARB, flags);

        if (mask)
            setWGLattrib(WGL_CONTEXT_PROFILE_MASK_ARB, mask);

        setWGLattrib(0, 0);

        window->context.wgl.handle =
            _glfw.wgl.CreateContextAttribsARB(window->context.wgl.dc,
                                              share, attribs);
        if (!window->context.wgl.handle)
        {
            _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                            "WGL: Failed to create OpenGL context");
            return GLFW_FALSE;
        }
    }
    else
    {
        window->context.wgl.handle = wglCreateContext(window->context.wgl.dc);
        if (!window->context.wgl.handle)
        {
            _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                            "WGL: Failed to create OpenGL context");
            return GLFW_FALSE;
        }

        if (share)
        {
            if (!wglShareLists(share, window->context.wgl.handle))
            {
                _glfwInputError(GLFW_PLATFORM_ERROR,
                                "WGL: Failed to enable sharing with specified OpenGL context");
                return GLFW_FALSE;
            }
        }
    }

    return GLFW_TRUE;
}

#undef setWGLattrib

// Destroy the OpenGL context
//
void _glfwDestroyContextWGL(_GLFWwindow* window)
{
    if (window->context.wgl.handle)
    {
        wglDeleteContext(window->context.wgl.handle);
        window->context.wgl.handle = NULL;
    }
}

// Analyzes the specified context for possible recreation
//
int _glfwAnalyzeContextWGL(_GLFWwindow* window,
                           const _GLFWctxconfig* ctxconfig,
                           const _GLFWfbconfig* fbconfig)
{
    GLFWbool required = GLFW_FALSE;

    if (_glfw.wgl.extensionsLoaded)
        return _GLFW_RECREATION_NOT_NEEDED;

    _glfwPlatformMakeContextCurrent(window);
    loadExtensions();

    if (ctxconfig->api == GLFW_OPENGL_API)
    {
        if (ctxconfig->forward)
        {
            if (!_glfw.wgl.ARB_create_context)
            {
                _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                                "WGL: A forward compatible OpenGL context requested but WGL_ARB_create_context is unavailable");
                return _GLFW_RECREATION_IMPOSSIBLE;
            }

            required = GLFW_TRUE;
        }

        if (ctxconfig->profile)
        {
            if (!_glfw.wgl.ARB_create_context_profile)
            {
                _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                                "WGL: OpenGL profile requested but WGL_ARB_create_context_profile is unavailable");
                return _GLFW_RECREATION_IMPOSSIBLE;
            }

            required = GLFW_TRUE;
        }

        if (ctxconfig->release)
        {
            if (_glfw.wgl.ARB_context_flush_control)
                required = GLFW_TRUE;
        }
    }
    else
    {
        if (!_glfw.wgl.ARB_create_context ||
            !_glfw.wgl.ARB_create_context_profile ||
            !_glfw.wgl.EXT_create_context_es2_profile)
        {
            _glfwInputError(GLFW_API_UNAVAILABLE,
                            "WGL: OpenGL ES requested but WGL_ARB_create_context_es2_profile is unavailable");
            return _GLFW_RECREATION_IMPOSSIBLE;
        }

        required = GLFW_TRUE;
    }

    if (ctxconfig->major != 1 || ctxconfig->minor != 0)
    {
        if (_glfw.wgl.ARB_create_context)
            required = GLFW_TRUE;
    }

    if (ctxconfig->debug)
    {
        if (_glfw.wgl.ARB_create_context)
            required = GLFW_TRUE;
    }

    if (fbconfig->samples > 0)
    {
        // MSAA is not a hard constraint, so do nothing if it's not supported
        if (_glfw.wgl.ARB_multisample && _glfw.wgl.ARB_pixel_format)
            required = GLFW_TRUE;
    }

    if (fbconfig->sRGB)
    {
        // sRGB is not a hard constraint, so do nothing if it's not supported
        if ((_glfw.wgl.ARB_framebuffer_sRGB ||
             _glfw.wgl.EXT_framebuffer_sRGB) &&
            _glfw.wgl.ARB_pixel_format)
        {
            required = GLFW_TRUE;
        }
    }

    if (required)
        return _GLFW_RECREATION_REQUIRED;

    return _GLFW_RECREATION_NOT_NEEDED;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwPlatformMakeContextCurrent(_GLFWwindow* window)
{
    if (window)
    {
        if (wglMakeCurrent(window->context.wgl.dc, window->context.wgl.handle))
            _glfwPlatformSetCurrentContext(window);
        else
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "WGL: Failed to make context current");
            _glfwPlatformSetCurrentContext(NULL);
        }
    }
    else
    {
        if (!wglMakeCurrent(NULL, NULL))
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "WGL: Failed to clear current context");
        }

        _glfwPlatformSetCurrentContext(NULL);
    }
}

void _glfwPlatformSwapBuffers(_GLFWwindow* window)
{
    // HACK: Use DwmFlush when desktop composition is enabled
    if (isCompositionEnabled() && !window->monitor)
    {
        int count = abs(window->context.wgl.interval);
        while (count--)
            _glfw_DwmFlush();
    }

    SwapBuffers(window->context.wgl.dc);
}

void _glfwPlatformSwapInterval(int interval)
{
    _GLFWwindow* window = _glfwPlatformGetCurrentContext();

    window->context.wgl.interval = interval;

    // HACK: Disable WGL swap interval when desktop composition is enabled to
    //       avoid interfering with DWM vsync
    if (isCompositionEnabled() && !window->monitor)
        interval = 0;

    if (_glfw.wgl.EXT_swap_control)
        _glfw.wgl.SwapIntervalEXT(interval);
}

int _glfwPlatformExtensionSupported(const char* extension)
{
    const char* extensions;

    _GLFWwindow* window = _glfwPlatformGetCurrentContext();

    if (_glfw.wgl.GetExtensionsStringEXT)
    {
        extensions = _glfw.wgl.GetExtensionsStringEXT();
        if (extensions)
        {
            if (_glfwStringInExtensionString(extension, extensions))
                return GLFW_TRUE;
        }
    }

    if (_glfw.wgl.GetExtensionsStringARB)
    {
        extensions = _glfw.wgl.GetExtensionsStringARB(window->context.wgl.dc);
        if (extensions)
        {
            if (_glfwStringInExtensionString(extension, extensions))
                return GLFW_TRUE;
        }
    }

    return GLFW_FALSE;
}

GLFWglproc _glfwPlatformGetProcAddress(const char* procname)
{
    const GLFWglproc proc = (GLFWglproc) wglGetProcAddress(procname);
    if (proc)
        return proc;

    return (GLFWglproc) GetProcAddress(_glfw.wgl.instance, procname);
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI HGLRC glfwGetWGLContext(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);

    if (window->context.api == GLFW_NO_API)
    {
        _glfwInputError(GLFW_NO_WINDOW_CONTEXT, NULL);
        return NULL;
    }

    return window->context.wgl.handle;
}

