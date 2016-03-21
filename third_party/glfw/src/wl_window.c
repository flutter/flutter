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

#define _GNU_SOURCE

#include "internal.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <poll.h>

#include <wayland-egl.h>
#include <wayland-cursor.h>


static void handlePing(void* data,
                       struct wl_shell_surface* shellSurface,
                       uint32_t serial)
{
    wl_shell_surface_pong(shellSurface, serial);
}

static void handleConfigure(void* data,
                            struct wl_shell_surface* shellSurface,
                            uint32_t edges,
                            int32_t width,
                            int32_t height)
{
    _GLFWwindow* window = data;
    _glfwInputFramebufferSize(window, width, height);
    _glfwInputWindowSize(window, width, height);
    _glfwPlatformSetWindowSize(window, width, height);
    _glfwInputWindowDamage(window);
}

static void handlePopupDone(void* data,
                            struct wl_shell_surface* shellSurface)
{
}

static const struct wl_shell_surface_listener shellSurfaceListener = {
    handlePing,
    handleConfigure,
    handlePopupDone
};

static GLboolean createSurface(_GLFWwindow* window,
                               const _GLFWwndconfig* wndconfig)
{
    window->wl.surface = wl_compositor_create_surface(_glfw.wl.compositor);
    if (!window->wl.surface)
        return GL_FALSE;

    wl_surface_set_user_data(window->wl.surface, window);

    window->wl.native = wl_egl_window_create(window->wl.surface,
                                             wndconfig->width,
                                             wndconfig->height);
    if (!window->wl.native)
        return GL_FALSE;

    window->wl.shell_surface = wl_shell_get_shell_surface(_glfw.wl.shell,
                                                          window->wl.surface);
    if (!window->wl.shell_surface)
        return GL_FALSE;

    wl_shell_surface_add_listener(window->wl.shell_surface,
                                  &shellSurfaceListener,
                                  window);

    window->wl.width = wndconfig->width;
    window->wl.height = wndconfig->height;

    return GL_TRUE;
}

static int
createTmpfileCloexec(char* tmpname)
{
    int fd;

    fd = mkostemp(tmpname, O_CLOEXEC);
    if (fd >= 0)
        unlink(tmpname);

    return fd;
}

static void
handleEvents(int timeout)
{
    struct wl_display* display = _glfw.wl.display;
    struct pollfd fds[] = {
        { wl_display_get_fd(display), POLLIN },
    };

    while (wl_display_prepare_read(display) != 0)
        wl_display_dispatch_pending(display);

    // If an error different from EAGAIN happens, we have likely been
    // disconnected from the Wayland session, try to handle that the best we
    // can.
    if (wl_display_flush(display) < 0 && errno != EAGAIN)
    {
        _GLFWwindow* window = _glfw.windowListHead;
        while (window)
        {
            _glfwInputWindowCloseRequest(window);
            window = window->next;
        }
        wl_display_cancel_read(display);
        return;
    }

    if (poll(fds, 1, timeout) > 0)
    {
        wl_display_read_events(display);
        wl_display_dispatch_pending(display);
    }
    else
    {
        wl_display_cancel_read(display);
    }
}

/*
 * Create a new, unique, anonymous file of the given size, and
 * return the file descriptor for it. The file descriptor is set
 * CLOEXEC. The file is immediately suitable for mmap()'ing
 * the given size at offset zero.
 *
 * The file should not have a permanent backing store like a disk,
 * but may have if XDG_RUNTIME_DIR is not properly implemented in OS.
 *
 * The file name is deleted from the file system.
 *
 * The file is suitable for buffer sharing between processes by
 * transmitting the file descriptor over Unix sockets using the
 * SCM_RIGHTS methods.
 *
 * posix_fallocate() is used to guarantee that disk space is available
 * for the file at the given size. If disk space is insufficent, errno
 * is set to ENOSPC. If posix_fallocate() is not supported, program may
 * receive SIGBUS on accessing mmap()'ed file contents instead.
 */
