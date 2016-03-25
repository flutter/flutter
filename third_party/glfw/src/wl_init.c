//========================================================================
// GLFW 3.2 Wayland - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2014 Jonas Ådahl <jadahl@gmail.com>
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

#include <linux/input.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <wayland-client.h>
#include <wayland-cursor.h>


static inline int min(int n1, int n2)
{
    return n1 < n2 ? n1 : n2;
}

static void pointerHandleEnter(void* data,
                               struct wl_pointer* pointer,
                               uint32_t serial,
                               struct wl_surface* surface,
                               wl_fixed_t sx,
                               wl_fixed_t sy)
{
    _GLFWwindow* window = wl_surface_get_user_data(surface);

    _glfw.wl.pointerSerial = serial;
    _glfw.wl.pointerFocus = window;

    _glfwPlatformSetCursor(window, window->wl.currentCursor);
    _glfwInputCursorEnter(window, GLFW_TRUE);
}

static void pointerHandleLeave(void* data,
                               struct wl_pointer* pointer,
                               uint32_t serial,
                               struct wl_surface* surface)
{
    _GLFWwindow* window = _glfw.wl.pointerFocus;

    if (!window)
        return;

    _glfw.wl.pointerSerial = serial;
    _glfw.wl.pointerFocus = NULL;
    _glfwInputCursorEnter(window, GLFW_FALSE);
}

static void pointerHandleMotion(void* data,
                                struct wl_pointer* pointer,
                                uint32_t time,
                                wl_fixed_t sx,
                                wl_fixed_t sy)
{
    _GLFWwindow* window = _glfw.wl.pointerFocus;

    if (!window)
        return;

    if (window->cursorMode == GLFW_CURSOR_DISABLED)
        return;
    else
    {
        window->wl.cursorPosX = wl_fixed_to_double(sx);
        window->wl.cursorPosY = wl_fixed_to_double(sy);
    }

    _glfwInputCursorMotion(window,
                           wl_fixed_to_double(sx),
                           wl_fixed_to_double(sy));
}

static void pointerHandleButton(void* data,
                                struct wl_pointer* wl_pointer,
                                uint32_t serial,
                                uint32_t time,
                                uint32_t button,
                                uint32_t state)
{
    _GLFWwindow* window = _glfw.wl.pointerFocus;
    int glfwButton;

    if (!window)
        return;

    /* Makes left, right and middle 0, 1 and 2. Overall order follows evdev
     * codes. */
    glfwButton = button - BTN_LEFT;

    _glfwInputMouseClick(window,
                         glfwButton,
                         state == WL_POINTER_BUTTON_STATE_PRESSED
                                ? GLFW_PRESS
                                : GLFW_RELEASE,
                         _glfw.wl.xkb.modifiers);
}

static void pointerHandleAxis(void* data,
                              struct wl_pointer* wl_pointer,
                              uint32_t time,
                              uint32_t axis,
                              wl_fixed_t value)
{
    _GLFWwindow* window = _glfw.wl.pointerFocus;
    double scroll_factor;
    double x, y;

    if (!window)
        return;

    /* Wayland scroll events are in pointer motion coordinate space (think
     * two finger scroll). The factor 10 is commonly used to convert to
     * "scroll step means 1.0. */
    scroll_factor = 1.0/10.0;

    switch (axis)
    {
        case WL_POINTER_AXIS_HORIZONTAL_SCROLL:
            x = wl_fixed_to_double(value) * scroll_factor;
            y = 0.0;
            break;
        case WL_POINTER_AXIS_VERTICAL_SCROLL:
            x = 0.0;
            y = wl_fixed_to_double(value) * scroll_factor;
            break;
        default:
            break;
    }

    _glfwInputScroll(window, x, y);
}

static const struct wl_pointer_listener pointerListener = {
    pointerHandleEnter,
    pointerHandleLeave,
    pointerHandleMotion,
    pointerHandleButton,
    pointerHandleAxis,
};

