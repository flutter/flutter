// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#include "flutter/shell/platform/android/android_semantics_mapper.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Decoupled representation of Dart callback metadata.
struct DartCallbackInfo {
  std::string name;
  std::string class_name;
  std::string library_path;

  bool operator==(const DartCallbackInfo& other) const {
    return name == other.name && class_name == other.class_name &&
           library_path == other.library_path;
  }
};

/// @brief Decoupled representation of decoded image header metadata.
struct ImageHeaderInfo {
  int32_t width = 0;
  int32_t height = 0;

  bool operator==(const ImageHeaderInfo& other) const {
    return width == other.width && height == other.height;
  }
};

/// @brief Abstract provider interface for resolving Dart callback
/// representations.
class CallbackCacheProvider {
 public:
  virtual ~CallbackCacheProvider() = default;

  /// @brief Looks up Dart callback information for a given callback handle.
  virtual std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) = 0;
};

/// @brief Abstract provider interface for platform/custom image decoding.
class ImageDecoderProvider {
 public:
  virtual ~ImageDecoderProvider() = default;

  /// @brief Decodes image data given raw buffer bytes and generator handle.
  virtual bool DecodeImage(const uint8_t* data,
                           size_t size,
                           int64_t generator_handle) = 0;

  /// @brief Handles native image header notification callback.
  virtual void OnImageHeader(int64_t generator_handle,
                             int32_t width,
                             int32_t height) = 0;

  /// @brief Returns the decoded image header info for a generator handle.
  virtual std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle) = 0;
};

/// @brief Delegate that adapts Flutter Embedder C-API operations to the JVM.
///
/// Holds an injected JvmInvoker instance that abstracts all direct JVM/JNI
/// calls, guaranteeing host testability without native JNI dependencies.
class JniDelegate {
 public:
  explicit JniDelegate(
      std::shared_ptr<JvmInvoker> jvm_invoker,
      std::shared_ptr<CallbackCacheProvider> callback_cache = nullptr,
      std::shared_ptr<ImageDecoderProvider> image_decoder = nullptr,
      std::shared_ptr<PlatformViewsProvider> platform_views_provider = nullptr);
  virtual ~JniDelegate();

