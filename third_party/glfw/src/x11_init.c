//========================================================================
// GLFW 3.2 X11 - www.glfw.org
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

#include <X11/Xresource.h>

#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdio.h>
#include <locale.h>


// Translate an X11 key code to a GLFW key code.
//
static int translateKeyCode(int scancode)
{
    int keySym;

    // Valid key code range is  [8,255], according to the Xlib manual
    if (scancode < 8 || scancode > 255)
        return GLFW_KEY_UNKNOWN;

    if (_glfw.x11.xkb.available)
    {
        // Try secondary keysym, for numeric keypad keys
        // Note: This way we always force "NumLock = ON", which is intentional
        // since the returned key code should correspond to a physical
        // location.
        keySym = XkbKeycodeToKeysym(_glfw.x11.display, scancode, 0, 1);
        switch (keySym)
        {
            case XK_KP_0:           return GLFW_KEY_KP_0;
            case XK_KP_1:           return GLFW_KEY_KP_1;
            case XK_KP_2:           return GLFW_KEY_KP_2;
            case XK_KP_3:           return GLFW_KEY_KP_3;
            case XK_KP_4:           return GLFW_KEY_KP_4;
            case XK_KP_5:           return GLFW_KEY_KP_5;
            case XK_KP_6:           return GLFW_KEY_KP_6;
            case XK_KP_7:           return GLFW_KEY_KP_7;
            case XK_KP_8:           return GLFW_KEY_KP_8;
            case XK_KP_9:           return GLFW_KEY_KP_9;
            case XK_KP_Separator:
            case XK_KP_Decimal:     return GLFW_KEY_KP_DECIMAL;
            case XK_KP_Equal:       return GLFW_KEY_KP_EQUAL;
            case XK_KP_Enter:       return GLFW_KEY_KP_ENTER;
            default:                break;
        }

        // Now try primary keysym for function keys (non-printable keys). These
        // should not be layout dependent (i.e. US layout and international
        // layouts should give the same result).
        keySym = XkbKeycodeToKeysym(_glfw.x11.display, scancode, 0, 0);
    }
    else
    {
        int dummy;
        KeySym* keySyms;

        keySyms = XGetKeyboardMapping(_glfw.x11.display, scancode, 1, &dummy);
        keySym = keySyms[0];
        XFree(keySyms);
    }

    switch (keySym)
    {
        case XK_Escape:         return GLFW_KEY_ESCAPE;
        case XK_Tab:            return GLFW_KEY_TAB;
        case XK_Shift_L:        return GLFW_KEY_LEFT_SHIFT;
        case XK_Shift_R:        return GLFW_KEY_RIGHT_SHIFT;
        case XK_Control_L:      return GLFW_KEY_LEFT_CONTROL;
        case XK_Control_R:      return GLFW_KEY_RIGHT_CONTROL;
        case XK_Meta_L:
        case XK_Alt_L:          return GLFW_KEY_LEFT_ALT;
        case XK_Mode_switch: // Mapped to Alt_R on many keyboards
        case XK_ISO_Level3_Shift: // AltGr on at least some machines
        case XK_Meta_R:
        case XK_Alt_R:          return GLFW_KEY_RIGHT_ALT;
        case XK_Super_L:        return GLFW_KEY_LEFT_SUPER;
        case XK_Super_R:        return GLFW_KEY_RIGHT_SUPER;
        case XK_Menu:           return GLFW_KEY_MENU;
        case XK_Num_Lock:       return GLFW_KEY_NUM_LOCK;
        case XK_Caps_Lock:      return GLFW_KEY_CAPS_LOCK;
        case XK_Print:          return GLFW_KEY_PRINT_SCREEN;
        case XK_Scroll_Lock:    return GLFW_KEY_SCROLL_LOCK;
        case XK_Pause:          return GLFW_KEY_PAUSE;
        case XK_Delete:         return GLFW_KEY_DELETE;
        case XK_BackSpace:      return GLFW_KEY_BACKSPACE;
        case XK_Return:         return GLFW_KEY_ENTER;
        case XK_Home:           return GLFW_KEY_HOME;
        case XK_End:            return GLFW_KEY_END;
        case XK_Page_Up:        return GLFW_KEY_PAGE_UP;
        case XK_Page_Down:      return GLFW_KEY_PAGE_DOWN;
        case XK_Insert:         return GLFW_KEY_INSERT;
        case XK_Left:           return GLFW_KEY_LEFT;
        case XK_Right:          return GLFW_KEY_RIGHT;
        case XK_Down:           return GLFW_KEY_DOWN;
        case XK_Up:             return GLFW_KEY_UP;
        case XK_F1:             return GLFW_KEY_F1;
        case XK_F2:             return GLFW_KEY_F2;
        case XK_F3:             return GLFW_KEY_F3;
        case XK_F4:             return GLFW_KEY_F4;
        case XK_F5:             return GLFW_KEY_F5;
        case XK_F6:             return GLFW_KEY_F6;
        case XK_F7:             return GLFW_KEY_F7;
        case XK_F8:             return GLFW_KEY_F8;
        case XK_F9:             return GLFW_KEY_F9;
        case XK_F10:            return GLFW_KEY_F10;
        case XK_F11:            return GLFW_KEY_F11;
        case XK_F12:            return GLFW_KEY_F12;
        case XK_F13:            return GLFW_KEY_F13;
        case XK_F14:            return GLFW_KEY_F14;
        case XK_F15:            return GLFW_KEY_F15;
        case XK_F16:            return GLFW_KEY_F16;
        case XK_F17:            return GLFW_KEY_F17;
        case XK_F18:            return GLFW_KEY_F18;
        case XK_F19:            return GLFW_KEY_F19;
        case XK_F20:            return GLFW_KEY_F20;
        case XK_F21:            return GLFW_KEY_F21;
        case XK_F22:            return GLFW_KEY_F22;
        case XK_F23:            return GLFW_KEY_F23;
        case XK_F24:            return GLFW_KEY_F24;
        case XK_F25:            return GLFW_KEY_F25;

        // Numeric keypad
        case XK_KP_Divide:      return GLFW_KEY_KP_DIVIDE;
        case XK_KP_Multiply:    return GLFW_KEY_KP_MULTIPLY;
        case XK_KP_Subtract:    return GLFW_KEY_KP_SUBTRACT;
        case XK_KP_Add:         return GLFW_KEY_KP_ADD;

        // These should have been detected in secondary keysym test above!
        case XK_KP_Insert:      return GLFW_KEY_KP_0;
        case XK_KP_End:         return GLFW_KEY_KP_1;
        case XK_KP_Down:        return GLFW_KEY_KP_2;
        case XK_KP_Page_Down:   return GLFW_KEY_KP_3;
        case XK_KP_Left:        return GLFW_KEY_KP_4;
        case XK_KP_Right:       return GLFW_KEY_KP_6;
        case XK_KP_Home:        return GLFW_KEY_KP_7;
        case XK_KP_Up:          return GLFW_KEY_KP_8;
        case XK_KP_Page_Up:     return GLFW_KEY_KP_9;
        case XK_KP_Delete:      return GLFW_KEY_KP_DECIMAL;
        case XK_KP_Equal:       return GLFW_KEY_KP_EQUAL;
        case XK_KP_Enter:       return GLFW_KEY_KP_ENTER;

        // Last resort: Check for printable keys (should not happen if the XKB
        // extension is available). This will give a layout dependent mapping
        // (which is wrong, and we may miss some keys, especially on non-US
        // keyboards), but it's better than nothing...
        case XK_a:              return GLFW_KEY_A;
        case XK_b:              return GLFW_KEY_B;
        case XK_c:              return GLFW_KEY_C;
        case XK_d:              return GLFW_KEY_D;
        case XK_e:              return GLFW_KEY_E;
        case XK_f:              return GLFW_KEY_F;
        case XK_g:              return GLFW_KEY_G;
        case XK_h:              return GLFW_KEY_H;
        case XK_i:              return GLFW_KEY_I;
        case XK_j:              return GLFW_KEY_J;
        case XK_k:              return GLFW_KEY_K;
        case XK_l:              return GLFW_KEY_L;
        case XK_m:              return GLFW_KEY_M;
        case XK_n:              return GLFW_KEY_N;
        case XK_o:              return GLFW_KEY_O;
        case XK_p:              return GLFW_KEY_P;
        case XK_q:              return GLFW_KEY_Q;
        case XK_r:              return GLFW_KEY_R;
        case XK_s:              return GLFW_KEY_S;
        case XK_t:              return GLFW_KEY_T;
        case XK_u:              return GLFW_KEY_U;
        case XK_v:              return GLFW_KEY_V;
        case XK_w:              return GLFW_KEY_W;
        case XK_x:              return GLFW_KEY_X;
        case XK_y:              return GLFW_KEY_Y;
        case XK_z:              return GLFW_KEY_Z;
        case XK_1:              return GLFW_KEY_1;
        case XK_2:              return GLFW_KEY_2;
        case XK_3:              return GLFW_KEY_3;
        case XK_4:              return GLFW_KEY_4;
        case XK_5:              return GLFW_KEY_5;
        case XK_6:              return GLFW_KEY_6;
        case XK_7:              return GLFW_KEY_7;
        case XK_8:              return GLFW_KEY_8;
        case XK_9:              return GLFW_KEY_9;
        case XK_0:              return GLFW_KEY_0;
        case XK_space:          return GLFW_KEY_SPACE;
        case XK_minus:          return GLFW_KEY_MINUS;
        case XK_equal:          return GLFW_KEY_EQUAL;
        case XK_bracketleft:    return GLFW_KEY_LEFT_BRACKET;
        case XK_bracketright:   return GLFW_KEY_RIGHT_BRACKET;
        case XK_backslash:      return GLFW_KEY_BACKSLASH;
        case XK_semicolon:      return GLFW_KEY_SEMICOLON;
        case XK_apostrophe:     return GLFW_KEY_APOSTROPHE;
        case XK_grave:          return GLFW_KEY_GRAVE_ACCENT;
        case XK_comma:          return GLFW_KEY_COMMA;
        case XK_period:         return GLFW_KEY_PERIOD;
        case XK_slash:          return GLFW_KEY_SLASH;
        case XK_less:           return GLFW_KEY_WORLD_1; // At least in some layouts...
        default:                break;
    }

    // No matching translation was found
    return GLFW_KEY_UNKNOWN;
}

