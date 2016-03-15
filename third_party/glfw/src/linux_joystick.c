//========================================================================
// GLFW 3.1 Linux - www.glfw.org
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

#if defined(__linux__)
#include <linux/joystick.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/inotify.h>
#include <fcntl.h>
#include <errno.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#endif // __linux__


// Attempt to open the specified joystick device
//
static void openJoystickDevice(const char* path)
{
#if defined(__linux__)
    char axisCount, buttonCount;
    char name[256];
    int joy, fd, version;

    for (joy = GLFW_JOYSTICK_1;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        if (!_glfw.linux_js.js[joy].present)
            continue;

        if (strcmp(_glfw.linux_js.js[joy].path, path) == 0)
            return;
    }

    for (joy = GLFW_JOYSTICK_1;  joy <= GLFW_JOYSTICK_LAST;  joy++)
    {
        if (!_glfw.linux_js.js[joy].present)
            break;
    }

    if (joy > GLFW_JOYSTICK_LAST)
        return;

    fd = open(path, O_RDONLY | O_NONBLOCK);
    if (fd == -1)
        return;

    _glfw.linux_js.js[joy].fd = fd;

    // Verify that the joystick driver version is at least 1.0
    ioctl(fd, JSIOCGVERSION, &version);
    if (version < 0x010000)
    {
        // It's an old 0.x interface (we don't support it)
        close(fd);
        return;
    }

    if (ioctl(fd, JSIOCGNAME(sizeof(name)), name) < 0)
        strncpy(name, "Unknown", sizeof(name));

    _glfw.linux_js.js[joy].name = strdup(name);
    _glfw.linux_js.js[joy].path = strdup(path);

    ioctl(fd, JSIOCGAXES, &axisCount);
    _glfw.linux_js.js[joy].axisCount = (int) axisCount;

    ioctl(fd, JSIOCGBUTTONS, &buttonCount);
    _glfw.linux_js.js[joy].buttonCount = (int) buttonCount;

    _glfw.linux_js.js[joy].axes = calloc(axisCount, sizeof(float));
    _glfw.linux_js.js[joy].buttons = calloc(buttonCount, 1);

    _glfw.linux_js.js[joy].present = GL_TRUE;
#endif // __linux__
}