  /// @brief Handles an incoming platform message dispatch to the JVM.
  virtual bool HandlePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id);

  /// @brief Handles a platform message response back to the JVM.
  virtual bool HandlePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data);

  /// @brief Updates accessibility semantics tree in the JVM.
  virtual bool UpdateSemantics(const std::vector<uint8_t>& buffer,
                               const std::vector<std::string>& strings);

  /// @brief Updates accessibility semantics tree with string attributes in the
  /// JVM.
  virtual bool UpdateSemantics(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings,
      const std::vector<std::vector<uint8_t>>& string_attribute_args);

  /// @brief Updates custom accessibility actions in the JVM.
  virtual bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& actions_buffer,
      const std::vector<std::string>& action_strings);

  /// @brief Updates complete semantics tree and custom actions from
  /// FlutterSemanticsUpdate2.
  virtual bool UpdateSemantics(const FlutterSemanticsUpdate2& update);

  /// @brief Enables or disables accessibility semantics tree in the JVM.
  virtual bool SetSemanticsEnabled(bool enabled);

  /// @brief Dispatches a semantics action to a node in the JVM.
  virtual bool DispatchSemanticsAction(int32_t node_id,
                                       FlutterSemanticsAction action,
                                       const std::vector<uint8_t>& data = {},
                                       int64_t view_id = 0);

  /// @brief Sets accessibility features bitmask in the JVM.
  virtual bool SetAccessibilityFeatures(int32_t flags);

  /// @brief Sets application locale in the JVM.
  virtual bool SetApplicationLocale(const std::string& locale);

  /// @brief Notifies the JVM that the first frame has rendered.
  virtual bool OnFirstFrame();

  /// @brief Notifies the JVM before the Flutter engine restarts.
  virtual bool OnPreEngineRestart();

  /// @brief Dispatches VSync callback timestamps to the JVM.
  virtual bool OnVsync(int64_t frame_time_nanos,
                       int64_t frame_target_time_nanos);

  /// @brief Updates display metrics for a view in the JVM.
  virtual bool DispatchViewportMetrics(int64_t view_id,
                                       double width,
                                       double height,
                                       double pixel_ratio);

  /// @brief Requests loading of a Dart deferred library component.
  virtual bool RequestDartDeferredLibrary(int64_t loading_unit_id);

  /// @brief Notifies the JVM that the asset manager / bundle has changed.
  virtual bool OnAssetManagerChanged();

  /// @brief Looks up Dart callback information for a given handle.
  virtual std::optional<DartCallbackInfo> LookupCallbackInformation(
      int64_t handle);

  /// @brief Decodes an image from buffer bytes.
  virtual bool DecodeImage(const uint8_t* data,
                           size_t size,
                           int64_t generator_handle);

  /// @brief Notifies that image header dimensions are parsed.
  virtual void OnNativeImageHeader(int64_t generator_handle,
                                   int32_t width,
                                   int32_t height);

  /// @brief Gets parsed image header info for a generator handle.
  virtual std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle);

  /// @brief Creates a platform view in the JVM.
  virtual int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type);

  /// @brief Disposes a platform view by ID.
  virtual bool DisposePlatformView(int64_t view_id);

  /// @brief Resizes a platform view.
  virtual bool ResizePlatformView(const PlatformViewResizeRequest& request);

  /// @brief Sets top-left offset for a platform view.
  virtual bool OffsetPlatformView(int64_t view_id, double top, double left);

  /// @brief Sets layout direction for a platform view.
  virtual bool SetPlatformViewDirection(int64_t view_id, int32_t direction);

  /// @brief Clears focus from a platform view.
  virtual bool ClearPlatformViewFocus(int64_t view_id);

  /// @brief Dispatches a touch event to a platform view.
  virtual bool DispatchPlatformViewTouch(const PlatformViewTouch& touch);

  /// @brief Positions and displays a platform view with geometry.
  virtual bool OnDisplayPlatformView(const PlatformViewGeometry& geometry);

  /// @brief Positions and displays a platform view with FlutterPlatformView.
  virtual bool OnDisplayPlatformView(const FlutterPlatformView& platform_view,
                                     int32_t x,
                                     int32_t y,
                                     int32_t width,
                                     int32_t height,
                                     int32_t view_width,
                                     int32_t view_height);

  /// @brief Hides a platform view.
  virtual bool HidePlatformView(int64_t view_id);

  /// @brief Synchronizes rendering surface to native view hierarchy.
  virtual bool SynchronizeToNativeViewHierarchy(bool synchronize);

  /// @brief Signals start of a frame for hybrid composition.
  virtual bool OnBeginFrame();

  /// @brief Signals end of a frame for hybrid composition.
  virtual bool OnEndFrame();

  /// @brief Instantiates an overlay surface in hybrid composition.
  virtual std::optional<int32_t> CreateOverlaySurface();

  /// @brief Destroys all active overlay surfaces.
  virtual bool DestroyOverlaySurfaces();

  /// @brief Positions and sizes an overlay surface.
  virtual bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay);

  /// @brief Shows an overlay surface.
  virtual bool ShowOverlaySurface(int32_t surface_id);

  /// @brief Hides an overlay surface.
  virtual bool HideOverlaySurface(int32_t surface_id);

  /// @brief Creates a SurfaceControl transaction for HC++.
  virtual bool CreatePlatformViewTransaction();

  /// @brief Swaps active SurfaceControl transactions for HC++.
  virtual bool SwapPlatformViewTransactions();

  /// @brief Applies pending SurfaceControl transactions for HC++.
  virtual bool ApplyPlatformViewTransactions();

  /// @brief Checks whether HC++ presentation is supported and enabled.
  virtual bool IsHcppEnabled() const;

  /// @brief Dispatches platform view mutator stack to the JVM.
  virtual bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      const AndroidMutatorsStack& mutators_stack);

  /// @brief Dispatches platform view mutator stack derived from a
  /// FlutterPlatformView.
  virtual bool PushPlatformViewMutators(
      const FlutterPlatformView& platform_view,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height);

  /// @brief Sets or replaces the CallbackCacheProvider used for lookups.
  void SetCallbackCache(std::shared_ptr<CallbackCacheProvider> provider);

  /// @brief Returns the current CallbackCacheProvider.
  std::shared_ptr<CallbackCacheProvider> GetCallbackCache() const;

  /// @brief Sets or replaces the ImageDecoderProvider.
  void SetImageDecoderProvider(std::shared_ptr<ImageDecoderProvider> provider);

  /// @brief Returns the current ImageDecoderProvider.
  std::shared_ptr<ImageDecoderProvider> GetImageDecoderProvider() const;

  /// @brief Sets or replaces the PlatformViewsProvider.
  void SetPlatformViewsProvider(
      std::shared_ptr<PlatformViewsProvider> provider);

  /// @brief Returns the current PlatformViewsProvider.
  std::shared_ptr<PlatformViewsProvider> GetPlatformViewsProvider() const;

  /// @brief Returns the current AndroidPlatformViewsController.
  std::shared_ptr<AndroidPlatformViewsController> GetPlatformViewsController()
      const;

  /// @brief Returns the underlying JvmInvoker instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;
  std::shared_ptr<ImageDecoderProvider> image_decoder_;
  std::shared_ptr<PlatformViewsProvider> platform_views_provider_;
  std::shared_ptr<AndroidPlatformViewsController> platform_views_controller_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniDelegate);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
