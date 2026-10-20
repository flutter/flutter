// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/recording.h"

#include <array>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <optional>

#include "dart_api.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "impeller/base/validation.h"
#include "impeller/core/raw_ptr.h"
#include "impeller/core/sampler.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_queue.h"
#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace flutter {
namespace gpu {

void RenderPassRecording::RetainReflection(
    const std::shared_ptr<const Shader::Reflection>& reflection) {
  for (const auto& retained : reflections) {
    if (retained == reflection) {
      return;
    }
  }
  reflections.push_back(reflection);
}

namespace {

constexpr size_t kMaxBindingSets = 4;
constexpr size_t kMaxVertexBufferSlots = 16;

// Bindings per draw are few, so a linear scan beats hashing.
template <typename K, typename V>
class FlatMap {
 public:
  void Set(K key, V value) {
    for (auto& entry : entries_) {
      if (entry.first == key) {
        entry.second = std::move(value);
        return;
      }
    }
    entries_.emplace_back(key, std::move(value));
  }

  void Clear() { entries_.clear(); }

  typename std::vector<std::pair<K, V>>::const_iterator begin() const {
    return entries_.begin();
  }

  typename std::vector<std::pair<K, V>>::const_iterator end() const {
    return entries_.end();
  }

 private:
  std::vector<std::pair<K, V>> entries_;
};

// Memoizes sampler lookups for one replay, since a frame uses a handful of
// distinct samplers across thousands of binds.
class SamplerCache {
 public:
  explicit SamplerCache(impeller::Context& context) : context_(context) {}

  impeller::raw_ptr<const impeller::Sampler> Get(
      const impeller::SamplerDescriptor& descriptor) {
    const uint64_t key = impeller::SamplerDescriptor::ToKey(descriptor);
    for (const auto& entry : entries_) {
      if (entry.first == key) {
        return entry.second;
      }
    }
    auto sampler = context_.GetSamplerLibrary()->GetSampler(descriptor);
    entries_.emplace_back(key, sampler);
    return sampler;
  }

 private:
  impeller::Context& context_;
  std::vector<std::pair<uint64_t, impeller::raw_ptr<const impeller::Sampler>>>
      entries_;
};

// Per-second replay totals, logged to stderr when FLUTTER_GPU_REPLAY_STATS
// is set. Timestamps are wall-clock microseconds so they line up with
// app-side logs.
// TODO(gpu-raster-timeline): Prototype instrumentation. Replace with trace
// events before upstreaming.
class ReplayStats {
 public:
  static void Record(int64_t replay_micros, size_t draws, size_t failed) {
    static const bool enabled = std::getenv("FLUTTER_GPU_REPLAY_STATS");
    if (!enabled) {
      return;
    }
    static std::mutex mutex;
    static ReplayStats stats;
    std::scoped_lock lock(mutex);
    stats.Add(replay_micros, draws, failed);
  }

 private:
  int64_t window_start_us_ = 0;
  size_t submits_ = 0;
  size_t draws_ = 0;
  size_t failed_ = 0;
  int64_t replay_us_ = 0;
  int64_t replay_max_us_ = 0;

  static int64_t WallMicros() {
    return std::chrono::duration_cast<std::chrono::microseconds>(
               std::chrono::system_clock::now().time_since_epoch())
        .count();
  }

  void Add(int64_t replay_micros, size_t draws, size_t failed) {
    const int64_t now = WallMicros();
    if (window_start_us_ == 0) {
      window_start_us_ = now;
    }
    submits_++;
    draws_ += draws;
    failed_ += failed;
    replay_us_ += replay_micros;
    replay_max_us_ = std::max(replay_max_us_, replay_micros);
    if (now - window_start_us_ < 1000000) {
      return;
    }
    std::fprintf(stderr,
                 "FGPU_REPLAY {\"start_us\":%lld,\"end_us\":%lld,"
                 "\"submits\":%zu,\"draws\":%zu,\"failed\":%zu,"
                 "\"replay_ms\":%.3f,\"replay_max_ms\":%.3f}\n",
                 static_cast<long long>(window_start_us_),
                 static_cast<long long>(now), submits_, draws_, failed_,
                 replay_us_ / 1000.0, replay_max_us_ / 1000.0);
    std::fflush(stderr);
    *this = ReplayStats{};
  }
};

class PassReplayer {
 public:
  PassReplayer(impeller::Context& context,
               const RenderPassRecording& recording,
               impeller::RenderPass& pass,
               SamplerCache& samplers)
      : context_(context),
        recording_(recording),
        pass_(pass),
        samplers_(samplers),
        pipelines_(recording.pipeline_states.size()),
        resolved_(recording.pipeline_states.size(), false) {}

