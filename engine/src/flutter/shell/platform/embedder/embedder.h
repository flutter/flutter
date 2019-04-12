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

// Additional accessibility features that may be enabled by the platform.
//
// Must match the |AccessibilityFeatures| enum in window.dart.
typedef enum {
  // Indicate there is a running accessibility service which is changing the
  // interaction model of the device.
  kFlutterAccessibilityFeatureAccessibleNavigation = 1 << 0,
  // Indicate the platform is inverting the colors of the application.
  kFlutterAccessibilityFeatureInvertColors = 1 << 1,
  // Request that animations be disabled or simplified.
  kFlutterAccessibilityFeatureDisableAnimations = 1 << 2,
  // Request that text be rendered at a bold font weight.
  kFlutterAccessibilityFeatureBoldText = 1 << 3,
  // Request that certain animations be simplified and parallax effects
  // removed.
  kFlutterAccessibilityFeatureReduceMotion = 1 << 4,
} FlutterAccessibilityFeature;

// The set of possible actions that can be conveyed to a semantics node.
//
// Must match the |SemanticsAction| enum in semantics.dart.
typedef enum {
  // The equivalent of a user briefly tapping the screen with the finger without
  // moving it.
  kFlutterSemanticsActionTap = 1 << 0,
  // The equivalent of a user pressing and holding the screen with the finger
  // for a few seconds without moving it.
  kFlutterSemanticsActionLongPress = 1 << 1,
  // The equivalent of a user moving their finger across the screen from right
  // to left.
  kFlutterSemanticsActionScrollLeft = 1 << 2,
  // The equivalent of a user moving their finger across the screen from left to
  // right.
  kFlutterSemanticsActionScrollRight = 1 << 3,
  // The equivalent of a user moving their finger across the screen from bottom
  // to top.
  kFlutterSemanticsActionScrollUp = 1 << 4,
  // The equivalent of a user moving their finger across the screen from top to
  // bottom.
  kFlutterSemanticsActionScrollDown = 1 << 5,
  // Increase the value represented by the semantics node.
  kFlutterSemanticsActionIncrease = 1 << 6,
  // Decrease the value represented by the semantics node.
  kFlutterSemanticsActionDecrease = 1 << 7,
  // A request to fully show the semantics node on screen.
  kFlutterSemanticsActionShowOnScreen = 1 << 8,
  // Move the cursor forward by one character.
  kFlutterSemanticsActionMoveCursorForwardByCharacter = 1 << 9,
  // Move the cursor backward by one character.
  kFlutterSemanticsActionMoveCursorBackwardByCharacter = 1 << 10,
  // Set the text selection to the given range.
  kFlutterSemanticsActionSetSelection = 1 << 11,
  // Copy the current selection to the clipboard.
  kFlutterSemanticsActionCopy = 1 << 12,
  // Cut the current selection and place it in the clipboard.
  kFlutterSemanticsActionCut = 1 << 13,
  // Paste the current content of the clipboard.
  kFlutterSemanticsActionPaste = 1 << 14,
  // Indicate that the node has gained accessibility focus.
  kFlutterSemanticsActionDidGainAccessibilityFocus = 1 << 15,
  // Indicate that the node has lost accessibility focus.
  kFlutterSemanticsActionDidLoseAccessibilityFocus = 1 << 16,
  // Indicate that the user has invoked a custom accessibility action.
  kFlutterSemanticsActionCustomAction = 1 << 17,
  // A request that the node should be dismissed.
  kFlutterSemanticsActionDismiss = 1 << 18,
  // Move the cursor forward by one word.
  kFlutterSemanticsActionMoveCursorForwardByWord = 1 << 19,
  // Move the cursor backward by one word.
  kFlutterSemanticsActionMoveCursorBackwardByWord = 1 << 20,
} FlutterSemanticsAction;

