//========================================================================
// GLFW 3.1 Mir - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2014-2015 Brandon Schaefer <brandon.schaefer@canonical.com>
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
#include <stdlib.h>
#include <string.h>


typedef struct EventNode
{
    TAILQ_ENTRY(EventNode) entries;
    const MirEvent*        event;
    _GLFWwindow*           window;
} EventNode;

static void deleteNode(EventQueue* queue, EventNode* node)
{
    mir_event_unref(node->event);
    free(node);
}

static int emptyEventQueue(EventQueue* queue)
{
    return queue->head.tqh_first == NULL ? GL_TRUE : GL_FALSE;
}

// TODO The mir_event_ref is not supposed to be used but ... its needed
//      in this case. Need to wait until we can read from an FD set up by mir
//      for single threaded event handling.
static EventNode* newEventNode(const MirEvent* event, _GLFWwindow* context)
{
    EventNode* new_node = calloc(1, sizeof(EventNode));
    new_node->event     = mir_event_ref(event);
    new_node->window    = context;

    return new_node;
}

static void enqueueEvent(const MirEvent* event, _GLFWwindow* context)
{
    pthread_mutex_lock(&_glfw.mir.event_mutex);

    EventNode* new_node = newEventNode(event, context);
    TAILQ_INSERT_TAIL(&_glfw.mir.event_queue->head, new_node, entries);

    pthread_cond_signal(&_glfw.mir.event_cond);

    pthread_mutex_unlock(&_glfw.mir.event_mutex);
}

static EventNode* dequeueEvent(EventQueue* queue)
{
    EventNode* node = NULL;

    pthread_mutex_lock(&_glfw.mir.event_mutex);

    node = queue->head.tqh_first;

    if (node)
        TAILQ_REMOVE(&queue->head, node, entries);

    pthread_mutex_unlock(&_glfw.mir.event_mutex);

    return node;
}

/* FIXME Soon to be changed upstream mir! So we can use an egl config to figure out
         the best pixel format!
*/
static MirPixelFormat findValidPixelFormat(void)
{
    unsigned int i, validFormats, mirPixelFormats = 32;
    MirPixelFormat formats[mir_pixel_formats];

    mir_connection_get_available_surface_formats(_glfw.mir.connection, formats,
                                                 mirPixelFormats, &validFormats);

    for (i = 0;  i < validFormats;  i++)
    {
        if (formats[i] == mir_pixel_format_abgr_8888 ||
            formats[i] == mir_pixel_format_xbgr_8888 ||
            formats[i] == mir_pixel_format_argb_8888 ||
            formats[i] == mir_pixel_format_xrgb_8888)
        {
            return formats[i];
        }
    }

    return mir_pixel_format_invalid;
}

static int mirModToGLFWMod(uint32_t mods)
{
    int publicMods = 0x0;

    if (mods & mir_input_event_modifier_alt)
        publicMods |= GLFW_MOD_ALT;
    else if (mods & mir_input_event_modifier_shift)
        publicMods |= GLFW_MOD_SHIFT;
    else if (mods & mir_input_event_modifier_ctrl)
        publicMods |= GLFW_MOD_CONTROL;
    else if (mods & mir_input_event_modifier_meta)
        publicMods |= GLFW_MOD_SUPER;

    return publicMods;
}

// Taken from wl_init.c
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

static void handleKeyEvent(const MirKeyboardEvent* key_event, _GLFWwindow* window)
{
    const int action    = mir_keyboard_event_action   (key_event);
    const int scan_code = mir_keyboard_event_scan_code(key_event);
    const int key_code  = mir_keyboard_event_key_code (key_event);
    const int modifiers = mir_keyboard_event_modifiers(key_event);

    const int  pressed = action == mir_keyboard_action_up ? GLFW_RELEASE : GLFW_PRESS;
    const int  mods    = mirModToGLFWMod(modifiers);
    const long text    = _glfwKeySym2Unicode(key_code);
    const int  plain   = !(mods & (GLFW_MOD_CONTROL | GLFW_MOD_ALT));

    _glfwInputKey(window, toGLFWKeyCode(scan_code), scan_code, pressed, mods);

    if (text != -1)
        _glfwInputChar(window, text, mods, plain);
}