  /// The pipelines resolved during replay. Commands may reference them by
  /// raw pointer until the work completes, and a shader reload can evict
  /// them from the library before then.
  std::vector<std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>>
  TakePipelines() {
    return std::move(pipelines_);
  }

  void Run(size_t& draws, size_t& failed) {
    for (const auto& [op, index] : recording_.ops) {
      switch (op) {
        case RecordedOp::kBindUniform: {
          const auto& bind = recording_.uniforms[index];
          (bind.stage == impeller::ShaderStage::kVertex ? vertex_uniforms_
                                                        : fragment_uniforms_)
              .Set(bind.binding, &bind);
          break;
        }
        case RecordedOp::kBindTexture: {
          const auto& bind = recording_.textures[index];
          (bind.stage == impeller::ShaderStage::kVertex ? vertex_textures_
                                                        : fragment_textures_)
              .Set(bind.binding,
                   BoundTexture{&bind, samplers_.Get(bind.sampler)});
          break;
        }
        case RecordedOp::kBindSet: {
          const auto& bind = recording_.sets[index];
          sets_[bind.slot] = bind.contents.get();
          break;
        }
        case RecordedOp::kClearBindings:
          vertex_uniforms_.Clear();
          fragment_uniforms_.Clear();
          vertex_textures_.Clear();
          fragment_textures_.Clear();
          sets_.fill(nullptr);
          vertex_buffers_.fill({});
          vertex_buffer_count_ = 0;
          index_buffer_ = {};
          index_type_ = impeller::IndexType::kNone;
          break;
        case RecordedOp::kBindVertexBuffer: {
          const auto& bind = recording_.vertex_buffers[index];
          vertex_buffers_[bind.slot] = bind.view;
          vertex_buffer_count_ = std::max(vertex_buffer_count_,
                                          static_cast<size_t>(bind.slot) + 1);
          break;
        }
        case RecordedOp::kBindIndexBuffer: {
          const auto& bind = recording_.index_buffers[index];
          index_buffer_ = bind.view;
          index_type_ = bind.type;
          break;
        }
        case RecordedOp::kSetStencilReference:
          stencil_reference_ = recording_.stencil_references[index];
          break;
        case RecordedOp::kSetScissor:
          scissor_ = recording_.scissors[index];
          break;
        case RecordedOp::kSetViewport:
          viewport_ = recording_.viewports[index];
          break;
        case RecordedOp::kDraw:
          draws++;
          if (!ReplayDraw(recording_.draws[index])) {
            failed++;
          }
          break;
      }
    }
  }

 private:
  struct BoundTexture {
    const RenderPassRecording::TextureBind* bind = nullptr;
    impeller::raw_ptr<const impeller::Sampler> sampler;
  };

  impeller::Context& context_;
  const RenderPassRecording& recording_;
  impeller::RenderPass& pass_;
  SamplerCache& samplers_;
  std::vector<std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>>
      pipelines_;
  std::vector<bool> resolved_;