// The set of properties that may be associated with a semantics node.
//
// Must match the |SemanticsFlag| enum in semantics.dart.
typedef enum {
  // The semantics node has the quality of either being "checked" or
  // "unchecked".
  kFlutterSemanticsFlagHasCheckedState = 1 << 0,
  // Whether a semantics node is checked.
  kFlutterSemanticsFlagIsChecked = 1 << 1,
  // Whether a semantics node is selected.
  kFlutterSemanticsFlagIsSelected = 1 << 2,
  // Whether the semantic node represents a button.
  kFlutterSemanticsFlagIsButton = 1 << 3,
  // Whether the semantic node represents a text field.
  kFlutterSemanticsFlagIsTextField = 1 << 4,
  // Whether the semantic node currently holds the user's focus.
  kFlutterSemanticsFlagIsFocused = 1 << 5,
  // The semantics node has the quality of either being "enabled" or "disabled".
  kFlutterSemanticsFlagHasEnabledState = 1 << 6,
  // Whether a semantic node that hasEnabledState is currently enabled.
  kFlutterSemanticsFlagIsEnabled = 1 << 7,
  // Whether a semantic node is in a mutually exclusive group.
  kFlutterSemanticsFlagIsInMutuallyExclusiveGroup = 1 << 8,
  // Whether a semantic node is a header that divides content into sections.
  kFlutterSemanticsFlagIsHeader = 1 << 9,
  // Whether the value of the semantics node is obscured.
  kFlutterSemanticsFlagIsObscured = 1 << 10,
  // Whether the semantics node is the root of a subtree for which a route name
  // should be announced.
  kFlutterSemanticsFlagScopesRoute = 1 << 11,
  // Whether the semantics node label is the name of a visually distinct route.
  kFlutterSemanticsFlagNamesRoute = 1 << 12,
  // Whether the semantics node is considered hidden.
  kFlutterSemanticsFlagIsHidden = 1 << 13,
  // Whether the semantics node represents an image.
  kFlutterSemanticsFlagIsImage = 1 << 14,
  // Whether the semantics node is a live region.
  kFlutterSemanticsFlagIsLiveRegion = 1 << 15,
  // The semantics node has the quality of either being "on" or "off".
  kFlutterSemanticsFlagHasToggledState = 1 << 16,
  // If true, the semantics node is "on". If false, the semantics node is "off".
  kFlutterSemanticsFlagIsToggled = 1 << 17,
  // Whether the platform can scroll the semantics node when the user attempts
  // to move the accessibility focus to an offscreen child.
  //
  // For example, a |ListView| widget has implicit scrolling so that users can
  // easily move the accessibility focus to the next set of children. A
  // |PageView| widget does not have implicit scrolling, so that users don't
  // navigate to the next page when reaching the end of the current one.
  kFlutterSemanticsFlagHasImplicitScrolling = 1 << 18,
} FlutterSemanticsFlag;

typedef enum {
  // Text has unknown text direction.
  kFlutterTextDirectionUnknown = 0,
  // Text is read from right to left.
  kFlutterTextDirectionRTL = 1,
  // Text is read from left to right.
  kFlutterTextDirectionLTR = 2,
} FlutterTextDirection;

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
typedef void (*VsyncCallback)(void* /* user data */, intptr_t /* baton */);

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

// The phase of the pointer event.
typedef enum {
  kCancel,
  kUp,
  kDown,
  kMove,
  kAdd,
  kRemove,
  kHover,
} FlutterPointerPhase;

// The type of a pointer signal.
typedef enum {
  kFlutterPointerSignalKindNone,
  kFlutterPointerSignalKindScroll,
} FlutterPointerSignalKind;

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
  FlutterPointerSignalKind signal_kind;
  double scroll_delta_x;
  double scroll_delta_y;
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
  double left;
  double top;
  double right;
  double bottom;
} FlutterRect;

// |FlutterSemanticsNode| ID used as a sentinel to signal the end of a batch of
// semantics node updates.
FLUTTER_EXPORT
extern const int32_t kFlutterSemanticsNodeIdBatchEnd;

