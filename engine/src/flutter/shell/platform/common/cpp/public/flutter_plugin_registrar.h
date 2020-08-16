// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_PUBLIC_FLUTTER_PLUGIN_REGISTRAR_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_PUBLIC_FLUTTER_PLUGIN_REGISTRAR_H_

#include <stddef.h>
#include <stdint.h>

#include "flutter_export.h"
#include "flutter_messenger.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a plugin registrar.
typedef struct FlutterDesktopPluginRegistrar* FlutterDesktopPluginRegistrarRef;

// Function pointer type for registrar destruction callback.
typedef void (*FlutterDesktopOnRegistrarDestroyed)(
    FlutterDesktopPluginRegistrarRef);

// Returns the engine messenger associated with this registrar.
FLUTTER_EXPORT FlutterDesktopMessengerRef
FlutterDesktopRegistrarGetMessenger(FlutterDesktopPluginRegistrarRef registrar);

// Registers a callback to be called when the plugin registrar is destroyed.
FLUTTER_EXPORT void FlutterDesktopRegistrarSetDestructionHandler(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopOnRegistrarDestroyed callback);

// Enables input blocking on the given channel.
//
// If set, then the Flutter window will disable input callbacks
// while waiting for the handler for messages on that channel to run. This is
// useful if handling the message involves showing a modal window, for instance.
//
// This must be called after FlutterDesktopSetMessageHandler, as setting a
// handler on a channel will reset the input blocking state back to the
// default of disabled.
FLUTTER_EXPORT void FlutterDesktopRegistrarEnableInputBlocking(
    FlutterDesktopPluginRegistrarRef registrar,
    const char* channel);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_PUBLIC_FLUTTER_PLUGIN_REGISTRAR_H_
