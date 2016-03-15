//========================================================================
// GLFW 3.1 Wayland - www.glfw.org
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
    _glfwInputCursorEnter(window, GL_TRUE);
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
    _glfwInputCursorEnter(window, GL_FALSE);
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
    {
        /* TODO */
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: GLFW_CURSOR_DISABLED not supported");
        return;
    }
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
    _glfwInputWindowFocus(window, GL_TRUE);
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
    _glfwInputWindowFocus(window, GL_FALSE);
}

static int toGLFWKeyCode(uint32_t key)
{
    switch (key)
    {
        case KEY_GRAVE:         return GLFW_KEY_GRAVE_ACCENT;
        case KEY_1:             return GLFW_KEY_1;
        case KEY_2:             return GLFW_KEY_2;
        case KEY_3:             return GLFW_KEY_3;
        case KEY_4:             return GLFW_KEY_4;
        case KEY_5:             return GLFW_KEY_5;
        case KEY_6:             return GLFW_KEY_6;
        case KEY_7:             return GLFW_KEY_7;
        case KEY_8:             return GLFW_KEY_8;
        case KEY_9:             return GLFW_KEY_9;
        case KEY_0:             return GLFW_KEY_0;
        case KEY_MINUS:         return GLFW_KEY_MINUS;
        case KEY_EQUAL:         return GLFW_KEY_EQUAL;
        case KEY_Q:             return GLFW_KEY_Q;
        case KEY_W:             return GLFW_KEY_W;
        case KEY_E:             return GLFW_KEY_E;
        case KEY_R:             return GLFW_KEY_R;
        case KEY_T:             return GLFW_KEY_T;
        case KEY_Y:             return GLFW_KEY_Y;
        case KEY_U:             return GLFW_KEY_U;
        case KEY_I:             return GLFW_KEY_I;
        case KEY_O:             return GLFW_KEY_O;
        case KEY_P:             return GLFW_KEY_P;
        case KEY_LEFTBRACE:     return GLFW_KEY_LEFT_BRACKET;
        case KEY_RIGHTBRACE:    return GLFW_KEY_RIGHT_BRACKET;
        case KEY_A:             return GLFW_KEY_A;
        case KEY_S:             return GLFW_KEY_S;
        case KEY_D:             return GLFW_KEY_D;
        case KEY_F:             return GLFW_KEY_F;
        case KEY_G:             return GLFW_KEY_G;
        case KEY_H:             return GLFW_KEY_H;
        case KEY_J:             return GLFW_KEY_J;
        case KEY_K:             return GLFW_KEY_K;
        case KEY_L:             return GLFW_KEY_L;
        case KEY_SEMICOLON:     return GLFW_KEY_SEMICOLON;
        case KEY_APOSTROPHE:    return GLFW_KEY_APOSTROPHE;
        case KEY_Z:             return GLFW_KEY_Z;
        case KEY_X:             return GLFW_KEY_X;
        case KEY_C:             return GLFW_KEY_C;
        case KEY_V:             return GLFW_KEY_V;
        case KEY_B:             return GLFW_KEY_B;
        case KEY_N:             return GLFW_KEY_N;
        case KEY_M:             return GLFW_KEY_M;
        case KEY_COMMA:         return GLFW_KEY_COMMA;
        case KEY_DOT:           return GLFW_KEY_PERIOD;
        case KEY_SLASH:         return GLFW_KEY_SLASH;
        case KEY_BACKSLASH:     return GLFW_KEY_BACKSLASH;
        case KEY_ESC:           return GLFW_KEY_ESCAPE;
        case KEY_TAB:           return GLFW_KEY_TAB;
        case KEY_LEFTSHIFT:     return GLFW_KEY_LEFT_SHIFT;
        case KEY_RIGHTSHIFT:    return GLFW_KEY_RIGHT_SHIFT;
        case KEY_LEFTCTRL:      return GLFW_KEY_LEFT_CONTROL;
        case KEY_RIGHTCTRL:     return GLFW_KEY_RIGHT_CONTROL;
        case KEY_LEFTALT:       return GLFW_KEY_LEFT_ALT;
        case KEY_RIGHTALT:      return GLFW_KEY_RIGHT_ALT;
        case KEY_LEFTMETA:      return GLFW_KEY_LEFT_SUPER;
        case KEY_RIGHTMETA:     return GLFW_KEY_RIGHT_SUPER;
        case KEY_MENU:          return GLFW_KEY_MENU;
        case KEY_NUMLOCK:       return GLFW_KEY_NUM_LOCK;
        case KEY_CAPSLOCK:      return GLFW_KEY_CAPS_LOCK;
        case KEY_PRINT:         return GLFW_KEY_PRINT_SCREEN;
        case KEY_SCROLLLOCK:    return GLFW_KEY_SCROLL_LOCK;
        case KEY_PAUSE:         return GLFW_KEY_PAUSE;
        case KEY_DELETE:        return GLFW_KEY_DELETE;
        case KEY_BACKSPACE:     return GLFW_KEY_BACKSPACE;
        case KEY_ENTER:         return GLFW_KEY_ENTER;
        case KEY_HOME:          return GLFW_KEY_HOME;
        case KEY_END:           return GLFW_KEY_END;
        case KEY_PAGEUP:        return GLFW_KEY_PAGE_UP;
        case KEY_PAGEDOWN:      return GLFW_KEY_PAGE_DOWN;
        case KEY_INSERT:        return GLFW_KEY_INSERT;
        case KEY_LEFT:          return GLFW_KEY_LEFT;
        case KEY_RIGHT:         return GLFW_KEY_RIGHT;
        case KEY_DOWN:          return GLFW_KEY_DOWN;
        case KEY_UP:            return GLFW_KEY_UP;
        case KEY_F1:            return GLFW_KEY_F1;
        case KEY_F2:            return GLFW_KEY_F2;
        case KEY_F3:            return GLFW_KEY_F3;
        case KEY_F4:            return GLFW_KEY_F4;
        case KEY_F5:            return GLFW_KEY_F5;
        case KEY_F6:            return GLFW_KEY_F6;
        case KEY_F7:            return GLFW_KEY_F7;
        case KEY_F8:            return GLFW_KEY_F8;
        case KEY_F9:            return GLFW_KEY_F9;
        case KEY_F10:           return GLFW_KEY_F10;
        case KEY_F11:           return GLFW_KEY_F11;
        case KEY_F12:           return GLFW_KEY_F12;
        case KEY_F13:           return GLFW_KEY_F13;
        case KEY_F14:           return GLFW_KEY_F14;
        case KEY_F15:           return GLFW_KEY_F15;
        case KEY_F16:           return GLFW_KEY_F16;
        case KEY_F17:           return GLFW_KEY_F17;
        case KEY_F18:           return GLFW_KEY_F18;
        case KEY_F19:           return GLFW_KEY_F19;
        case KEY_F20:           return GLFW_KEY_F20;
        case KEY_F21:           return GLFW_KEY_F21;
        case KEY_F22:           return GLFW_KEY_F22;
        case KEY_F23:           return GLFW_KEY_F23;
        case KEY_F24:           return GLFW_KEY_F24;
        case KEY_KPSLASH:       return GLFW_KEY_KP_DIVIDE;
        case KEY_KPDOT:         return GLFW_KEY_KP_MULTIPLY;
        case KEY_KPMINUS:       return GLFW_KEY_KP_SUBTRACT;
        case KEY_KPPLUS:        return GLFW_KEY_KP_ADD;
        case KEY_KP0:           return GLFW_KEY_KP_0;
        case KEY_KP1:           return GLFW_KEY_KP_1;
        case KEY_KP2:           return GLFW_KEY_KP_2;
        case KEY_KP3:           return GLFW_KEY_KP_3;
        case KEY_KP4:           return GLFW_KEY_KP_4;
        case KEY_KP5:           return GLFW_KEY_KP_5;
        case KEY_KP6:           return GLFW_KEY_KP_6;
        case KEY_KP7:           return GLFW_KEY_KP_7;
        case KEY_KP8:           return GLFW_KEY_KP_8;
        case KEY_KP9:           return GLFW_KEY_KP_9;
        case KEY_KPCOMMA:       return GLFW_KEY_KP_DECIMAL;
        case KEY_KPEQUAL:       return GLFW_KEY_KP_EQUAL;
        case KEY_KPENTER:       return GLFW_KEY_KP_ENTER;
        default:                return GLFW_KEY_UNKNOWN;
    }
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
        _glfw.wl.compositor =
            wl_registry_bind(registry, name, &wl_compositor_interface, 1);
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
        _glfwAddOutput(name, version);
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
        return GL_FALSE;
    }

    _glfw.wl.registry = wl_display_get_registry(_glfw.wl.display);
    wl_registry_add_listener(_glfw.wl.registry, &registryListener, NULL);

    _glfw.wl.monitors = calloc(4, sizeof(_GLFWmonitor*));
    _glfw.wl.monitorsSize = 4;

    _glfw.wl.xkb.context = xkb_context_new(0);
    if (!_glfw.wl.xkb.context)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Failed to initialize xkb context");
        return GL_FALSE;
    }

    // Sync so we got all registry objects
    wl_display_roundtrip(_glfw.wl.display);

    // Sync so we got all initial output events
    wl_display_roundtrip(_glfw.wl.display);

    if (!_glfwInitContextAPI())
        return GL_FALSE;

    _glfwInitTimer();
    _glfwInitJoysticks();

    if (_glfw.wl.pointer && _glfw.wl.shm)
    {
        _glfw.wl.cursorTheme = wl_cursor_theme_load(NULL, 32, _glfw.wl.shm);
        if (!_glfw.wl.cursorTheme)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "Wayland: Unable to load default cursor theme\n");
            return GL_FALSE;
        }
        _glfw.wl.defaultCursor =
            wl_cursor_theme_get_cursor(_glfw.wl.cursorTheme, "left_ptr");
        if (!_glfw.wl.defaultCursor)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "Wayland: Unable to load default left pointer\n");
            return GL_FALSE;
        }
        _glfw.wl.cursorSurface =
            wl_compositor_create_surface(_glfw.wl.compositor);
    }

    return GL_TRUE;
}

void _glfwPlatformTerminate(void)
{
    _glfwTerminateContextAPI();
    _glfwTerminateJoysticks();

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

