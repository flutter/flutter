// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_LIBRARY_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_LIBRARY_GLES_H_

#include <unordered_map>
#include <vector>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/task_runner.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"
#include "impeller/renderer/backend/gles/reactor_gles.h"
#include "impeller/renderer/backend/gles/unique_handle_gles.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/shader_function.h"
#include "third_party/abseil-cpp/absl/status/status.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

namespace impeller {

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

  std::shared_ptr<ReactorGLES> reactor_;
  PipelineMap pipelines_;
  Mutex programs_mutex_;
  ProgramMap programs_ IPLR_GUARDED_BY(programs_mutex_);
  std::shared_ptr<PipelineCompileQueueGLES> compile_queue_;

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
  /// @brief      A program object whose shaders are compiled and linked in two
  ///             steps: `Compile` issues the work, and `Wait` checks whether
  ///             linking succeeded. Separating the two allows drivers that
  ///             compile asynchronously to make progress in between.
  ///
  ///             All methods, including the destructor, must be called on the
  ///             reactor.
  ///
  class PendingProgram {
   public:
    PendingProgram(std::shared_ptr<ReactorGLES> reactor,
                   PipelineDescriptor desc,
                   std::shared_ptr<const ShaderFunction> vert_function,
                   std::shared_ptr<const ShaderFunction> frag_function,
                   bool threadsafe);

    ~PendingProgram();

    PendingProgram(const PendingProgram&) = delete;

    PendingProgram& operator=(const PendingProgram&) = delete;

    //--------------------------------------------------------------------------
    /// @brief      Creates the program object, creates and compiles the
    ///             shaders, attaches them to the program, and requests that the
    ///             program be linked.
    ///
    /// @return     An error if the program or shaders could not be created or
    ///             the shaders could not be compiled.
    ///
    absl::Status Compile();

    //--------------------------------------------------------------------------
    /// @brief      Checks the result of linking the program and releases the
    ///             shaders. Must only be called after `Compile` succeeds.
    ///
    /// @return     The linked program object, or an error if the program
    ///             failed to link.
    ///
    absl::StatusOr<std::shared_ptr<UniqueHandleGLES>> Wait();

   private:
    absl::Status CompileShaders();

    absl::Status CheckLinkStatus() const;

    void ReleaseShaders();

    std::shared_ptr<ReactorGLES> reactor_;
    PipelineDescriptor desc_;
    std::shared_ptr<const ShaderFunction> vert_function_;
    std::shared_ptr<const ShaderFunction> frag_function_;
    bool threadsafe_ = false;
    std::shared_ptr<UniqueHandleGLES> handle_;
    GLuint program_ = 0;
    GLuint vert_shader_ = 0;
    GLuint frag_shader_ = 0;
    bool shaders_attached_ = false;
    bool link_pending_ = false;
  };

  //----------------------------------------------------------------------------
  /// @brief      Creates a pipeline for the descriptor that uses the given,
  ///             already linked, program. Must be called on the reactor.
  ///
  /// @return     The pipeline, or nullptr on failure.
  ///
  static std::shared_ptr<PipelineGLES> CreatePipeline(
      const std::weak_ptr<PipelineLibrary>& weak_library,
      const std::shared_ptr<ReactorGLES>& reactor,
      const PipelineDescriptor& desc,
      std::shared_ptr<UniqueHandleGLES> program_handle);

  std::shared_ptr<UniqueHandleGLES> GetCachedProgram(const ProgramKey& key);

  void CacheProgram(const ProgramKey& key,
                    std::shared_ptr<UniqueHandleGLES> program);

  // |PipelineLibrary|
  void PerformEagerly(const PipelineDescriptor& descriptor) override;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_LIBRARY_GLES_H_
