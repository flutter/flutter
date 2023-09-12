// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONFIG_BUILDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONFIG_BUILDER_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_object.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_software.h"

namespace flutter {
namespace testing {

struct UniqueEngineTraits {
  static FlutterEngine InvalidValue() { return nullptr; }

  static bool IsValid(const FlutterEngine& value) { return value != nullptr; }

  static void Free(FlutterEngine& engine) {
    auto result = FlutterEngineShutdown(engine);
    FML_CHECK(result == kSuccess);
  }
};

using UniqueEngine = fml::UniqueObject<FlutterEngine, UniqueEngineTraits>;

class EmbedderConfigBuilder {
 public:
  enum class InitializationPreference {
    kSnapshotsInitialize,
    kAOTDataInitialize,
    kMultiAOTInitialize,
    kNoInitialize,
  };

  explicit EmbedderConfigBuilder(
      EmbedderTestContext& context,
      InitializationPreference preference =
          InitializationPreference::kSnapshotsInitialize);

  ~EmbedderConfigBuilder();

  FlutterProjectArgs& GetProjectArgs();

  void SetRendererConfig(EmbedderTestContextType type, SkISize surface_size);

  void SetSoftwareRendererConfig(SkISize surface_size = SkISize::Make(1, 1));

  void SetOpenGLRendererConfig(SkISize surface_size);

  void SetMetalRendererConfig(SkISize surface_size);

  void SetVulkanRendererConfig(
      SkISize surface_size,
      std::optional<FlutterVulkanInstanceProcAddressCallback>
          instance_proc_address_callback = {});

  // Used to explicitly set an `open_gl.fbo_callback`. Using this method will
  // cause your test to fail since the ctor for this class sets
  // `open_gl.fbo_callback_with_frame_info`. This method exists as a utility to
  // explicitly test this behavior.
  void SetOpenGLFBOCallBack();

  // Used to explicitly set an `open_gl.present`. Using this method will cause
  // your test to fail since the ctor for this class sets
  // `open_gl.present_with_info`. This method exists as a utility to explicitly
  // test this behavior.
  void SetOpenGLPresentCallBack();

  void SetAssetsPath();

  void SetSnapshots();

  void SetAOTDataElf();

  void SetIsolateCreateCallbackHook();

  void SetSemanticsCallbackHooks();

  // Used to set a custom log message handler.
  void SetLogMessageCallbackHook();

  void SetChannelUpdateCallbackHook();

  // Used to set a custom log tag.
  void SetLogTag(std::string tag);

  void SetLocalizationCallbackHooks();

  void SetExecutableName(std::string executable_name);

  void SetDartEntrypoint(std::string entrypoint);

  void AddCommandLineArgument(std::string arg);

  void AddDartEntrypointArgument(std::string arg);

  void SetPlatformTaskRunner(const FlutterTaskRunnerDescription* runner);

  void SetRenderTaskRunner(const FlutterTaskRunnerDescription* runner);

  void SetPlatformMessageCallback(
      const std::function<void(const FlutterPlatformMessage*)>& callback);

  void SetCompositor(bool avoid_backing_store_cache = false);

  FlutterCompositor& GetCompositor();

  FlutterRendererConfig& GetRendererConfig();

  void SetRenderTargetType(
      EmbedderTestBackingStoreProducer::RenderTargetType type,
      FlutterSoftwarePixelFormat software_pixfmt =
          kFlutterSoftwarePixelFormatNative32);

  UniqueEngine LaunchEngine() const;

  UniqueEngine InitializeEngine() const;

  // Sets up the callback for vsync, the callbacks needs to be specified on the
  // text context vis `SetVsyncCallback`.
  void SetupVsyncCallback();

 private:
  EmbedderTestContext& context_;
  FlutterProjectArgs project_args_ = {};
  FlutterRendererConfig renderer_config_ = {};
  FlutterSoftwareRendererConfig software_renderer_config_ = {};
#ifdef SHELL_ENABLE_GL
  FlutterOpenGLRendererConfig opengl_renderer_config_ = {};
#endif
#ifdef SHELL_ENABLE_VULKAN
  void InitializeVulkanRendererConfig();
  FlutterVulkanRendererConfig vulkan_renderer_config_ = {};
#endif
#ifdef SHELL_ENABLE_METAL
  void InitializeMetalRendererConfig();
  FlutterMetalRendererConfig metal_renderer_config_ = {};
#endif
  std::string dart_entrypoint_;
  FlutterCustomTaskRunners custom_task_runners_ = {};
  FlutterCompositor compositor_ = {};
  std::vector<std::string> command_line_arguments_;
  std::vector<std::string> dart_entrypoint_arguments_;
  std::string log_tag_;

  UniqueEngine SetupEngine(bool run) const;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderConfigBuilder);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONFIG_BUILDER_H_
