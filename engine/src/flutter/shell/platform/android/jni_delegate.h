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
      std::shared_ptr<ImageDecoderProvider> image_decoder = nullptr);
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

  /// @brief Enables or disables accessibility semantics tree in the JVM.
  virtual bool SetSemanticsEnabled(bool enabled);

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

  /// @brief Returns the underlying JvmInvoker instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

 private:
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;
  std::shared_ptr<ImageDecoderProvider> image_decoder_;

  FML_DISALLOW_COPY_AND_ASSIGN(JniDelegate);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_DELEGATE_H_
