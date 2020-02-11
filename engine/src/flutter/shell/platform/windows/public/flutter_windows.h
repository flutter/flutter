// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_PUBLIC_FLUTTER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_PUBLIC_FLUTTER_H_

#include <stddef.h>
#include <stdint.h>

#include "flutter_export.h"
#include "flutter_messenger.h"
#include "flutter_plugin_registrar.h"

#include "Windows.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a Flutter window controller.
typedef struct FlutterDesktopViewControllerState*
    FlutterDesktopViewControllerRef;

// Opaque reference to a Flutter window.
typedef struct FlutterDesktopView* FlutterDesktopViewRef;

// Opaque reference to a Flutter engine instance.
typedef struct FlutterDesktopEngineState* FlutterDesktopEngineRef;

// Creates a View running a Flutter Application.
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
FLUTTER_EXPORT FlutterDesktopViewControllerRef
FlutterDesktopCreateViewController(int initial_width,
                                   int initial_height,
                                   const char* assets_path,
                                   const char* icu_data_path,
                                   const char** arguments,
                                   size_t argument_count);

// Shuts down the engine instance associated with |controller|, and cleans up
// associated state.
//
// |controller| is no longer valid after this call.
FLUTTER_EXPORT void FlutterDesktopDestroyViewController(
    FlutterDesktopViewControllerRef controller);

// Returns the plugin registrar handle for the plugin with the given name.
//
// The name must be unique across the application.
FLUTTER_EXPORT FlutterDesktopPluginRegistrarRef
FlutterDesktopGetPluginRegistrar(FlutterDesktopViewControllerRef controller,
                                 const char* plugin_name);

// Returns the view managed by the given controller.
FLUTTER_EXPORT FlutterDesktopViewRef
FlutterDesktopGetView(FlutterDesktopViewControllerRef controller);

// Processes any pending events in the Flutter engine, and returns the
// number of nanoseconds until the next scheduled event (or  max, if none).
//
// This should be called on every run of the application-level runloop, and
// a wait for native events in the runloop should never be longer than the
// last return value from this function.
FLUTTER_EXPORT uint64_t
FlutterDesktopProcessMessages(FlutterDesktopViewControllerRef controller);

// Return backing HWND for manipulation in host application.
FLUTTER_EXPORT HWND FlutterDesktopViewGetHWND(FlutterDesktopViewRef view);

// Gets the DPI for a given |hwnd|, depending on the supported APIs per
// windows version and DPI awareness mode. If nullptr is passed, returns the DPI
// of the primary monitor.
FLUTTER_EXPORT UINT FlutterDesktopGetDpiForHWND(HWND hwnd);

// Gets the DPI for a given |monitor|. If the API is not available, a default
// DPI of 96 is returned.
FLUTTER_EXPORT UINT FlutterDesktopGetDpiForMonitor(HMONITOR monitor);

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

// Returns the view associated with this registrar's engine instance
// This is a Windows-specific extension to flutter_plugin_registrar.h.
FLUTTER_EXPORT FlutterDesktopViewRef
FlutterDesktopRegistrarGetView(FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_PUBLIC_FLUTTER_WINDOWS_H_