// A node that represents some semantic data.
//
// The semantics tree is maintained during the semantics phase of the pipeline
// (i.e., during PipelineOwner.flushSemantics), which happens after
// compositing. Updates are then pushed to embedders via the registered
// |FlutterUpdateSemanticsNodeCallback|.
typedef struct {
  // The size of this struct. Must be sizeof(FlutterSemanticsNode).
  size_t struct_size;
  // The unique identifier for this node.
  int32_t id;
  // The set of semantics flags associated with this node.
  FlutterSemanticsFlag flags;
  // The set of semantics actions applicable to this node.
  FlutterSemanticsAction actions;
  // The position at which the text selection originates.
  int32_t text_selection_base;
  // The position at which the text selection terminates.
  int32_t text_selection_extent;
  // The total number of scrollable children that contribute to semantics.
  int32_t scroll_child_count;
  // The index of the first visible semantic child of a scroll node.
  int32_t scroll_index;
  // The current scrolling position in logical pixels if the node is scrollable.
  double scroll_position;
  // The maximum in-range value for |scrollPosition| if the node is scrollable.
  double scroll_extent_max;
  // The minimum in-range value for |scrollPosition| if the node is scrollable.
  double scroll_extent_min;
  // The elevation along the z-axis at which the rect of this semantics node is
  // located above its parent.
  double elevation;
  // Describes how much space the semantics node takes up along the z-axis.
  double thickness;
  // A textual description of the node.
  const char* label;
  // A brief description of the result of performing an action on the node.
  const char* hint;
  // A textual description of the current value of the node.
  const char* value;
  // A value that |value| will have after a kFlutterSemanticsActionIncrease|
  // action has been performed.
  const char* increased_value;
  // A value that |value| will have after a kFlutterSemanticsActionDecrease|
  // action has been performed.
  const char* decreased_value;
  // The reading direction for |label|, |value|, |hint|, |increasedValue|, and
  // |decreasedValue|.
  FlutterTextDirection text_direction;
  // The bounding box for this node in its coordinate system.
  FlutterRect rect;
  // The transform from this node's coordinate system to its parent's coordinate
  // system.
  FlutterTransformation transform;
  // The number of children this node has.
  size_t child_count;
  // Array of child node IDs in traversal order. Has length |child_count|.
  const int32_t* children_in_traversal_order;
  // Array of child node IDs in hit test order. Has length |child_count|.
  const int32_t* children_in_hit_test_order;
  // The number of custom accessibility action associated with this node.
  size_t custom_accessibility_actions_count;
  // Array of |FlutterSemanticsCustomAction| IDs associated with this node.
  // Has length |custom_accessibility_actions_count|.
  const int32_t* custom_accessibility_actions;
} FlutterSemanticsNode;

// |FlutterSemanticsCustomAction| ID used as a sentinel to signal the end of a
// batch of semantics custom action updates.
FLUTTER_EXPORT
extern const int32_t kFlutterSemanticsCustomActionIdBatchEnd;

// A custom semantics action, or action override.
//
// Custom actions can be registered by applications in order to provide
// semantic actions other than the standard actions available through the
// |FlutterSemanticsAction| enum.
//
// Action overrides are custom actions that the application developer requests
// to be used in place of the standard actions in the |FlutterSemanticsAction|
// enum.
typedef struct {
  // The size of the struct. Must be sizeof(FlutterSemanticsCustomAction).
  size_t struct_size;
  // The unique custom action or action override ID.
  int32_t id;
  // For overriden standard actions, corresponds to the
  // |FlutterSemanticsAction| to override.
  FlutterSemanticsAction override_action;
  // The user-readable name of this custom semantics action.
  const char* label;
  // The hint description of this custom semantics action.
  const char* hint;
} FlutterSemanticsCustomAction;

typedef void (*FlutterUpdateSemanticsNodeCallback)(
    const FlutterSemanticsNode* /* semantics node */,
    void* /* user data */);

typedef void (*FlutterUpdateSemanticsCustomActionCallback)(
    const FlutterSemanticsCustomAction* /* semantics custom action */,
    void* /* user data */);

typedef struct _FlutterTaskRunner* FlutterTaskRunner;

