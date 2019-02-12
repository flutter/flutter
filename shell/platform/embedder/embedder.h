// Copyright 2013 The Flutter Authors. All rights reserved.
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
  kInternalInconsistency,
} FlutterEngineResult;

typedef enum {
  kOpenGL,
  kSoftware,
} FlutterRendererType;

typedef struct _FlutterEngine* FlutterEngine;

typedef struct {
  //   horizontal scale factor
  double scaleX;
  //    horizontal skew factor
  double skewX;
  //   horizontal translation
  double transX;
  //    vertical skew factor
  double skewY;
  //   vertical scale factor
  double scaleY;
  //   vertical translation
  double transY;
  //    input x-axis perspective factor
  double pers0;
  //    input y-axis perspective factor
  double pers1;
  //    perspective scale factor
  double pers2;
} FlutterTransformation;

typedef void (*VoidCallback)(void* /* user data */);

typedef struct {
  //    Target texture of the active texture unit (example GL_TEXTURE_2D).
  uint32_t target;
  //    The name of the texture.
  uint32_t name;
  //    The texture format (example GL_RGBA8).
  uint32_t format;
  //    User data to be returned on the invocation of the destruction callback.
  void* user_data;
  //    Callback invoked (on an engine managed thread) that asks the embedder to
  //    collect the texture.
  VoidCallback destruction_callback;
} FlutterOpenGLTexture;

typedef bool (*BoolCallback)(void* /* user data */);
typedef FlutterTransformation (*TransformationCallback)(void* /* user data */);
typedef uint32_t (*UIntCallback)(void* /* user data */);
typedef bool (*SoftwareSurfacePresentCallback)(void* /* user data */,
                                               const void* /* allocation */,
                                               size_t /* row bytes */,
                                               size_t /* height */);
typedef void* (*ProcResolver)(void* /* user data */, const char* /* name */);
typedef bool (*TextureFrameCallback)(void* /* user data */,
                                     int64_t /* texture identifier */,
                                     size_t /* width */,
                                     size_t /* height */,
                                     FlutterOpenGLTexture* /* texture out */);

typedef struct {
  // The size of this struct. Must be sizeof(FlutterOpenGLRendererConfig).
  size_t struct_size;
  BoolCallback make_current;
  BoolCallback clear_current;
  BoolCallback present;
  UIntCallback fbo_callback;
  // This is an optional callback. Flutter will ask the emebdder to create a GL
  // context current on a background thread. If the embedder is able to do so,
  // Flutter will assume that this context is in the same sharegroup as the main
  // rendering context and use this context for asynchronous texture uploads.
  // Though optional, it is recommended that all embedders set this callback as
  // it will lead to better performance in texture handling.
  BoolCallback make_resource_current;
  // By default, the renderer config assumes that the FBO does not change for
  // the duration of the engine run. If this argument is true, the
  // engine will ask the embedder for an updated FBO target (via an fbo_callback
  // invocation) after a present call.
  bool fbo_reset_after_present;
  // The transformation to apply to the render target before any rendering
  // operations. This callback is optional.
  TransformationCallback surface_transformation;
  ProcResolver gl_proc_resolver;
  // When the embedder specifies that a texture has a frame available, the
  // engine will call this method (on an internal engine managed thread) so that
  // external texture details can be supplied to the engine for subsequent
  // composition.
  TextureFrameCallback gl_external_texture_frame_callback;
} FlutterOpenGLRendererConfig;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterSoftwareRendererConfig).
  size_t struct_size;
  // The callback presented to the embedder to present a fully populated buffer
  // to the user. The pixel format of the buffer is the native 32-bit RGBA
  // format. The buffer is owned by the Flutter engine and must be copied in
  // this callback if needed.
  SoftwareSurfacePresentCallback surface_present_callback;
} FlutterSoftwareRendererConfig;