static void handlePointerButton(_GLFWwindow* window,
                              int pressed,
                              const MirPointerEvent* pointer_event)
{
    MirPointerButton button = mir_pointer_event_buttons  (pointer_event);
    int mods                = mir_pointer_event_modifiers(pointer_event);
    const int publicMods    = mirModToGLFWMod(mods);
    int publicButton;

    switch (button)
    {
        case mir_pointer_button_primary:
            publicButton = GLFW_MOUSE_BUTTON_LEFT;
            break;
        case mir_pointer_button_secondary:
            publicButton = GLFW_MOUSE_BUTTON_RIGHT;
            break;
        case mir_pointer_button_tertiary:
            publicButton = GLFW_MOUSE_BUTTON_MIDDLE;
            break;
        case mir_pointer_button_forward:
            // FIXME What is the forward button?
            publicButton = GLFW_MOUSE_BUTTON_4;
            break;
        case mir_pointer_button_back:
            // FIXME What is the back button?
            publicButton = GLFW_MOUSE_BUTTON_5;
            break;
        default:
            break;
    }

    _glfwInputMouseClick(window, publicButton, pressed, publicMods);
}

static void handlePointerMotion(_GLFWwindow* window,
                                const MirPointerEvent* pointer_event)
{
    int current_x = window->cursorPosX;
    int current_y = window->cursorPosY;
    int x  = mir_pointer_event_axis_value(pointer_event, mir_pointer_axis_x);
    int y  = mir_pointer_event_axis_value(pointer_event, mir_pointer_axis_y);
    int dx = mir_pointer_event_axis_value(pointer_event, mir_pointer_axis_hscroll);
    int dy = mir_pointer_event_axis_value(pointer_event, mir_pointer_axis_vscroll);

    if (current_x != x || current_y != y)
      _glfwInputCursorMotion(window, x, y);
    if (dx != 0 || dy != 0)
      _glfwInputScroll(window, dx, dy);
}

static void handlePointerEvent(const MirPointerEvent* pointer_event,
                             _GLFWwindow* window)
{
    int action = mir_pointer_event_action(pointer_event);

    switch (action)
    {
          case mir_pointer_action_button_down:
              handlePointerButton(window, GLFW_PRESS, pointer_event);
              break;
          case mir_pointer_action_button_up:
              handlePointerButton(window, GLFW_RELEASE, pointer_event);
              break;
          case mir_pointer_action_motion:
              handlePointerMotion(window, pointer_event);
              break;
          case mir_pointer_action_enter:
          case mir_pointer_action_leave:
              break;
          default:
              break;

    }
}

static void handleInput(const MirInputEvent* input_event, _GLFWwindow* window)
{
    int type = mir_input_event_get_type(input_event);

    switch (type)
    {
        case mir_input_event_type_key:
            handleKeyEvent(mir_input_event_get_keyboard_event(input_event), window);
            break;
        case mir_input_event_type_pointer:
            handlePointerEvent(mir_input_event_get_pointer_event(input_event), window);
            break;
        default:
            break;
    }
}

static void handleEvent(const MirEvent* event, _GLFWwindow* window)
{
    int type = mir_event_get_type(event);

    switch (type)
    {
        case mir_event_type_input:
            handleInput(mir_event_get_input_event(event), window);
            break;
        default:
            break;
    }
}

static void addNewEvent(MirSurface* surface, const MirEvent* event, void* context)
{
    enqueueEvent(event, context);
}

static int createSurface(_GLFWwindow* window)
{
    MirSurfaceSpec* spec;
    MirBufferUsage buffer_usage = mir_buffer_usage_hardware;
    MirPixelFormat pixel_format = findValidPixelFormat();

    if (pixel_format == mir_pixel_format_invalid)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Unable to find a correct pixel format");
        return GL_FALSE;
    }
 
    spec = mir_connection_create_spec_for_normal_surface(_glfw.mir.connection,
                                                         window->mir.width,
                                                         window->mir.height,
                                                         pixel_format);

    mir_surface_spec_set_buffer_usage(spec, buffer_usage);
    mir_surface_spec_set_name(spec, "MirSurface");

    window->mir.surface = mir_surface_create_sync(spec);
    mir_surface_spec_release(spec);

    if (!mir_surface_is_valid(window->mir.surface))
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Unable to create surface: %s",
                        mir_surface_get_error_message(window->mir.surface));

        return GL_FALSE;
    }

    mir_surface_set_event_handler(window->mir.surface, addNewEvent, window);

    return GL_TRUE;
}

//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwInitEventQueue(EventQueue* queue)
{
    TAILQ_INIT(&queue->head);
}

