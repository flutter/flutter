// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/task_runner.h"
#include "flutter/fml/task_runner_util.h"
#include "flutter/fml/thread.h"
#include "impeller/fixtures/spec_constant.frag.h"
#include "impeller/fixtures/spec_constant.vert.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/pipeline_library_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/backend/gles/test/pipeline_library_gles_test_utils.h"
#include "impeller/renderer/pipeline_descriptor.h"
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

TEST_P(PipelineLibraryGLESTest, SynchronousPipelineIsValid) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);

  std::optional<PipelineDescriptor> desc =
      PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());

  std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline =
      context->GetPipelineLibrary()
          ->GetPipeline(desc.value(), /*async=*/false)
          .Get();
  ASSERT_TRUE(pipeline && pipeline->IsValid());

  // A variant reuses the program of the pipeline above.
  std::optional<PipelineDescriptor> variant = desc;
  variant->SetSampleCount(SampleCount::kCount4);
  std::shared_ptr<Pipeline<PipelineDescriptor>> variant_pipeline =
      context->GetPipelineLibrary()
          ->GetPipeline(variant.value(), /*async=*/false)
          .Get();
  ASSERT_TRUE(variant_pipeline && variant_pipeline->IsValid());
}
// NOLINTEND(bugprone-unchecked-optional-access)

// A pending pipeline whose link nobody can check must fail rather than leave
// its promise unset, because a caller of WaitAndGet blocks on that promise.
TEST(PipelineLibraryGLESDeferredTest,
     FailsPendingPipelinesWhenTheReactorCannotReact) {
  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::nullopt, "OpenGL ES 3.0 (ANGLE 2.1.0)");
  fml::Thread io_thread;
  std::shared_ptr<ContextGLES> context = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(kMockResolverGLES),
      std::vector<std::shared_ptr<fml::Mapping>>{},
      /*enable_gpu_tracing=*/false,
      std::make_shared<fml::WrapperBasicTaskRunner>(io_thread.GetTaskRunner()));
  ASSERT_NE(context, nullptr);
  auto worker = std::make_shared<ToggleWorker>(false);
  context->AddReactorWorker(worker);

  auto context_base = std::static_pointer_cast<Context>(context);
  auto& library =
      PipelineLibraryGLES::Cast(*context_base->GetPipelineLibrary());
  auto promise = std::make_shared<PipelineLibraryGLES::PipelinePromise>();
  std::future<std::shared_ptr<Pipeline<PipelineDescriptor>>> future =
      promise->get_future();
  {
    Lock lock(library.pending_mutex_);
    library.pending_pipelines_.push_back(PipelineLibraryGLES::PendingPipeline{
        .pipeline = nullptr,
        .promise = promise,
        .program_key = PipelineLibraryGLES::ProgramKey{nullptr, nullptr, {}},
    });
  }
  library.WatchQueueForDrain();

  // Any job drains the queue, and the queue reports that to the library.
  ASSERT_TRUE(library.compile_queue_->PostJobForDescriptor(PipelineDescriptor{},
                                                           []() {}));
  EXPECT_EQ(future.get(), nullptr);

  io_thread.Join();
}

