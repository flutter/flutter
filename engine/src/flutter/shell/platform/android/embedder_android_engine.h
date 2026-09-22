// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_ENGINE_H_

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/shell/platform/android/android_compositor.h"
#include "flutter/shell/platform/android/android_engine.h"
#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_surface_control.h"
#include "flutter/shell/platform/android/android_surface_manager.h"
#include "flutter/shell/platform/android/android_task_runners.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/android_vulkan_texture.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

/**
 * @brief An implementation of AndroidEngine that routes engine operations
 * through the public C Embedder API (FlutterEngineProcTable / FlutterEngine)
 * and manages AndroidSurfaceManager, AndroidCompositor, and AndroidTaskRunners.
 */
class EmbedderAndroidEngine final : public AndroidEngine {
 public:
  explicit EmbedderAndroidEngine(
      const TaskRunners& task_runners,
      const Settings& settings = Settings(),
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade = nullptr,
      AndroidRenderingAPI android_rendering_api =
          AndroidRenderingAPI::kImpellerOpenGLES);

  EmbedderAndroidEngine(const Settings& settings,
                        std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
                        AndroidRenderingAPI android_rendering_api);

  ~EmbedderAndroidEngine() override;

  // |AndroidEngine|
  bool IsValid() const override;

  // |AndroidEngine|
  bool IsSetup() const override;

  // |AndroidEngine|
  bool Run(std::unique_ptr<APKAssetProvider> asset_provider,
           const std::string& entrypoint,
           const std::string& library_url,
           const std::vector<std::string>& entrypoint_args,
           int64_t engine_id) override;

  // |AndroidEngine|
  std::unique_ptr<AndroidEngine> Spawn(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      const std::string& entrypoint,
      const std::string& library_url,
      const std::string& initial_route,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id) const override;

  // |AndroidEngine|
  Rasterizer::Screenshot Screenshot(Rasterizer::ScreenshotType type,
                                    bool base64_encode) override;

  // |AndroidEngine|
  void NotifyLowMemoryWarning() override;

  // |AndroidEngine|
  void OnDisplayUpdates(
      std::vector<std::unique_ptr<Display>> displays) override;

  // |AndroidEngine|
  const std::shared_ptr<PlatformMessageHandler>& GetPlatformMessageHandler()
      const override;

  // |AndroidEngine|
  void RegisterImageDecoder(ImageGeneratorFactory factory,
                            int32_t priority) override;

  // |AndroidEngine|
  const TaskRunners& GetTaskRunners() const override;

  // |AndroidEngine|
  void NotifyCreated() override;

  // |AndroidEngine|
  void NotifyDestroyed() override;

  // |AndroidEngine|
  void ScheduleFrame() override;

  // |AndroidEngine|
  void SetNextFrameCallback(const fml::closure& closure) override;

  // |AndroidEngine|
  void SetViewportMetrics(int64_t view_id,
                          const ViewportMetrics& metrics) override;

  // |AndroidEngine|
  void DispatchPlatformMessage(
      std::unique_ptr<PlatformMessage> message) override;

  // |AndroidEngine|
  void DispatchPointerDataPacket(
      std::unique_ptr<PointerDataPacket> packet) override;

  // |AndroidEngine|
  void DispatchSemanticsAction(int64_t view_id,
                               int32_t node_id,
                               SemanticsAction action,
                               fml::MallocMapping args) override;

  // |AndroidEngine|
  void SetSemanticsEnabled(bool enabled) override;

  // |AndroidEngine|
  void SetAccessibilityFeatures(int32_t flags) override;

  // |AndroidEngine|
  bool UpdateSemantics(
      int64_t view_id,
      const flutter::SemanticsNodeUpdates& update,
      const flutter::CustomAccessibilityActionUpdates& actions) override;

  // |AndroidEngine|
  void OnVsyncCallback(intptr_t baton) override;

