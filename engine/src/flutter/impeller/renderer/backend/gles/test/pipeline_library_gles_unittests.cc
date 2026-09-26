// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atomic>
#include <chrono>
#include <cstring>
#include <deque>
#include <future>
#include <memory>
#include <optional>
#include <thread>
#include <unordered_map>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/task_runner_util.h"
#include "flutter/fml/thread.h"
#include "flutter/fml/time/time_delta.h"
#include "impeller/fixtures/spec_constant.frag.h"
#include "impeller/fixtures/spec_constant.vert.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/pipeline_gles.h"
#include "impeller/renderer/backend/gles/pipeline_library_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/shader_library.h"
#include "impeller/renderer/vertex_descriptor.h"

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

// Async requests may start the link of a program and check it later, which
// GL_KHR_parallel_shader_compile allows. More requests than links may run at
// the same time, and some of them share a program that is still linking.
TEST_P(PipelineLibraryGLESTest, AsyncPipelinesAreValid) {
  using VS = SpecConstantVertexShader;
  using FS = SpecConstantFragmentShader;
  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);

  std::vector<PipelineFuture<PipelineDescriptor>> futures;
  for (Scalar constant : {1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f}) {
    for (SampleCount samples : {SampleCount::kCount1, SampleCount::kCount4}) {
      std::optional<PipelineDescriptor> desc =
          PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
      ASSERT_TRUE(desc.has_value());
      desc->SetSpecializationConstants({constant});
      desc->SetSampleCount(samples);
      futures.push_back(
          context->GetPipelineLibrary()->GetPipeline(desc.value()));
    }
  }

  for (PipelineFuture<PipelineDescriptor>& future : futures) {
    std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline = future.Get();
    ASSERT_TRUE(pipeline && pipeline->IsValid());
  }
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

namespace {

/// A worker that answers whether the reactor may react with a value the test
/// sets.
class ToggleWorker final : public ReactorGLES::Worker {
 public:
  explicit ToggleWorker(bool allowed) : allowed_(allowed) {}

  // |ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return allowed_.load();
  }

  void SetAllowed(bool allowed) { allowed_.store(allowed); }

 private:
  std::atomic<bool> allowed_;
};

}  // namespace

