// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/render_pipeline.h"

#include <chrono>
#include <future>
#include <vector>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/lib/gpu/context.h"
#include "flutter/lib/gpu/shader.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

fml::RefPtr<Shader> MakeShader(impeller::ShaderStage stage) {
  return Shader::Make("library", "Entrypoint", stage,
                      /*code_mapping=*/nullptr, /*inputs=*/{}, /*layouts=*/{},
                      /*uniform_structs=*/{}, /*uniform_textures=*/{},
                      /*descriptor_set_layouts=*/{});
}

// Pairing shaders of the wrong stages previously constructed a pipeline that
// only failed at first draw, deep inside backend pipeline compilation; the
// stages must be rejected with an error at creation instead.
TEST(FlutterGpuRenderPipelineTest, ValidatesShaderStages) {
  auto vertex = MakeShader(impeller::ShaderStage::kVertex);
  auto fragment = MakeShader(impeller::ShaderStage::kFragment);

  EXPECT_EQ(ValidateRenderPipelineShaderStages(*vertex, *fragment), nullptr);

  const char* swapped = ValidateRenderPipelineShaderStages(*fragment, *vertex);
  ASSERT_NE(swapped, nullptr);
  EXPECT_NE(std::string(swapped).find("vertex"), std::string::npos);

  const char* two_vertex = ValidateRenderPipelineShaderStages(*vertex, *vertex);
  ASSERT_NE(two_vertex, nullptr);
  EXPECT_NE(std::string(two_vertex).find("fragment"), std::string::npos);
}

// Registers immediately, with a result the test picks.
class FakeShaderLibrary : public impeller::ShaderLibrary {
 public:
  bool IsValid() const override { return true; }

  std::shared_ptr<const impeller::ShaderFunction> GetFunction(
      std::string_view name,
      impeller::ShaderStage stage) override {
    return nullptr;
  }

  void RegisterFunction(std::string name,
                        impeller::ShaderStage stage,
                        std::shared_ptr<fml::Mapping> code,
                        RegistrationCallback callback) override {
    registrations++;
    if (defer) {
      deferred.push_back(std::move(callback));
      return;
    }
    callback(succeed);
  }

  void UnregisterFunction(std::string name,
                          impeller::ShaderStage stage) override {}

  void RunDeferred() {
    for (auto& callback : deferred) {
      callback(succeed);
    }
    deferred.clear();
  }

  int registrations = 0;
  bool succeed = true;
  bool defer = false;
  std::vector<RegistrationCallback> deferred;
};

// Registration is scheduled, not waited on, so a shader registers once per
// version of its code, plus a retry after a failed registration. Without a
// raster task runner (as here) it runs inline.
TEST(FlutterGpuRenderPipelineTest, ScheduleRegistrationOncePerVersion) {
  auto library = std::make_shared<FakeShaderLibrary>();
  auto impeller_context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  ON_CALL(*impeller_context, GetShaderLibrary)
      .WillByDefault(::testing::Return(library));
  Context context(impeller_context);
  auto shader = MakeShader(impeller::ShaderStage::kVertex);

  EXPECT_TRUE(shader->IsDirty());
  shader->ScheduleRegistration(context);
  EXPECT_FALSE(shader->IsDirty());
  EXPECT_TRUE(shader->GetRegistration().get());
  shader->ScheduleRegistration(context);
  EXPECT_EQ(library->registrations, 1);

  // A reload makes the shader dirty again.
  shader->ResetFrom(*MakeShader(impeller::ShaderStage::kVertex));
  shader->ScheduleRegistration(context);
  EXPECT_EQ(library->registrations, 2);

  // A failed registration is retried by the next pipeline.
  library->succeed = false;
  shader->ResetFrom(*MakeShader(impeller::ShaderStage::kVertex));
  shader->ScheduleRegistration(context);
  EXPECT_FALSE(shader->GetRegistration().get());
  library->succeed = true;
  shader->ScheduleRegistration(context);
  EXPECT_EQ(library->registrations, 4);
  EXPECT_TRUE(shader->GetRegistration().get());
}

// Resolving a pipeline waits on its shaders' registrations, so a failed one
// fails the bind instead of reading a library slot that was never filled.
TEST(FlutterGpuRenderPipelineTest, BindFailsWhenRegistrationFailed) {
  auto library = std::make_shared<FakeShaderLibrary>();
  library->succeed = false;
  auto impeller_context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  ON_CALL(*impeller_context, GetShaderLibrary)
      .WillByDefault(::testing::Return(library));
  Context context(impeller_context);
  auto vertex = MakeShader(impeller::ShaderStage::kVertex);
  auto fragment = MakeShader(impeller::ShaderStage::kFragment);
  vertex->ScheduleRegistration(context);
  fragment->ScheduleRegistration(context);
  auto pipeline = fml::MakeRefCounted<RenderPipeline>(
      vertex, fragment, vertex->CreateVertexDescriptor());

  impeller::PipelineDescriptor desc;
  impeller::ScopedValidationDisable disable_validation;
  EXPECT_FALSE(pipeline->GetCore()->BindToPipelineDescriptor(*library, desc));
}

// A reload can schedule a registration after a replay that uses an existing
// pipeline was queued, behind it on the same thread. Resolving that pipeline
// must not wait on the newer registration, or the replay thread deadlocks.
TEST(FlutterGpuRenderPipelineTest, BindIgnoresRegistrationsAfterCreation) {
  auto library = std::make_shared<FakeShaderLibrary>();
  auto impeller_context = std::make_shared<
      ::testing::NiceMock<impeller::testing::MockImpellerContext>>();
  ON_CALL(*impeller_context, GetShaderLibrary)
      .WillByDefault(::testing::Return(library));
  Context context(impeller_context);
  auto vertex = MakeShader(impeller::ShaderStage::kVertex);
  auto fragment = MakeShader(impeller::ShaderStage::kFragment);
  vertex->ScheduleRegistration(context);
  fragment->ScheduleRegistration(context);
  auto pipeline = fml::MakeRefCounted<RenderPipeline>(
      vertex, fragment, vertex->CreateVertexDescriptor());

  library->defer = true;
  vertex->ResetFrom(*MakeShader(impeller::ShaderStage::kVertex));
  vertex->ScheduleRegistration(context);
  ASSERT_EQ(library->deferred.size(), 1u);

  impeller::ScopedValidationDisable disable_validation;
  auto bind = std::async(std::launch::async, [&pipeline, &library]() {
    impeller::PipelineDescriptor desc;
    return pipeline->GetCore()->BindToPipelineDescriptor(*library, desc);
  });
  EXPECT_EQ(bind.wait_for(std::chrono::seconds(5)), std::future_status::ready);
  library->RunDeferred();
  bind.wait();
}

}  // namespace
}  // namespace flutter::gpu