  // |AndroidEngine|
  void RegisterExternalTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) override;

  // |AndroidEngine|
  void RegisterImageTexture(
      int64_t texture_id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
      bool reset_on_background) override;

  // |AndroidEngine|
  void UnregisterTexture(int64_t texture_id) override;

  // |AndroidEngine|
  void MarkTextureFrameAvailable(int64_t texture_id) override;

  // |AndroidEngine|
  void LoadDartDeferredLibrary(
      intptr_t loading_unit_id,
      std::unique_ptr<const fml::Mapping> snapshot_data,
      std::unique_ptr<const fml::Mapping> snapshot_instructions) override;

  // |AndroidEngine|
  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string error_message,
                                    bool transient) override;

  // |AndroidEngine|
  void UpdateAssetResolverByType(
      std::unique_ptr<AssetResolver> updated_asset_resolver,
      AssetResolver::AssetResolverType type) override;

  // ---------------------------------------------------------------------------
  // Standalone C-API Lifecycle & Subsystems (v7 alignment)
  // ---------------------------------------------------------------------------

  std::unique_ptr<EmbedderAndroidEngine> SpawnCAPI(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      const std::string& entrypoint,
      const std::string& library_url,
      const std::string& initial_route,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id) const;

  void NotifySurfaceCreated(ANativeWindow* window,
                            bool is_fake_window = false) override;
  void NotifySurfaceChanged(size_t width, size_t height) override;
  void NotifySurfaceWindowChanged(ANativeWindow* window,
                                  bool is_fake_window = false) override;
  void NotifySurfaceDestroyed() override;

  void SetSurfaceControlEnabled(bool enabled);
  bool IsSurfaceControlEnabled() const override;

  void SetPlatformMessageHandler(
      std::shared_ptr<PlatformMessageHandler> handler);

  FlutterEngineProcTable& GetMutableProcTableForTesting() {
    return proc_table_;
  }

  AndroidRenderingAPI GetRenderingAPI() const { return android_rendering_api_; }
  std::shared_ptr<AndroidSurfaceManager> GetSurfaceManager() const {
    return surface_manager_;
  }
  std::shared_ptr<AndroidCompositor> GetCompositor() const {
    return compositor_;
  }
  std::shared_ptr<AndroidTaskRunners> GetAndroidTaskRunners() const {
    return android_task_runners_;
  }
  std::shared_ptr<android::AndroidVsyncWaiter> GetVsyncWaiter() const {
    return vsync_waiter_;
  }
  std::shared_ptr<android::AndroidPlatformViewsController>
  GetPlatformViewsController() const {
    return platform_views_controller_;
  }
  std::shared_ptr<android::AndroidSurfaceControlProvider>
  GetSurfaceControlProvider() const {
    return surface_control_provider_;
  }
  std::shared_ptr<android::AndroidHardwareBufferProvider>
  GetHardwareBufferProvider() const {
    return hardware_buffer_provider_;
  }
  std::shared_ptr<android::AndroidVulkanTextureProvider>
  GetVulkanTextureProvider() const {
    return vulkan_texture_provider_;
  }
  std::shared_ptr<android::AndroidEngineGroup> GetEngineGroup() const {
    return engine_group_;
  }

  void OnBeginFrame();
  void OnPlatformViewPresented(int64_t view_id,
                               const FlutterPoint& offset,
                               const FlutterSize& size,
                               size_t mutations_count,
                               const FlutterPlatformViewMutation** mutations);
  void OnFramePresented();
  bool OnGLExternalTextureFrame(int64_t texture_id,
                                size_t width,
                                size_t height,
                                FlutterOpenGLTexture* texture_out);
  bool OnHardwareBufferExternalTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterHardwareBufferExternalTexture* texture_out);
  bool OnVulkanExternalTextureFrame(int64_t texture_id,
                                    size_t width,
                                    size_t height,
                                    FlutterVulkanExternalTexture* texture_out);

  // ---------------------------------------------------------------------------
  // Conversion & Serialization Helpers
  // ---------------------------------------------------------------------------
  static FlutterPointerPhase ToFlutterPointerPhase(int64_t change);
  static FlutterPointerDeviceKind ToFlutterPointerDeviceKind(int64_t kind);
  static FlutterPointerSignalKind ToFlutterPointerSignalKind(
      int64_t signal_kind);
  /// Rebuilds a `DlPath` from the flattened path the engine sends in a
  /// platform view clip mutation.
  static DlPath ToDlPath(const FlutterPath& path);
  /// Replays embedder platform view mutations onto a `MutatorsStack` so that
  /// they can be handed to the Java `FlutterMutatorsStack`.
  static MutatorsStack ToMutatorsStack(
      size_t mutations_count,
      const FlutterPlatformViewMutation** mutations);

  /// The display feature arrays to forward to the C API, rewritten so that the
  /// engine always accepts them.
  ///
  /// `bounds` holds exactly `4 * type.size()` values, and `type` and `state`
  /// always have the same length, so the three are consistent by construction
  /// and the count the engine is given can be read off any of them.
  struct DisplayFeatures {
    std::vector<double> bounds;
    std::vector<int32_t> type;
    std::vector<int32_t> state;
  };

  /// The display features of |metrics|, normalized for the C API.
  ///
  /// The bounds, type and state arrays reach C++ as three independent Java
  /// arrays. `FlutterRenderer` sizes all three from one feature count and only
  /// ever writes known enum values, but `FlutterJNI::setViewportMetrics` is
  /// public API and forwards whatever it is handed, so neither the lengths nor
  /// the contents can be relied on here.
  ///
  /// The incoming bounds array is authoritative because it carries the
  /// geometry the framework lays out around; a feature whose type or state is
  /// missing or unusable is reported as "unknown" rather than dropped.
  /// Features past |kFlutterMaxDisplayFeatures| are dropped, because the
  /// engine rejects the whole metrics event once the count exceeds that limit.
  ///
  /// An unrecognized but non-negative state is deliberately passed through
  /// rather than reset, because both the C API and `_decodeDisplayFeatures` in
  /// `lib/ui/hooks.dart` treat it as forward compatible.
  static DisplayFeatures NormalizeDisplayFeatures(
      const ViewportMetrics& metrics);

  /// The `FlutterWindowMetricsEvent` describing |metrics| for |view_id|.
  ///
  /// The returned event borrows all three display feature arrays from
  /// |display_features|, which must therefore outlive it.
  static FlutterWindowMetricsEvent ToFlutterWindowMetricsEvent(
      int64_t view_id,
      const ViewportMetrics& metrics,
      const DisplayFeatures& display_features);

  /// Binding the result of `NormalizeDisplayFeatures` directly to the
  /// parameter above would leave the returned event pointing at arrays that
  /// die at the end of the full expression.
  static FlutterWindowMetricsEvent ToFlutterWindowMetricsEvent(
      int64_t view_id,
      const ViewportMetrics& metrics,
      DisplayFeatures&& display_features) = delete;

  static std::vector<FlutterPointerEvent> UnpackPointerDataPacket(
      const uint8_t* buffer,
      size_t position);
  static void SerializeSemanticsUpdate(
      const FlutterSemanticsUpdate2* update,
      std::vector<uint8_t>& buffer,
      std::vector<std::string>& strings,
      std::vector<std::vector<uint8_t>>& string_attribute_args,
      std::vector<uint8_t>& actions_buffer,
      std::vector<std::string>& action_strings);

 private:
  class CompositorDelegate;

  FLUTTER_API_SYMBOL(FlutterEngine) GetEngineHandle() const {
    return c_api_engine_;
  }

  void InitializeSubsystems(const TaskRunners* existing_task_runners = nullptr);
  void BindPlatformMessageHandler();
  void PopulateRendererConfig(FlutterRendererConfig* config);

  FlutterEngineProcTable proc_table_{};
  FLUTTER_API_SYMBOL(FlutterEngine) c_api_engine_ = nullptr;
  bool c_api_is_valid_ = false;
  bool surface_attached_ = false;
  bool surface_control_enabled_ = false;
  std::atomic<bool> first_frame_presented_{false};

  Settings settings_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  std::shared_ptr<PlatformMessageHandler> platform_message_handler_;
  AndroidRenderingAPI android_rendering_api_ =
      AndroidRenderingAPI::kImpellerOpenGLES;
  std::optional<TaskRunners> task_runners_;

  struct PendingImageGenerator {
    ImageGeneratorFactory factory;
    int32_t priority;
  };
  std::vector<PendingImageGenerator> pending_image_generators_;

  struct ExternalTextureEntry {
    enum class Type {
      kSurfaceTexture,
      kImageTexture,
    };
    Type type = Type::kSurfaceTexture;
    int64_t id = 0;
    fml::jni::ScopedJavaGlobalRef<jobject> java_object;
    bool reset_on_background = false;

    ExternalTextureEntry(Type p_type,
                         int64_t p_id,
                         const fml::jni::ScopedJavaGlobalRef<jobject>& p_object,
                         bool p_reset_on_background)
        : type(p_type),
          id(p_id),
          java_object(p_object),
          reset_on_background(p_reset_on_background) {}
  };
  mutable std::mutex external_textures_mutex_;
  std::unordered_map<int64_t, std::unique_ptr<ExternalTextureEntry>>
      external_textures_;

  std::shared_ptr<AndroidTaskRunners> android_task_runners_;
  std::shared_ptr<android::AndroidVsyncWaiter> vsync_waiter_;
  std::shared_ptr<android::AndroidPlatformViewsController>
      platform_views_controller_;
  std::shared_ptr<android::AndroidSurfaceControlProvider>
      surface_control_provider_;
  std::shared_ptr<android::AndroidHardwareBufferProvider>
      hardware_buffer_provider_;
  std::shared_ptr<android::AndroidVulkanTextureProvider>
      vulkan_texture_provider_;
  std::shared_ptr<android::AndroidEngineGroup> engine_group_;
  std::shared_ptr<AndroidSurfaceManager> surface_manager_;
  std::shared_ptr<CompositorDelegate> compositor_delegate_;
  std::shared_ptr<AndroidCompositor> compositor_;
  std::unique_ptr<APKAssetProvider> apk_asset_provider_;
  FlutterAssetResolver asset_resolver_{};
  const FlutterAssetResolver* asset_resolvers_array_[1] = {nullptr};

  FlutterRendererConfig renderer_config_{};
  FlutterCompositor embedder_compositor_{};
  FlutterProjectArgs project_args_{};
  FlutterEngineAOTData aot_data_ = nullptr;

  std::mutex next_frame_callback_mutex_;
  fml::closure next_frame_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderAndroidEngine);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_ANDROID_ENGINE_H_