// Create key code translation tables
//
static void createKeyTables(void)
{
    int scancode, key;

    memset(_glfw.x11.publicKeys, -1, sizeof(_glfw.x11.publicKeys));
    memset(_glfw.x11.nativeKeys, -1, sizeof(_glfw.x11.nativeKeys));

    if (_glfw.x11.xkb.available)
    {
        // Use XKB to determine physical key locations independently of the current
        // keyboard layout

        char name[XkbKeyNameLength + 1];
        XkbDescPtr desc = XkbGetMap(_glfw.x11.display, 0, XkbUseCoreKbd);
        XkbGetNames(_glfw.x11.display, XkbKeyNamesMask, desc);

        // Find the X11 key code -> GLFW key code mapping
        for (scancode = desc->min_key_code;  scancode <= desc->max_key_code;  scancode++)
        {
            memcpy(name, desc->names->keys[scancode].name, XkbKeyNameLength);
            name[XkbKeyNameLength] = '\0';

            // Map the key name to a GLFW key code. Note: We only map printable
            // keys here, and we use the US keyboard layout. The rest of the
            // keys (function keys) are mapped using traditional KeySym
            // translations.
            if (strcmp(name, "TLDE") == 0) key = GLFW_KEY_GRAVE_ACCENT;
            else if (strcmp(name, "AE01") == 0) key = GLFW_KEY_1;
            else if (strcmp(name, "AE02") == 0) key = GLFW_KEY_2;
            else if (strcmp(name, "AE03") == 0) key = GLFW_KEY_3;
            else if (strcmp(name, "AE04") == 0) key = GLFW_KEY_4;
            else if (strcmp(name, "AE05") == 0) key = GLFW_KEY_5;
            else if (strcmp(name, "AE06") == 0) key = GLFW_KEY_6;
            else if (strcmp(name, "AE07") == 0) key = GLFW_KEY_7;
            else if (strcmp(name, "AE08") == 0) key = GLFW_KEY_8;
            else if (strcmp(name, "AE09") == 0) key = GLFW_KEY_9;
            else if (strcmp(name, "AE10") == 0) key = GLFW_KEY_0;
            else if (strcmp(name, "AE11") == 0) key = GLFW_KEY_MINUS;
            else if (strcmp(name, "AE12") == 0) key = GLFW_KEY_EQUAL;
            else if (strcmp(name, "AD01") == 0) key = GLFW_KEY_Q;
            else if (strcmp(name, "AD02") == 0) key = GLFW_KEY_W;
            else if (strcmp(name, "AD03") == 0) key = GLFW_KEY_E;
            else if (strcmp(name, "AD04") == 0) key = GLFW_KEY_R;
            else if (strcmp(name, "AD05") == 0) key = GLFW_KEY_T;
            else if (strcmp(name, "AD06") == 0) key = GLFW_KEY_Y;
            else if (strcmp(name, "AD07") == 0) key = GLFW_KEY_U;
            else if (strcmp(name, "AD08") == 0) key = GLFW_KEY_I;
            else if (strcmp(name, "AD09") == 0) key = GLFW_KEY_O;
            else if (strcmp(name, "AD10") == 0) key = GLFW_KEY_P;
            else if (strcmp(name, "AD11") == 0) key = GLFW_KEY_LEFT_BRACKET;
            else if (strcmp(name, "AD12") == 0) key = GLFW_KEY_RIGHT_BRACKET;
            else if (strcmp(name, "AC01") == 0) key = GLFW_KEY_A;
            else if (strcmp(name, "AC02") == 0) key = GLFW_KEY_S;
            else if (strcmp(name, "AC03") == 0) key = GLFW_KEY_D;
            else if (strcmp(name, "AC04") == 0) key = GLFW_KEY_F;
            else if (strcmp(name, "AC05") == 0) key = GLFW_KEY_G;
            else if (strcmp(name, "AC06") == 0) key = GLFW_KEY_H;
            else if (strcmp(name, "AC07") == 0) key = GLFW_KEY_J;
            else if (strcmp(name, "AC08") == 0) key = GLFW_KEY_K;
            else if (strcmp(name, "AC09") == 0) key = GLFW_KEY_L;
            else if (strcmp(name, "AC10") == 0) key = GLFW_KEY_SEMICOLON;
            else if (strcmp(name, "AC11") == 0) key = GLFW_KEY_APOSTROPHE;
            else if (strcmp(name, "AB01") == 0) key = GLFW_KEY_Z;
            else if (strcmp(name, "AB02") == 0) key = GLFW_KEY_X;
            else if (strcmp(name, "AB03") == 0) key = GLFW_KEY_C;
            else if (strcmp(name, "AB04") == 0) key = GLFW_KEY_V;
            else if (strcmp(name, "AB05") == 0) key = GLFW_KEY_B;
            else if (strcmp(name, "AB06") == 0) key = GLFW_KEY_N;
            else if (strcmp(name, "AB07") == 0) key = GLFW_KEY_M;
            else if (strcmp(name, "AB08") == 0) key = GLFW_KEY_COMMA;
            else if (strcmp(name, "AB09") == 0) key = GLFW_KEY_PERIOD;
            else if (strcmp(name, "AB10") == 0) key = GLFW_KEY_SLASH;
            else if (strcmp(name, "BKSL") == 0) key = GLFW_KEY_BACKSLASH;
            else if (strcmp(name, "LSGT") == 0) key = GLFW_KEY_WORLD_1;
            else key = GLFW_KEY_UNKNOWN;

            if ((scancode >= 0) && (scancode < 256))
                _glfw.x11.publicKeys[scancode] = key;
        }

        XkbFreeNames(desc, XkbKeyNamesMask, True);
        XkbFreeKeyboard(desc, 0, True);
    }

    for (scancode = 0;  scancode < 256;  scancode++)
    {
        // Translate the un-translated key codes using traditional X11 KeySym
        // lookups
        if (_glfw.x11.publicKeys[scancode] < 0)
            _glfw.x11.publicKeys[scancode] = translateKeyCode(scancode);

        // Store the reverse translation for faster key name lookup
        if (_glfw.x11.publicKeys[scancode] > 0)
            _glfw.x11.nativeKeys[_glfw.x11.publicKeys[scancode]] = scancode;
    }
}