void _glfwDeleteEventQueue(EventQueue* queue)
{
    if (queue)
    {
        EventNode* node, *node_next;
        node = queue->head.tqh_first;

        while (node != NULL)
        {
            node_next = node->entries.tqe_next;

            TAILQ_REMOVE(&queue->head, node, entries);
            deleteNode(queue, node);

            node = node_next;
        }

        free(queue);
    }
}

//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformCreateWindow(_GLFWwindow* window,
                              const _GLFWwndconfig* wndconfig,
                              const _GLFWctxconfig* ctxconfig,
                              const _GLFWfbconfig* fbconfig)
{
    if (!_glfwCreateContext(window, ctxconfig, fbconfig))
        return GL_FALSE;

    if (wndconfig->monitor)
    {
        GLFWvidmode mode;
        _glfwPlatformGetVideoMode(wndconfig->monitor, &mode);

        mir_surface_set_state(window->mir.surface, mir_surface_state_fullscreen);

        if (wndconfig->width > mode.width || wndconfig->height > mode.height)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "Mir: Requested surface size too large: %ix%i",
                            wndconfig->width, wndconfig->height);

            return GL_FALSE;
        }
    }

    window->mir.width  = wndconfig->width;
    window->mir.height = wndconfig->height;

    if (!createSurface(window))
        return GL_FALSE;

    window->mir.window = mir_buffer_stream_get_egl_native_window(
                                   mir_surface_get_buffer_stream(window->mir.surface));

    return GL_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    if (mir_surface_is_valid(window->mir.surface))
    {
        mir_surface_release_sync(window->mir.surface);
        window->mir.surface = NULL;
    }

    _glfwDestroyContext(window);
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char* title)
{
    MirSurfaceSpec* spec;
    const char* e_title = title ? title : "";

    spec = mir_connection_create_spec_for_changes(_glfw.mir.connection);
    mir_surface_spec_set_name(spec, e_title);

    mir_surface_apply_spec(window->mir.surface, spec);
    mir_surface_spec_release(spec);
}

void _glfwPlatformSetWindowSize(_GLFWwindow* window, int width, int height)
{
    MirSurfaceSpec* spec;

    spec = mir_connection_create_spec_for_changes(_glfw.mir.connection);
    mir_surface_spec_set_width (spec, width);
    mir_surface_spec_set_height(spec, height);

    mir_surface_apply_spec(window->mir.surface, spec);
    mir_surface_spec_release(spec);
}

void _glfwPlatformSetWindowPos(_GLFWwindow* window, int xpos, int ypos)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformGetWindowFrameSize(_GLFWwindow* window,
                                     int* left, int* top,
                                     int* right, int* bottom)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformGetWindowPos(_GLFWwindow* window, int* xpos, int* ypos)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformGetWindowSize(_GLFWwindow* window, int* width, int* height)
{
    if (width)
        *width  = window->mir.width;
    if (height)
        *height = window->mir.height;
}

void _glfwPlatformIconifyWindow(_GLFWwindow* window)
{
    mir_surface_set_state(window->mir.surface, mir_surface_state_minimized);
}

void _glfwPlatformRestoreWindow(_GLFWwindow* window)
{
    mir_surface_set_state(window->mir.surface, mir_surface_state_restored);
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    MirSurfaceSpec* spec;

    spec = mir_connection_create_spec_for_changes(_glfw.mir.connection);
    mir_surface_spec_set_state(spec, mir_surface_state_hidden);

    mir_surface_apply_spec(window->mir.surface, spec);
    mir_surface_spec_release(spec);
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    MirSurfaceSpec* spec;

    spec = mir_connection_create_spec_for_changes(_glfw.mir.connection);
    mir_surface_spec_set_state(spec, mir_surface_state_restored);

    mir_surface_apply_spec(window->mir.surface, spec);
    mir_surface_spec_release(spec);
}

