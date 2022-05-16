// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/blend_filter_contents.h"

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

BlendFilterContents::BlendFilterContents() {
  SetBlendMode(Entity::BlendMode::kSourceOver);
}

BlendFilterContents::~BlendFilterContents() = default;

using PipelineProc =
    std::shared_ptr<Pipeline> (ContentContext::*)(ContentContextOptions) const;

template <typename TPipeline>
static bool AdvancedBlend(const FilterInput::Vector& inputs,
                          const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass,
                          const Rect& coverage,
                          PipelineProc pipeline_proc) {
  using VS = typename TPipeline::VertexShader;
  using FS = typename TPipeline::FragmentShader;

  if (inputs.size() < 2) {
    return false;
  }

  auto dst_snapshot = inputs[1]->GetSnapshot(renderer, entity);
  if (!dst_snapshot.has_value()) {
    return true;
  }
  auto maybe_dst_uvs = dst_snapshot->GetCoverageUVs(coverage);
  if (!maybe_dst_uvs.has_value()) {
    return true;
  }
  auto dst_uvs = maybe_dst_uvs.value();

  auto src_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  if (!src_snapshot.has_value()) {
    return true;
  }
  auto maybe_src_uvs = src_snapshot->GetCoverageUVs(coverage);
  if (!maybe_src_uvs.has_value()) {
    return true;
  }
  auto src_uvs = maybe_src_uvs.value();

  auto& host_buffer = pass.GetTransientsBuffer();

  auto size = pass.GetRenderTargetSize();
  VertexBufferBuilder<typename VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0, 0), dst_uvs[0], src_uvs[0]},
      {Point(size.width, 0), dst_uvs[1], src_uvs[1]},
      {Point(size.width, size.height), dst_uvs[3], src_uvs[3]},
      {Point(0, 0), dst_uvs[0], src_uvs[0]},
      {Point(size.width, size.height), dst_uvs[3], src_uvs[3]},
      {Point(0, size.height), dst_uvs[2], src_uvs[2]},
  });
  auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

  auto options = OptionsFromPassAndEntity(pass, entity);
  std::shared_ptr<Pipeline> pipeline =
      std::invoke(pipeline_proc, renderer, options);

  Command cmd;
  cmd.label = "Advanced Blend Filter";
  cmd.BindVertices(vtx_buffer);
  cmd.pipeline = std::move(pipeline);

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
  FS::BindTextureSamplerDst(cmd, dst_snapshot->texture, sampler);
  FS::BindTextureSamplerSrc(cmd, src_snapshot->texture, sampler);

  typename VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(size);

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);
  pass.AddCommand(cmd);

  return true;
}

void BlendFilterContents::SetBlendMode(Entity::BlendMode blend_mode) {
  if (blend_mode > Entity::BlendMode::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " assigned to BlendFilterContents.";
  }

  blend_mode_ = blend_mode;

  if (blend_mode > Entity::BlendMode::kLastPipelineBlendMode) {
    static_assert(Entity::BlendMode::kLastAdvancedBlendMode ==
                  Entity::BlendMode::kColorBurn);

    switch (blend_mode) {
      case Entity::BlendMode::kScreen:
        advanced_blend_proc_ = [](const FilterInput::Vector& inputs,
                                  const ContentContext& renderer,
                                  const Entity& entity, RenderPass& pass,
                                  const Rect& coverage) {
          PipelineProc p = &ContentContext::GetBlendScreenPipeline;
          return AdvancedBlend<BlendScreenPipeline>(inputs, renderer, entity,
                                                    pass, coverage, p);
        };
        break;
      case Entity::BlendMode::kColorBurn:
        advanced_blend_proc_ = [](const FilterInput::Vector& inputs,
                                  const ContentContext& renderer,
                                  const Entity& entity, RenderPass& pass,
                                  const Rect& coverage) {
          PipelineProc p = &ContentContext::GetBlendColorburnPipeline;
          return AdvancedBlend<BlendColorburnPipeline>(inputs, renderer, entity,
                                                       pass, coverage, p);
        };
        break;
      default:
        FML_UNREACHABLE();
    }
  }
}

static bool BasicBlend(const FilterInput::Vector& inputs,
                       const ContentContext& renderer,
                       const Entity& entity,
                       RenderPass& pass,
                       const Rect& coverage,
                       Entity::BlendMode basic_blend) {
  using VS = BlendPipeline::VertexShader;
  using FS = BlendPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  Command cmd;
  cmd.label = "Basic Blend Filter";
  auto options = OptionsFromPass(pass);

  auto add_blend_command = [&](std::optional<Snapshot> input) {
    if (!input.has_value()) {
      return false;
    }
    auto input_coverage = input->GetCoverage();
    if (!input_coverage.has_value()) {
      return false;
    }

    FS::BindTextureSamplerSrc(cmd, input->texture, sampler);

    auto size = input->texture->GetSize();
    VertexBufferBuilder<VS::PerVertexData> vtx_builder;
    vtx_builder.AddVertices({
        {Point(0, 0), Point(0, 0)},
        {Point(size.width, 0), Point(1, 0)},
        {Point(size.width, size.height), Point(1, 1)},
        {Point(0, 0), Point(0, 0)},
        {Point(size.width, size.height), Point(1, 1)},
        {Point(0, size.height), Point(0, 1)},
    });
    auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);
    cmd.BindVertices(vtx_buffer);

    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     Matrix::MakeTranslation(-coverage.origin) *
                     input->transform;

    auto uniform_view = host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(cmd, uniform_view);

    pass.AddCommand(cmd);
    return true;
  };

  // Draw the first texture using kSource.

  options.blend_mode = Entity::BlendMode::kSource;
  cmd.pipeline = renderer.GetBlendPipeline(options);
  if (!add_blend_command(inputs[0]->GetSnapshot(renderer, entity))) {
    return true;
  }

  if (inputs.size() < 2) {
    return true;
  }

  // Write subsequent textures using the selected blend mode.

  options.blend_mode = basic_blend;
  cmd.pipeline = renderer.GetBlendPipeline(options);

  for (auto texture_i = inputs.begin() + 1; texture_i < inputs.end();
       texture_i++) {
    auto input = texture_i->get()->GetSnapshot(renderer, entity);
    if (!add_blend_command(input)) {
      return true;
    }
  }

  return true;
}

bool BlendFilterContents::RenderFilter(const FilterInput::Vector& inputs,
                                       const ContentContext& renderer,
                                       const Entity& entity,
                                       RenderPass& pass,
                                       const Rect& coverage) const {
  if (inputs.empty()) {
    return true;
  }

  if (inputs.size() == 1) {
    // Nothing to blend.
    return BasicBlend(inputs, renderer, entity, pass, coverage,
                      Entity::BlendMode::kSource);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastPipelineBlendMode) {
    return BasicBlend(inputs, renderer, entity, pass, coverage, blend_mode_);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastAdvancedBlendMode) {
    return advanced_blend_proc_(inputs, renderer, entity, pass, coverage);
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
