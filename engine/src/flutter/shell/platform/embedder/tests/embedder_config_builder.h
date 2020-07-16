// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONFIG_BUILDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONFIG_BUILDER_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_object.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"

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

  EmbedderConfigBuilder(EmbedderTestContext& context,
                        InitializationPreference preference =
                            InitializationPreference::kSnapshotsInitialize);

  ~EmbedderConfigBuilder();

  FlutterProjectArgs& GetProjectArgs();

  void SetSoftwareRendererConfig(SkISize surface_size = SkISize::Make(1, 1));

  void SetOpenGLRendererConfig(SkISize surface_size);

  void SetAssetsPath();

  void SetSnapshots();

  void SetAOTDataElf();

  void SetIsolateCreateCallbackHook();

  void SetSemanticsCallbackHooks();

  void SetLocalizationCallbackHooks();

  void SetDartEntrypoint(std::string entrypoint);

  void AddCommandLineArgument(std::string arg);

  void SetPlatformTaskRunner(const FlutterTaskRunnerDescription* runner);

  void SetRenderTaskRunner(const FlutterTaskRunnerDescription* runner);

  void SetPlatformMessageCallback(
      const std::function<void(const FlutterPlatformMessage*)>& callback);

  void SetCompositor();

  FlutterCompositor& GetCompositor();

  UniqueEngine LaunchEngine() const;

  UniqueEngine InitializeEngine() const;

 private:
  EmbedderTestContext& context_;
  FlutterProjectArgs project_args_ = {};
  FlutterRendererConfig renderer_config_ = {};
  FlutterSoftwareRendererConfig software_renderer_config_ = {};
  FlutterOpenGLRendererConfig opengl_renderer_config_ = {};
  std::string dart_entrypoint_;
  FlutterCustomTaskRunners custom_task_runners_ = {};
  FlutterCompositor compositor_ = {};
  std::vector<std::string> command_line_arguments_;

  UniqueEngine SetupEngine(bool run) const;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderConfigBuilder);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONFIG_BUILDER_H_