// Polls for and processes events for all present joysticks
//
static void pollJoystickEvents(void)
{
#if defined(__linux__)
    int i;
    struct js_event e;
    ssize_t offset = 0;
    char buffer[16384];

    const ssize_t size = read(_glfw.linux_js.inotify, buffer, sizeof(buffer));

    while (size > offset)
    {
        regmatch_t match;
        const struct inotify_event* e = (struct inotify_event*) (buffer + offset);

        if (regexec(&_glfw.linux_js.regex, e->name, 1, &match, 0) == 0)
        {
            char path[20];
            snprintf(path, sizeof(path), "/dev/input/%s", e->name);
            openJoystickDevice(path);
        }

        offset += sizeof(struct inotify_event) + e->len;
    }

    for (i = 0;  i <= GLFW_JOYSTICK_LAST;  i++)
    {
        if (!_glfw.linux_js.js[i].present)
            continue;

        // Read all queued events (non-blocking)
        for (;;)
        {
            errno = 0;
            if (read(_glfw.linux_js.js[i].fd, &e, sizeof(e)) < 0)
            {
                if (errno == ENODEV)
                {
                    // The joystick was disconnected

                    free(_glfw.linux_js.js[i].axes);
                    free(_glfw.linux_js.js[i].buttons);
                    free(_glfw.linux_js.js[i].name);
                    free(_glfw.linux_js.js[i].path);

                    memset(&_glfw.linux_js.js[i], 0, sizeof(_glfw.linux_js.js[i]));
                }

                break;
            }

            // We don't care if it's an init event or not
            e.type &= ~JS_EVENT_INIT;

            switch (e.type)
            {
                case JS_EVENT_AXIS:
                    _glfw.linux_js.js[i].axes[e.number] =
                        (float) e.value / 32767.0f;
                    break;

                case JS_EVENT_BUTTON:
                    _glfw.linux_js.js[i].buttons[e.number] =
                        e.value ? GLFW_PRESS : GLFW_RELEASE;
                    break;

                default:
                    break;
            }
        }
    }
#endif // __linux__
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW internal API                      //////
//////////////////////////////////////////////////////////////////////////

// Initialize joystick interface
//
int _glfwInitJoysticks(void)
{
#if defined(__linux__)
    const char* dirname = "/dev/input";
    DIR* dir;

    _glfw.linux_js.inotify = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    if (_glfw.linux_js.inotify == -1)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Linux: Failed to initialize inotify: %s",
                        strerror(errno));
        return GL_FALSE;
    }

    // HACK: Register for IN_ATTRIB as well to get notified when udev is done
    //       This works well in practice but the true way is libudev

    _glfw.linux_js.watch = inotify_add_watch(_glfw.linux_js.inotify,
                                             dirname,
                                             IN_CREATE | IN_ATTRIB);
    if (_glfw.linux_js.watch == -1)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Linux: Failed to watch for joystick connections in %s: %s",
                        dirname,
                        strerror(errno));
        // Continue without device connection notifications
    }

    if (regcomp(&_glfw.linux_js.regex, "^js[0-9]\\+$", 0) != 0)
    {
        _glfwInputError(GLFW_PLATFORM_ERROR, "Linux: Failed to compile regex");
        return GL_FALSE;
    }

    dir = opendir(dirname);
    if (dir)
    {
        struct dirent* entry;

        while ((entry = readdir(dir)))
        {
            char path[20];
            regmatch_t match;

            if (regexec(&_glfw.linux_js.regex, entry->d_name, 1, &match, 0) != 0)
                continue;

            snprintf(path, sizeof(path), "%s/%s", dirname, entry->d_name);
            openJoystickDevice(path);
        }

        closedir(dir);
    }
    else
    {
        _glfwInputError(GLFW_PLATFORM_ERROR,
                        "Linux: Failed to open joystick device directory %s: %s",
                        dirname,
                        strerror(errno));
        // Continue with no joysticks detected
    }

#endif // __linux__

    return GL_TRUE;
}

// Close all opened joystick handles
//
void _glfwTerminateJoysticks(void)
{
#if defined(__linux__)
    int i;

    for (i = 0;  i <= GLFW_JOYSTICK_LAST;  i++)
    {
        if (_glfw.linux_js.js[i].present)
        {
            close(_glfw.linux_js.js[i].fd);
            free(_glfw.linux_js.js[i].axes);
            free(_glfw.linux_js.js[i].buttons);
            free(_glfw.linux_js.js[i].name);
            free(_glfw.linux_js.js[i].path);
        }
    }

    regfree(&_glfw.linux_js.regex);

    if (_glfw.linux_js.inotify > 0)
    {
        if (_glfw.linux_js.watch > 0)
            inotify_rm_watch(_glfw.linux_js.inotify, _glfw.linux_js.watch);

        close(_glfw.linux_js.inotify);
    }
#endif // __linux__
}


//////////////////////////////////////////////////////////////////////////
//////                       GLFW platform API                      //////
//////////////////////////////////////////////////////////////////////////

int _glfwPlatformJoystickPresent(int joy)
{
    pollJoystickEvents();

    return _glfw.linux_js.js[joy].present;
}

const float* _glfwPlatformGetJoystickAxes(int joy, int* count)
{
    pollJoystickEvents();

    *count = _glfw.linux_js.js[joy].axisCount;
    return _glfw.linux_js.js[joy].axes;
}

const unsigned char* _glfwPlatformGetJoystickButtons(int joy, int* count)
{
    pollJoystickEvents();

    *count = _glfw.linux_js.js[joy].buttonCount;
    return _glfw.linux_js.js[joy].buttons;
}

const char* _glfwPlatformGetJoystickName(int joy)
{
    pollJoystickEvents();

    return _glfw.linux_js.js[joy].name;
}

