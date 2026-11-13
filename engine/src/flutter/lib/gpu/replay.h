// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_GPU_REPLAY_H_
#define FLUTTER_LIB_GPU_REPLAY_H_

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/gpu/recording.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/raw_ptr.h"
#include "impeller/core/sampler.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/compute_pass.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/render_pass.h"

namespace flutter {
namespace gpu {

/// Replays recordings into Impeller passes.
///
/// Every method must run on the replay thread.
class PassReplayer {
 public:
  explicit PassReplayer(impeller::Context& context);

  /// Replays a render pass. Draws whose pipeline fails to build are dropped.
  void ReplayRender(PassRecording& recording, impeller::RenderPass& pass);

  /// Replays a compute pass. Returns false if the backend rejected a dispatch.
  bool ReplayCompute(const PassRecording& recording,
                     impeller::ComputePass& pass);

  /// Replays copies. Copies the backend refuses are dropped.
  void ReplayBlit(const PassRecording& recording, impeller::BlitPass& pass);

 private:
  static constexpr size_t kMaxBindingSets = 4;
  static constexpr size_t kMaxVertexBufferSlots = 16;

  impeller::raw_ptr<const impeller::Sampler> GetSampler(uint64_t key);

  void SetPipelineState(PassRecording& recording, const SetPipelineStateOp& op);

  void Draw(impeller::RenderPass& pass, const DrawOp& op);

  impeller::Context& context_;

  // The state bound at the current point in the pass. The ops are stable in
  // the recording, so these point at them rather than copying.
  std::vector<const BindUniformOp*> uniforms_;
  std::vector<const BindTextureOp*> textures_;
  std::array<const BindingSet::Contents*, kMaxBindingSets> sets_ = {};
  std::array<impeller::BufferView, kMaxVertexBufferSlots> vertex_buffers_;
  size_t vertex_buffer_count_ = 0;
  impeller::BufferView index_buffer_;
  impeller::IndexType index_type_ = impeller::IndexType::kNone;
  uint32_t stencil_reference_ = 0;
  std::optional<impeller::IRect32> scissor_;
  std::optional<impeller::Viewport> viewport_;
  const SetPipelineStateOp* pipeline_op_ = nullptr;
  impeller::PipelineRef pipeline_;

  FML_DISALLOW_COPY_AND_ASSIGN(PassReplayer);
};

/// The thread Flutter GPU work is encoded on, which is the raster thread, so
/// that Impeller's raster-owned state is only ever touched there.
///
/// Work runs in the order it was posted. Nothing here is tied to the raster
/// thread other than the task runner it was given, and without one work runs
/// on the calling thread.
class ReplayQueue {
 public:
  /// The raster task runner of the current isolate, or null when there is none
  /// (unit tests).
  static fml::RefPtr<fml::TaskRunner> GetCurrentTaskRunner();

  ReplayQueue(std::shared_ptr<impeller::Context> context,
              fml::RefPtr<fml::TaskRunner> task_runner);

  ~ReplayQueue();

  const std::shared_ptr<impeller::Context>& GetContext() const {
    return context_;
  }

  /// Runs [task] on the replay thread, after everything posted before it.
  void Post(const fml::closure& task);

  /// Whether `Post` runs tasks before returning.
  bool RunsOnCallingThread() const { return !task_runner_; }

  /// The replayer, for use on the replay thread.
  PassReplayer& GetReplayer() { return replayer_; }

 private:
  const std::shared_ptr<impeller::Context> context_;
  const fml::RefPtr<fml::TaskRunner> task_runner_;
  PassReplayer replayer_;

  FML_DISALLOW_COPY_AND_ASSIGN(ReplayQueue);
};

/// The Impeller command buffer a Flutter GPU command buffer encodes into.
///
/// Created on the recording thread and used on the replay thread. Dropping
/// the last reference, which happens once the GPU finishes, frees the
/// recordings. Everything they point at stays alive until then, which is why
/// replay can hand Impeller non-owning references.
class CommandBufferEncoder {
 public:
  explicit CommandBufferEncoder(std::shared_ptr<ReplayQueue> queue);

  ~CommandBufferEncoder();

  /// Encodes a finished pass.
  void Encode(PassRecording::Ptr recording);

  /// Encodes anything deferred and submits. [completion] runs when the work
  /// finishes, with `kError` if anything failed. Returns whether the work was
  /// submitted.
  static bool Submit(std::shared_ptr<CommandBufferEncoder> encoder,
                     impeller::CommandBuffer::CompletionCallback completion);

 private:
  /// A pass that OpenGL ES encodes at submit. Encoding hands the reactor raw
  /// pointers into the recordings, which are only guaranteed to last for a
  /// submitted command buffer.
  struct DeferredPass {
    std::shared_ptr<impeller::RenderPass> render_pass;
    std::shared_ptr<impeller::BlitPass> blit_pass;

    bool EncodeCommands() const;
  };

  bool EnsureCommandBuffer();

  void EncodeRenderPass(PassRecording& recording);

  void EncodeComputePass(const PassRecording& recording);

  void EncodeBlitPass(const PassRecording& recording);

  bool DefersEncoding() const;

  const std::shared_ptr<ReplayQueue> queue_;
  std::shared_ptr<impeller::CommandBuffer> command_buffer_;
  std::vector<DeferredPass> deferred_passes_;
  std::vector<PassRecording::Ptr> recordings_;
  bool failed_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(CommandBufferEncoder);
};

}  // namespace gpu
}  // namespace flutter

#endif  // FLUTTER_LIB_GPU_REPLAY_H_
