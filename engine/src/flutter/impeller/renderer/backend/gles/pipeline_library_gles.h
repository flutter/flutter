// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_LIBRARY_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_LIBRARY_GLES_H_

#include <future>
#include <memory>
#include <unordered_map>
#include <vector>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/unique_handle_gles.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/shader_function.h"

namespace impeller {

namespace testing {
FML_TEST_CLASS(PipelineLibraryGLESDeferredTest,
               FailsPendingPipelinesWhenTheReactorCannotReact);
}  // namespace testing

class ContextGLES;
class PipelineGLES;

class PipelineLibraryGLES final
    : public PipelineLibrary,
      public BackendCast<PipelineLibraryGLES, PipelineLibrary> {
 public:
  // |PipelineLibrary|
  ~PipelineLibraryGLES() override;

  PipelineLibraryGLES(const PipelineLibraryGLES&) = delete;

  PipelineLibraryGLES& operator=(const PipelineLibraryGLES&) = delete;

 private:
  friend ContextGLES;
  FML_FRIEND_TEST(testing::PipelineLibraryGLESDeferredTest,
                  FailsPendingPipelinesWhenTheReactorCannotReact);

  //----------------------------------------------------------------------------
  /// @brief      A subset of the items in a pipeline descriptor (and the items
  ///             they reference in shader libraries) whose dynamism requires a
  ///             program object re-compilation and link. In all other cases,
  ///             creating a pipeline variant reuses an existing (compatible)
  ///             program object.
  ///
  struct ProgramKey {
    std::shared_ptr<const ShaderFunction> vertex_shader;
    std::shared_ptr<const ShaderFunction> fragment_shader;
    //--------------------------------------------------------------------------
    /// Specialization constants used in the shaders affect defines used when
    /// compiling and linking the program.
    ///
    std::vector<Scalar> specialization_constants;

    ProgramKey(std::shared_ptr<const ShaderFunction> p_vertex_shader,
               std::shared_ptr<const ShaderFunction> p_fragment_shader,
               std::vector<Scalar> p_specialization_constants)
        : vertex_shader(std::move(p_vertex_shader)),
          fragment_shader(std::move(p_fragment_shader)),
          specialization_constants(std::move(p_specialization_constants)) {}

    struct Hash {
      std::size_t operator()(const ProgramKey& key) const {
        auto seed = fml::HashCombine();
        if (key.vertex_shader) {
          fml::HashCombineSeed(seed, key.vertex_shader->GetHash());
        }
        if (key.fragment_shader) {
          fml::HashCombineSeed(seed, key.fragment_shader->GetHash());
        }
        for (const auto& constant : key.specialization_constants) {
          fml::HashCombineSeed(seed, constant);
        }
        return seed;
      }
    };

    struct Equal {
      bool operator()(const ProgramKey& lhs, const ProgramKey& rhs) const {
        return DeepComparePointer(lhs.vertex_shader, rhs.vertex_shader) &&
               DeepComparePointer(lhs.fragment_shader, rhs.fragment_shader) &&
               lhs.specialization_constants == rhs.specialization_constants;
      }
    };
  };

  using ProgramMap = std::unordered_map<ProgramKey,
                                        std::shared_ptr<UniqueHandleGLES>,
                                        ProgramKey::Hash,
                                        ProgramKey::Equal>;

  using PipelinePromise =
      std::promise<std::shared_ptr<Pipeline<PipelineDescriptor>>>;

  //----------------------------------------------------------------------------
  /// @brief      Holds a pipeline whose program link was started with
  ///             GL_KHR_parallel_shader_compile and not checked yet.
  ///
  struct PendingPipeline {
    std::shared_ptr<PipelineGLES> pipeline;
    std::shared_ptr<PipelinePromise> promise;
    ProgramKey program_key;
    /// The shaders are 0 if the pipeline reuses a program that another
    /// pipeline is linking.
    GLuint vert_shader = 0;
    GLuint frag_shader = 0;
  };

  std::shared_ptr<ReactorGLES> reactor_;
  PipelineMap pipelines_;
  Mutex programs_mutex_;
  ProgramMap programs_ IPLR_GUARDED_BY(programs_mutex_);
  std::shared_ptr<PipelineCompileQueueGLES> compile_queue_;
  const bool supports_parallel_shader_compile_;
  const size_t max_pending_links_;
  Mutex pending_mutex_;
  std::vector<PendingPipeline> pending_pipelines_
      IPLR_GUARDED_BY(pending_mutex_);
  bool is_watching_queue_ IPLR_GUARDED_BY(pending_mutex_) = false;

  explicit PipelineLibraryGLES(
      std::shared_ptr<ReactorGLES> reactor,
      std::shared_ptr<fml::BasicTaskRunner> io_task_runner);

  // |PipelineLibrary|
  bool IsValid() const override;

  // |PipelineLibrary|
  PipelineFuture<PipelineDescriptor> GetPipeline(PipelineDescriptor descriptor,
                                                 bool async,
                                                 bool threadsafe) override;

  // |PipelineLibrary|
  PipelineFuture<ComputePipelineDescriptor> GetPipeline(
      ComputePipelineDescriptor descriptor,
      bool async) override;

  // |PipelineLibrary|
  bool HasPipeline(const PipelineDescriptor& descriptor) override;

  // |PipelineLibrary|
  void RemovePipelinesWithEntryPoint(
      std::shared_ptr<const ShaderFunction> function) override;

  const std::shared_ptr<ReactorGLES>& GetReactor() const;

  //----------------------------------------------------------------------------
  /// @brief      Creates a pipeline and links its program.
  ///
  ///             With a deferred_promise, this starts the link and returns
  ///             before it finishes. FinishPendingPipelines checks the link
  ///             later and sets deferred_promise. That requires
  ///             GL_KHR_parallel_shader_compile and a thread that runs a
  ///             PipelineCompileQueueGLES job.
  ///
  static std::shared_ptr<PipelineGLES> CreatePipeline(
      const std::weak_ptr<PipelineLibrary>& weak_library,
      const PipelineDescriptor& desc,
      const std::shared_ptr<const ShaderFunction>& vert_shader,
      const std::shared_ptr<const ShaderFunction>& frag_shader,
      bool threadsafe,
      std::shared_ptr<PipelinePromise> deferred_promise = nullptr);

  //----------------------------------------------------------------------------
  /// @brief      Checks the link of every pending pipeline and sets its
  ///             promise. A status query here waits for the link.
  ///
  void FinishPendingPipelines(const ReactorGLES& reactor);

  /// Sets the promise of every pending pipeline to null, so nothing waits for
  /// a link that no thread will check, and removes the programs those
  /// pipelines started from the cache.
  void FailPendingPipelines();

  std::shared_ptr<PipelineGLES> FinishPipeline(const ReactorGLES& reactor,
                                               const PendingPipeline& item);

  //----------------------------------------------------------------------------
  /// @brief      Asks the compile queue to report when it runs out of jobs,
  ///             which is when the pending links are checked.
  ///
  void WatchQueueForDrain();

  bool SupportsParallelShaderCompile() const;

  std::shared_ptr<UniqueHandleGLES> GetProgramForKey(const ProgramKey& key);

  void SetProgramForKey(const ProgramKey& key,
                        std::shared_ptr<UniqueHandleGLES> program);

  /// Removes the entry for key only if it still holds program.
  void RemoveProgramForKey(const ProgramKey& key,
                           const std::shared_ptr<UniqueHandleGLES>& program);
  // |PipelineLibrary|
  PipelineCompileQueue* GetPipelineCompileQueue() const override;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_LIBRARY_GLES_H_
