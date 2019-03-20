// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_PUBLIC_FLUTTER_MESSENGER_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_PUBLIC_FLUTTER_MESSENGER_H_

#include <stddef.h>
#include <stdint.h>

#include "flutter_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

// Opaque reference to a Flutter engine messenger.
typedef struct FlutterDesktopMessenger* FlutterDesktopMessengerRef;

// Opaque handle for tracking responses to messages.
typedef struct _FlutterPlatformMessageResponseHandle
    FlutterDesktopMessageResponseHandle;

// A message received from Flutter.
typedef struct {
  // Size of this struct as created by Flutter.
  size_t struct_size;
  // The name of the channel used for this message.
  const char* channel;
  // The raw message data.
  const uint8_t* message;
  // The length of |message|.
  size_t message_size;
  // The response handle. If non-null, the receiver of this message must call
  // FlutterDesktopSendMessageResponse exactly once with this handle.
  const FlutterDesktopMessageResponseHandle* response_handle;
} FlutterDesktopMessage;

// Function pointer type for message handler callback registration.
//
// The user data will be whatever was passed to FlutterDesktopSetMessageHandler
// for the channel the message is received on.
typedef void (*FlutterDesktopMessageCallback)(
    FlutterDesktopMessengerRef /* messenger */,
    const FlutterDesktopMessage* /* message*/,
    void* /* user data */);

// Sends a binary message to the Flutter side on the specified channel.
FLUTTER_EXPORT void FlutterDesktopMessengerSend(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    const uint8_t* message,
    const size_t message_size);

// Sends a reply to a FlutterDesktopMessage for the given response handle.
//
// Once this has been called, |handle| is invalid and must not be used again.
FLUTTER_EXPORT void FlutterDesktopMessengerSendResponse(
    FlutterDesktopMessengerRef messenger,
    const FlutterDesktopMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length);

// Registers a callback function for incoming binary messages from the Flutter
// side on the specified channel.
//
// Replaces any existing callback. Provide a null handler to unregister the
// existing callback.
//
// If |user_data| is provided, it will be passed in |callback| calls.
FLUTTER_EXPORT void FlutterDesktopMessengerSetCallback(
    FlutterDesktopMessengerRef messenger,
    const char* channel,
    FlutterDesktopMessageCallback callback,
    void* user_data);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_PUBLIC_FLUTTER_MESSENGER_H_