  FlatMap<const Shader::UniformBinding*,
          const RenderPassRecording::UniformBind*>
      vertex_uniforms_;
  FlatMap<const Shader::UniformBinding*,
          const RenderPassRecording::UniformBind*>
      fragment_uniforms_;
  FlatMap<const Shader::TextureBinding*, BoundTexture> vertex_textures_;
  FlatMap<const Shader::TextureBinding*, BoundTexture> fragment_textures_;
  std::array<const BindingSet::Contents*, kMaxBindingSets> sets_ = {};
  std::array<impeller::BufferView, kMaxVertexBufferSlots> vertex_buffers_;
  size_t vertex_buffer_count_ = 0;
  impeller::BufferView index_buffer_;
  impeller::IndexType index_type_ = impeller::IndexType::kNone;
  uint32_t stencil_reference_ = 0;
  std::optional<impeller::IRect32> scissor_;
  std::optional<impeller::Viewport> viewport_;

  const std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>&
  ResolvePipeline(uint32_t index) {
    if (resolved_[index]) {
      return pipelines_[index];
    }
    resolved_[index] = true;
    const auto& state = recording_.pipeline_states[index];
    impeller::PipelineDescriptor descriptor = state.descriptor;
    if (!state.pipeline->BindToPipelineDescriptor(*context_.GetShaderLibrary(),
                                                  descriptor)) {
      state.pipeline->MarkBuildFailed(state.key);
      return pipelines_[index];
    }
    auto& library = *context_.GetPipelineLibrary();
    pipelines_[index] =
        context_.GetBackendType() == impeller::Context::BackendType::kOpenGLES
            ? library
                  .GetPipeline(descriptor, /*async=*/true, /*threadsafe=*/true)
                  .Get()
            : library.GetPipeline(descriptor).Get();
    if (!pipelines_[index]) {
      VALIDATION_LOG << "Failed to build the render pipeline. The vertex and "
                        "fragment shaders may be incompatible (for example, a "
                        "fragment input with no matching vertex output).";
      state.pipeline->MarkBuildFailed(state.key);
    }
    return pipelines_[index];
  }

