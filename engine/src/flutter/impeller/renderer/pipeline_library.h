// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_PIPELINE_LIBRARY_H_
#define FLUTTER_IMPELLER_RENDERER_PIPELINE_LIBRARY_H_

#include <optional>
#include <unordered_map>

#include "compute_pipeline_descriptor.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"

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

 protected:
  PipelineLibrary();

 private:
  PipelineLibrary(const PipelineLibrary&) = delete;

  PipelineLibrary& operator=(const PipelineLibrary&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_PIPELINE_LIBRARY_H_