static void keyboardHandleKeymap(void* data,
                                 struct wl_keyboard* keyboard,
                                 uint32_t format,
                                 int fd,
                                 uint32_t size)
{
    struct xkb_keymap* keymap;
    struct xkb_state* state;
    char* mapStr;

    if (format != WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1)
    {
        close(fd);
        return;
    }

    mapStr = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);
    if (mapStr == MAP_FAILED) {
        close(fd);
        return;
    }

    keymap = xkb_map_new_from_string(_glfw.wl.xkb.context,
                                     mapStr,
                                     XKB_KEYMAP_FORMAT_TEXT_V1,
                                     0);
    munmap(mapStr, size);
    close(fd);

    if (!keymap)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Failed to compile keymap");
        return;
    }

    state = xkb_state_new(keymap);
    if (!state)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Failed to create XKB state");
        xkb_map_unref(keymap);
        return;
    }

    xkb_keymap_unref(_glfw.wl.xkb.keymap);
    xkb_state_unref(_glfw.wl.xkb.state);
    _glfw.wl.xkb.keymap = keymap;
    _glfw.wl.xkb.state = state;

    _glfw.wl.xkb.control_mask =
        1 << xkb_map_mod_get_index(_glfw.wl.xkb.keymap, "Control");
    _glfw.wl.xkb.alt_mask =
        1 << xkb_map_mod_get_index(_glfw.wl.xkb.keymap, "Mod1");
    _glfw.wl.xkb.shift_mask =
        1 << xkb_map_mod_get_index(_glfw.wl.xkb.keymap, "Shift");
    _glfw.wl.xkb.super_mask =
        1 << xkb_map_mod_get_index(_glfw.wl.xkb.keymap, "Mod4");
}

static void keyboardHandleEnter(void* data,
                                struct wl_keyboard* keyboard,
                                uint32_t serial,
                                struct wl_surface* surface,
                                struct wl_array* keys)
{
    _GLFWwindow* window = wl_surface_get_user_data(surface);

    _glfw.wl.keyboardFocus = window;
    _glfwInputWindowFocus(window, GLFW_TRUE);
}

static void keyboardHandleLeave(void* data,
                                struct wl_keyboard* keyboard,
                                uint32_t serial,
                                struct wl_surface* surface)
{
    _GLFWwindow* window = _glfw.wl.keyboardFocus;

    if (!window)
        return;

    _glfw.wl.keyboardFocus = NULL;
    _glfwInputWindowFocus(window, GLFW_FALSE);
}

static int toGLFWKeyCode(uint32_t key)
{
    if (key < sizeof(_glfw.wl.publicKeys) / sizeof(_glfw.wl.publicKeys[0]))
        return _glfw.wl.publicKeys[key];

    return GLFW_KEY_UNKNOWN;
}

static void keyboardHandleKey(void* data,
                              struct wl_keyboard* keyboard,
                              uint32_t serial,
                              uint32_t time,
                              uint32_t key,
                              uint32_t state)
{
    uint32_t code, num_syms;
    long cp;
    int keyCode;
    int action;
    const xkb_keysym_t *syms;
    _GLFWwindow* window = _glfw.wl.keyboardFocus;

    if (!window)
        return;

    keyCode = toGLFWKeyCode(key);
    action = state == WL_KEYBOARD_KEY_STATE_PRESSED
            ? GLFW_PRESS : GLFW_RELEASE;

    _glfwInputKey(window, keyCode, key, action,
                  _glfw.wl.xkb.modifiers);

    code = key + 8;
    num_syms = xkb_key_get_syms(_glfw.wl.xkb.state, code, &syms);

    if (num_syms == 1)
    {
        cp = _glfwKeySym2Unicode(syms[0]);
        if (cp != -1)
        {
            const int mods = _glfw.wl.xkb.modifiers;
            const int plain = !(mods & (GLFW_MOD_CONTROL | GLFW_MOD_ALT));
            _glfwInputChar(window, cp, mods, plain);
        }
    }
}

