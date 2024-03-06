// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/shader_library.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/testing/dart_fixture.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/testing.h"
#include "fml/memory/ref_ptr.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/render_pass.h"

#include "gtest/gtest.h"
#include "third_party/imgui/imgui.h"

namespace impeller {
namespace testing {

static void InstantiateTestShaderLibrary(Context::BackendType backend_type) {
  auto fixture =
      flutter::testing::OpenFixtureAsMapping("playground.shaderbundle");
  auto library = flutter::gpu::ShaderLibrary::MakeFromFlatbuffer(
      backend_type, std::move(fixture));
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

    InstantiateTestShaderLibrary(GetContext()->GetBackendType());

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

DART_TEST_CASE(canCreateShaderLibrary);
DART_TEST_CASE(canReflectUniformStructs);
DART_TEST_CASE(uniformBindFailsForInvalidHostBufferOffset);

DART_TEST_CASE(canCreateRenderPassAndSubmit);

}  // namespace testing
}  // namespace impeller
