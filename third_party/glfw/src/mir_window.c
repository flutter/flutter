//========================================================================
// GLFW 3.2 Mir - www.glfw.org
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

static GLFWbool emptyEventQueue(EventQueue* queue)
{
    return queue->head.tqh_first == NULL;
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

static int toGLFWKeyCode(uint32_t key)
{
    if (key < sizeof(_glfw.mir.publicKeys) / sizeof(_glfw.mir.publicKeys[0]))
        return _glfw.mir.publicKeys[key];

    return GLFW_KEY_UNKNOWN;
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

static GLFWbool createSurface(_GLFWwindow* window)
{
    MirSurfaceSpec* spec;
    MirBufferUsage buffer_usage = mir_buffer_usage_hardware;
    MirPixelFormat pixel_format = findValidPixelFormat();

    if (pixel_format == mir_pixel_format_invalid)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Unable to find a correct pixel format");
        return GLFW_FALSE;
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

        return GLFW_FALSE;
    }

    mir_surface_set_event_handler(window->mir.surface, addNewEvent, window);

    return GLFW_TRUE;
}

//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

void _glfwInitEventQueueMir(EventQueue* queue)
{
    TAILQ_INIT(&queue->head);
}

void _glfwDeleteEventQueueMir(EventQueue* queue)
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
    if (ctxconfig->api != GLFW_NO_API)
    {
        if (!_glfwCreateContextEGL(window, ctxconfig, fbconfig))
            return GLFW_FALSE;
    }

    if (window->monitor)
    {
        GLFWvidmode mode;
        _glfwPlatformGetVideoMode(window->monitor, &mode);

        mir_surface_set_state(window->mir.surface, mir_surface_state_fullscreen);

        if (wndconfig->width > mode.width || wndconfig->height > mode.height)
        {
            _glfwInputError(GLFW_PLATFORM_ERROR,
                            "Mir: Requested surface size too large: %ix%i",
                            wndconfig->width, wndconfig->height);

            return GLFW_FALSE;
        }
    }

    window->mir.width  = wndconfig->width;
    window->mir.height = wndconfig->height;

    if (!createSurface(window))
        return GLFW_FALSE;

    window->mir.window = mir_buffer_stream_get_egl_native_window(
                                   mir_surface_get_buffer_stream(window->mir.surface));

    return GLFW_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    if (mir_surface_is_valid(window->mir.surface))
    {
        mir_surface_release_sync(window->mir.surface);
        window->mir.surface = NULL;
    }

    _glfwDestroyContextEGL(window);
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

void _glfwPlatformSetWindowIcon(_GLFWwindow* window,
                                int count, const GLFWimage* images)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
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

void _glfwPlatformSetWindowSizeLimits(_GLFWwindow* window,
                                      int minwidth, int minheight,
                                      int maxwidth, int maxheight)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformSetWindowAspectRatio(_GLFWwindow* window, int numer, int denom)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
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

void _glfwPlatformMaximizeWindow(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
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

void _glfwPlatformFocusWindow(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

void _glfwPlatformSetWindowMonitor(_GLFWwindow* window,
                                   _GLFWmonitor* monitor,
                                   int xpos, int ypos,
                                   int width, int height,
                                   int refreshRate)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

int _glfwPlatformWindowFocused(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
    return GLFW_FALSE;
}

int _glfwPlatformWindowIconified(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
    return GLFW_FALSE;
}

int _glfwPlatformWindowVisible(_GLFWwindow* window)
{
    return mir_surface_get_visibility(window->mir.surface) == mir_surface_visibility_exposed;
}

int _glfwPlatformWindowMaximized(_GLFWwindow* window)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
    return GLFW_FALSE;
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

void _glfwPlatformWaitEventsTimeout(double timeout)
{
    pthread_mutex_lock(&_glfw.mir.event_mutex);

    if (emptyEventQueue(_glfw.mir.event_queue))
    {
        struct timespec time;
        clock_gettime(CLOCK_REALTIME, &time);
        time.tv_sec += (long) timeout;
        time.tv_nsec += (long) ((timeout - (long) timeout) * 1e9);
        pthread_cond_timedwait(&_glfw.mir.event_cond, &_glfw.mir.event_mutex, &time);
    }

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
        return GLFW_FALSE;
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

    return GLFW_TRUE;
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

        return GLFW_TRUE;
    }

    return GLFW_FALSE;
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

void _glfwPlatformSetCursorMode(_GLFWwindow* window, int mode)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
}

const char* _glfwPlatformGetKeyName(int key, int scancode)
{
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Mir: Unsupported function %s", __PRETTY_FUNCTION__);
    return NULL;
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

char** _glfwPlatformGetRequiredInstanceExtensions(unsigned int* count)
{
    char** extensions;

    *count = 0;

    if (!_glfw.vk.KHR_mir_surface)
        return NULL;

    extensions = calloc(2, sizeof(char*));
    extensions[0] = strdup("VK_KHR_surface");
    extensions[1] = strdup("VK_KHR_mir_surface");

    *count = 2;
    return extensions;
}

int _glfwPlatformGetPhysicalDevicePresentationSupport(VkInstance instance,
                                                      VkPhysicalDevice device,
                                                      unsigned int queuefamily)
{
    PFN_vkGetPhysicalDeviceMirPresentationSupportKHR vkGetPhysicalDeviceMirPresentationSupportKHR =
        (PFN_vkGetPhysicalDeviceMirPresentationSupportKHR)
        vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMirPresentationSupportKHR");
    if (!vkGetPhysicalDeviceMirPresentationSupportKHR)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Mir: Vulkan instance missing VK_KHR_mir_surface extension");
        return GLFW_FALSE;
    }

    return vkGetPhysicalDeviceMirPresentationSupportKHR(device,
                                                        queuefamily,
                                                        _glfw.mir.connection);
}

VkResult _glfwPlatformCreateWindowSurface(VkInstance instance,
                                          _GLFWwindow* window,
                                          const VkAllocationCallbacks* allocator,
                                          VkSurfaceKHR* surface)
{
    VkResult err;
    VkMirSurfaceCreateInfoKHR sci;
    PFN_vkCreateMirSurfaceKHR vkCreateMirSurfaceKHR;

    vkCreateMirSurfaceKHR = (PFN_vkCreateMirSurfaceKHR)
        vkGetInstanceProcAddr(instance, "vkCreateMirSurfaceKHR");
    if (!vkCreateMirSurfaceKHR)
    {
        _glfwInputError(GLFW_API_UNAVAILABLE,
                        "Mir: Vulkan instance missing VK_KHR_mir_surface extension");
        return VK_ERROR_EXTENSION_NOT_PRESENT;
    }

    memset(&sci, 0, sizeof(sci));
    sci.sType = VK_STRUCTURE_TYPE_MIR_SURFACE_CREATE_INFO_KHR;
    sci.connection = _glfw.mir.connection;
    sci.mirSurface = window->mir.surface;

    err = vkCreateMirSurfaceKHR(instance, &sci, allocator, surface);
    if (err)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Mir: Failed to create Vulkan surface: %s",
                        _glfwGetVulkanResultString(err));
    }

    return err;
}


//////////////////////////////////////////////////////////////////////////
//////                        GLFW native API                       //////
//////////////////////////////////////////////////////////////////////////

GLFWAPI MirConnection* glfwGetMirDisplay(void)
{
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return _glfw.mir.connection;
}

GLFWAPI MirSurface* glfwGetMirWindow(GLFWwindow* handle)
{
    _GLFWwindow* window = (_GLFWwindow*) handle;
    _GLFW_REQUIRE_INIT_OR_RETURN(NULL);
    return window->mir.surface;
}