typedef struct {
  FlutterTaskRunner runner;
  uint64_t task;
} FlutterTask;

typedef void (*FlutterTaskRunnerPostTaskCallback)(
    FlutterTask /* task */,
    uint64_t /* target time nanos */,
    void* /* user data */);

// An interface used by the Flutter engine to execute tasks at the target time
// on a specified thread. There should be a 1-1 relationship between a thread
// and a task runner. It is undefined behavior to run a task on a thread that is
// not associated with its task runner.
typedef struct {
  // The size of this struct. Must be sizeof(FlutterTaskRunnerDescription).
  size_t struct_size;
  void* user_data;
  // May be called from any thread. Should return true if tasks posted on the
  // calling thread will be run on that same thread.
  //
  // This field is required.
  BoolCallback runs_task_on_current_thread_callback;
  // May be called from any thread. The given task should be executed by the
  // embedder on the thread associated with that task runner by calling
  // |FlutterEngineRunTask| at the given target time. The system monotonic clock
  // should be used for the target time. The target time is the absolute time
  // from epoch (NOT a delta) at which the task must be returned back to the
  // engine on the correct thread. If the embedder needs to calculate a delta,
  // |FlutterEngineGetCurrentTime| may be called and the difference used as the
  // delta.
  //
  // This field is required.
  FlutterTaskRunnerPostTaskCallback post_task_callback;
} FlutterTaskRunnerDescription;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterCustomTaskRunners).
  size_t struct_size;
  // Specify the task runner for the thread on which the |FlutterEngineRun| call
  // is made.
  const FlutterTaskRunnerDescription* platform_task_runner;
} FlutterCustomTaskRunners;

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
  // The callback invoked by the engine in order to give the embedder the
  // chance to respond to semantics node updates from the Dart application.
  // Semantics node updates are sent in batches terminated by a 'batch end'
  // callback that is passed a sentinel |FlutterSemanticsNode| whose |id| field
  // has the value |kFlutterSemanticsNodeIdBatchEnd|.
  //
  // The callback will be invoked on the thread on which the |FlutterEngineRun|
  // call is made.
  FlutterUpdateSemanticsNodeCallback update_semantics_node_callback;
  // The callback invoked by the engine in order to give the embedder the
  // chance to respond to updates to semantics custom actions from the Dart
  // application.  Custom action updates are sent in batches terminated by a
  // 'batch end' callback that is passed a sentinel
  // |FlutterSemanticsCustomAction| whose |id| field has the value
  // |kFlutterSemanticsCustomActionIdBatchEnd|.
  //
  // The callback will be invoked on the thread on which the |FlutterEngineRun|
  // call is made.
  FlutterUpdateSemanticsCustomActionCallback
      update_semantics_custom_action_callback;
  // Path to a directory used to store data that is cached across runs of a
  // Flutter application (such as compiled shader programs used by Skia).
  // This is optional.  The string must be NULL terminated.
  const char* persistent_cache_path;

  // If true, we'll only read the existing cache, but not write new ones.
  bool is_persistent_cache_read_only;

  // A callback that gets invoked by the engine when it attempts to wait for a
  // platform vsync event. The engine will give the platform a baton that needs
  // to be returned back to the engine via |FlutterEngineOnVsync|. All batons
  // must be retured to the engine before initializing a
  // |FlutterEngineShutdown|. Not doing the same will result in a memory leak.
  // While the call to |FlutterEngineOnVsync| must occur on the thread that made
  // the call to |FlutterEngineRun|, the engine will make this callback on an
  // internal engine-managed thread. If the components accessed on the embedder
  // are not thread safe, the appropriate re-threading must be done.
  VsyncCallback vsync_callback;

  // The name of a custom Dart entrypoint. This is optional and specifying a
  // null or empty entrypoint makes the engine look for a method named "main" in
  // the root library of the application.
  //
  // Care must be taken to ensure that the custom entrypoint is not tree-shaken
  // away. Usually, this is done using the `@pragma('vm:entry-point')`
  // decoration.
  const char* custom_dart_entrypoint;

  // Typically the Flutter engine create and manages its internal threads. This
  // optional argument allows for the specification of task runner interfaces to
  // event loops managed by the embedder on threads it creates.
  const FlutterCustomTaskRunners* custom_task_runners;
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

