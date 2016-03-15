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

#include "internal.h"
#include <sys/param.h> // For MAXPATHLEN


#if defined(_GLFW_USE_CHDIR)

// Change to our application bundle's resources directory, if present
//
static void changeToResourcesDirectory(void)
{
    char resourcesPath[MAXPATHLEN];

    CFBundleRef bundle = CFBundleGetMainBundle();
    if (!bundle)
        return;

    CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(bundle);

    CFStringRef last = CFURLCopyLastPathComponent(resourcesURL);
    if (CFStringCompare(CFSTR("Resources"), last, 0) != kCFCompareEqualTo)
    {
        CFRelease(last);
        CFRelease(resourcesURL);
        return;
    }

    CFRelease(last);

    if (!CFURLGetFileSystemRepresentation(resourcesURL,
                                          true,
                                          (UInt8*) resourcesPath,
                                          MAXPATHLEN))
    {
        CFRelease(resourcesURL);
        return;
    }

    CFRelease(resourcesURL);

    chdir(resourcesPath);
}

#endif /* _GLFW_USE_CHDIR */

// Create key code translation tables
//
static void createKeyTables(void)
{
    memset(_glfw.ns.publicKeys, -1, sizeof(_glfw.ns.publicKeys));

    _glfw.ns.publicKeys[0x1D] = GLFW_KEY_0;
    _glfw.ns.publicKeys[0x12] = GLFW_KEY_1;
    _glfw.ns.publicKeys[0x13] = GLFW_KEY_2;
    _glfw.ns.publicKeys[0x14] = GLFW_KEY_3;
    _glfw.ns.publicKeys[0x15] = GLFW_KEY_4;
    _glfw.ns.publicKeys[0x17] = GLFW_KEY_5;
    _glfw.ns.publicKeys[0x16] = GLFW_KEY_6;
    _glfw.ns.publicKeys[0x1A] = GLFW_KEY_7;
    _glfw.ns.publicKeys[0x1C] = GLFW_KEY_8;
    _glfw.ns.publicKeys[0x19] = GLFW_KEY_9;
    _glfw.ns.publicKeys[0x00] = GLFW_KEY_A;
    _glfw.ns.publicKeys[0x0B] = GLFW_KEY_B;
    _glfw.ns.publicKeys[0x08] = GLFW_KEY_C;
    _glfw.ns.publicKeys[0x02] = GLFW_KEY_D;
    _glfw.ns.publicKeys[0x0E] = GLFW_KEY_E;
    _glfw.ns.publicKeys[0x03] = GLFW_KEY_F;
    _glfw.ns.publicKeys[0x05] = GLFW_KEY_G;
    _glfw.ns.publicKeys[0x04] = GLFW_KEY_H;
    _glfw.ns.publicKeys[0x22] = GLFW_KEY_I;
    _glfw.ns.publicKeys[0x26] = GLFW_KEY_J;
    _glfw.ns.publicKeys[0x28] = GLFW_KEY_K;
    _glfw.ns.publicKeys[0x25] = GLFW_KEY_L;
    _glfw.ns.publicKeys[0x2E] = GLFW_KEY_M;
    _glfw.ns.publicKeys[0x2D] = GLFW_KEY_N;
    _glfw.ns.publicKeys[0x1F] = GLFW_KEY_O;
    _glfw.ns.publicKeys[0x23] = GLFW_KEY_P;
    _glfw.ns.publicKeys[0x0C] = GLFW_KEY_Q;
    _glfw.ns.publicKeys[0x0F] = GLFW_KEY_R;
    _glfw.ns.publicKeys[0x01] = GLFW_KEY_S;
    _glfw.ns.publicKeys[0x11] = GLFW_KEY_T;
    _glfw.ns.publicKeys[0x20] = GLFW_KEY_U;
    _glfw.ns.publicKeys[0x09] = GLFW_KEY_V;
    _glfw.ns.publicKeys[0x0D] = GLFW_KEY_W;
    _glfw.ns.publicKeys[0x07] = GLFW_KEY_X;
    _glfw.ns.publicKeys[0x10] = GLFW_KEY_Y;
    _glfw.ns.publicKeys[0x06] = GLFW_KEY_Z;

    _glfw.ns.publicKeys[0x27] = GLFW_KEY_APOSTROPHE;
    _glfw.ns.publicKeys[0x2A] = GLFW_KEY_BACKSLASH;
    _glfw.ns.publicKeys[0x2B] = GLFW_KEY_COMMA;
    _glfw.ns.publicKeys[0x18] = GLFW_KEY_EQUAL;
    _glfw.ns.publicKeys[0x32] = GLFW_KEY_GRAVE_ACCENT;
    _glfw.ns.publicKeys[0x21] = GLFW_KEY_LEFT_BRACKET;
    _glfw.ns.publicKeys[0x1B] = GLFW_KEY_MINUS;
    _glfw.ns.publicKeys[0x2F] = GLFW_KEY_PERIOD;
    _glfw.ns.publicKeys[0x1E] = GLFW_KEY_RIGHT_BRACKET;
    _glfw.ns.publicKeys[0x29] = GLFW_KEY_SEMICOLON;
    _glfw.ns.publicKeys[0x2C] = GLFW_KEY_SLASH;
    _glfw.ns.publicKeys[0x0A] = GLFW_KEY_WORLD_1;

    _glfw.ns.publicKeys[0x33] = GLFW_KEY_BACKSPACE;
    _glfw.ns.publicKeys[0x39] = GLFW_KEY_CAPS_LOCK;
    _glfw.ns.publicKeys[0x75] = GLFW_KEY_DELETE;
    _glfw.ns.publicKeys[0x7D] = GLFW_KEY_DOWN;
    _glfw.ns.publicKeys[0x77] = GLFW_KEY_END;
    _glfw.ns.publicKeys[0x24] = GLFW_KEY_ENTER;
    _glfw.ns.publicKeys[0x35] = GLFW_KEY_ESCAPE;
    _glfw.ns.publicKeys[0x7A] = GLFW_KEY_F1;
    _glfw.ns.publicKeys[0x78] = GLFW_KEY_F2;
    _glfw.ns.publicKeys[0x63] = GLFW_KEY_F3;
    _glfw.ns.publicKeys[0x76] = GLFW_KEY_F4;
    _glfw.ns.publicKeys[0x60] = GLFW_KEY_F5;
    _glfw.ns.publicKeys[0x61] = GLFW_KEY_F6;
    _glfw.ns.publicKeys[0x62] = GLFW_KEY_F7;
    _glfw.ns.publicKeys[0x64] = GLFW_KEY_F8;
    _glfw.ns.publicKeys[0x65] = GLFW_KEY_F9;
    _glfw.ns.publicKeys[0x6D] = GLFW_KEY_F10;
    _glfw.ns.publicKeys[0x67] = GLFW_KEY_F11;
    _glfw.ns.publicKeys[0x6F] = GLFW_KEY_F12;
    _glfw.ns.publicKeys[0x69] = GLFW_KEY_F13;
    _glfw.ns.publicKeys[0x6B] = GLFW_KEY_F14;
    _glfw.ns.publicKeys[0x71] = GLFW_KEY_F15;
    _glfw.ns.publicKeys[0x6A] = GLFW_KEY_F16;
    _glfw.ns.publicKeys[0x40] = GLFW_KEY_F17;
    _glfw.ns.publicKeys[0x4F] = GLFW_KEY_F18;
    _glfw.ns.publicKeys[0x50] = GLFW_KEY_F19;
    _glfw.ns.publicKeys[0x5A] = GLFW_KEY_F20;
    _glfw.ns.publicKeys[0x73] = GLFW_KEY_HOME;
    _glfw.ns.publicKeys[0x72] = GLFW_KEY_INSERT;
    _glfw.ns.publicKeys[0x7B] = GLFW_KEY_LEFT;
    _glfw.ns.publicKeys[0x3A] = GLFW_KEY_LEFT_ALT;
    _glfw.ns.publicKeys[0x3B] = GLFW_KEY_LEFT_CONTROL;
    _glfw.ns.publicKeys[0x38] = GLFW_KEY_LEFT_SHIFT;
    _glfw.ns.publicKeys[0x37] = GLFW_KEY_LEFT_SUPER;
    _glfw.ns.publicKeys[0x6E] = GLFW_KEY_MENU;
    _glfw.ns.publicKeys[0x47] = GLFW_KEY_NUM_LOCK;
    _glfw.ns.publicKeys[0x79] = GLFW_KEY_PAGE_DOWN;
    _glfw.ns.publicKeys[0x74] = GLFW_KEY_PAGE_UP;
    _glfw.ns.publicKeys[0x7C] = GLFW_KEY_RIGHT;
    _glfw.ns.publicKeys[0x3D] = GLFW_KEY_RIGHT_ALT;
    _glfw.ns.publicKeys[0x3E] = GLFW_KEY_RIGHT_CONTROL;
    _glfw.ns.publicKeys[0x3C] = GLFW_KEY_RIGHT_SHIFT;
    _glfw.ns.publicKeys[0x36] = GLFW_KEY_RIGHT_SUPER;
    _glfw.ns.publicKeys[0x31] = GLFW_KEY_SPACE;
    _glfw.ns.publicKeys[0x30] = GLFW_KEY_TAB;
    _glfw.ns.publicKeys[0x7E] = GLFW_KEY_UP;

    _glfw.ns.publicKeys[0x52] = GLFW_KEY_KP_0;
    _glfw.ns.publicKeys[0x53] = GLFW_KEY_KP_1;
    _glfw.ns.publicKeys[0x54] = GLFW_KEY_KP_2;
    _glfw.ns.publicKeys[0x55] = GLFW_KEY_KP_3;
    _glfw.ns.publicKeys[0x56] = GLFW_KEY_KP_4;
    _glfw.ns.publicKeys[0x57] = GLFW_KEY_KP_5;
    _glfw.ns.publicKeys[0x58] = GLFW_KEY_KP_6;
    _glfw.ns.publicKeys[0x59] = GLFW_KEY_KP_7;
    _glfw.ns.publicKeys[0x5B] = GLFW_KEY_KP_8;
    _glfw.ns.publicKeys[0x5C] = GLFW_KEY_KP_9;
    _glfw.ns.publicKeys[0x45] = GLFW_KEY_KP_ADD;
    _glfw.ns.publicKeys[0x41] = GLFW_KEY_KP_DECIMAL;
    _glfw.ns.publicKeys[0x4B] = GLFW_KEY_KP_DIVIDE;
    _glfw.ns.publicKeys[0x4C] = GLFW_KEY_KP_ENTER;
    _glfw.ns.publicKeys[0x51] = GLFW_KEY_KP_EQUAL;
    _glfw.ns.publicKeys[0x43] = GLFW_KEY_KP_MULTIPLY;
    _glfw.ns.publicKeys[0x4E] = GLFW_KEY_KP_SUBTRACT;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformInit(void)
{
    _glfw.ns.autoreleasePool = [[NSAutoreleasePool alloc] init];

#if defined(_GLFW_USE_CHDIR)
    changeToResourcesDirectory();
#endif

    createKeyTables();

    _glfw.ns.eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    if (!_glfw.ns.eventSource)
        return GL_FALSE;

    CGEventSourceSetLocalEventsSuppressionInterval(_glfw.ns.eventSource, 0.0);

    if (!_glfwInitContextAPI())
        return GL_FALSE;

    _glfwInitTimer();
    _glfwInitJoysticks();

    return GL_TRUE;
}

void _glfwPlatformTerminate(void)
{
    if (_glfw.ns.eventSource)
    {
        CFRelease(_glfw.ns.eventSource);
        _glfw.ns.eventSource = NULL;
    }

    if (_glfw.ns.delegate)
    {
        [NSApp setDelegate:nil];
        [_glfw.ns.delegate release];
        _glfw.ns.delegate = nil;
    }

    [_glfw.ns.autoreleasePool release];
    _glfw.ns.autoreleasePool = nil;

    [_glfw.ns.cursor release];
    _glfw.ns.cursor = nil;

    free(_glfw.ns.clipboardString);

    _glfwTerminateJoysticks();
    _glfwTerminateContextAPI();
}

const char* _glfwPlatformGetVersionString(void)
{
    return _GLFW_VERSION_NUMBER " Cocoa"
#if defined(_GLFW_NSGL)
        " NSGL"
#endif
#if defined(_GLFW_USE_CHDIR)
        " chdir"
#endif
#if defined(_GLFW_USE_MENUBAR)
        " menubar"
#endif
#if defined(_GLFW_USE_RETINA)
        " retina"
#endif
#if defined(_GLFW_BUILD_DLL)
        " dynamic"
#endif
        ;
}