// Check whether the IM has a usable style
//
static GLFWbool hasUsableInputMethodStyle(void)
{
    unsigned int i;
    GLFWbool found = GLFW_FALSE;
    XIMStyles* styles = NULL;

    if (XGetIMValues(_glfw.x11.im, XNQueryInputStyle, &styles, NULL) != NULL)
        return GLFW_FALSE;

    for (i = 0;  i < styles->count_styles;  i++)
    {
        if (styles->supported_styles[i] == (XIMPreeditNothing | XIMStatusNothing))
        {
            found = GLFW_TRUE;
            break;
        }
    }

    XFree(styles);
    return found;
}

// Check whether the specified atom is supported
//
static Atom getSupportedAtom(Atom* supportedAtoms,
                             unsigned long atomCount,
                             const char* atomName)
{
    Atom atom = XInternAtom(_glfw.x11.display, atomName, True);
    if (atom != None)
    {
        unsigned long i;

        for (i = 0;  i < atomCount;  i++)
        {
            if (supportedAtoms[i] == atom)
                return atom;
        }
    }

    return None;
}

// Check whether the running window manager is EWMH-compliant
//
static void detectEWMH(void)
{
    Window* windowFromRoot = NULL;
    Window* windowFromChild = NULL;

    // First we need a couple of atoms, which should already be there
    Atom supportingWmCheck =
        XInternAtom(_glfw.x11.display, "_NET_SUPPORTING_WM_CHECK", True);
    Atom wmSupported =
        XInternAtom(_glfw.x11.display, "_NET_SUPPORTED", True);
    if (supportingWmCheck == None || wmSupported == None)
        return;

    // Then we look for the _NET_SUPPORTING_WM_CHECK property of the root window
    if (_glfwGetWindowPropertyX11(_glfw.x11.root,
                                  supportingWmCheck,
                                  XA_WINDOW,
                                  (unsigned char**) &windowFromRoot) != 1)
    {
        if (windowFromRoot)
            XFree(windowFromRoot);
        return;
    }

    _glfwGrabErrorHandlerX11();

    // It should be the ID of a child window (of the root)
    // Then we look for the same property on the child window
    if (_glfwGetWindowPropertyX11(*windowFromRoot,
                                  supportingWmCheck,
                                  XA_WINDOW,
                                  (unsigned char**) &windowFromChild) != 1)
    {
        XFree(windowFromRoot);
        if (windowFromChild)
            XFree(windowFromChild);
        return;
    }

    _glfwReleaseErrorHandlerX11();

    // It should be the ID of that same child window
    if (*windowFromRoot != *windowFromChild)
    {
        XFree(windowFromRoot);
        XFree(windowFromChild);
        return;
    }

    XFree(windowFromRoot);
    XFree(windowFromChild);

    // We are now fairly sure that an EWMH-compliant window manager is running

    Atom* supportedAtoms;
    unsigned long atomCount;

    // Now we need to check the _NET_SUPPORTED property of the root window
    // It should be a list of supported WM protocol and state atoms
    atomCount = _glfwGetWindowPropertyX11(_glfw.x11.root,
                                          wmSupported,
                                          XA_ATOM,
                                          (unsigned char**) &supportedAtoms);

    // See which of the atoms we support that are supported by the WM
    _glfw.x11.NET_WM_STATE =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_STATE");
    _glfw.x11.NET_WM_STATE_ABOVE =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_STATE_ABOVE");
    _glfw.x11.NET_WM_STATE_FULLSCREEN =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_STATE_FULLSCREEN");
    _glfw.x11.NET_WM_STATE_MAXIMIZED_VERT =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_STATE_MAXIMIZED_VERT");
    _glfw.x11.NET_WM_STATE_MAXIMIZED_HORZ =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_STATE_MAXIMIZED_HORZ");
    _glfw.x11.NET_WM_FULLSCREEN_MONITORS =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_FULLSCREEN_MONITORS");
    _glfw.x11.NET_WM_NAME =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_NAME");
    _glfw.x11.NET_WM_ICON_NAME =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_ICON_NAME");
    _glfw.x11.NET_WM_ICON =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_ICON");
    _glfw.x11.NET_WM_PID =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_PID");
    _glfw.x11.NET_WM_PING =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_PING");
    _glfw.x11.NET_WM_WINDOW_TYPE =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_WINDOW_TYPE");
    _glfw.x11.NET_WM_WINDOW_TYPE_NORMAL =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_WINDOW_TYPE_NORMAL");
    _glfw.x11.NET_ACTIVE_WINDOW =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_ACTIVE_WINDOW");
    _glfw.x11.NET_FRAME_EXTENTS =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_FRAME_EXTENTS");
    _glfw.x11.NET_REQUEST_FRAME_EXTENTS =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_REQUEST_FRAME_EXTENTS");
    _glfw.x11.NET_WM_BYPASS_COMPOSITOR =
        getSupportedAtom(supportedAtoms, atomCount, "_NET_WM_BYPASS_COMPOSITOR");

    XFree(supportedAtoms);
}