int
createAnonymousFile(off_t size)
{
    static const char template[] = "/glfw-shared-XXXXXX";
    const char* path;
    char* name;
    int fd;
    int ret;

    path = getenv("XDG_RUNTIME_DIR");
    if (!path)
    {
        errno = ENOENT;
        return -1;
    }

    name = calloc(strlen(path) + sizeof(template), 1);
    strcpy(name, path);
    strcat(name, template);

    fd = createTmpfileCloexec(name);

    free(name);

    if (fd < 0)
        return -1;
    ret = posix_fallocate(fd, 0, size);
    if (ret != 0)
    {
        close(fd);
        errno = ret;
        return -1;
    }
    return fd;
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

    if (!createSurface(window, wndconfig))
        return GL_FALSE;

    if (wndconfig->monitor)
    {
        wl_shell_surface_set_fullscreen(
            window->wl.shell_surface,
            WL_SHELL_SURFACE_FULLSCREEN_METHOD_DEFAULT,
            0,
            wndconfig->monitor->wl.output);
    }
    else
    {
        wl_shell_surface_set_toplevel(window->wl.shell_surface);
    }

    window->wl.currentCursor = NULL;

    return GL_TRUE;
}

void _glfwPlatformDestroyWindow(_GLFWwindow* window)
{
    if (window == _glfw.wl.pointerFocus)
    {
        _glfw.wl.pointerFocus = NULL;
        _glfwInputCursorEnter(window, GL_FALSE);
    }
    if (window == _glfw.wl.keyboardFocus)
    {
        _glfw.wl.keyboardFocus = NULL;
        _glfwInputWindowFocus(window, GL_FALSE);
    }

    _glfwDestroyContext(window);

    if (window->wl.native)
        wl_egl_window_destroy(window->wl.native);

    if (window->wl.shell_surface)
        wl_shell_surface_destroy(window->wl.shell_surface);

    if (window->wl.surface)
        wl_surface_destroy(window->wl.surface);
}

void _glfwPlatformSetWindowTitle(_GLFWwindow* window, const char* title)
{
    wl_shell_surface_set_title(window->wl.shell_surface, title);
}

void _glfwPlatformGetWindowPos(_GLFWwindow* window, int* xpos, int* ypos)
{
    // A Wayland client is not aware of its position, so just warn and leave it
    // as (0, 0)

    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Wayland: Window position retrieval not supported");
}

void _glfwPlatformSetWindowPos(_GLFWwindow* window, int xpos, int ypos)
{
    // A Wayland client can not set its position, so just warn

    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Wayland: Window position setting not supported");
}

void _glfwPlatformGetWindowSize(_GLFWwindow* window, int* width, int* height)
{
    if (width)
        *width = window->wl.width;
    if (height)
        *height = window->wl.height;
}

void _glfwPlatformSetWindowSize(_GLFWwindow* window, int width, int height)
{
    wl_egl_window_resize(window->wl.native, width, height, 0, 0);
    window->wl.width = width;
    window->wl.height = height;
}

void _glfwPlatformGetFramebufferSize(_GLFWwindow* window, int* width, int* height)
{
    _glfwPlatformGetWindowSize(window, width, height);
}

void _glfwPlatformGetWindowFrameSize(_GLFWwindow* window,
                                     int* left, int* top,
                                     int* right, int* bottom)
{
    // TODO
    fprintf(stderr, "_glfwPlatformGetWindowFrameSize not implemented yet\n");
}

void _glfwPlatformIconifyWindow(_GLFWwindow* window)
{
    // TODO
    fprintf(stderr, "_glfwPlatformIconifyWindow not implemented yet\n");
}

void _glfwPlatformRestoreWindow(_GLFWwindow* window)
{
    // TODO
    fprintf(stderr, "_glfwPlatformRestoreWindow not implemented yet\n");
}

void _glfwPlatformShowWindow(_GLFWwindow* window)
{
    wl_shell_surface_set_toplevel(window->wl.shell_surface);
}

void _glfwPlatformUnhideWindow(_GLFWwindow* window)
{
    // TODO
    fprintf(stderr, "_glfwPlatformUnhideWindow not implemented yet\n");
}

void _glfwPlatformHideWindow(_GLFWwindow* window)
{
    wl_surface_attach(window->wl.surface, NULL, 0, 0);
    wl_surface_commit(window->wl.surface);
}

int _glfwPlatformWindowFocused(_GLFWwindow* window)
{
    // TODO
    return GL_FALSE;
}

int _glfwPlatformWindowIconified(_GLFWwindow* window)
{
    // TODO
    return GL_FALSE;
}

int _glfwPlatformWindowVisible(_GLFWwindow* window)
{
    // TODO
    return GL_FALSE;
}

void _glfwPlatformPollEvents(void)
{
    handleEvents(0);
}

void _glfwPlatformWaitEvents(void)
{
    handleEvents(-1);
}

void _glfwPlatformPostEmptyEvent(void)
{
    wl_display_sync(_glfw.wl.display);
}

