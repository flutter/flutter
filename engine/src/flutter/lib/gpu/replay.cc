// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/replay.h"

#include <algorithm>
#include <atomic>
#include <chrono>

#include "dart_api.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "impeller/base/validation.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/sampler_library.h"

namespace flutter {
namespace gpu {

namespace {

// Comfortably more than a heavy frame's recordings, so reaching it means the
// caller is running ahead of the GPU rather than rendering frames.
constexpr size_t kMaxInFlightBytes = 32 * 1024 * 1024;

constexpr std::chrono::seconds kMaxInFlightWait(1);

// The recording keeps the buffer alive until the GPU finishes, so the view
// does not need to own it. Binding through an owning view would cost atomics
// per bind, and on Vulkan a tracked object per bind.
impeller::BufferView Borrow(const impeller::DeviceBuffer* buffer,
                            uint64_t offset,
                            uint64_t length) {
  return impeller::BufferView(buffer, impeller::Range(offset, length));
}

impeller::BufferView Borrow(const impeller::BufferView& view) {
  return impeller::BufferView(view.GetBuffer(), view.GetRange());
}

template <typename T>
const T& As(const OpHeader& header) {
  return static_cast<const T&>(header);
}

// Keeps one entry per binding. Bindings per draw are few, so a linear scan
// beats hashing.
template <typename T>
void SetBinding(std::vector<const T*>& bindings, const T* op) {
  for (const T*& binding : bindings) {
    if (binding->binding == op->binding) {
      binding = op;
      return;
    }
  }
  bindings.push_back(op);
}

}  // namespace

PassReplayer::PassReplayer(impeller::Context& context) : context_(context) {}

impeller::raw_ptr<const impeller::Sampler> PassReplayer::GetSampler(
    uint64_t key) {
  for (const auto& entry : samplers_) {
    if (entry.first == key) {
      return entry.second;
    }
  }
  auto sampler = context_.GetSamplerLibrary()->GetSampler(
      impeller::SamplerDescriptor::FromKey(key));
  samplers_.emplace_back(key, sampler);
  return sampler;
}

void PassReplayer::SetPipelineState(PassRecording& recording,
                                    const SetPipelineStateOp& op) {
  if (pipeline_op_ && pipeline_op_->core == op.core &&
      pipeline_op_->state == op.state) {
    return;
  }
  pipeline_op_ = &op;
  const RenderPipeline::Core::ResolvedPipeline& resolved =
      op.core->Resolve(context_, op.state);
  if (!resolved.pipeline) {
    pipeline_ = impeller::PipelineRef();
    return;
  }
  pipeline_ = impeller::PipelineRef(resolved.pipeline);
  // Backends can read the pipeline until the work completes, and a shader
  // reload can drop it from the core and the library before then.
  recording.Retain(resolved.retain_stamp, resolved.pipeline);
}

void PassReplayer::Draw(impeller::RenderPass& pass, const DrawOp& op) {
  if (!pipeline_) {
    return;
  }
  pass.SetPipeline(pipeline_);

  // Binding sets are replayed first, so an individual bind that collides
  // with a set member overrides it for this draw. A set's compute bindings
  // belong to compute passes.
  for (const BindingSet::Contents* set : sets_) {
    if (!set) {
      continue;
    }
    for (const BindingSet::BufferBinding& buffer : set->buffer_bindings) {
      if (buffer.stage == impeller::ShaderStage::kCompute) {
        continue;
      }
      pass.BindResource(buffer.stage, impeller::DescriptorType::kUniformBuffer,
                        buffer.slot, buffer.metadata, Borrow(buffer.view));
    }
    for (const BindingSet::TextureBinding& texture : set->texture_bindings) {
      if (texture.stage == impeller::ShaderStage::kCompute) {
        continue;
      }
      pass.BindResource(texture.stage, impeller::DescriptorType::kSampledImage,
                        texture.slot, texture.metadata,
                        impeller::BorrowTexture(texture.texture.get()),
                        GetSampler(texture.sampler_key));
    }
  }
  for (const BindUniformOp* uniform : uniforms_) {
    pass.BindResource(
        uniform->stage, impeller::DescriptorType::kUniformBuffer,
        uniform->binding->slot, &uniform->binding->metadata,
        Borrow(uniform->buffer, uniform->offset, uniform->length));
  }
  for (const BindTextureOp* texture : textures_) {
    pass.BindResource(texture->stage, impeller::DescriptorType::kSampledImage,
                      texture->binding->slot, &texture->binding->metadata,
                      impeller::BorrowTexture(texture->texture),
                      GetSampler(texture->sampler_key));
  }

  pass.SetVertexBuffer(vertex_buffers_.data(), vertex_buffer_count_);
  if (op.indexed) {
    pass.SetIndexBuffer(index_buffer_, index_type_);
  } else {
    pass.SetIndexBuffer(impeller::BufferView{}, impeller::IndexType::kNone);
  }
  pass.SetElementCount(op.element_count);
  pass.SetInstanceCount(op.instance_count);
  pass.SetStencilReference(stencil_reference_);
  if (viewport_.has_value()) {
    pass.SetViewport(viewport_.value());
  }
  if (scissor_.has_value()) {
    pass.SetScissor(scissor_.value());
  }
  if (auto status = pass.Draw(); !status.ok()) {
    VALIDATION_LOG << "Failed to encode a recorded draw: " << status.message();
  }
}

void PassReplayer::ReplayRender(PassRecording& recording,
                                impeller::RenderPass& pass) {
  uniforms_.clear();
  textures_.clear();
  sets_.fill(nullptr);
  std::fill_n(vertex_buffers_.begin(), vertex_buffer_count_,
              impeller::BufferView{});
  vertex_buffer_count_ = 0;
  index_buffer_ = {};
  index_type_ = impeller::IndexType::kNone;
  stencil_reference_ = 0;
  scissor_.reset();
  viewport_.reset();
  pipeline_op_ = nullptr;
  pipeline_ = impeller::PipelineRef();

  recording.ops.ForEach([&](const OpHeader& header) {
    switch (header.op) {
      case RecordedOp::kSetPipelineState:
        SetPipelineState(recording, As<SetPipelineStateOp>(header));
        break;
      case RecordedOp::kBindUniform:
        SetBinding(uniforms_, &As<BindUniformOp>(header));
        break;
      case RecordedOp::kBindTexture:
        SetBinding(textures_, &As<BindTextureOp>(header));
        break;
      case RecordedOp::kBindSet: {
        const auto& op = As<BindSetOp>(header);
        sets_[op.slot] = op.contents;
        break;
      }
      case RecordedOp::kClearBindings:
        uniforms_.clear();
        textures_.clear();
        sets_.fill(nullptr);
        std::fill_n(vertex_buffers_.begin(), vertex_buffer_count_,
                    impeller::BufferView{});
        vertex_buffer_count_ = 0;
        index_buffer_ = {};
        index_type_ = impeller::IndexType::kNone;
        break;
      case RecordedOp::kBindVertexBuffer: {
        const auto& op = As<BindVertexBufferOp>(header);
        vertex_buffers_[op.slot] = Borrow(op.buffer, op.offset, op.length);
        vertex_buffer_count_ =
            std::max(vertex_buffer_count_, static_cast<size_t>(op.slot) + 1);
        break;
      }
      case RecordedOp::kBindIndexBuffer: {
        const auto& op = As<BindIndexBufferOp>(header);
        index_buffer_ = Borrow(op.buffer, op.offset, op.length);
        index_type_ = op.type;
        break;
      }
      case RecordedOp::kSetStencilReference:
        stencil_reference_ = As<SetStencilReferenceOp>(header).reference;
        break;
      case RecordedOp::kSetScissor:
        scissor_ = As<SetScissorOp>(header).scissor;
        break;
      case RecordedOp::kSetViewport: {
        const auto& op = As<SetViewportOp>(header);
        impeller::Viewport viewport;
        viewport.rect = op.rect;
        viewport.depth_range.z_near = op.z_near;
        viewport.depth_range.z_far = op.z_far;
        viewport_ = viewport;
        break;
      }
      case RecordedOp::kDraw:
        Draw(pass, As<DrawOp>(header));
        break;
      default:
        FML_UNREACHABLE();
    }
  });
}

bool PassReplayer::ReplayCompute(const PassRecording& recording,
                                 impeller::ComputePass& pass) {
  bool success = true;
  recording.ops.ForEach([&](const OpHeader& header) {
    switch (header.op) {
      case RecordedOp::kSetComputePipeline: {
        // Non-owning for the same reason as `Borrow`.
        pass.SetPipeline(std::shared_ptr<BackendComputePipeline>(
            std::shared_ptr<BackendComputePipeline>(),
            As<SetComputePipelineOp>(header).pipeline));
        break;
      }
      case RecordedOp::kBindComputeBuffer: {
        const auto& op = As<BindComputeBufferOp>(header);
        pass.BindResource(impeller::ShaderStage::kCompute, op.type, *op.slot,
                          op.metadata, Borrow(op.buffer, op.offset, op.length));
        break;
      }
      case RecordedOp::kBindComputeTexture: {
        const auto& op = As<BindComputeTextureOp>(header);
        pass.BindResource(impeller::ShaderStage::kCompute,
                          impeller::DescriptorType::kSampledImage, *op.slot,
                          op.metadata, impeller::BorrowTexture(op.texture),
                          GetSampler(op.sampler_key));
        break;
      }
      case RecordedOp::kDispatch: {
        const auto& op = As<DispatchOp>(header);
        if (auto status =
                pass.Compute({op.workgroup_count[0], op.workgroup_count[1],
                              op.workgroup_count[2]});
            !status.ok()) {
          VALIDATION_LOG << "Failed to encode a recorded dispatch: "
                         << status.message();
          success = false;
        }
        break;
      }
      default:
        FML_UNREACHABLE();
    }
  });
  return success;
}

void PassReplayer::ReplayBlit(const PassRecording& recording,
                              impeller::BlitPass& pass) {
  recording.ops.ForEach([&](const OpHeader& header) {
    bool added = false;
    switch (header.op) {
      case RecordedOp::kCopyBufferToTexture: {
        const auto& op = As<CopyBufferToTextureOp>(header);
        added = pass.AddCopy(
            Borrow(op.source, op.source_offset, op.source_length),
            impeller::BorrowTexture(op.destination), op.destination_region,
            "CommandBuffer.copyBufferToTexture", op.mip_level, op.slice);
        break;
      }
      case RecordedOp::kCopyTextureToBuffer: {
        const auto& op = As<CopyTextureToBufferOp>(header);
        added = pass.AddCopy(
            impeller::BorrowTexture(op.source),
            std::shared_ptr<impeller::DeviceBuffer>(
                std::shared_ptr<impeller::DeviceBuffer>(), op.destination),
            op.source_region, op.destination_offset,
            "CommandBuffer.copyTextureToBuffer");
        break;
      }
      case RecordedOp::kCopyTextureToTexture: {
        const auto& op = As<CopyTextureToTextureOp>(header);
        added = pass.AddCopy(impeller::BorrowTexture(op.source),
                             impeller::BorrowTexture(op.destination),
                             op.source_region, op.destination_origin,
                             "CommandBuffer.copyTextureToTexture");
        break;
      }
      default:
        FML_UNREACHABLE();
    }
    if (!added) {
      VALIDATION_LOG << "Dropped a recorded blit the backend refused.";
    }
  });
}

fml::RefPtr<fml::TaskRunner> ReplayQueue::GetCurrentTaskRunner() {
  if (Dart_CurrentIsolate() == nullptr) {
    return nullptr;
  }
  auto* dart_state = flutter::UIDartState::Current();
  if (!dart_state) {
    return nullptr;
  }
  return dart_state->GetTaskRunners().GetRasterTaskRunner();
}

ReplayQueue::ReplayQueue(std::shared_ptr<impeller::Context> context,
                         fml::RefPtr<fml::TaskRunner> task_runner)
    : context_(std::move(context)),
      task_runner_(std::move(task_runner)),
      replayer_(*context_) {}

ReplayQueue::~ReplayQueue() = default;

void ReplayQueue::Post(const fml::closure& task) {
  if (!task_runner_) {
    task();
    return;
  }
  // Always posted, even when this thread is the replay thread (the raster
  // and platform threads can merge), so that work stays in order.
  task_runner_->PostTask(task);
}

void ReplayQueue::AddInFlightBytes(size_t bytes) {
  // Merged threads can't make progress while this one waits.
  const bool can_wait =
      task_runner_ && !task_runner_->RunsTasksOnCurrentThread();
  std::unique_lock lock(in_flight_mutex_);
  if (can_wait) {
    in_flight_changed_.wait_for(lock, kMaxInFlightWait, [this]() {
      return in_flight_bytes_ <= kMaxInFlightBytes;
    });
  }
  in_flight_bytes_ += bytes;
}

void ReplayQueue::RemoveInFlightBytes(size_t bytes) {
  {
    std::scoped_lock lock(in_flight_mutex_);
    in_flight_bytes_ -= bytes;
  }
  in_flight_changed_.notify_all();
}

CommandBufferEncoder::CommandBufferEncoder(std::shared_ptr<ReplayQueue> queue)
    : queue_(std::move(queue)) {}

CommandBufferEncoder::~CommandBufferEncoder() {
  // Recycled before the queue hears that the memory is free.
  recordings_.clear();
  if (in_flight_bytes_ > 0) {
    queue_->RemoveInFlightBytes(in_flight_bytes_);
  }
}

bool CommandBufferEncoder::DeferredPass::EncodeCommands() const {
  return render_pass ? render_pass->EncodeCommands()
                     : blit_pass->EncodeCommands();
}

bool CommandBufferEncoder::DefersEncoding() const {
  return queue_->GetContext()->GetBackendType() ==
         impeller::Context::BackendType::kOpenGLES;
}

bool CommandBufferEncoder::EnsureCommandBuffer() {
  if (!command_buffer_ && !failed_) {
    command_buffer_ = queue_->GetContext()->CreateCommandBuffer();
    failed_ = !command_buffer_;
  }
  return !failed_;
}

void CommandBufferEncoder::Encode(PassRecording::Ptr recording) {
  TRACE_EVENT0("flutter", "FlutterGPU::EncodePass");
  if (EnsureCommandBuffer()) {
    switch (recording->GetKind()) {
      case PassRecording::Kind::kRender:
        EncodeRenderPass(*recording);
        break;
      case PassRecording::Kind::kCompute:
        EncodeComputePass(*recording);
        break;
      case PassRecording::Kind::kBlit:
        EncodeBlitPass(*recording);
        break;
    }
  }
  recordings_.push_back(std::move(recording));
}

void CommandBufferEncoder::EncodeRenderPass(PassRecording& recording) {
  auto pass = command_buffer_->CreateRenderPass(recording.render_target);
  if (!pass) {
    VALIDATION_LOG << "Failed to create a recorded render pass.";
    failed_ = true;
    return;
  }
  pass->ReserveCommands(recording.draw_count, recording.uniform_bind_count,
                        recording.texture_bind_count,
                        recording.vertex_buffer_bind_count);
  queue_->GetReplayer().ReplayRender(recording, *pass);
  if (DefersEncoding()) {
    deferred_passes_.push_back({.render_pass = std::move(pass)});
  } else if (!pass->EncodeCommands()) {
    failed_ = true;
  }
}

void CommandBufferEncoder::EncodeComputePass(const PassRecording& recording) {
  auto pass = command_buffer_->CreateComputePass();
  if (!pass) {
    VALIDATION_LOG << "Failed to create a recorded compute pass.";
    failed_ = true;
    return;
  }
  if (!queue_->GetReplayer().ReplayCompute(recording, *pass) ||
      !pass->EncodeCommands()) {
    failed_ = true;
  }
}

void CommandBufferEncoder::EncodeBlitPass(const PassRecording& recording) {
  auto pass = command_buffer_->CreateBlitPass();
  if (!pass) {
    VALIDATION_LOG << "Failed to create a recorded blit pass.";
    failed_ = true;
    return;
  }
  queue_->GetReplayer().ReplayBlit(recording, *pass);
  if (DefersEncoding()) {
    deferred_passes_.push_back({.blit_pass = std::move(pass)});
  } else if (!pass->EncodeCommands()) {
    failed_ = true;
  }
}

bool CommandBufferEncoder::Submit(
    std::shared_ptr<CommandBufferEncoder> encoder,
    impeller::CommandBuffer::CompletionCallback completion,
    size_t in_flight_bytes) {
  TRACE_EVENT0("flutter", "FlutterGPU::Submit");
  encoder->in_flight_bytes_ = in_flight_bytes;
  const std::shared_ptr<impeller::Context> context =
      encoder->queue_->GetContext();

  // Backends report kError themselves for some failed submissions, so the
  // completion runs at most once however the submission fails.
  auto completed = std::make_shared<std::atomic<bool>>(false);
  impeller::CommandBuffer::CompletionCallback complete =
      [completed, completion = std::move(completion)](
          impeller::CommandBuffer::Status status) {
        if (completion && !completed->exchange(true)) {
          completion(status);
        }
      };

  bool failed = !encoder->EnsureCommandBuffer();
  bool encoded_deferred_pass = false;
  if (!failed) {
    for (const DeferredPass& pass : encoder->deferred_passes_) {
      if (!pass.EncodeCommands()) {
        encoder->failed_ = true;
        break;
      }
      encoded_deferred_pass = true;
    }
  }
  encoder->deferred_passes_.clear();
  failed = failed || encoder->failed_;

  // A pass handed to the reactor points into the recordings, so even a failed
  // command buffer has to go through the queue, which outlasts the reactor's
  // work, before they can be recycled.
  if (failed && !encoded_deferred_pass) {
    complete(impeller::CommandBuffer::Status::kError);
    context->DisposeThreadLocalCachedResources();
    return false;
  }

  // Dropped here so that the Impeller command buffer never outlives this
  // thread's use of it. The recordings go with the completion.
  std::shared_ptr<impeller::CommandBuffer> command_buffer =
      std::move(encoder->command_buffer_);
  auto status = context->GetCommandQueue()->Submit(
      {command_buffer}, [encoder = std::move(encoder), complete,
                         failed](impeller::CommandBuffer::Status status) {
        complete(failed ? impeller::CommandBuffer::Status::kError : status);
      });
  if (!status.ok()) {
    complete(impeller::CommandBuffer::Status::kError);
  }
  context->DisposeThreadLocalCachedResources();
  return status.ok() && !failed;
}

}  // namespace gpu
}  // namespace flutter