void _glfwPlatformUnhideWindow(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

int _glfwPlatformWindowFocused(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
    return GL_FALSE;
}

int _glfwPlatformWindowIconified(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
    return GL_FALSE;
}

int _glfwPlatformWindowVisible(_GLFWwindow* window)
{
    return mir_surface_get_visibility(window->mir.surface) == mir_surface_visibility_exposed;
}

void _glfwPlatformPollEvents(void)
{
    EventNode* node = NULL;

    while ((node = dequeueEvent(_glfw.mir.event_queue)))
    {
        handleEvent(node->event, node->window);
        deleteNode(_glfw.mir.event_queue, node);
    }
}

void _glfwPlatformWaitEvents(void)
{
    pthread_mutex_lock(&_glfw.mir.event_mutex);

    if (emptyEventQueue(_glfw.mir.event_queue))
        pthread_cond_wait(&_glfw.mir.event_cond, &_glfw.mir.event_mutex);

    pthread_mutex_unlock(&_glfw.mir.event_mutex);

    _glfwPlatformPollEvents();
}

void _glfwPlatformPostEmptyEvent(void)
{
}

void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height)
{
    if (width)
        *width  = window->mir.width;
    if (height)
        *height = window->mir.height;
}

// FIXME implement
int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    MirBufferStream* stream;
    MirPixelFormat pixel_format = findValidPixelFormat();

    int i_w = image->width;
    int i_h = image->height;

    if (pixel_format == mir_pixel_format_invalid)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Unable to find a correct pixel format");
        return GL_FALSE;
    }

    stream = mir_connection_create_buffer_stream_sync(_glfw.mir.connection,
                                                      i_w, i_h,
                                                      pixel_format,
                                                      mir_buffer_usage_software);

    cursor->mir.conf = mir_cursor_configuration_from_buffer_stream(stream, xhot, yhot);

    char* dest;
    unsigned char *pixels;
    int i, r_stride, bytes_per_pixel, bytes_per_row;

    MirGraphicsRegion region;
    mir_buffer_stream_get_graphics_region(stream, &region);

    // FIXME Figure this out based on the current_pf
    bytes_per_pixel = 4;
    bytes_per_row   = bytes_per_pixel * i_w;

    dest   = region.vaddr;
    pixels = image->pixels;

    r_stride = region.stride;

    for (i = 0; i < i_h; i++)
    {
        memcpy(dest, pixels, bytes_per_row);
        dest   += r_stride;
        pixels += r_stride;
    }

    cursor->mir.custom_cursor = stream;

    return GL_TRUE;
}

const char* getSystemCursorName(int shape)
{
    switch (shape)
    {
        case GLFW_ARROW_CURSOR:
            return mir_arrow_cursor_name;
        case GLFW_IBEAM_CURSOR:
            return mir_caret_cursor_name;
        case GLFW_CROSSHAIR_CURSOR:
            return mir_crosshair_cursor_name;
        case GLFW_HAND_CURSOR:
            return mir_open_hand_cursor_name;
        case GLFW_HRESIZE_CURSOR:
            return mir_horizontal_resize_cursor_name;
        case GLFW_VRESIZE_CURSOR:
            return mir_vertical_resize_cursor_name;
    }

    return NULL;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    const char* cursor_name = getSystemCursorName(shape);

    if (cursor_name)
    {
        cursor->mir.conf          = mir_cursor_configuration_from_name(cursor_name);
        cursor->mir.custom_cursor = NULL;

        return GL_TRUE;
    }

    return GL_FALSE;
}

void _glfwPlatformDestroyCursor(_GLFWcursor* cursor)
{
    if (cursor->mir.conf)
        mir_cursor_configuration_destroy(cursor->mir.conf);
    if (cursor->mir.custom_cursor)
        mir_buffer_stream_release_sync(cursor->mir.custom_cursor);
}

void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor)
{
    if (cursor && cursor->mir.conf)
    {
        mir_wait_for(mir_surface_configure_cursor(window->mir.surface, cursor->mir.conf));
        if (cursor->mir.custom_cursor)
        {
            /* FIXME Bug https://bugs.launchpad.net/mir/+bug/1477285
                     Requires a triple buffer swap to get the cursor buffer on top! (since mir is tripled buffered)
            */
            mir_buffer_stream_swap_buffers_sync(cursor->mir.custom_cursor);
            mir_buffer_stream_swap_buffers_sync(cursor->mir.custom_cursor);
            mir_buffer_stream_swap_buffers_sync(cursor->mir.custom_cursor);
        }
    }
    else
    {
        mir_wait_for(mir_surface_configure_cursor(window->mir.surface, _glfw.mir.default_conf));
    }
}

void _glfwPlatformGetCursorPos(_GLFWwindow* window, double* xpos, double* ypos)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformSetCursorPos(_GLFWwindow* window, double xpos, double ypos)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformApplyCursorMode(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformSetClipboardString(_GLFWwindow* window, const char* string)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

const char* _glfwPlatformGetClipboardString(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);

    return NULL;
}