void _glfwPlatformGetCursorPos(_GLFWwindow* window, double* xpos, double* ypos)
{
    if (xpos)
        *xpos = window->wl.cursorPosX;
    if (ypos)
        *ypos = window->wl.cursorPosY;
}

void _glfwPlatformSetCursorPos(_GLFWwindow* window, double x, double y)
{
    // A Wayland client can not set the cursor position
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Wayland: Cursor position setting not supported");
}

void _glfwPlatformApplyCursorMode(_GLFWwindow* window)
{
    _glfwPlatformSetCursor(window, window->wl.currentCursor);
}

int _glfwPlatformCreateCursor(_GLFWcursor* cursor,
                              const GLFWimage* image,
                              int xhot, int yhot)
{
    struct wl_shm_pool* pool;
    int stride = image->width * 4;
    int length = image->width * image->height * 4;
    void* data;
    int fd, i;

    fd = createAnonymousFile(length);
    if (fd < 0)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Creating a buffer file for %d B failed: %m\n",
                        length);
        return GL_FALSE;
    }

    data = mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Wayland: Cursor mmap failed: %m\n");
        close(fd);
        return GL_FALSE;
    }

    pool = wl_shm_create_pool(_glfw.wl.shm, fd, length);

    close(fd);
    unsigned char* source = (unsigned char*) image->pixels;
    unsigned char* target = data;
    for (i = 0;  i < image->width * image->height;  i++, source += 4)
    {
        *target++ = source[2];
        *target++ = source[1];
        *target++ = source[0];
        *target++ = source[3];
    }

    cursor->wl.buffer =
        wl_shm_pool_create_buffer(pool, 0,
                                  image->width,
                                  image->height,
                                  stride, WL_SHM_FORMAT_ARGB8888);
    munmap(data, length);
    wl_shm_pool_destroy(pool);

    cursor->wl.width = image->width;
    cursor->wl.height = image->height;
    cursor->wl.xhot = xhot;
    cursor->wl.yhot = yhot;
    return GL_TRUE;
}

int _glfwPlatformCreateStandardCursor(_GLFWcursor* cursor, int shape)
{
    // TODO
    fprintf(stderr, "_glfwPlatformCreateStandardCursor not implemented yet\n");
    return GL_FALSE;
}

void _glfwPlatformDestroyCursor(_GLFWcursor* cursor)
{
    wl_buffer_destroy(cursor->wl.buffer);
}

void _glfwPlatformSetCursor(_GLFWwindow* window, _GLFWcursor* cursor)
{
    struct wl_buffer* buffer;
    struct wl_cursor_image* image;
    struct wl_surface* surface = _glfw.wl.cursorSurface;

    if (!_glfw.wl.pointer)
        return;

    window->wl.currentCursor = cursor;

    // If we're not in the correct window just save the cursor
    // the next time the pointer enters the window the cursor will change
    if (window != _glfw.wl.pointerFocus)
        return;

    if (window->cursorMode == GLFW_CURSOR_NORMAL)
    {
        if (cursor == NULL)
        {
            image = _glfw.wl.defaultCursor->images[0];
            buffer = wl_cursor_image_get_buffer(image);
            if (!buffer)
                return;
            wl_pointer_set_cursor(_glfw.wl.pointer, _glfw.wl.pointerSerial,
                                  surface,
                                  image->hotspot_x,
                                  image->hotspot_y);
            wl_surface_attach(surface, buffer, 0, 0);
            wl_surface_damage(surface, 0, 0,
                              image->width, image->height);
            wl_surface_commit(surface);
        }
        else
        {
            wl_pointer_set_cursor(_glfw.wl.pointer, _glfw.wl.pointerSerial,
                                  surface,
                                  cursor->wl.xhot,
                                  cursor->wl.yhot);
            wl_surface_attach(surface, cursor->wl.buffer, 0, 0);
            wl_surface_damage(surface, 0, 0,
                              cursor->wl.width, cursor->wl.height);
            wl_surface_commit(surface);
        }
    }
    else /* Cursor is hidden set cursor surface to NULL */
    {
        wl_pointer_set_cursor(_glfw.wl.pointer, _glfw.wl.pointerSerial, NULL, 0, 0);
    }
}

void _glfwPlatformSetClipboardString(_GLFWwindow* window, const char* string)
{
    // TODO
    fprintf(stderr, "_glfwPlatformSetClipboardString not implemented yet\n");
}

const char* _glfwPlatformGetClipboardString(_GLFWwindow* window)
{
    // TODO
    fprintf(stderr, "_glfwPlatformGetClipboardString not implemented yet\n");
    return NULL;
}