namespace {

/// A status query waits for the link, so a job must not make a blocking one
/// for a link it started. A variant that reuses a linking program must get
/// the result of that link, and a failed link must not stay in the cache.
void RunDeferredLink(bool fail_compile,
                     bool fail_link,
                     bool abandon_before_check = false) {
  // Limit is above 2 and the mock reports no completed link, so both requests
  // stay pending until the queue drains
  DeferredLinkHarness harness(/*max_pending_links=*/4);
  DeferredLinkState& state = harness.state;
  state.fail_compile = fail_compile;
  state.fail_link = fail_link;
  PipelineDescriptor desc = harness.desc;
  std::shared_ptr<PipelineLibrary>& library = harness.library;
  PipelineFuture<PipelineDescriptor> first =
      library->GetPipeline(desc, true, true);
  desc.SetSampleCount(SampleCount::kCount4);
  PipelineFuture<PipelineDescriptor> second =
      library->GetPipeline(desc, true, true);
  ASSERT_FALSE(harness.runner->tasks.empty());
  // Job of second is still queued, so the queue has not drained and the link
  // of first must stay unchecked
  harness.runner->RunOne();
  EXPECT_EQ(state.links, 1);
  EXPECT_EQ(state.compile_queries, 0);
  EXPECT_EQ(state.link_queries, 0);
  EXPECT_FALSE(IsReady(first));
  EXPECT_FALSE(IsReady(second));
  if (abandon_before_check) {
    // Reactor cannot react here, so the drain check cannot run and first must
    // fail instead of leaving its promise unset. Operation that creates second
    // stays in the reactor.
    harness.worker->SetAllowed(false);
    harness.runner->RunAll();
    EXPECT_TRUE(IsReady(first));
    EXPECT_FALSE(IsReady(second));
    harness.worker->SetAllowed(true);
    state.fail_compile = false;
    state.fail_link = false;
    desc.SetSampleCount(SampleCount::kCount1);
    desc.SetColorAttachmentDescriptor(0, ColorAttachmentDescriptor{});
    // Next reaction on this thread creates second outside of a queue job, so
    // it links synchronously. The abandoned program left the cache, so second
    // links a new one, and retry reuses it.
    PipelineFuture<PipelineDescriptor> retry =
        library->GetPipeline(desc, false, true);
    ASSERT_TRUE(IsReady(retry));
    ASSERT_TRUE(IsReady(second));
    ASSERT_NE(retry.Get(), nullptr);
    ASSERT_NE(second.Get(), nullptr);
    EXPECT_EQ(PipelineGLES::Cast(*second.Get()).GetSharedHandle(),
              PipelineGLES::Cast(*retry.Get()).GetSharedHandle());
    EXPECT_EQ(state.programs, 2);
    return;
  }
  harness.runner->RunAll();
  ASSERT_TRUE(IsReady(first));
  ASSERT_TRUE(IsReady(second));
  EXPECT_EQ(state.programs, 1);
  EXPECT_EQ(state.links, 1);
  EXPECT_EQ(state.compile_queries, 2);
  EXPECT_EQ(state.detached, 2);
  EXPECT_EQ(state.deleted_shaders, 2);
  if (!fail_compile && !fail_link) {
    ASSERT_NE(first.Get(), nullptr);
    ASSERT_NE(second.Get(), nullptr);
    EXPECT_EQ(PipelineGLES::Cast(*first.Get()).GetSharedHandle(),
              PipelineGLES::Cast(*second.Get()).GetSharedHandle());
  } else {
    EXPECT_EQ(first.Get(), nullptr);
    EXPECT_EQ(second.Get(), nullptr);
    state.fail_compile = false;
    state.fail_link = false;
    desc.SetSampleCount(SampleCount::kCount1);
    desc.SetColorAttachmentDescriptor(0, ColorAttachmentDescriptor{});
    PipelineFuture<PipelineDescriptor> retry =
        library->GetPipeline(desc, true, true);
    harness.runner->RunAll();
    ASSERT_TRUE(IsReady(retry));
    ASSERT_NE(retry.Get(), nullptr);
    EXPECT_EQ(state.programs, 2);
  }
}

// Async requests may start the link of a program and check it later, which
// GL_KHR_parallel_shader_compile allows. More requests than links may run at
// the same time, and some of them share a program that is still linking.
TEST(PipelineLibraryGLESDeferredTest, AsyncPipelinesAreValid) {
  DeferredLinkHarness harness(/*max_pending_links=*/4);
  std::vector<PipelineFuture<PipelineDescriptor>> futures;
  for (Scalar constant : {1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f}) {
    for (SampleCount samples : {SampleCount::kCount1, SampleCount::kCount4}) {
      PipelineDescriptor desc = harness.desc;
      desc.SetSpecializationConstants({constant});
      desc.SetSampleCount(samples);
      futures.push_back(harness.library->GetPipeline(desc, true, true));
    }
  }
  // 4th job reaches the limit, so it checks 4 pending pipelines before the
  // queue drains
  for (int i = 0; i < 4; i++) {
    harness.runner->RunOne();
  }
  for (int i = 0; i < 4; i++) {
    EXPECT_TRUE(IsReady(futures[i])) << i;
  }
  EXPECT_FALSE(IsReady(futures[4]));

  harness.runner->RunAll();
  for (size_t i = 0; i < futures.size(); i++) {
    ASSERT_TRUE(IsReady(futures[i])) << i;
    ASSERT_NE(futures[i].Get(), nullptr) << i;
  }
  for (size_t i = 0; i < futures.size(); i += 2) {
    EXPECT_EQ(PipelineGLES::Cast(*futures[i].Get()).GetSharedHandle(),
              PipelineGLES::Cast(*futures[i + 1].Get()).GetSharedHandle());
  }
  EXPECT_EQ(harness.state.programs, 6);
  EXPECT_EQ(harness.state.links, 6);
}

/// A link that completes early must not wait for the limit or the drain, so
/// the next job finishes it. A driver that rejects the query leaves the value
/// unchanged, and the link must then stay pending until the drain.
void RunCompletedLink(bool completion_supported) {
  DeferredLinkHarness harness(/*max_pending_links=*/4);
  harness.state.completion_supported = completion_supported;
  std::vector<PipelineFuture<PipelineDescriptor>> futures;
  for (Scalar constant : {1.0f, 2.0f, 3.0f}) {
    PipelineDescriptor desc = harness.desc;
    desc.SetSpecializationConstants({constant});
    futures.push_back(harness.library->GetPipeline(desc, true, true));
  }
  harness.runner->RunOne();
  ASSERT_EQ(harness.state.linked.size(), 1u);
  harness.state.completed[harness.state.linked.begin()->first] = true;

  harness.runner->RunOne();
  EXPECT_GT(harness.state.completion_queries, 0);
  EXPECT_EQ(IsReady(futures[0]), completion_supported);
  EXPECT_EQ(harness.state.link_queries, completion_supported ? 1 : 0);
  EXPECT_FALSE(IsReady(futures[1]));
  EXPECT_FALSE(IsReady(futures[2]));

  harness.runner->RunAll();
  for (size_t i = 0; i < futures.size(); i++) {
    ASSERT_TRUE(IsReady(futures[i])) << i;
    ASSERT_NE(futures[i].Get(), nullptr) << i;
  }
  EXPECT_EQ(harness.state.programs, 3);
  EXPECT_EQ(harness.state.link_queries, 3);
}

TEST(PipelineLibraryGLESDeferredTest, FinishesCompletedLinkBeforeLimit) {
  RunCompletedLink(/*completion_supported=*/true);
}

TEST(PipelineLibraryGLESDeferredTest,
     KeepsLinkPendingWhenCompletionQueryFails) {
  RunCompletedLink(/*completion_supported=*/false);
}

TEST(PipelineLibraryGLESDeferredTest, DefersStatusAndSharesPendingProgram) {
  RunDeferredLink(false, false);
}

TEST(PipelineLibraryGLESDeferredTest, FailedCompileRejectsBothSharedPipelines) {
  RunDeferredLink(true, false);
}

TEST(PipelineLibraryGLESDeferredTest, FailedLinkRejectsBothSharedPipelines) {
  RunDeferredLink(false, true);
}

TEST(PipelineLibraryGLESDeferredTest,
     AbandonedFailedLinkDoesNotPoisonProgramCache) {
  RunDeferredLink(false, true, true);
}

TEST(PipelineLibraryGLESDeferredTest,
     ResolvesUnstartedPipelinesWhenTheRunnerDiscardsJobs) {
  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::vector<const char*>{"GL_KHR_parallel_shader_compile"},
                     "OpenGL ES 3.0 (ANGLE 2.1.0)");
  fml::Thread io_thread;
  auto runner = std::make_shared<fml::ConditionalBasicTaskRunner>(
      io_thread.GetTaskRunner(), []() { return false; });
  std::shared_ptr<ContextGLES> context = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(kMockResolverGLES),
      std::vector<std::shared_ptr<fml::Mapping>>{},
      /*enable_gpu_tracing=*/false, runner);
  ASSERT_NE(context, nullptr);
  auto context_base = std::static_pointer_cast<Context>(context);
  std::shared_ptr<PipelineLibrary> library = context_base->GetPipelineLibrary();
  PipelineCompileQueue* queue = library->GetPipelineCompileQueue();
  ASSERT_NE(queue, nullptr);
  std::weak_ptr<PipelineCompileQueue> weak_queue = queue->weak_from_this();
  PipelineDescriptor descriptor;
  descriptor.AddStageEntrypoint(
      std::make_shared<UnstartedShaderFunction>(ShaderStage::kVertex));
  descriptor.AddStageEntrypoint(
      std::make_shared<UnstartedShaderFunction>(ShaderStage::kFragment));
  PipelineFuture<PipelineDescriptor> future =
      library->GetPipeline(descriptor, /*async=*/true);
  library.reset();
  context_base.reset();
  context.reset();
  io_thread.Join();

  EXPECT_TRUE(weak_queue.expired());
  const bool ready = IsReady(future);
  EXPECT_TRUE(ready);
  if (ready) {
    EXPECT_EQ(future.Get(), nullptr);
  }
  if (std::shared_ptr<PipelineCompileQueue> leaked_queue = weak_queue.lock()) {
    leaked_queue->PerformJobEagerly(descriptor);
  }
}

}  // namespace

}  // namespace impeller::testing
