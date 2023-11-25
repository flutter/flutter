// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/shader.h"
#include "flutter/lib/gpu/shader_library.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/testing/dart_fixture.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/testing.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/core/shader_types.h"
#include "impeller/fixtures/flutter_gpu_unlit.vert.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_descriptor.h"
#include "impeller/runtime_stage/runtime_stage.h"

#include "gtest/gtest.h"
#include "third_party/imgui/imgui.h"

namespace impeller {
namespace testing {

// This helper is for piggybacking on the RuntimeStage infrastructure for
// testing shaders/pipelines before the full shader bundle importer is finished.
static fml::RefPtr<flutter::gpu::Shader> OpenRuntimeStageAsShader(
    const std::string& fixture_name,
    std::shared_ptr<VertexDescriptor> vertex_desc) {
  auto fixture = flutter::testing::OpenFixtureAsMapping(fixture_name);
  assert(fixture);
  RuntimeStage stage(std::move(fixture));
  return flutter::gpu::Shader::Make(
      stage.GetEntrypoint(), ToShaderStage(stage.GetShaderStage()),
      stage.GetCodeMapping(), stage.GetUniforms(), std::move(vertex_desc));
}

static void InstantiateTestShaderLibrary() {
  flutter::gpu::ShaderLibrary::ShaderMap shaders;
  auto vertex_desc = std::make_shared<VertexDescriptor>();
  vertex_desc->SetStageInputs(
      // TODO(bdero): The stage inputs need to be packed into the flatbuffer.
      FlutterGpuUnlitVertexShader::kAllShaderStageInputs,
      // TODO(bdero): Make the vertex attribute layout fully configurable.
      //              When encoding commands, allow for specifying a stride,
      //              type, and vertex buffer slot for each attribute.
      //              Provide a way to lookup vertex attribute slot locations by
      //              name from the shader.
      FlutterGpuUnlitVertexShader::kInterleavedBufferLayout);
  shaders["UnlitVertex"] = OpenRuntimeStageAsShader(
      "flutter_gpu_unlit.vert.iplr", std::move(vertex_desc));
  shaders["UnlitFragment"] =
      OpenRuntimeStageAsShader("flutter_gpu_unlit.frag.iplr", nullptr);
  auto library =
      flutter::gpu::ShaderLibrary::MakeFromShaders(std::move(shaders));
  flutter::gpu::ShaderLibrary::SetOverride(library);
}

class RendererDartTest : public PlaygroundTest,
                         public flutter::testing::DartFixture {
 public:
  RendererDartTest()
      : settings_(CreateSettingsForFixture()),
        vm_ref_(flutter::DartVMRef::Create(settings_)) {
    fml::MessageLoop::EnsureInitializedForCurrentThread();

    current_task_runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();

    isolate_ = CreateDartIsolate();
    assert(isolate_);
    assert(isolate_->get()->GetPhase() == flutter::DartIsolate::Phase::Running);
  }

  flutter::testing::AutoIsolateShutdown* GetIsolate() {
    // Sneak the context into the Flutter GPU API.
    assert(GetContext() != nullptr);
    flutter::gpu::Context::SetOverrideContext(GetContext());

    InstantiateTestShaderLibrary();

    return isolate_.get();
  }

 private:
  std::unique_ptr<flutter::testing::AutoIsolateShutdown> CreateDartIsolate() {
    const auto settings = CreateSettingsForFixture();
    flutter::TaskRunners task_runners(flutter::testing::GetCurrentTestName(),
                                      current_task_runner_,  //
                                      current_task_runner_,  //
                                      current_task_runner_,  //
                                      current_task_runner_   //
    );
    return flutter::testing::RunDartCodeInIsolate(
        vm_ref_, settings, task_runners, "main", {},
        flutter::testing::GetDefaultKernelFilePath());
  }

  const flutter::Settings settings_;
  flutter::DartVMRef vm_ref_;
  fml::RefPtr<fml::TaskRunner> current_task_runner_;
  std::unique_ptr<flutter::testing::AutoIsolateShutdown> isolate_;
};

INSTANTIATE_PLAYGROUND_SUITE(RendererDartTest);

TEST_P(RendererDartTest, CanRunDartInPlaygroundFrame) {
  auto isolate = GetIsolate();

  SinglePassCallback callback = [&](RenderPass& pass) {
    ImGui::Begin("Dart test", nullptr);
    ImGui::Text(
        "This test executes Dart code during the playground frame callback.");
    ImGui::End();

    return isolate->RunInIsolateScope([]() -> bool {
      if (tonic::CheckAndHandleError(::Dart_Invoke(
              Dart_RootLibrary(), tonic::ToDart("sayHi"), 0, nullptr))) {
        return false;
      }
      return true;
    });
  };
  OpenPlaygroundHere(callback);
}

TEST_P(RendererDartTest, CanInstantiateFlutterGPUContext) {
  auto isolate = GetIsolate();
  bool result = isolate->RunInIsolateScope([]() -> bool {
    if (tonic::CheckAndHandleError(::Dart_Invoke(
            Dart_RootLibrary(), tonic::ToDart("instantiateDefaultContext"), 0,
            nullptr))) {
      return false;
    }
    return true;
  });

  ASSERT_TRUE(result);
}

#define DART_TEST_CASE(name)                                            \
  TEST_P(RendererDartTest, name) {                                      \
    auto isolate = GetIsolate();                                        \
    bool result = isolate->RunInIsolateScope([]() -> bool {             \
      if (tonic::CheckAndHandleError(::Dart_Invoke(                     \
              Dart_RootLibrary(), tonic::ToDart(#name), 0, nullptr))) { \
        return false;                                                   \
      }                                                                 \
      return true;                                                      \
    });                                                                 \
    ASSERT_TRUE(result);                                                \
  }

/// These test entries correspond to Dart functions located in
/// `flutter/impeller/fixtures/dart_tests.dart`

DART_TEST_CASE(canEmplaceHostBuffer);

DART_TEST_CASE(canCreateDeviceBuffer);
DART_TEST_CASE(canOverwriteDeviceBuffer);
DART_TEST_CASE(deviceBufferOverwriteFailsWhenOutOfBounds);
DART_TEST_CASE(deviceBufferOverwriteThrowsForNegativeDestinationOffset);

DART_TEST_CASE(canCreateTexture);
DART_TEST_CASE(canOverwriteTexture);
DART_TEST_CASE(textureOverwriteThrowsForWrongBufferSize);
DART_TEST_CASE(textureAsImageReturnsAValidUIImageHandle);
DART_TEST_CASE(textureAsImageThrowsWhenNotShaderReadable);

DART_TEST_CASE(canCreateShaderLibrary);

DART_TEST_CASE(canCreateRenderPassAndSubmit);

}  // namespace testing
}  // namespace impeller