// Initialize X11 display and look for supported X11 extensions
//
static GLFWbool initExtensions(void)
{
    // Find or create window manager atoms
    _glfw.x11.WM_PROTOCOLS = XInternAtom(_glfw.x11.display,
                                         "WM_PROTOCOLS",
                                         False);
    _glfw.x11.WM_STATE = XInternAtom(_glfw.x11.display, "WM_STATE", False);
    _glfw.x11.WM_DELETE_WINDOW = XInternAtom(_glfw.x11.display,
                                             "WM_DELETE_WINDOW",
                                             False);
    _glfw.x11.MOTIF_WM_HINTS = XInternAtom(_glfw.x11.display,
                                           "_MOTIF_WM_HINTS",
                                           False);

#if defined(_GLFW_HAS_XF86VM)
    // Check for XF86VidMode extension
    _glfw.x11.vidmode.available =
        XF86VidModeQueryExtension(_glfw.x11.display,
                                  &_glfw.x11.vidmode.eventBase,
                                  &_glfw.x11.vidmode.errorBase);
#endif /*_GLFW_HAS_XF86VM*/

    // Check for RandR extension
    if (XRRQueryExtension(_glfw.x11.display,
                          &_glfw.x11.randr.eventBase,
                          &_glfw.x11.randr.errorBase))
    {
        if (XRRQueryVersion(_glfw.x11.display,
                            &_glfw.x11.randr.major,
                            &_glfw.x11.randr.minor))
        {
            // The GLFW RandR path requires at least version 1.3
            if (_glfw.x11.randr.major > 1 || _glfw.x11.randr.minor >= 3)
                _glfw.x11.randr.available = GLFW_TRUE;
        }
        else
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Failed to query RandR version");
        }
    }

    if (_glfw.x11.randr.available)
    {
        XRRScreenResources* sr = XRRGetScreenResources(_glfw.x11.display,
                                                       _glfw.x11.root);

        if (!sr->ncrtc || !XRRGetCrtcGammaSize(_glfw.x11.display, sr->crtcs[0]))
        {
            // This is either a headless system or an older Nvidia binary driver
            // with broken gamma support
            // Flag it as useless and fall back to Xf86VidMode gamma, if
            // available
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: RandR gamma ramp support seems broken");
            _glfw.x11.randr.gammaBroken = GLFW_TRUE;
        }

        XRRFreeScreenResources(sr);

        XRRSelectInput(_glfw.x11.display, _glfw.x11.root,
                       RROutputChangeNotifyMask);
    }

    if (XineramaQueryExtension(_glfw.x11.display,
                               &_glfw.x11.xinerama.major,
                               &_glfw.x11.xinerama.minor))
    {
        if (XineramaIsActive(_glfw.x11.display))
            _glfw.x11.xinerama.available = GLFW_TRUE;
    }

    // Check if Xkb is supported on this display
    _glfw.x11.xkb.major = 1;
    _glfw.x11.xkb.minor = 0;
    _glfw.x11.xkb.available =
        XkbQueryExtension(_glfw.x11.display,
                          &_glfw.x11.xkb.majorOpcode,
                          &_glfw.x11.xkb.eventBase,
                          &_glfw.x11.xkb.errorBase,
                          &_glfw.x11.xkb.major,
                          &_glfw.x11.xkb.minor);

    if (_glfw.x11.xkb.available)
    {
        Bool supported;

        if (XkbSetDetectableAutoRepeat(_glfw.x11.display, True, &supported))
        {
            if (supported)
                _glfw.x11.xkb.detectable = GLFW_TRUE;
        }
    }

    _glfw.x11.x11xcb.handle = dlopen("libX11-xcb.so", RTLD_LAZY | RTLD_GLOBAL);
    if (_glfw.x11.x11xcb.handle)
    {
        _glfw.x11.x11xcb.XGetXCBConnection = (XGETXCBCONNECTION_T)
            dlsym(_glfw.x11.x11xcb.handle, "XGetXCBConnection");
    }

    // Update the key code LUT
    // FIXME: We should listen to XkbMapNotify events to track changes to
    // the keyboard mapping.
    createKeyTables();

    // Detect whether an EWMH-conformant window manager is running
    detectEWMH();

    // Find or create string format atoms
    _glfw.x11.NULL_ = XInternAtom(_glfw.x11.display, "NULL", False);
    _glfw.x11.UTF8_STRING =
        XInternAtom(_glfw.x11.display, "UTF8_STRING", False);
    _glfw.x11.COMPOUND_STRING =
        XInternAtom(_glfw.x11.display, "COMPOUND_STRING", False);
    _glfw.x11.ATOM_PAIR = XInternAtom(_glfw.x11.display, "ATOM_PAIR", False);

    // Find or create selection property atom
    _glfw.x11.GLFW_SELECTION =
        XInternAtom(_glfw.x11.display, "GLFW_SELECTION", False);

    // Find or create standard clipboard atoms
    _glfw.x11.TARGETS = XInternAtom(_glfw.x11.display, "TARGETS", False);
    _glfw.x11.MULTIPLE = XInternAtom(_glfw.x11.display, "MULTIPLE", False);
    _glfw.x11.CLIPBOARD = XInternAtom(_glfw.x11.display, "CLIPBOARD", False);

    // Find or create clipboard manager atoms
    _glfw.x11.CLIPBOARD_MANAGER =
        XInternAtom(_glfw.x11.display, "CLIPBOARD_MANAGER", False);
    _glfw.x11.SAVE_TARGETS =
        XInternAtom(_glfw.x11.display, "SAVE_TARGETS", False);

    // Find Xdnd (drag and drop) atoms, if available
    _glfw.x11.XdndAware = XInternAtom(_glfw.x11.display, "XdndAware", True);
    _glfw.x11.XdndEnter = XInternAtom(_glfw.x11.display, "XdndEnter", True);
    _glfw.x11.XdndPosition = XInternAtom(_glfw.x11.display, "XdndPosition", True);
    _glfw.x11.XdndStatus = XInternAtom(_glfw.x11.display, "XdndStatus", True);
    _glfw.x11.XdndActionCopy = XInternAtom(_glfw.x11.display, "XdndActionCopy", True);
    _glfw.x11.XdndDrop = XInternAtom(_glfw.x11.display, "XdndDrop", True);
    _glfw.x11.XdndLeave = XInternAtom(_glfw.x11.display, "XdndLeave", True);
    _glfw.x11.XdndFinished = XInternAtom(_glfw.x11.display, "XdndFinished", True);
    _glfw.x11.XdndSelection = XInternAtom(_glfw.x11.display, "XdndSelection", True);

    return GLFW_TRUE;
}

