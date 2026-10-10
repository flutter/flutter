// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SHELL_HOLDER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SHELL_HOLDER_H_

#include <memory>
#include <type_traits>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/vsync_waiter_android.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//----------------------------------------------------------------------------
/// @brief      This is the Android owner of the core engine Shell.
///
/// @details    This is the top orchestrator class on the C++ side for the
///             Android embedding. It corresponds to a FlutterEngine on the
///             Java side. This class is in C++ because the Shell is in
///             C++ and an Android orchestrator needs to exist to
///             compose it with other Android specific C++ components such as
///             the PlatformViewAndroid. This composition of many-to-one
///             C++ components would be difficult to do through JNI whereas
///             a FlutterEngine and AndroidShellHolder has a 1:1 relationship.
///
///             Technically, the FlutterJNI class owns this AndroidShellHolder
///             class instance, but the FlutterJNI class is meant to be mostly
///             static and has minimal state to perform the C++ pointer <->
///             Java class instance translation.
///
class AndroidShellHolder {
 public:
  AndroidShellHolder(const flutter::Settings& settings,
                     std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
                     AndroidRenderingAPI android_rendering_api);

  ~AndroidShellHolder();

  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      This is a factory for a derived AndroidShellHolder from an
  ///             existing AndroidShellHolder.
  ///
  /// @details    Creates one Shell from another Shell where the created
  ///             Shell takes the opportunity to share any internal components
  ///             it can. This results is a Shell that has a smaller startup
  ///             time cost and a smaller memory footprint than an Shell created
  ///             with a Create function.
  ///
  ///             The new Shell is returned in a new AndroidShellHolder
  ///             instance.
  ///
  ///             The new Shell's flutter::Settings cannot be changed from that
  ///             of the initial Shell. The RunConfiguration subcomponent can
  ///             be changed however in the spawned Shell to run a different
  ///             entrypoint than the existing shell.
  ///
  ///             Since the AndroidShellHolder both binds downwards to a Shell
  ///             and also upwards to JNI callbacks that the PlatformViewAndroid
  ///             makes, the JNI instance holding this AndroidShellHolder should
  ///             be created first to supply the jni_facade callback.
  ///
  /// @param[in]  jni_facade this argument should be the JNI callback facade of
  ///             a new JNI instance meant to hold this AndroidShellHolder.
  ///
  /// @returns    A new AndroidShellHolder containing a new Shell. Returns
  ///             nullptr when a new Shell can't be created.
  ///
  std::unique_ptr<AndroidShellHolder> Spawn(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      const std::string& entrypoint,
      const std::string& libraryUrl,
      const std::string& initial_route,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id) const;

  void Launch(std::unique_ptr<APKAssetProvider> apk_asset_provider,
              const std::string& entrypoint,
              const std::string& libraryUrl,
              const std::vector<std::string>& entrypoint_args,
              int64_t engine_id);

  const flutter::Settings& GetSettings() const;

  fml::WeakPtr<PlatformViewAndroid> GetPlatformView();