  bool ReplayDraw(const RenderPassRecording::Draw& draw) {
    const auto& pipeline = ResolvePipeline(draw.pipeline_state);
    if (!pipeline) {
      return false;
    }
    pass_.SetPipeline(impeller::PipelineRef(pipeline));

    // Binding sets are replayed first, so an individual bind that collides
    // with a set member overrides it for this draw. Metadata is borrowed
    // from reflections the recording retains.
    for (const BindingSet::Contents* set : sets_) {
      if (!set) {
        continue;
      }
      for (const auto& buffer : set->buffer_bindings) {
        pass_.BindResource(buffer.stage,
                           impeller::DescriptorType::kUniformBuffer,
                           buffer.slot, buffer.metadata, buffer.view);
      }
      for (const auto& texture : set->texture_bindings) {
        pass_.BindResource(texture.stage,
                           impeller::DescriptorType::kSampledImage,
                           texture.slot, texture.metadata, texture.texture,
                           samplers_.Get(texture.sampler));
      }
    }
    for (const auto* uniforms : {&vertex_uniforms_, &fragment_uniforms_}) {
      for (const auto& [binding, bind] : *uniforms) {
        pass_.BindResource(bind->stage,
                           impeller::DescriptorType::kUniformBuffer,
                           binding->slot, &binding->metadata, bind->view);
      }
    }
    for (const auto* textures : {&vertex_textures_, &fragment_textures_}) {
      for (const auto& [binding, bound] : *textures) {
        pass_.BindResource(bound.bind->stage,
                           impeller::DescriptorType::kSampledImage,
                           binding->slot, &binding->metadata,
                           bound.bind->texture, bound.sampler);
      }
    }

    pass_.SetVertexBuffer(vertex_buffers_.data(), vertex_buffer_count_);
    if (draw.indexed) {
      pass_.SetIndexBuffer(index_buffer_, index_type_);
    } else {
      pass_.SetIndexBuffer(impeller::BufferView{}, impeller::IndexType::kNone);
    }
    pass_.SetElementCount(draw.element_count);
    pass_.SetInstanceCount(draw.instance_count);
    pass_.SetStencilReference(stencil_reference_);
    if (viewport_.has_value()) {
      pass_.SetViewport(viewport_.value());
    }
    if (scissor_.has_value()) {
      pass_.SetScissor(scissor_.value());
    }
    return pass_.Draw().ok();
  }
};

bool ReplayBlits(impeller::CommandBuffer& command_buffer,
                 const std::vector<RecordedBlit>& blits) {
  auto blit_pass = command_buffer.CreateBlitPass();
  if (!blit_pass) {
    return false;
  }
  for (const auto& blit : blits) {
    bool added = false;
    switch (blit.kind) {
      case RecordedBlit::Kind::kBufferToTexture:
        added = blit_pass->AddCopy(
            blit.source_buffer, blit.destination_texture, blit.region,
            "CommandBuffer.copyBufferToTexture", blit.mip_level, blit.slice);
        break;
      case RecordedBlit::Kind::kTextureToBuffer:
        added = blit_pass->AddCopy(blit.source_texture, blit.destination_buffer,
                                   blit.region, blit.destination_offset,
                                   "CommandBuffer.copyTextureToBuffer");
        break;
      case RecordedBlit::Kind::kTextureToTexture:
        added = blit_pass->AddCopy(
            blit.source_texture, blit.destination_texture, blit.region,
            blit.destination_origin, "CommandBuffer.copyTextureToTexture");
        break;
    }
    if (!added) {
      VALIDATION_LOG << "Dropped a recorded blit the backend refused.";
    }
  }
  return blit_pass->EncodeCommands();
}

}  // namespace

fml::RefPtr<fml::TaskRunner> GetReplayTaskRunner() {
  if (Dart_CurrentIsolate() == nullptr) {
    return nullptr;
  }
  auto* dart_state = flutter::UIDartState::Current();
  if (!dart_state) {
    return nullptr;
  }
  return dart_state->GetTaskRunners().GetRasterTaskRunner();
}

bool ReplayAndSubmit(const std::shared_ptr<impeller::Context>& context,
                     std::shared_ptr<const CommandBufferRecording> recording,
                     impeller::CommandBuffer::CompletionCallback completion) {
  const fml::TimePoint start = fml::TimePoint::Now();
  size_t draws = 0;
  size_t failed = 0;
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
  auto fail = [&]() {
    complete(impeller::CommandBuffer::Status::kError);
    context->DisposeThreadLocalCachedResources();
    return false;
  };

  auto command_buffer = context->CreateCommandBuffer();
  if (!command_buffer) {
    return fail();
  }
  SamplerCache samplers(*context);
  std::vector<std::shared_ptr<impeller::Pipeline<impeller::PipelineDescriptor>>>
      pipelines;
  for (const auto& encodable : recording->encodables) {
    if (!encodable.render_pass) {
      if (!ReplayBlits(*command_buffer, encodable.blits)) {
        return fail();
      }
      continue;
    }
    auto pass =
        command_buffer->CreateRenderPass(encodable.render_pass->render_target);
    if (!pass) {
      VALIDATION_LOG << "Failed to create a recorded render pass.";
      return fail();
    }
    PassReplayer replayer(*context, *encodable.render_pass, *pass, samplers);
    replayer.Run(draws, failed);
    for (auto& pipeline : replayer.TakePipelines()) {
      if (pipeline) {
        pipelines.push_back(std::move(pipeline));
      }
    }
    if (!pass->EncodeCommands()) {
      return fail();
    }
  }

  // Backends may read the shader metadata the recording retains, and the
  // pipelines its commands point at, after submission (GLES encodes in a
  // deferred reactor operation), so both live until the work completes.
  auto status = context->GetCommandQueue()->Submit(
      {command_buffer},
      [recording, pipelines = std::move(pipelines),
       complete](impeller::CommandBuffer::Status status) { complete(status); });
  if (!status.ok()) {
    complete(impeller::CommandBuffer::Status::kError);
  }
  context->DisposeThreadLocalCachedResources();
  ReplayStats::Record((fml::TimePoint::Now() - start).ToMicroseconds(), draws,
                      failed);
  return status.ok();
}

}  // namespace gpu
}  // namespace flutter