// Create a blank cursor for hidden and disabled cursor modes
//
static Cursor createHiddenCursor(void)
{
    unsigned char pixels[16 * 16 * 4];
    GLFWimage image = { 16, 16, pixels };

    memset(pixels, 0, sizeof(pixels));

    return _glfwCreateCursorX11(&image, 0, 0);
}

// X error handler
//
static int errorHandler(Display *display, XErrorEvent* event)
{
    _glfw.x11.errorCode = event->error_code;
    return 0;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Sets the X error handler callback
//
void _glfwGrabErrorHandlerX11(void)
{
    _glfw.x11.errorCode = Success;
    XSetErrorHandler(errorHandler);
}

// Clears the X error handler callback
//
void _glfwReleaseErrorHandlerX11(void)
{
    // Synchronize to make sure all commands are processed
    XSync(_glfw.x11.display, False);
    XSetErrorHandler(NULL);
}

// Reports the specified error, appending information about the last X error
//
void _glfwInputErrorX11(int error, const char* message)
{
    char buffer[8192];
    XGetErrorText(_glfw.x11.display, _glfw.x11.errorCode,
                  buffer, sizeof(buffer));

    _glfwInputError(error, "%s: %s", message, buffer);
}

// Creates a native cursor object from the specified image and hotspot
//
Cursor _glfwCreateCursorX11(const GLFWimage* image, int xhot, int yhot)
{
    int i;
    Cursor cursor;

    XcursorImage* native = XcursorImageCreate(image->width, image->height);
    if (native == NULL)
        return None;

    native->xhot = xhot;
    native->yhot = yhot;

    unsigned char* source = (unsigned char*) image->pixels;
    XcursorPixel* target = native->pixels;

    for (i = 0;  i < image->width * image->height;  i++, target++, source += 4)
    {
        unsigned int alpha = source[3];

        *target = (alpha << 24) |
                  ((unsigned char) ((source[0] * alpha) / 255) << 16) |
                  ((unsigned char) ((source[1] * alpha) / 255) <<  8) |
                  ((unsigned char) ((source[2] * alpha) / 255) <<  0);
    }

    cursor = XcursorImageLoadCursor(_glfw.x11.display, native);
    XcursorImageDestroy(native);

    return cursor;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformInit(void)
{
#if !defined(X_HAVE_UTF8_STRING)
    // HACK: If the current locale is C, apply the environment's locale
    //       This is done because the C locale breaks wide character input
    if (strcmp(setlocale(LC_CTYPE, NULL), "C") == 0)
        setlocale(LC_CTYPE, "");
#endif

    XInitThreads();

    _glfw.x11.display = XOpenDisplay(NULL);
    if (!_glfw.x11.display)
    {
        const char* display = getenv("DISPLAY");
        if (display)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: Failed to open display %s", display);
        }
        else
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "X11: The DISPLAY environment variable is missing");
        }

        return GLFW_FALSE;
    }

    _glfw.x11.screen = DefaultScreen(_glfw.x11.display);
    _glfw.x11.root = RootWindow(_glfw.x11.display, _glfw.x11.screen);
    _glfw.x11.context = XUniqueContext();

    if (!initExtensions())
        return GLFW_FALSE;

    _glfw.x11.cursor = createHiddenCursor();

    if (XSupportsLocale())
    {
        XSetLocaleModifiers("");

        _glfw.x11.im = XOpenIM(_glfw.x11.display, 0, NULL, NULL);
        if (_glfw.x11.im)
        {
            if (!hasUsableInputMethodStyle())
            {
                XCloseIM(_glfw.x11.im);
                _glfw.x11.im = NULL;
            }
        }
    }

    if (!_glfwInitThreadLocalStoragePOSIX())
        return GLFW_FALSE;