typedef struct {
  FlutterRendererType type;
  union {
    FlutterOpenGLRendererConfig open_gl;
    FlutterSoftwareRendererConfig software;
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
  // An optional device identifier. If this is not specified, it is assumed that
  // the embedder has no multitouch capability.
  int32_t device;
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
  // The path to the Dart file containing the |main| entry point.
  // The string can be collected after the call to |FlutterEngineRun| returns.
  // The string must be NULL terminated.
  //
  // \deprecated As of Dart 2, running from Dart source is no longer supported.
  // Dart code should now be compiled to kernel form and will be loaded by from
  // |kernel_blob.bin| in the assets directory. This struct member is retained
  // for ABI stability.
  const char* main_path__unused__;
  // The path to the |.packages| for the project. The string can be collected
  // after the call to |FlutterEngineRun| returns. The string must be NULL
  // terminated.
  //
  // \deprecated As of Dart 2, running from Dart source is no longer supported.
  // Dart code should now be compiled to kernel form and will be loaded by from
  // |kernel_blob.bin| in the assets directory. This struct member is retained
  // for ABI stability.
  const char* packages_path__unused__;
  // The path to the icudtl.dat file for the project. The string can be
  // collected after the call to |FlutterEngineRun| returns. The string must
  // be NULL terminated.
  const char* icu_data_path;
  // The command line argument count used to initialize the project.
  int command_line_argc;
  // The command line arguments used to initialize the project. The strings can
  // be collected after the call to |FlutterEngineRun| returns. The strings must
  // be NULL terminated.
  // Note: The first item in the command line (if specificed at all) is
  // interpreted as the executable name. So if an engine flag needs to be passed
  // into the same, it needs to not be the very first item in the list. The set
  // of engine flags are only meant to control unstable features in the engine.
  // Deployed applications should not pass any command line arguments at all as
  // they may affect engine stability at runtime in the presence of unsanitized
  // input. The list of currently recognized engine flags and their descriptions
  // can be retrieved from the |switches.h| engine source file.
  const char* const* command_line_argv;
  // The callback invoked by the engine in order to give the embedder the chance
  // to respond to platform messages from the Dart application. The callback
  // will be invoked on the thread on which the |FlutterEngineRun| call is made.
  FlutterPlatformMessageCallback platform_message_callback;
  // The VM snapshot data buffer used in AOT operation. This buffer must be
  // mapped in as read-only. For more information refer to the documentation on
  // the Wiki at
  // https://github.com/flutter/flutter/wiki/Flutter-engine-operation-in-AOT-Mode
  const uint8_t* vm_snapshot_data;
  // The size of the VM snapshot data buffer.
  size_t vm_snapshot_data_size;
  // The VM snapshot instructions buffer used in AOT operation. This buffer must
  // be mapped in as read-execute. For more information refer to the
  // documentation on the Wiki at
  // https://github.com/flutter/flutter/wiki/Flutter-engine-operation-in-AOT-Mode
  const uint8_t* vm_snapshot_instructions;
  // The size of the VM snapshot instructions buffer.
  size_t vm_snapshot_instructions_size;
  // The isolate snapshot data buffer used in AOT operation. This buffer must be
  // mapped in as read-only. For more information refer to the documentation on
  // the Wiki at
  // https://github.com/flutter/flutter/wiki/Flutter-engine-operation-in-AOT-Mode
  const uint8_t* isolate_snapshot_data;
  // The size of the isolate snapshot data buffer.
  size_t isolate_snapshot_data_size;
  // The isolate snapshot instructions buffer used in AOT operation. This buffer
  // must be mapped in as read-execute. For more information refer to the
  // documentation on the Wiki at
  // https://github.com/flutter/flutter/wiki/Flutter-engine-operation-in-AOT-Mode
  const uint8_t* isolate_snapshot_instructions;
  // The size of the isolate snapshot instructions buffer.
  size_t isolate_snapshot_instructions_size;
  // The callback invoked by the engine in root isolate scope. Called
  // immediately after the root isolate has been created and marked runnable.
  VoidCallback root_isolate_create_callback;
} FlutterProjectArgs;

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineRun(size_t version,
                                     const FlutterRendererConfig* config,
                                     const FlutterProjectArgs* args,
                                     void* user_data,
                                     FlutterEngine* engine_out);

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineShutdown(FlutterEngine engine);

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineSendWindowMetricsEvent(
    FlutterEngine engine,
    const FlutterWindowMetricsEvent* event);

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineSendPointerEvent(
    FlutterEngine engine,
    const FlutterPointerEvent* events,
    size_t events_count);

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineSendPlatformMessage(
    FlutterEngine engine,
    const FlutterPlatformMessage* message);

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineSendPlatformMessageResponse(
    FlutterEngine engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length);

// This API is only meant to be used by platforms that need to flush tasks on a
// message loop not controlled by the Flutter engine. This API will be
// deprecated soon.
FLUTTER_EXPORT
FlutterEngineResult __FlutterEngineFlushPendingTasksNow();

// Register an external texture with a unique (per engine) identifier. Only
// rendering backends that support external textures accept external texture
// registrations. After the external texture is registered, the application can
// mark that a frame is available by calling
// |FlutterEngineMarkExternalTextureFrameAvailable|.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineRegisterExternalTexture(
    FlutterEngine engine,
    int64_t texture_identifier);

// Unregister a previous texture registration.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineUnregisterExternalTexture(
    FlutterEngine engine,
    int64_t texture_identifier);

// Mark that a new texture frame is available for a given texture identifier.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineMarkExternalTextureFrameAvailable(
    FlutterEngine engine,
    int64_t texture_identifier);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_EMBEDDER_H_