// Enable or disable accessibility semantics.
//
// When enabled, changes to the semantic contents of the window are sent via
// the |FlutterUpdateSemanticsNodeCallback| registered to
// |update_semantics_node_callback| in |FlutterProjectArgs|;
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineUpdateSemanticsEnabled(FlutterEngine engine,
                                                        bool enabled);

// Sets additional accessibility features.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineUpdateAccessibilityFeatures(
    FlutterEngine engine,
    FlutterAccessibilityFeature features);

// Dispatch a semantics action to the specified semantics node.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineDispatchSemanticsAction(
    FlutterEngine engine,
    uint64_t id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length);

// Notify the engine that a vsync event occurred. A baton passed to the
// platform via the vsync callback must be returned. This call must be made on
// the thread on which the call to |FlutterEngineRun| was made.
//
// |frame_start_time_nanos| is the point at which the vsync event occurred or
// will occur. If the time point is in the future, the engine will wait till
// that point to begin its frame workload. The system monotonic clock is used as
// the timebase.
//
// |frame_target_time_nanos| is the point at which the embedder anticipates the
// next vsync to occur. This is a hint the engine uses to schedule Dart VM
// garbage collection in periods in which the various threads are most likely to
// be idle. For example, for a 60Hz display, embedders should add 16.6 * 1e6 to
// the frame time field. The system monotonic clock is used as the timebase.
//
// That frame timepoints are in nanoseconds.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineOnVsync(FlutterEngine engine,
                                         intptr_t baton,
                                         uint64_t frame_start_time_nanos,
                                         uint64_t frame_target_time_nanos);

// A profiling utility. Logs a trace duration begin event to the timeline. If
// the timeline is unavailable or disabled, this has no effect. Must be
// balanced with an duration end event (via
// |FlutterEngineTraceEventDurationEnd|) with the same name on the same thread.
// Can be called on any thread. Strings passed into the function will NOT be
// copied when added to the timeline. Only string literals may be passed in.
FLUTTER_EXPORT
void FlutterEngineTraceEventDurationBegin(const char* name);

// A profiling utility. Logs a trace duration end event to the timeline. If the
// timeline is unavailable or disabled, this has no effect. This call must be
// preceded by a trace duration begin call (via
// |FlutterEngineTraceEventDurationBegin|) with the same name on the same
// thread. Can be called on any thread. Strings passed into the function will
// NOT be copied when added to the timeline. Only string literals may be passed
// in.
FLUTTER_EXPORT
void FlutterEngineTraceEventDurationEnd(const char* name);

// A profiling utility. Logs a trace duration instant event to the timeline. If
// the timeline is unavailable or disabled, this has no effect. Can be called
// on any thread. Strings passed into the function will NOT be copied when added
// to the timeline. Only string literals may be passed in.
FLUTTER_EXPORT
void FlutterEngineTraceEventInstant(const char* name);

// Posts a task onto the Flutter render thread. Typically, this may be called
// from any thread as long as a |FlutterEngineShutdown| on the specific engine
// has not already been initiated.
FLUTTER_EXPORT
FlutterEngineResult FlutterEnginePostRenderThreadTask(FlutterEngine engine,
                                                      VoidCallback callback,
                                                      void* callback_data);

// Get the current time in nanoseconds from the clock used by the flutter
// engine. This is the system monotonic clock.
FLUTTER_EXPORT
uint64_t FlutterEngineGetCurrentTime();

// Inform the engine to run the specified task. This task has been given to
// the engine via the |FlutterTaskRunnerDescription.post_task_callback|. This
// call must only be made at the target time specified in that callback. Running
// the task before that time is undefined behavior.
FLUTTER_EXPORT
FlutterEngineResult FlutterEngineRunTask(FlutterEngine engine,
                                         const FlutterTask* task);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_EMBEDDER_H_