// A pending pipeline whose link nobody can check must fail rather than leave
// its promise unset, because a caller of WaitAndGet blocks on that promise.
TEST(PipelineLibraryGLESDeferredTest,
     FailsPendingPipelinesWhenTheReactorCannotReact) {
  auto mock_gles = MockGLES::Init(std::nullopt, "OpenGL ES 3.0 (ANGLE 2.1.0)");
  fml::Thread io_thread;
  auto context = ContextGLES::Create(
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
  auto future = promise->get_future();
  {
    Lock lock(library.pending_mutex_);
    library.pending_pipelines_.push_back(PipelineLibraryGLES::PendingPipeline{
        .pipeline = nullptr,
        .promise = promise,
        .program_key = PipelineLibraryGLES::ProgramKey{nullptr, nullptr, {}},
    });
  }
  library.WatchQueueForDrain();

  // A loaded bot needs far less than this, and a regression fails here
  // instead of waiting for the timeout of the whole suite.
  const auto timeout = std::chrono::seconds(30);

  // Any job drains the queue, and the queue reports that to the library.
  fml::AutoResetWaitableEvent job_done;
  ASSERT_TRUE(library.compile_queue_->PostJobForDescriptor(
      PipelineDescriptor{}, [&]() { job_done.Signal(); }));
  ASSERT_FALSE(job_done.WaitWithTimeout(fml::TimeDelta::FromSeconds(30)));

  ASSERT_EQ(future.wait_for(timeout), std::future_status::ready);
  EXPECT_EQ(future.get(), nullptr);

  io_thread.Join();
}

namespace {

class DeferredLinkRunner final : public fml::BasicTaskRunner {
 public:
  void PostTask(const fml::closure& task) override { tasks.push_back(task); }
  void RunOne() {
    auto task = std::move(tasks.front());
    tasks.pop_front();
    task();
  }
  void RunAll() {
    while (!tasks.empty()) {
      RunOne();
    }
  }
  std::deque<fml::closure> tasks;
};

struct DeferredLinkState {
  GLuint next = 1;
  int programs = 0;
  int links = 0;
  int compile_queries = 0;
  int link_queries = 0;
  int detached = 0;
  int deleted_shaders = 0;
  bool fail_compile = false;
  bool fail_link = false;
  std::unordered_map<GLuint, bool> shaders;
  std::unordered_map<GLuint, bool> linked;
};

DeferredLinkState* deferred_links = nullptr;

GLuint GL_APIENTRY DeferredCreateShader(GLenum type) {
  auto id = deferred_links->next++;
  deferred_links->shaders[id] =
      !(deferred_links->fail_compile && type == GL_VERTEX_SHADER);
  return id;
}
GLuint GL_APIENTRY DeferredCreateProgram() {
  deferred_links->programs++;
  return deferred_links->next++;
}
void GL_APIENTRY DeferredLinkProgram(GLuint program) {
  deferred_links->links++;
  deferred_links->linked[program] =
      !deferred_links->fail_compile && !deferred_links->fail_link;
}
void GL_APIENTRY DeferredGetShaderiv(GLuint shader,
                                     GLenum pname,
                                     GLint* value) {
  *value = 0;
  if (pname == GL_COMPILE_STATUS) {
    deferred_links->compile_queries++;
    *value = deferred_links->shaders[shader] ? GL_TRUE : GL_FALSE;
  }
}
void GL_APIENTRY DeferredGetProgramiv(GLuint program,
                                      GLenum pname,
                                      GLint* value) {
  *value = 0;
  if (pname == GL_LINK_STATUS) {
    deferred_links->link_queries++;
    *value = deferred_links->linked[program] ? GL_TRUE : GL_FALSE;
  }
}
void GL_APIENTRY DeferredDetachShader(GLuint program, GLuint shader) {
  deferred_links->detached++;
}
void GL_APIENTRY DeferredDeleteShader(GLuint shader) {
  deferred_links->deleted_shaders++;
}
GLboolean GL_APIENTRY DeferredIsProgram(GLuint program) {
  return program != 0 ? GL_TRUE : GL_FALSE;
}
GLint GL_APIENTRY DeferredGetUniformLocation(GLuint program,
                                             const GLchar* name) {
  return -1;
}
void GL_APIENTRY DeferredGetText(GLuint object,
                                 GLsizei size,
                                 GLsizei* length,
                                 GLchar* text) {
  if (length) {
    *length = 0;
  }
  if (size > 0 && text) {
    text[0] = '\0';
  }
}
void* DeferredLinkResolver(const char* name) {
  if (strcmp(name, "glCreateShader") == 0) {
    return reinterpret_cast<void*>(DeferredCreateShader);
  }
  if (strcmp(name, "glCreateProgram") == 0) {
    return reinterpret_cast<void*>(DeferredCreateProgram);
  }
  if (strcmp(name, "glLinkProgram") == 0) {
    return reinterpret_cast<void*>(DeferredLinkProgram);
  }
  if (strcmp(name, "glGetShaderiv") == 0) {
    return reinterpret_cast<void*>(DeferredGetShaderiv);
  }
  if (strcmp(name, "glGetProgramiv") == 0) {
    return reinterpret_cast<void*>(DeferredGetProgramiv);
  }
  if (strcmp(name, "glDetachShader") == 0) {
    return reinterpret_cast<void*>(DeferredDetachShader);
  }
  if (strcmp(name, "glDeleteShader") == 0) {
    return reinterpret_cast<void*>(DeferredDeleteShader);
  }
  if (strcmp(name, "glIsProgram") == 0) {
    return reinterpret_cast<void*>(DeferredIsProgram);
  }
  if (strcmp(name, "glGetUniformLocation") == 0) {
    return reinterpret_cast<void*>(DeferredGetUniformLocation);
  }
  if (strcmp(name, "glGetShaderSource") == 0 ||
      strcmp(name, "glGetShaderInfoLog") == 0 ||
      strcmp(name, "glGetProgramInfoLog") == 0) {
    return reinterpret_cast<void*>(DeferredGetText);
  }
  return kMockResolverGLES(name);
}

void RunDeferredLink(bool fail_compile,
                     bool fail_link,
                     bool abandon_before_check = false) {
  if (std::thread::hardware_concurrency() < 4) {
    GTEST_SKIP() << "The pending limit must allow at least 2 pipelines";
  }
  DeferredLinkState state;
  state.fail_compile = fail_compile;
  state.fail_link = fail_link;
  deferred_links = &state;
  fml::ScopedCleanupClosure reset_deferred_links(
      []() { deferred_links = nullptr; });
  auto mock_gles =
      MockGLES::Init(std::vector<const char*>{"GL_KHR_parallel_shader_compile"},
                     "OpenGL ES 3.0 (ANGLE 2.1.0)", DeferredLinkResolver);
  auto runner = std::make_shared<DeferredLinkRunner>();
  auto context = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(DeferredLinkResolver),
      std::vector<std::shared_ptr<fml::Mapping>>{},
      /*enable_gpu_tracing=*/false, runner);
  ASSERT_NE(context, nullptr);
  auto worker = std::make_shared<ToggleWorker>(true);
  context->AddReactorWorker(worker);
  auto base_context = std::static_pointer_cast<Context>(context);
  auto shader_library = base_context->GetShaderLibrary();
  for (auto stage : {ShaderStage::kVertex, ShaderStage::kFragment}) {
    shader_library->RegisterFunction(
        "deferred", stage,
        std::make_shared<fml::DataMapping>(std::string("void main() {}")),
        [](bool result) { EXPECT_TRUE(result); });
  }
  PipelineDescriptor desc;
  desc.SetVertexDescriptor(std::make_shared<VertexDescriptor>());
  desc.AddStageEntrypoint(
      shader_library->GetFunction("deferred", ShaderStage::kVertex));
  desc.AddStageEntrypoint(
      shader_library->GetFunction("deferred", ShaderStage::kFragment));
  auto library = base_context->GetPipelineLibrary();
  auto first = library->GetPipeline(desc, true, true);
  desc.SetSampleCount(SampleCount::kCount4);
  auto second = library->GetPipeline(desc, true, true);
  ASSERT_FALSE(runner->tasks.empty());
  runner->RunOne();
  EXPECT_EQ(state.links, 1);
  EXPECT_EQ(state.compile_queries, 0);
  EXPECT_EQ(state.link_queries, 0);
  EXPECT_EQ(first.future.wait_for(std::chrono::seconds(0)),
            std::future_status::timeout);
  EXPECT_EQ(second.future.wait_for(std::chrono::seconds(0)),
            std::future_status::timeout);
  if (abandon_before_check) {
    worker->SetAllowed(false);
    runner->RunAll();
    EXPECT_TRUE(first.future.wait_for(std::chrono::seconds(0)) ==
                    std::future_status::ready ||
                second.future.wait_for(std::chrono::seconds(0)) ==
                    std::future_status::ready);
    worker->SetAllowed(true);
    state.fail_compile = false;
    state.fail_link = false;
    desc.SetSampleCount(SampleCount::kCount1);
    desc.SetColorAttachmentDescriptor(0, ColorAttachmentDescriptor{});
    auto retry = library->GetPipeline(desc, false, true);
    ASSERT_EQ(retry.future.wait_for(std::chrono::seconds(0)),
              std::future_status::ready);
    EXPECT_NE(retry.Get(), nullptr);
    EXPECT_EQ(state.programs, 2);
    return;
  }
  runner->RunAll();
  ASSERT_EQ(first.future.wait_for(std::chrono::seconds(0)),
            std::future_status::ready);
  ASSERT_EQ(second.future.wait_for(std::chrono::seconds(0)),
            std::future_status::ready);
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
    auto retry = library->GetPipeline(desc, true, true);
    runner->RunAll();
    ASSERT_EQ(retry.future.wait_for(std::chrono::seconds(0)),
              std::future_status::ready);
    ASSERT_NE(retry.Get(), nullptr);
    EXPECT_EQ(state.programs, 2);
  }
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

namespace {
class UnstartedShaderFunction final : public ShaderFunction {
 public:
  explicit UnstartedShaderFunction(ShaderStage stage)
      : ShaderFunction(UniqueID{}, "unstarted", stage) {}
};
}  // namespace

TEST(PipelineLibraryGLESDeferredTest,
     ResolvesUnstartedPipelinesWhenTheRunnerDiscardsJobs) {
  auto mock_gles =
      MockGLES::Init(std::vector<const char*>{"GL_KHR_parallel_shader_compile"},
                     "OpenGL ES 3.0 (ANGLE 2.1.0)");
  fml::Thread io_thread;
  auto runner = std::make_shared<fml::ConditionalBasicTaskRunner>(
      io_thread.GetTaskRunner(), []() { return false; });
  auto context = ContextGLES::Create(
      Flags{}, std::make_unique<ProcTableGLES>(kMockResolverGLES),
      std::vector<std::shared_ptr<fml::Mapping>>{},
      /*enable_gpu_tracing=*/false, runner);
  ASSERT_NE(context, nullptr);
  auto context_base = std::static_pointer_cast<Context>(context);
  auto library = context_base->GetPipelineLibrary();
  auto* queue = library->GetPipelineCompileQueue();
  ASSERT_NE(queue, nullptr);
  std::weak_ptr<PipelineCompileQueue> weak_queue = queue->weak_from_this();
  PipelineDescriptor descriptor;
  descriptor.AddStageEntrypoint(
      std::make_shared<UnstartedShaderFunction>(ShaderStage::kVertex));
  descriptor.AddStageEntrypoint(
      std::make_shared<UnstartedShaderFunction>(ShaderStage::kFragment));
  auto future = library->GetPipeline(descriptor, /*async=*/true);
  library.reset();
  context_base.reset();
  context.reset();
  io_thread.Join();

  EXPECT_TRUE(weak_queue.expired());
  const auto status = future.future.wait_for(std::chrono::milliseconds(100));
  EXPECT_EQ(status, std::future_status::ready);
  if (status == std::future_status::ready) {
    EXPECT_EQ(future.Get(), nullptr);
  }
  if (auto leaked_queue = weak_queue.lock()) {
    leaked_queue->PerformJobEagerly(descriptor);
  }
}

}  // namespace

}  // namespace impeller::testing
