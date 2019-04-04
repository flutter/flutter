// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_GLFW_PUBLIC_FLUTTER_GLFW_H_
#define FLUTTER_SHELL_PLATFORM_GLFW_PUBLIC_FLUTTER_GLFW_H_

#include <stddef.h>
#include <stdint.h>

#include "flutter_export.h"
#include "flutter_messenger.h"
#include "flutter_plugin_registrar.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a Flutter window.
typedef struct FlutterDesktopWindowState* FlutterDesktopWindowRef;

// Opaque reference to a Flutter engine instance.
typedef struct FlutterDesktopEngineState* FlutterDesktopEngineRef;

// Sets up the library's graphic context. Must be called before any other
// methods.
//
// Note: Internally, this library uses GLFW, which does not support multiple
// copies within the same process. Internally this calls glfwInit, which will
// fail if you have called glfwInit elsewhere in the process.
FLUTTER_EXPORT bool FlutterDesktopInit();

// Tears down library state. Must be called before the process terminates.
FLUTTER_EXPORT void FlutterDesktopTerminate();

// Creates a Window running a Flutter Application.
//
// FlutterDesktopInit() must be called prior to this function.
//
// The |assets_path| is the path to the flutter_assets folder for the Flutter
// application to be run. |icu_data_path| is the path to the icudtl.dat file
// for the version of Flutter you are using.
//
// The |arguments| are passed to the Flutter engine. See:
// https://github.com/flutter/engine/blob/master/shell/common/switches.h for
// for details. Not all arguments will apply to desktop.
//
// Returns a null pointer in the event of an error. Otherwise, the pointer is
// valid until FlutterDesktopRunWindowLoop has been called and returned.
// Note that calling FlutterDesktopCreateWindow without later calling
// FlutterDesktopRunWindowLoop on the returned reference is a memory leak.
FLUTTER_EXPORT FlutterDesktopWindowRef
FlutterDesktopCreateWindow(int initial_width,
                           int initial_height,
                           const char* title,
                           const char* assets_path,
                           const char* icu_data_path,
                           const char** arguments,
                           size_t argument_count);

// Enables or disables hover tracking.
//
// If hover is enabled, mouse movement will send hover events to the Flutter
// engine, rather than only tracking the mouse while the button is pressed.
// Defaults to off.
FLUTTER_EXPORT void FlutterDesktopSetHoverEnabled(
    FlutterDesktopWindowRef flutter_window,
    bool enabled);

// Sets the displayed title for |flutter_window|.
FLUTTER_EXPORT void FlutterDesktopSetWindowTitle(
    FlutterDesktopWindowRef flutter_window,
    const char* title);

// Sets the displayed icon for |flutter_window|.
//
// The pixel format is 32-bit RGBA. The provided image data only needs to be
// valid for the duration of the call to this method. Pass a nullptr to revert
// to the default icon.
FLUTTER_EXPORT void FlutterDesktopSetWindowIcon(
    FlutterDesktopWindowRef flutter_window,
    uint8_t* pixel_data,
    int width,
    int height);

// Loops on Flutter window events until the window is closed.
//
// Once this function returns, FlutterDesktopWindowRef is no longer valid, and
// must not be used again.
FLUTTER_EXPORT void FlutterDesktopRunWindowLoop(
    FlutterDesktopWindowRef flutter_window);

// Runs an instance of a headless Flutter engine.
//
// The |assets_path| is the path to the flutter_assets folder for the Flutter
// application to be run. |icu_data_path| is the path to the icudtl.dat file
// for the version of Flutter you are using.
//
// The |arguments| are passed to the Flutter engine. See:
// https://github.com/flutter/engine/blob/master/shell/common/switches.h for
// for details. Not all arguments will apply to desktop.
//
// Returns a null pointer in the event of an error.
FLUTTER_EXPORT FlutterDesktopEngineRef
FlutterDesktopRunEngine(const char* assets_path,
                        const char* icu_data_path,
                        const char** arguments,
                        size_t argument_count);

// Shuts down the given engine instance. Returns true if the shutdown was
// successful. |engine_ref| is no longer valid after this call.
FLUTTER_EXPORT bool FlutterDesktopShutDownEngine(
    FlutterDesktopEngineRef engine_ref);

// Returns the plugin registrar handle for the plugin with the given name.
//
// The name must be unique across the application.
FLUTTER_EXPORT FlutterDesktopPluginRegistrarRef
FlutterDesktopGetPluginRegistrar(FlutterDesktopWindowRef flutter_window,
                                 const char* plugin_name);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_GLFW_PUBLIC_FLUTTER_GLFW_H_