  bool IsSurfaceControlEnabled();

  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode);

  void NotifyLowMemoryWarning();

  const std::shared_ptr<PlatformMessageHandler>& GetPlatformMessageHandler()
      const;

  //----------------------------------------------------------------------------
  /// @brief      Reads display metrics from the JNI facade and sends them to
  ///             the engine through the embedder API.
  ///
  void UpdateDisplayMetrics();

  //----------------------------------------------------------------------------
  /// @brief      Tells the engine whether the platform's accessibility
  ///             services want semantics, through the embedder API.
  ///
  void SetSemanticsEnabled(bool enabled);

  //----------------------------------------------------------------------------
  /// @brief      Sends the platform's accessibility features through the
  ///             embedder API.
  ///
  /// @param[in]  flags  A bitmask of AccessibilityFeatureFlag values, which
  ///             FlutterAccessibilityFeature shares.
  ///
  void SetAccessibilityFeatures(int32_t flags);

  //----------------------------------------------------------------------------
  /// @brief      Sends a semantics action for a node on the implicit view
  ///             through the embedder API.
  ///
  void DispatchSemanticsAction(int32_t node_id,
                               int32_t action,
                               fml::MallocMapping args);

  //----------------------------------------------------------------------------
  /// @brief      Asks the engine for a frame through the embedder API.
  ///
  void ScheduleFrame();

  //----------------------------------------------------------------------------
  /// @brief      Sends viewport metrics for a view through the embedder API.
  ///
  void SetViewportMetrics(int64_t view_id, const ViewportMetrics& metrics);

  //----------------------------------------------------------------------------
  /// @brief      Sends a binary platform message to the engine through the
  ///             embedder API.
  ///
  void DispatchPlatformMessage(const std::string& name,
                               const void* message_data,
                               int message_position,
                               int response_id);

  //----------------------------------------------------------------------------
  /// @brief      Sends an empty (null payload) platform message to the engine
  ///             through the embedder API.
  ///
  void DispatchEmptyPlatformMessage(const std::string& name, int response_id);

  //----------------------------------------------------------------------------
  /// @brief      Unpacks a binary pointer data packet buffer from
  ///             AndroidTouchProcessor and dispatches the events to the engine
  ///             through the embedder API.
  ///
  void DispatchPointerDataPacket(const uint8_t* buffer, int size_bytes);

  //----------------------------------------------------------------------------
  /// @brief      Delivers a resolved deferred Dart loading unit's data and
  ///             instructions mappings to the engine through the embedder API.
  ///
  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions);

  //----------------------------------------------------------------------------
  /// @brief      Notifies the engine that a deferred Dart loading unit failed
  ///             to load or install, through the embedder API.
  ///
  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string& error_message,
                                    bool transient);

  //----------------------------------------------------------------------------
  /// @brief      Replaces the engine's APK asset resolver through the embedder
  ///             API.
  ///
  void UpdateJavaAssetManager(std::unique_ptr<APKAssetProvider> asset_provider);

  //----------------------------------------------------------------------------
  /// @brief      Registers an Android SurfaceTexture-backed external texture
  ///             with the engine through the embedder API.
  ///
  void RegisterExternalTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture);

  //----------------------------------------------------------------------------
  /// @brief      Registers an Android ImageTextureEntry-backed external
  ///             texture with the engine through the embedder API.
  ///
  void RegisterImageTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
      ImageExternalTexture::ImageLifecycle lifecycle);

  //----------------------------------------------------------------------------
  /// @brief      Unregisters an external texture from the engine through the
  ///             embedder API.
  ///
  void UnregisterTexture(int64_t texture_id);

  //----------------------------------------------------------------------------
  /// @brief      Notifies the engine that the frame is available on an
  ///             external texture through the embedder API.
  ///
  void MarkTextureFrameAvailable(int64_t texture_id);

  //----------------------------------------------------------------------------
  /// @brief      Attaches a native window to the Android surface, installs the
  ///             first-frame callback, and notifies the engine that its
  ///             rendering surface was created through the embedder API.
  ///
  void NotifySurfaceCreated(fml::RefPtr<AndroidNativeWindow> native_window);

  //----------------------------------------------------------------------------
  /// @brief      Replaces the native window on the Android surface and
  ///             schedules a frame through the embedder API.
  ///
  void NotifySurfaceWindowChanged(
      fml::RefPtr<AndroidNativeWindow> native_window);

  //----------------------------------------------------------------------------
  /// @brief      Resizes the on-screen Android surface.
  ///
  void NotifySurfaceChanged(int width, int height);

  //----------------------------------------------------------------------------
  /// @brief      Notifies the engine that its rendering surface is being
  ///             destroyed through the embedder API, then tears down the
  ///             Android surface context.
  ///
  void NotifySurfaceDestroyed();

  // Visible for testing.
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngineForTesting() const {
    return engine_.get();
  }

  // Visible for testing. Replacing an entry changes what the holder calls.
  FlutterEngineProcTable& GetEmbedderApiForTesting();

 private:
  // Destroys the engine behind an embedder API handle.
  struct EngineDeleter {
    void operator()(FLUTTER_API_SYMBOL(FlutterEngine) engine) const;
  };
  // Owns an engine through its embedder API handle.
  using UniqueEngine =
      std::unique_ptr<std::remove_pointer_t<FLUTTER_API_SYMBOL(FlutterEngine)>,
                      EngineDeleter>;

  const flutter::Settings settings_;
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  fml::WeakPtr<PlatformViewAndroid> platform_view_;
  std::shared_ptr<PlatformMessageHandler> platform_message_handler_;
  std::shared_ptr<ThreadHost> thread_host_;
  UniqueEngine engine_;
  // The embedder API functions that the holder calls engine_ through.
  FlutterEngineProcTable embedder_api_;
  // Answers the vsync callback of the platform view. Detached before engine_
  // is destroyed.
  std::shared_ptr<VsyncWaiterAndroid> vsync_waiter_;
  bool is_valid_ = false;
  uint64_t next_pointer_flow_id_ = 0;
  const uint64_t holder_id_;
  std::unique_ptr<APKAssetProvider> apk_asset_provider_;
  const AndroidRenderingAPI android_rendering_api_;

  void SendPlatformMessage(const std::string& name,
                           const uint8_t* message_data,
                           size_t message_size,
                           int response_id);

  //----------------------------------------------------------------------------
  /// @brief      Constructor with its components injected.
  ///
  /// @details    This is similar to the standard constructor, except its
  ///             members were constructed elsewhere and injected.
  ///
  ///             All injected components must be non-null and valid.
  ///
  ///             Used when constructing the Shell from the inside out when
  ///             spawning from an existing Shell.
  ///
  AndroidShellHolder(const flutter::Settings& settings,
                     const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
                     const std::shared_ptr<ThreadHost>& thread_host,
                     UniqueEngine engine,
                     uint64_t holder_id,
                     std::unique_ptr<APKAssetProvider> apk_asset_provider,
                     const fml::WeakPtr<PlatformViewAndroid>& platform_view,
                     std::shared_ptr<VsyncWaiterAndroid> vsync_waiter,
                     AndroidRenderingAPI rendering_api);
  static void ThreadDestructCallback(void* value);
  std::optional<RunConfiguration> BuildRunConfiguration(
      const std::string& entrypoint,
      const std::string& libraryUrl,
      const std::vector<std::string>& entrypoint_args) const;

  bool IsNDKImageDecoderAvailable();

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidShellHolder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SHELL_HOLDER_H_