#if defined(_GLFW_GLX)
    if (!_glfwInitGLX())
        return GLFW_FALSE;
#elif defined(_GLFW_EGL)
    if (!_glfwInitEGL())
        return GLFW_FALSE;
#endif

    if (!_glfwInitJoysticksLinux())
        return GLFW_FALSE;

    _glfwInitTimerPOSIX();

    return GLFW_TRUE;
}

void _glfwPlatformTerminate(void)
{
    if (_glfw.x11.x11xcb.handle)
    {
        dlclose(_glfw.x11.x11xcb.handle);
        _glfw.x11.x11xcb.handle = NULL;
    }

    if (_glfw.x11.cursor)
    {
        XFreeCursor(_glfw.x11.display, _glfw.x11.cursor);
        _glfw.x11.cursor = (Cursor) 0;
    }

    free(_glfw.x11.clipboardString);

    if (_glfw.x11.im)
    {
        XCloseIM(_glfw.x11.im);
        _glfw.x11.im = NULL;
    }

#if defined(_GLFW_EGL)
    _glfwTerminateEGL();
#endif

    if (_glfw.x11.display)
    {
        XCloseDisplay(_glfw.x11.display);
        _glfw.x11.display = NULL;
    }

    // NOTE: This needs to be done after XCloseDisplay, as libGL registers
    //       cleanup callbacks that get called by it
#if defined(_GLFW_GLX)
    _glfwTerminateGLX();
#endif

    _glfwTerminateJoysticksLinux();
    _glfwTerminateThreadLocalStoragePOSIX();
}

const char* _glfwPlatformGetVersionString(void)
{
    return _GLFW_VERSION_NUMBER " X11"
#if defined(_GLFW_GLX)
        " GLX"
#elif defined(_GLFW_EGL)
        " EGL"
#endif
#if defined(_POSIX_TIMERS) && defined(_POSIX_MONOTONIC_CLOCK)
        " clock_gettime"
#else
        " gettimeofday"
#endif
#if defined(__linux__)
        " /dev/js"
#endif
#if defined(_GLFW_HAS_XF86VM)
        " Xf86vm"
#endif
#if defined(_GLFW_BUILD_DLL)
        " shared"
#endif
        ;
}

