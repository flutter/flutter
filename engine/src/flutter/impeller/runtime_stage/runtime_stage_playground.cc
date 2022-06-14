// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/runtime_stage/runtime_stage_playground.h"

#include <future>

#include "flutter/fml/make_copyable.h"
#include "flutter/testing/testing.h"
#include "impeller/renderer/shader_library.h"

namespace impeller {

RuntimeStagePlayground::RuntimeStagePlayground() = default;

RuntimeStagePlayground::~RuntimeStagePlayground() = default;

std::unique_ptr<RuntimeStage> RuntimeStagePlayground::CreateStageFromFixture(
    const std::string& fixture_name) const {
  auto fixture = flutter::testing::OpenFixtureAsMapping(fixture_name);
  if (!fixture || fixture->GetSize() == 0) {
    return nullptr;
  }
  auto stage = std::make_unique<RuntimeStage>(std::move(fixture));
  if (!stage->IsValid()) {
    return nullptr;
  }
  return stage;
}

bool RuntimeStagePlayground::RegisterStage(const RuntimeStage& stage) {
  std::promise<bool> registration;
  auto future = registration.get_future();
  auto library = GetContext()->GetShaderLibrary();
  GetContext()->GetShaderLibrary()->RegisterFunction(
      stage.GetEntrypoint(), stage.GetShaderStage(), stage.GetCodeMapping(),
      fml::MakeCopyable([reg = std::move(registration)](bool result) mutable {
        reg.set_value(result);
      }));
  return future.get();
}

}  // namespace impeller
