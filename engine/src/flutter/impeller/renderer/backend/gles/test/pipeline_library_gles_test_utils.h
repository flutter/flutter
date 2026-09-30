// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEST_PIPELINE_LIBRARY_GLES_TEST_UTILS_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEST_PIPELINE_LIBRARY_GLES_TEST_UTILS_H_

#include <atomic>
#include <deque>
#include <memory>
#include <unordered_map>

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/shader_function.h"

namespace impeller::testing {

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

struct DeferredLinkRunner final : public fml::BasicTaskRunner {
  void PostTask(const fml::closure& task) override { tasks.push_back(task); }
  void RunOne() {
    fml::closure task = std::move(tasks.front());
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
  int completion_queries = 0;
  int detached = 0;
  int deleted_shaders = 0;
  bool fail_compile = false;
  bool fail_link = false;
  bool completion_supported = true;
  std::unordered_map<GLuint, bool> shaders;
  std::unordered_map<GLuint, bool> linked;
  std::unordered_map<GLuint, bool> completed;
};

/// Holds a MockGLES context with an ANGLE version and
/// GL_KHR_parallel_shader_compile, so async requests take the deferred path.
/// Jobs run only in RunOne or RunAll, so a test can check state between 2 jobs.
struct DeferredLinkHarness {
  DeferredLinkState state;
  fml::ScopedCleanupClosure reset_deferred_links;
  std::shared_ptr<MockGLES> mock_gles;
  std::shared_ptr<DeferredLinkRunner> runner;
  std::shared_ptr<ContextGLES> context;
  std::shared_ptr<ToggleWorker> worker;
  std::shared_ptr<PipelineLibrary> library;
  PipelineDescriptor desc;
  explicit DeferredLinkHarness(size_t max_pending_links);
};

bool IsReady(const PipelineFuture<PipelineDescriptor>& future);

class UnstartedShaderFunction final : public ShaderFunction {
 public:
  explicit UnstartedShaderFunction(ShaderStage stage)
      : ShaderFunction(UniqueID{}, "unstarted", stage) {}
};

}  // namespace impeller::testing

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_TEST_PIPELINE_LIBRARY_GLES_TEST_UTILS_H_
