// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_PIPELINE_LIBRARY_H_
#define FLUTTER_IMPELLER_RENDERER_PIPELINE_LIBRARY_H_

#include <optional>
#include <unordered_map>

#include "compute_pipeline_descriptor.h"
#include "impeller/base/thread.h"
#include "impeller/base/thread_safety.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_map.h"

namespace impeller {

class Context;

using PipelineMap = std::unordered_map<PipelineDescriptor,
                                       PipelineFuture<PipelineDescriptor>,
                                       ComparableHash<PipelineDescriptor>,
                                       ComparableEqual<PipelineDescriptor>>;

using ComputePipelineMap =
    std::unordered_map<ComputePipelineDescriptor,
                       PipelineFuture<ComputePipelineDescriptor>,
                       ComparableHash<ComputePipelineDescriptor>,
                       ComparableEqual<ComputePipelineDescriptor>>;

//------------------------------------------------------------------------------
/// @brief      How a pipeline was used, as recorded by a `PipelineLibrary` in
///             debug and profile builds.
///
struct PipelineUsage {
  /// The number of times the pipeline was bound in a render pass.
  int count = 0;
  /// Whether the pipeline was created eagerly (warmed up), before it was first
  /// needed. See `PipelineLibrary::LogPipelineCreation`.
  bool eagerly_created = false;
};

using PipelineUsageMap =
    absl::flat_hash_map<PipelineDescriptor,
                        PipelineUsage,
                        ComparableHash<PipelineDescriptor>,
                        ComparableEqual<PipelineDescriptor>>;

class PipelineLibrary : public std::enable_shared_from_this<PipelineLibrary> {
 public:
  virtual ~PipelineLibrary();

  PipelineFuture<PipelineDescriptor> GetPipeline(
      std::optional<PipelineDescriptor> descriptor,
      bool async = true);

  PipelineFuture<ComputePipelineDescriptor> GetPipeline(
      std::optional<ComputePipelineDescriptor> descriptor,
      bool async = true);

  virtual bool IsValid() const = 0;

  //------------------------------------------------------------------------------
  /// @brief      Creates a pipeline.
  ///
  /// @param[in]  descriptor  The descriptor of the texture to create.
  /// @param[in]  async       Whether to allow pipeline creation to be deferred.
  ///                         If `false`, pipeline creation will block on the
  ///                         current thread.
  ///
  /// @param[in]  threadsafe  Whether mutations to this texture should be
  ///                         protected with a threadsafe barrier.
  ///
  ///                         This parameter only affects the OpenGLES rendering
  ///                         backend.
  ///
  ///                         If any interaction with this texture (including
  ///                         creation) will be done on a thread other than
  ///                         where the OpenGLES context resides, then
  ///                         `threadsafe`, must be set to `true`.
  ///
  virtual PipelineFuture<PipelineDescriptor> GetPipeline(
      PipelineDescriptor descriptor,
      bool async = true,
      bool threadsafe = false) = 0;

  virtual PipelineFuture<ComputePipelineDescriptor> GetPipeline(
      ComputePipelineDescriptor descriptor,
      bool async = true) = 0;

  virtual bool HasPipeline(const PipelineDescriptor& descriptor) = 0;

  virtual void RemovePipelinesWithEntryPoint(
      std::shared_ptr<const ShaderFunction> function) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Records that the pipeline for the descriptor was bound in a
  ///             render pass. Only recorded in debug and profile builds.
  ///
  void LogPipelineUsage(const PipelineDescriptor& p);

  //----------------------------------------------------------------------------
  /// @brief      Records that the pipeline for the descriptor was created
  ///             eagerly (warmed up), before it was first needed. The pipeline
  ///             is reported by `GetPipelineUsage` even if it is never bound.
  ///             Only recorded in debug and profile builds.
  ///
  void LogPipelineCreation(const PipelineDescriptor& p);

  //----------------------------------------------------------------------------
  /// @brief      A snapshot of the usage of every pipeline that was either
  ///             created eagerly or bound. Always empty in release builds.
  ///
  PipelineUsageMap GetPipelineUsage() const;

  //----------------------------------------------------------------------------
  /// @brief      If creation of the pipeline for the descriptor is still
  ///             pending, perform it eagerly on the calling thread. This can be
  ///             used in lieu of an idle wait for the pipeline on the calling
  ///             thread.
  ///
  /// @param[in]  descriptor  The descriptor of the pipeline.
  ///
  virtual void PerformEagerly(const PipelineDescriptor& descriptor);

 protected:
  PipelineLibrary();

 private:
  PipelineLibrary(const PipelineLibrary&) = delete;

  PipelineLibrary& operator=(const PipelineLibrary&) = delete;
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  mutable RWMutex pipeline_usage_mutex_;

  PipelineUsageMap pipeline_usage_ IPLR_GUARDED_BY(pipeline_usage_mutex_);

#endif
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_PIPELINE_LIBRARY_H_
