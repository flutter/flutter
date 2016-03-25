//========================================================================
// GLFW 3.2 OS X - www.glfw.org
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

#include "internal.h"


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize OpenGL support
//
GLFWbool _glfwInitNSGL(void)
{
    _glfw.nsgl.framework =
        CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl"));
    if (_glfw.nsgl.framework == NULL)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "NSGL: Failed to locate OpenGL framework");
        return GLFW_FALSE;
    }

    return GLFW_TRUE;
}

// Terminate OpenGL support
//
void _glfwTerminateNSGL(void)
{
}

// Create the OpenGL context
//
GLFWbool _glfwCreateContextNSGL(_GLFWwindow* window,
                                const _GLFWctxconfig* ctxconfig,
                                const _GLFWfbconfig* fbconfig)
{
    unsigned int attributeCount = 0;

    if (ctxconfig->api == GLFW_OPENGL_ES_API)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "NSGL: OpenGL ES is not available on OS X");
        return GLFW_FALSE;
    }

    if (ctxconfig->major == 3 && ctxconfig->minor < 2)
    {
        _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                        "NSGL: The targeted version of OS X does not support OpenGL 3.0 or 3.1");
        return GLFW_FALSE;
    }

    if (ctxconfig->major > 2)
    {
        if (!ctxconfig->forward)
        {
            _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                            "NSGL: The targeted version of OS X only supports forward-compatible contexts for OpenGL 3.2 and above");
            return GLFW_FALSE;
        }

        if (ctxconfig->profile != GLFW_OPENGL_CORE_PROFILE)
        {
            _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                            "NSGL: The targeted version of OS X only supports core profile contexts for OpenGL 3.2 and above");
            return GLFW_FALSE;
        }
    }

    // Context robustness modes (GL_KHR_robustness) are not yet supported on
    // OS X but are not a hard constraint, so ignore and continue

    // Context release behaviors (GL_KHR_context_flush_control) are not yet
    // supported on OS X but are not a hard constraint, so ignore and continue

#define ADD_ATTR(x) { attributes[attributeCount++] = x; }
#define ADD_ATTR2(x, y) { ADD_ATTR(x); ADD_ATTR(y); }

    // Arbitrary array size here
    NSOpenGLPixelFormatAttribute attributes[40];

    ADD_ATTR(NSOpenGLPFAAccelerated);
    ADD_ATTR(NSOpenGLPFAClosestPolicy);

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101000
    if (ctxconfig->major >= 4)
    {
        ADD_ATTR2(NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core);
    }
    else
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/
    if (ctxconfig->major >= 3)
    {
        ADD_ATTR2(NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core);
    }

    if (ctxconfig->major <= 2)
    {
        if (fbconfig->auxBuffers != GLFW_DONT_CARE)
            ADD_ATTR2(NSOpenGLPFAAuxBuffers, fbconfig->auxBuffers);

        if (fbconfig->accumRedBits != GLFW_DONT_CARE &&
            fbconfig->accumGreenBits != GLFW_DONT_CARE &&
            fbconfig->accumBlueBits != GLFW_DONT_CARE &&
            fbconfig->accumAlphaBits != GLFW_DONT_CARE)
        {
            const int accumBits = fbconfig->accumRedBits +
                                  fbconfig->accumGreenBits +
                                  fbconfig->accumBlueBits +
                                  fbconfig->accumAlphaBits;

            ADD_ATTR2(NSOpenGLPFAAccumSize, accumBits);
        }
    }

    if (fbconfig->redBits != GLFW_DONT_CARE &&
        fbconfig->greenBits != GLFW_DONT_CARE &&
        fbconfig->blueBits != GLFW_DONT_CARE)
    {
        int colorBits = fbconfig->redBits +
                        fbconfig->greenBits +
                        fbconfig->blueBits;

        // OS X needs non-zero color size, so set reasonable values
        if (colorBits == 0)
            colorBits = 24;
        else if (colorBits < 15)
            colorBits = 15;

        ADD_ATTR2(NSOpenGLPFAColorSize, colorBits);
    }

    if (fbconfig->alphaBits != GLFW_DONT_CARE)
        ADD_ATTR2(NSOpenGLPFAAlphaSize, fbconfig->alphaBits);

    if (fbconfig->depthBits != GLFW_DONT_CARE)
        ADD_ATTR2(NSOpenGLPFADepthSize, fbconfig->depthBits);

    if (fbconfig->stencilBits != GLFW_DONT_CARE)
        ADD_ATTR2(NSOpenGLPFAStencilSize, fbconfig->stencilBits);

    if (fbconfig->stereo)
        ADD_ATTR(NSOpenGLPFAStereo);

    if (fbconfig->doublebuffer)
        ADD_ATTR(NSOpenGLPFADoubleBuffer);

    if (fbconfig->samples != GLFW_DONT_CARE)
    {
        if (fbconfig->samples == 0)
        {
            ADD_ATTR2(NSOpenGLPFASampleBuffers, 0);
        }
        else
        {
            ADD_ATTR2(NSOpenGLPFASampleBuffers, 1);
            ADD_ATTR2(NSOpenGLPFASamples, fbconfig->samples);
        }
    }

    // NOTE: All NSOpenGLPixelFormats on the relevant cards support sRGB
    //       framebuffer, so there's no need (and no way) to request it

    ADD_ATTR(0);

