// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/runtime/dart_isolate.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/runtime/isolate_configuration.h"
#include "flutter/testing/dart_fixture.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/fixture_test.h"
#include "flutter/testing/testing.h"
#include "impeller/fixtures/box_fade.frag.h"
#include "impeller/fixtures/box_fade.vert.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

#include "third_party/imgui/imgui.h"

namespace impeller {
namespace testing {

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

  flutter::testing::AutoIsolateShutdown* GetIsolate() { return isolate_.get(); }

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

}  // namespace testing
}  // namespace impeller
