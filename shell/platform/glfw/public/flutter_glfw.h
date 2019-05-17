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

// Opaque reference to a Flutter window controller.
typedef struct FlutterDesktopWindowControllerState*
    FlutterDesktopWindowControllerRef;

// Opaque reference to a Flutter window.
typedef struct FlutterDesktopWindow* FlutterDesktopWindowRef;

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
// valid until FlutterDesktopRunWindowLoop has been called and returned, or
// FlutterDesktopDestroyWindow is called.
// Note that calling FlutterDesktopCreateWindow without later calling
// one of those two methods on the returned reference is a memory leak.
FLUTTER_EXPORT FlutterDesktopWindowControllerRef
FlutterDesktopCreateWindow(int initial_width,
                           int initial_height,
                           const char* title,
                           const char* assets_path,
                           const char* icu_data_path,
                           const char** arguments,
                           size_t argument_count);

// Shuts down the engine instance associated with |controller|, and cleans up
// associated state.
//
// |controller| is no longer valid after this call.
FLUTTER_EXPORT void FlutterDesktopDestroyWindow(
    FlutterDesktopWindowControllerRef controller);

// Loops on Flutter window events until the window is closed.
//
// Once this function returns, |controller| is no longer valid, and must not be
// be used again, as it calls FlutterDesktopDestroyWindow internally.
//
// TODO: Replace this with a method that allows running the runloop
// incrementally.
FLUTTER_EXPORT void FlutterDesktopRunWindowLoop(
    FlutterDesktopWindowControllerRef controller);

// Returns the window handle for the window associated with
// FlutterDesktopWindowControllerRef.
//
// Its lifetime is the same as the |controller|'s.
FLUTTER_EXPORT FlutterDesktopWindowRef
FlutterDesktopGetWindow(FlutterDesktopWindowControllerRef controller);

// Returns the plugin registrar handle for the plugin with the given name.
//
// The name must be unique across the application.
FLUTTER_EXPORT FlutterDesktopPluginRegistrarRef
FlutterDesktopGetPluginRegistrar(FlutterDesktopWindowControllerRef controller,
                                 const char* plugin_name);

// Enables or disables hover tracking.
//
// If hover is enabled, mouse movement will send hover events to the Flutter
// engine, rather than only tracking the mouse while the button is pressed.
// Defaults to on.
FLUTTER_EXPORT void FlutterDesktopWindowSetHoverEnabled(
    FlutterDesktopWindowRef flutter_window,
    bool enabled);

// Sets the displayed title for |flutter_window|.
FLUTTER_EXPORT void FlutterDesktopWindowSetTitle(
    FlutterDesktopWindowRef flutter_window,
    const char* title);

// Sets the displayed icon for |flutter_window|.
//
// The pixel format is 32-bit RGBA. The provided image data only needs to be
// valid for the duration of the call to this method. Pass a nullptr to revert
// to the default icon.
FLUTTER_EXPORT void FlutterDesktopWindowSetIcon(
    FlutterDesktopWindowRef flutter_window,
    uint8_t* pixel_data,
    int width,
    int height);

// Gets the position and size of |flutter_window| in screen coordinates.
FLUTTER_EXPORT void FlutterDesktopWindowGetFrame(
    FlutterDesktopWindowRef flutter_window,
    int* x,
    int* y,
    int* width,
    int* height);

// Sets the position and size of |flutter_window| in screen coordinates.
FLUTTER_EXPORT void FlutterDesktopWindowSetFrame(
    FlutterDesktopWindowRef flutter_window,
    int x,
    int y,
    int width,
    int height);

// Returns the scale factor--the number of pixels per screen coordinate--for
// |flutter_window|.
FLUTTER_EXPORT double FlutterDesktopWindowGetScaleFactor(
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

// Returns the window associated with this registrar's engine instance.
// This is a GLFW shell-specific extension to flutter_plugin_registrar.h
FLUTTER_EXPORT FlutterDesktopWindowRef
FlutterDesktopRegistrarGetWindow(FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_GLFW_PUBLIC_FLUTTER_GLFW_H_
