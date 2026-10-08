// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <chrono>
#include <deque>
#include <future>
#include <memory>

#include "flutter/fml/mapping.h"
#include "flutter/fml/task_runner.h"
#include "gmock/gmock.h"
#include "impeller/fixtures/gles/fixtures_shaders_gles.h"
#include "impeller/fixtures/spec_constant.frag.h"
#include "impeller/fixtures/spec_constant.vert.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/pipeline_library_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/pipeline_library.h"

namespace impeller::testing {

using PipelineLibraryGLESTest = PlaygroundTest;
INSTANTIATE_OPENGLES_PLAYGROUND_SUITE(PipelineLibraryGLESTest);

// NOLINTBEGIN(bugprone-unchecked-optional-access)
TEST_P(PipelineLibraryGLESTest, ProgramHandlesAreReused) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  auto new_desc = desc;
  // Changing the sample counts should not result in a new program object.
  new_desc->SetSampleCount(SampleCount::kCount4);
  // Make sure we don't hit the top-level descriptor cache. This will cause
  // caching irrespective of backends.
  ASSERT_FALSE(desc->IsEqual(new_desc.value()));
  auto new_pipeline =
      context->GetPipelineLibrary()->GetPipeline(new_desc).Get();
  ASSERT_TRUE(new_pipeline && new_pipeline->IsValid());
  const auto& pipeline_gles = PipelineGLES::Cast(*pipeline);
  const auto& new_pipeline_gles = PipelineGLES::Cast(*new_pipeline);
  // The program handles should be live and equal.
  ASSERT_FALSE(pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_FALSE(new_pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_EQ(pipeline_gles.GetProgramHandle().GetName().value(),
            new_pipeline_gles.GetProgramHandle().GetName().value());
}

TEST_P(PipelineLibraryGLESTest, ChangingSpecConstantsCausesNewProgramObject) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  auto context = GetContext();
  ASSERT_TRUE(context);
  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSpecializationConstants({2.0f});
  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  auto new_desc = desc;
  // Changing the spec. constants should result in a new program object.
  new_desc->SetSpecializationConstants({4.0f});
  auto new_pipeline =
      context->GetPipelineLibrary()->GetPipeline(new_desc).Get();
  ASSERT_TRUE(new_pipeline && new_pipeline->IsValid());
  const auto& pipeline_gles = PipelineGLES::Cast(*pipeline);
  const auto& new_pipeline_gles = PipelineGLES::Cast(*new_pipeline);
  // The program handles should be live and equal.
  ASSERT_FALSE(pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_FALSE(new_pipeline_gles.GetProgramHandle().IsDead());
  ASSERT_FALSE(pipeline_gles.GetProgramHandle().GetName().value() ==
               new_pipeline_gles.GetProgramHandle().GetName().value());
}

TEST_P(PipelineLibraryGLESTest, ClearingPipelineWillAlsoClearProgramHandle) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  std::shared_ptr<Context> context = GetContext();
  std::optional<PipelineDescriptor> desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);

  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline =
      context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  const auto& pipeline_gles = PipelineGLES::Cast(*pipeline);
  HandleGLES handle = pipeline_gles.GetProgramHandle();

  // Clear the pipeline descriptor.
  auto entrypoint =
      pipeline->GetDescriptor().GetEntrypointForStage(ShaderStage::kFragment);
  context->GetPipelineLibrary()->RemovePipelinesWithEntryPoint(entrypoint);

  // Re-create the pipeline
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline_2 =
      context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());
  const auto& pipeline_gles_2 = PipelineGLES::Cast(*pipeline_2);
  HandleGLES handle_2 = pipeline_gles_2.GetProgramHandle();

  EXPECT_FALSE(HandleGLES::Equal{}(handle, handle_2));
}
// NOLINTEND(bugprone-unchecked-optional-access)

namespace {

class MockReactorWorker final : public ReactorGLES::Worker {
 public:
  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};

/// A task runner that captures posted tasks so tests can run them on demand.
class CapturingTaskRunner final : public fml::BasicTaskRunner {
 public:
  void PostTask(const fml::closure& task) override { tasks_.push_back(task); }

  size_t RunAll() {
    size_t count = 0;
    while (!tasks_.empty()) {
      RunOne();
      count++;
    }
    return count;
  }

  void RunOne() {
    fml::closure task = std::move(tasks_.front());
    tasks_.pop_front();
    task();
  }

  size_t PendingTaskCount() const { return tasks_.size(); }

