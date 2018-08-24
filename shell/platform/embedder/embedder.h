// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_EMBEDDER_H_
#define FLUTTER_EMBEDDER_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

#ifndef FLUTTER_EXPORT
#define FLUTTER_EXPORT
#endif  // FLUTTER_EXPORT

#define FLUTTER_ENGINE_VERSION 1

typedef enum {
  kSuccess = 0,
  kInvalidLibraryVersion,
  kInvalidArguments,
} FlutterResult;

typedef enum {
  kOpenGL,
} FlutterRendererType;

typedef struct _FlutterEngine* FlutterEngine;

typedef bool (*BoolCallback)(void* /* user data */);
typedef uint32_t (*UIntCallback)(void* /* user data */);

typedef struct {
  // The size of this struct. Must be sizeof(FlutterOpenGLRendererConfig).
  size_t struct_size;
  BoolCallback make_current;
  BoolCallback clear_current;
  BoolCallback present;
  UIntCallback fbo_callback;
  BoolCallback make_resource_current;
  // By default, the renderer config assumes that the FBO does not change for
  // the duration of the engine run. If this argument is true, the
  // engine will ask the embedder for an updated FBO target (via an fbo_callback
  // invocation) after a present call.
  bool fbo_reset_after_present;
} FlutterOpenGLRendererConfig;

typedef struct {
  FlutterRendererType type;
  union {
    FlutterOpenGLRendererConfig open_gl;
  };
} FlutterRendererConfig;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterWindowMetricsEvent).
  size_t struct_size;
  // Physical width of the window.
  size_t width;
  // Physical height of the window.
  size_t height;
  // Scale factor for the physical screen.
  double pixel_ratio;
} FlutterWindowMetricsEvent;

typedef enum {
  kCancel,
  kUp,
  kDown,
  kMove,
} FlutterPointerPhase;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterPointerEvent).
  size_t struct_size;
  FlutterPointerPhase phase;
  size_t timestamp;  // in microseconds.
  double x;
  double y;
} FlutterPointerEvent;

struct _FlutterPlatformMessageResponseHandle;
typedef struct _FlutterPlatformMessageResponseHandle
    FlutterPlatformMessageResponseHandle;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterPlatformMessage).
  size_t struct_size;
  const char* channel;
  const uint8_t* message;
  const size_t message_size;
  // The response handle on which to invoke
  // |FlutterEngineSendPlatformMessageResponse| when the response is ready. This
  // field is ignored for messages being sent from the embedder to the
  // framework. If the embedder ever receives a message with a non-null response
  // handle, that handle must always be used with a
  // |FlutterEngineSendPlatformMessageResponse| call. If not, this is a memory
  // leak. It is not safe to send multiple responses on a single response
  // object.
  const FlutterPlatformMessageResponseHandle* response_handle;
} FlutterPlatformMessage;

typedef void (*FlutterPlatformMessageCallback)(
    const FlutterPlatformMessage* /* message*/,
    void* /* user data */);

typedef struct {
  // The size of this struct. Must be sizeof(FlutterProjectArgs).
  size_t struct_size;
  // The path to the Flutter assets directory containing project assets. The
  // string can be collected after the call to |FlutterEngineRun| returns. The
  // string must be NULL terminated.
  const char* assets_path;
  // The path to the Dart file containing the |main| entry point. The string can
  // be collected after the call to |FlutterEngineRun| returns. The string must
  // be NULL terminated.
  const char* main_path;
  // The path to the |.packages| for the project. The string can be collected
  // after the call to |FlutterEngineRun| returns. The string must be NULL
  // terminated.
  const char* packages_path;
  // The path to the icudtl.dat file for the project. The string can be
  // collected after the call to |FlutterEngineRun| returns. The string must
  // be NULL terminated.
  const char* icu_data_path;
  // The command line argument count used to initialize the project.
  int command_line_argc;
  // The command line arguments used to initialize the project. The strings can
  // be collected after the call to |FlutterEngineRun| returns. The strings must
  // be NULL terminated.
  const char* const* command_line_argv;
  // The callback invoked by the engine in order to give the embedder the chance
  // to respond to platform messages from the Dart application. The callback
  // will be invoked on the thread on which the |FlutterEngineRun| call is made.
  FlutterPlatformMessageCallback platform_message_callback;
} FlutterProjectArgs;

FLUTTER_EXPORT
FlutterResult FlutterEngineRun(size_t version,
                               const FlutterRendererConfig* config,
                               const FlutterProjectArgs* args,
                               void* user_data,
                               FlutterEngine* engine_out);

FLUTTER_EXPORT
FlutterResult FlutterEngineShutdown(FlutterEngine engine);

FLUTTER_EXPORT
FlutterResult FlutterEngineSendWindowMetricsEvent(
    FlutterEngine engine,
    const FlutterWindowMetricsEvent* event);

FLUTTER_EXPORT
FlutterResult FlutterEngineSendPointerEvent(FlutterEngine engine,
                                            const FlutterPointerEvent* events,
                                            size_t events_count);

FLUTTER_EXPORT
FlutterResult FlutterEngineSendPlatformMessage(
    FlutterEngine engine,
    const FlutterPlatformMessage* message);

FLUTTER_EXPORT
FlutterResult FlutterEngineSendPlatformMessageResponse(
    FlutterEngine engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length);

// This API is only meant to be used by platforms that need to flush tasks on a
// message loop not controlled by the Flutter engine. This API will be
// deprecated soon.
FLUTTER_EXPORT
FlutterResult __FlutterEngineFlushPendingTasksNow();

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_EMBEDDER_H_