static void keyboardHandleModifiers(void* data,
                                    struct wl_keyboard* keyboard,
                                    uint32_t serial,
                                    uint32_t modsDepressed,
                                    uint32_t modsLatched,
                                    uint32_t modsLocked,
                                    uint32_t group)
{
    xkb_mod_mask_t mask;
    unsigned int modifiers = 0;

    if (!_glfw.wl.xkb.keymap)
        return;

    xkb_state_update_mask(_glfw.wl.xkb.state,
                          modsDepressed,
                          modsLatched,
                          modsLocked,
                          0,
                          0,
                          group);

    mask = xkb_state_serialize_mods(_glfw.wl.xkb.state,
                                    XKB_STATE_DEPRESSED |
                                    XKB_STATE_LATCHED);
    if (mask & _glfw.wl.xkb.control_mask)
        modifiers |= GLFW_MOD_CONTROL;
    if (mask & _glfw.wl.xkb.alt_mask)
        modifiers |= GLFW_MOD_ALT;
    if (mask & _glfw.wl.xkb.shift_mask)
        modifiers |= GLFW_MOD_SHIFT;
    if (mask & _glfw.wl.xkb.super_mask)
        modifiers |= GLFW_MOD_SUPER;
    _glfw.wl.xkb.modifiers = modifiers;
}

static const struct wl_keyboard_listener keyboardListener = {
    keyboardHandleKeymap,
    keyboardHandleEnter,
    keyboardHandleLeave,
    keyboardHandleKey,
    keyboardHandleModifiers,
};

static void seatHandleCapabilities(void* data,
                                   struct wl_seat* seat,
                                   enum wl_seat_capability caps)
{
    if ((caps & WL_SEAT_CAPABILITY_POINTER) && !_glfw.wl.pointer)
    {
        _glfw.wl.pointer = wl_seat_get_pointer(seat);
        wl_pointer_add_listener(_glfw.wl.pointer, &pointerListener, NULL);
    }
    else if (!(caps & WL_SEAT_CAPABILITY_POINTER) && _glfw.wl.pointer)
    {
        wl_pointer_destroy(_glfw.wl.pointer);
        _glfw.wl.pointer = NULL;
    }

    if ((caps & WL_SEAT_CAPABILITY_KEYBOARD) && !_glfw.wl.keyboard)
    {
        _glfw.wl.keyboard = wl_seat_get_keyboard(seat);
        wl_keyboard_add_listener(_glfw.wl.keyboard, &keyboardListener, NULL);
    }
    else if (!(caps & WL_SEAT_CAPABILITY_KEYBOARD) && _glfw.wl.keyboard)
    {
        wl_keyboard_destroy(_glfw.wl.keyboard);
        _glfw.wl.keyboard = NULL;
    }
}

static const struct wl_seat_listener seatListener = {
    seatHandleCapabilities
};

static void registryHandleGlobal(void* data,
                                 struct wl_registry* registry,
                                 uint32_t name,
                                 const char* interface,
                                 uint32_t version)
{
    if (strcmp(interface, "wl_compositor") == 0)
    {
        _glfw.wl.wl_compositor_version = min(3, version);
        _glfw.wl.compositor =
            wl_registry_bind(registry, name, &wl_compositor_interface,
                             _glfw.wl.wl_compositor_version);
    }
    else if (strcmp(interface, "wl_shm") == 0)
    {
        _glfw.wl.shm =
            wl_registry_bind(registry, name, &wl_shm_interface, 1);
    }
    else if (strcmp(interface, "wl_shell") == 0)
    {
        _glfw.wl.shell =
            wl_registry_bind(registry, name, &wl_shell_interface, 1);
    }
    else if (strcmp(interface, "wl_output") == 0)
    {
        _glfwAddOutputWayland(name, version);
    }
    else if (strcmp(interface, "wl_seat") == 0)
    {
        if (!_glfw.wl.seat)
        {
            _glfw.wl.seat =
                wl_registry_bind(registry, name, &wl_seat_interface, 1);
            wl_seat_add_listener(_glfw.wl.seat, &seatListener, NULL);
        }
    }
    else if (strcmp(interface, "zwp_relative_pointer_manager_v1") == 0)
    {
        _glfw.wl.relativePointerManager =
            wl_registry_bind(registry, name,
                             &zwp_relative_pointer_manager_v1_interface,
                             1);
    }
    else if (strcmp(interface, "zwp_pointer_constraints_v1") == 0)
    {
        _glfw.wl.pointerConstraints =
            wl_registry_bind(registry, name,
                             &zwp_pointer_constraints_v1_interface,
                             1);
    }
}