#undef ADD_ATTR
#undef ADD_ATTR2

    window->context.nsgl.pixelFormat =
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    if (window->context.nsgl.pixelFormat == nil)
    {
        _glfwInputError(GLFW_FORMAT_UNAVAILABLE,
                        "NSGL: Failed to find a suitable pixel format");
        return GLFW_FALSE;
    }

    NSOpenGLContext* share = NULL;

    if (ctxconfig->share)
        share = ctxconfig->share->context.nsgl.object;

    window->context.nsgl.object =
        [[NSOpenGLContext alloc] initWithFormat:window->context.nsgl.pixelFormat
                                   shareContext:share];
    if (window->context.nsgl.object == nil)
    {
        _glfwInputError(GLFW_VERSION_UNAVAILABLE,
                        "NSGL: Failed to create OpenGL context");
        return GLFW_FALSE;
    }

    [window->context.nsgl.object setView:window->ns.view];
    return GLFW_TRUE;
}

// Destroy the OpenGL context
//
void _glfwDestroyContextNSGL(_GLFWwindow* window)
{
    [window->context.nsgl.pixelFormat release];
    window->context.nsgl.pixelFormat = nil;

    [window->context.nsgl.object release];
    window->context.nsgl.object = nil;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwPlatformMakeContextCurrent(_GLFWwindow* window)
{
    if (window)
        [window->context.nsgl.object makeCurrentContext];
    else
        [NSOpenGLContext clearCurrentContext];

    _glfwPlatformSetCurrentContext(window);
}

void _glfwPlatformSwapBuffers(_GLFWwindow* window)
{
    // ARP appears to be unnecessary, but this is future-proof
    [window->context.nsgl.object flushBuffer];
}

void _glfwPlatformSwapInterval(int interval)
{
    _GLFWwindow* window = _glfwPlatformGetCurrentContext();

    GLint sync = interval;
    [window->context.nsgl.object setValues:&sync
                              forParameter:NSOpenGLCPSwapInterval];
}

int _glfwPlatformExtensionSupported(const char* extension)
{
    // There are no NSGL extensions
    return GLFW_FALSE;
}

GLFWglproc _glfwPlatformGetProcAddress(const char* procname)
{
    CFStringRef symbolName = CFStringCreateWithCString(kCFAllocatorDefault,
                                                       procname,
                                                       kCFStringEncodingASCII);

    GLFWglproc symbol = CFBundleGetFunctionPointerForName(_glfw.nsgl.framework,
                                                          symbolName);

    CFRelease(symbolName);

    return symbol;
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI id glfwGetNSGLContext(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(nil);

    if (window->context.api == GLFW_NO_API)
    {
        _glfwInputError(GLFW_NO_WINDOW_CONTEXT, NULL);
        return NULL;
    }

    return window->context.nsgl.object;
}