 private:
  std::deque<fml::closure> tasks_;
};

/// A GLES context backed by mock GL with an IO task runner, so async pipeline
/// creation goes through the compile queue.
struct MockAsyncContext {
  std::shared_ptr<MockGLES> mock_gles;
  std::shared_ptr<CapturingTaskRunner> io_task_runner;
  std::shared_ptr<ContextGLES> context;
  std::shared_ptr<MockReactorWorker> worker;
  std::shared_ptr<int> link_status_queries;
};

MockAsyncContext CreateMockAsyncContext() {
  MockAsyncContext result;
  result.link_status_queries = std::make_shared<int>(0);
  auto impl = std::make_unique<::testing::NiceMock<MockGLESImpl>>();
  ON_CALL(*impl, CreateProgram()).WillByDefault(::testing::Return(1));
  ON_CALL(*impl, IsProgram(::testing::_))
      .WillByDefault(::testing::Return(GL_TRUE));
  ON_CALL(*impl, CreateShader(::testing::_))
      .WillByDefault(::testing::Return(2));
  ON_CALL(*impl, GetShaderiv(::testing::_, GL_COMPILE_STATUS, ::testing::_))
      .WillByDefault(::testing::SetArgPointee<2>(GL_TRUE));
  ON_CALL(*impl, GetProgramiv(::testing::_, GL_LINK_STATUS, ::testing::_))
      .WillByDefault(::testing::DoAll(
          ::testing::SetArgPointee<2>(GL_TRUE),
          ::testing::InvokeWithoutArgs(
              [queries = result.link_status_queries] { (*queries)++; })));
  result.mock_gles = MockGLES::Init(std::move(impl));
  result.io_task_runner = std::make_shared<CapturingTaskRunner>();
  result.context = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(kMockResolverGLES),
      {std::make_shared<fml::NonOwnedMapping>(
          impeller_fixtures_shaders_gles_data,
          impeller_fixtures_shaders_gles_length)},
      /*enable_gpu_tracing=*/false, result.io_task_runner);
  result.worker = std::make_shared<MockReactorWorker>();
  result.context->AddReactorWorker(result.worker);
  return result;
}

bool IsReady(const PipelineFuture<PipelineDescriptor>& future) {
  return future.future.wait_for(std::chrono::seconds(0)) ==
         std::future_status::ready;
}

}  // namespace

// NOLINTBEGIN(bugprone-unchecked-optional-access)
TEST(PipelineLibraryGLESAsyncTest, WaitsForLinkInSeparateIOEvent) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  MockAsyncContext mock = CreateMockAsyncContext();
  std::shared_ptr<Context> context = mock.context;
  ASSERT_TRUE(context && context->IsValid());
  std::optional<PipelineDescriptor> desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());

  PipelineFuture<PipelineDescriptor> future =
      context->GetPipelineLibrary()->GetPipeline(desc, /*async=*/true);
  ASSERT_EQ(mock.io_task_runner->PendingTaskCount(), 1u);

  // The first IO event compiles the program and posts the link check.
  mock.io_task_runner->RunOne();
  EXPECT_EQ(*mock.link_status_queries, 0);
  EXPECT_FALSE(IsReady(future));
  EXPECT_GE(mock.io_task_runner->PendingTaskCount(), 1u);

  // A later IO event checks the link status and finishes the pipeline.
  mock.io_task_runner->RunAll();
  EXPECT_EQ(*mock.link_status_queries, 1);
  ASSERT_TRUE(IsReady(future));
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline = future.Get();
  EXPECT_TRUE(pipeline && pipeline->IsValid());
}

TEST(PipelineLibraryGLESAsyncTest, PerformEagerlyCompilesAndWaitsImmediately) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  MockAsyncContext mock = CreateMockAsyncContext();
  std::shared_ptr<Context> context = mock.context;
  ASSERT_TRUE(context && context->IsValid());
  std::optional<PipelineDescriptor> desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());

  std::shared_ptr<PipelineLibrary> library = context->GetPipelineLibrary();
  PipelineFuture<PipelineDescriptor> future =
      library->GetPipeline(desc, /*async=*/true);
  EXPECT_FALSE(IsReady(future));

  // Performing the job eagerly compiles and waits on the calling thread.
  library->PerformEagerly(desc.value());
  EXPECT_EQ(*mock.link_status_queries, 1);
  ASSERT_TRUE(IsReady(future));
  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline = future.Get();
  EXPECT_TRUE(pipeline && pipeline->IsValid());

  // Nothing is left for the IO task runner to do.
  mock.io_task_runner->RunAll();
  EXPECT_EQ(*mock.link_status_queries, 1);
}
// NOLINTEND(bugprone-unchecked-optional-access)

}  // namespace impeller::testing