static void registryHandleGlobalRemove(void *data,
                                       struct wl_registry *registry,
                                       uint32_t name)
{
}


static const struct wl_registry_listener registryListener = {
    registryHandleGlobal,
    registryHandleGlobalRemove
};

// Create key code translation tables
//
static void createKeyTables(void)
{
    memset(_glfw.wl.publicKeys, -1, sizeof(_glfw.wl.publicKeys));

    _glfw.wl.publicKeys[KEY_GRAVE]      = GLFW_KEY_GRAVE_ACCENT;
    _glfw.wl.publicKeys[KEY_1]          = GLFW_KEY_1;
    _glfw.wl.publicKeys[KEY_2]          = GLFW_KEY_2;
    _glfw.wl.publicKeys[KEY_3]          = GLFW_KEY_3;
    _glfw.wl.publicKeys[KEY_4]          = GLFW_KEY_4;
    _glfw.wl.publicKeys[KEY_5]          = GLFW_KEY_5;
    _glfw.wl.publicKeys[KEY_6]          = GLFW_KEY_6;
    _glfw.wl.publicKeys[KEY_7]          = GLFW_KEY_7;
    _glfw.wl.publicKeys[KEY_8]          = GLFW_KEY_8;
    _glfw.wl.publicKeys[KEY_9]          = GLFW_KEY_9;
    _glfw.wl.publicKeys[KEY_0]          = GLFW_KEY_0;
    _glfw.wl.publicKeys[KEY_MINUS]      = GLFW_KEY_MINUS;
    _glfw.wl.publicKeys[KEY_EQUAL]      = GLFW_KEY_EQUAL;
    _glfw.wl.publicKeys[KEY_Q]          = GLFW_KEY_Q;
    _glfw.wl.publicKeys[KEY_W]          = GLFW_KEY_W;
    _glfw.wl.publicKeys[KEY_E]          = GLFW_KEY_E;
    _glfw.wl.publicKeys[KEY_R]          = GLFW_KEY_R;
    _glfw.wl.publicKeys[KEY_T]          = GLFW_KEY_T;
    _glfw.wl.publicKeys[KEY_Y]          = GLFW_KEY_Y;
    _glfw.wl.publicKeys[KEY_U]          = GLFW_KEY_U;
    _glfw.wl.publicKeys[KEY_I]          = GLFW_KEY_I;
    _glfw.wl.publicKeys[KEY_O]          = GLFW_KEY_O;
    _glfw.wl.publicKeys[KEY_P]          = GLFW_KEY_P;
    _glfw.wl.publicKeys[KEY_LEFTBRACE]  = GLFW_KEY_LEFT_BRACKET;
    _glfw.wl.publicKeys[KEY_RIGHTBRACE] = GLFW_KEY_RIGHT_BRACKET;
    _glfw.wl.publicKeys[KEY_A]          = GLFW_KEY_A;
    _glfw.wl.publicKeys[KEY_S]          = GLFW_KEY_S;
    _glfw.wl.publicKeys[KEY_D]          = GLFW_KEY_D;
    _glfw.wl.publicKeys[KEY_F]          = GLFW_KEY_F;
    _glfw.wl.publicKeys[KEY_G]          = GLFW_KEY_G;
    _glfw.wl.publicKeys[KEY_H]          = GLFW_KEY_H;
    _glfw.wl.publicKeys[KEY_J]          = GLFW_KEY_J;
    _glfw.wl.publicKeys[KEY_K]          = GLFW_KEY_K;
    _glfw.wl.publicKeys[KEY_L]          = GLFW_KEY_L;
    _glfw.wl.publicKeys[KEY_SEMICOLON]  = GLFW_KEY_SEMICOLON;
    _glfw.wl.publicKeys[KEY_APOSTROPHE] = GLFW_KEY_APOSTROPHE;
    _glfw.wl.publicKeys[KEY_Z]          = GLFW_KEY_Z;
    _glfw.wl.publicKeys[KEY_X]          = GLFW_KEY_X;
    _glfw.wl.publicKeys[KEY_C]          = GLFW_KEY_C;
    _glfw.wl.publicKeys[KEY_V]          = GLFW_KEY_V;
    _glfw.wl.publicKeys[KEY_B]          = GLFW_KEY_B;
    _glfw.wl.publicKeys[KEY_N]          = GLFW_KEY_N;
    _glfw.wl.publicKeys[KEY_M]          = GLFW_KEY_M;
    _glfw.wl.publicKeys[KEY_COMMA]      = GLFW_KEY_COMMA;
    _glfw.wl.publicKeys[KEY_DOT]        = GLFW_KEY_PERIOD;
    _glfw.wl.publicKeys[KEY_SLASH]      = GLFW_KEY_SLASH;
    _glfw.wl.publicKeys[KEY_BACKSLASH]  = GLFW_KEY_BACKSLASH;
    _glfw.wl.publicKeys[KEY_ESC]        = GLFW_KEY_ESCAPE;
    _glfw.wl.publicKeys[KEY_TAB]        = GLFW_KEY_TAB;
    _glfw.wl.publicKeys[KEY_LEFTSHIFT]  = GLFW_KEY_LEFT_SHIFT;
    _glfw.wl.publicKeys[KEY_RIGHTSHIFT] = GLFW_KEY_RIGHT_SHIFT;
    _glfw.wl.publicKeys[KEY_LEFTCTRL]   = GLFW_KEY_LEFT_CONTROL;
    _glfw.wl.publicKeys[KEY_RIGHTCTRL]  = GLFW_KEY_RIGHT_CONTROL;
    _glfw.wl.publicKeys[KEY_LEFTALT]    = GLFW_KEY_LEFT_ALT;
    _glfw.wl.publicKeys[KEY_RIGHTALT]   = GLFW_KEY_RIGHT_ALT;
    _glfw.wl.publicKeys[KEY_LEFTMETA]   = GLFW_KEY_LEFT_SUPER;
    _glfw.wl.publicKeys[KEY_RIGHTMETA]  = GLFW_KEY_RIGHT_SUPER;
    _glfw.wl.publicKeys[KEY_MENU]       = GLFW_KEY_MENU;
    _glfw.wl.publicKeys[KEY_NUMLOCK]    = GLFW_KEY_NUM_LOCK;
    _glfw.wl.publicKeys[KEY_CAPSLOCK]   = GLFW_KEY_CAPS_LOCK;
    _glfw.wl.publicKeys[KEY_PRINT]      = GLFW_KEY_PRINT_SCREEN;
    _glfw.wl.publicKeys[KEY_SCROLLLOCK] = GLFW_KEY_SCROLL_LOCK;
    _glfw.wl.publicKeys[KEY_PAUSE]      = GLFW_KEY_PAUSE;
    _glfw.wl.publicKeys[KEY_DELETE]     = GLFW_KEY_DELETE;
    _glfw.wl.publicKeys[KEY_BACKSPACE]  = GLFW_KEY_BACKSPACE;
    _glfw.wl.publicKeys[KEY_ENTER]      = GLFW_KEY_ENTER;
    _glfw.wl.publicKeys[KEY_HOME]       = GLFW_KEY_HOME;
    _glfw.wl.publicKeys[KEY_END]        = GLFW_KEY_END;
    _glfw.wl.publicKeys[KEY_PAGEUP]     = GLFW_KEY_PAGE_UP;
    _glfw.wl.publicKeys[KEY_PAGEDOWN]   = GLFW_KEY_PAGE_DOWN;
    _glfw.wl.publicKeys[KEY_INSERT]     = GLFW_KEY_INSERT;
    _glfw.wl.publicKeys[KEY_LEFT]       = GLFW_KEY_LEFT;
    _glfw.wl.publicKeys[KEY_RIGHT]      = GLFW_KEY_RIGHT;
    _glfw.wl.publicKeys[KEY_DOWN]       = GLFW_KEY_DOWN;
    _glfw.wl.publicKeys[KEY_UP]         = GLFW_KEY_UP;
    _glfw.wl.publicKeys[KEY_F1]         = GLFW_KEY_F1;
    _glfw.wl.publicKeys[KEY_F2]         = GLFW_KEY_F2;
    _glfw.wl.publicKeys[KEY_F3]         = GLFW_KEY_F3;
    _glfw.wl.publicKeys[KEY_F4]         = GLFW_KEY_F4;
    _glfw.wl.publicKeys[KEY_F5]         = GLFW_KEY_F5;
    _glfw.wl.publicKeys[KEY_F6]         = GLFW_KEY_F6;
    _glfw.wl.publicKeys[KEY_F7]         = GLFW_KEY_F7;
    _glfw.wl.publicKeys[KEY_F8]         = GLFW_KEY_F8;
    _glfw.wl.publicKeys[KEY_F9]         = GLFW_KEY_F9;
    _glfw.wl.publicKeys[KEY_F10]        = GLFW_KEY_F10;
    _glfw.wl.publicKeys[KEY_F11]        = GLFW_KEY_F11;
    _glfw.wl.publicKeys[KEY_F12]        = GLFW_KEY_F12;
    _glfw.wl.publicKeys[KEY_F13]        = GLFW_KEY_F13;
    _glfw.wl.publicKeys[KEY_F14]        = GLFW_KEY_F14;
    _glfw.wl.publicKeys[KEY_F15]        = GLFW_KEY_F15;
    _glfw.wl.publicKeys[KEY_F16]        = GLFW_KEY_F16;
    _glfw.wl.publicKeys[KEY_F17]        = GLFW_KEY_F17;
    _glfw.wl.publicKeys[KEY_F18]        = GLFW_KEY_F18;
    _glfw.wl.publicKeys[KEY_F19]        = GLFW_KEY_F19;
    _glfw.wl.publicKeys[KEY_F20]        = GLFW_KEY_F20;
    _glfw.wl.publicKeys[KEY_F21]        = GLFW_KEY_F21;
    _glfw.wl.publicKeys[KEY_F22]        = GLFW_KEY_F22;
    _glfw.wl.publicKeys[KEY_F23]        = GLFW_KEY_F23;
    _glfw.wl.publicKeys[KEY_F24]        = GLFW_KEY_F24;
    _glfw.wl.publicKeys[KEY_KPSLASH]    = GLFW_KEY_KP_DIVIDE;
    _glfw.wl.publicKeys[KEY_KPDOT]      = GLFW_KEY_KP_MULTIPLY;
    _glfw.wl.publicKeys[KEY_KPMINUS]    = GLFW_KEY_KP_SUBTRACT;
    _glfw.wl.publicKeys[KEY_KPPLUS]     = GLFW_KEY_KP_ADD;
    _glfw.wl.publicKeys[KEY_KP0]        = GLFW_KEY_KP_0;
    _glfw.wl.publicKeys[KEY_KP1]        = GLFW_KEY_KP_1;
    _glfw.wl.publicKeys[KEY_KP2]        = GLFW_KEY_KP_2;
    _glfw.wl.publicKeys[KEY_KP3]        = GLFW_KEY_KP_3;
    _glfw.wl.publicKeys[KEY_KP4]        = GLFW_KEY_KP_4;
    _glfw.wl.publicKeys[KEY_KP5]        = GLFW_KEY_KP_5;
    _glfw.wl.publicKeys[KEY_KP6]        = GLFW_KEY_KP_6;
    _glfw.wl.publicKeys[KEY_KP7]        = GLFW_KEY_KP_7;
    _glfw.wl.publicKeys[KEY_KP8]        = GLFW_KEY_KP_8;
    _glfw.wl.publicKeys[KEY_KP9]        = GLFW_KEY_KP_9;
    _glfw.wl.publicKeys[KEY_KPCOMMA]    = GLFW_KEY_KP_DECIMAL;
    _glfw.wl.publicKeys[KEY_KPEQUAL]    = GLFW_KEY_KP_EQUAL;
    _glfw.wl.publicKeys[KEY_KPENTER]    = GLFW_KEY_KP_ENTER;
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformInit(void)
{
    _glfw.wl.display = wl_display_connect(NULL);
    if (!_glfw.wl.display)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Failed to connect to display");
        return GLFW_FALSE;
    }

    _glfw.wl.registry = wl_display_get_registry(_glfw.wl.display);
    wl_registry_add_listener(_glfw.wl.registry, &registryListener, NULL);

    _glfw.wl.monitors = calloc(4, sizeof(_GLFWmonitor*));
    _glfw.wl.monitorsSize = 4;

    createKeyTables();

    _glfw.wl.xkb.context = xkb_context_new(0);
    if (!_glfw.wl.xkb.context)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Failed to initialize xkb context");
        return GLFW_FALSE;
    }

    // Sync so we got all registry objects
    wl_display_roundtrip(_glfw.wl.display);

    // Sync so we got all initial output events
    wl_display_roundtrip(_glfw.wl.display);

    if (!_glfwInitThreadLocalStoragePOSIX())
        return GLFW_FALSE;

    if (!_glfwInitEGL())
        return GLFW_FALSE;

    if (!_glfwInitJoysticksLinux())
        return GLFW_FALSE;

    _glfwInitTimerPOSIX();

    if (_glfw.wl.pointer && _glfw.wl.shm)
    {
        _glfw.wl.cursorTheme = wl_cursor_theme_load(NULL, 32, _glfw.wl.shm);
        if (!_glfw.wl.cursorTheme)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "Wayland: Unable to load default cursor theme\n");
            return GLFW_FALSE;
        }
        _glfw.wl.cursorSurface =
            wl_compositor_create_surface(_glfw.wl.compositor);
    }

    return GLFW_TRUE;
}

void _glfwPlatformTerminate(void)
{
    _glfwTerminateEGL();
    _glfwTerminateJoysticksLinux();
    _glfwTerminateThreadLocalStoragePOSIX();

    if (_glfw.wl.cursorTheme)
        wl_cursor_theme_destroy(_glfw.wl.cursorTheme);
    if (_glfw.wl.cursorSurface)
        wl_surface_destroy(_glfw.wl.cursorSurface);
    if (_glfw.wl.registry)
        wl_registry_destroy(_glfw.wl.registry);
    if (_glfw.wl.display)
        wl_display_flush(_glfw.wl.display);
    if (_glfw.wl.display)
        wl_display_disconnect(_glfw.wl.display);
}

const char* _glfwPlatformGetVersionString(void)
{
    return _GLFW_VERSION_NUMBER " Wayland EGL"
#if defined(_POSIX_TIMERS) && defined(_POSIX_MONOTONIC_CLOCK)
        " clock_gettime"
#else
        " gettimeofday"
#endif
#if defined(__linux__)
        " /dev/js"
#endif
#if defined(_GLFW_BUILD_DLL)
        " shared"
#endif
        ;
}

