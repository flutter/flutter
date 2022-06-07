// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/blend_filter_contents.h"

#include <array>
#include <memory>
#include <optional>

#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/geometry/path_builder.h"
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
                          std::optional<Color> foreground_color,
                          PipelineProc pipeline_proc) {
  using VS = typename TPipeline::VertexShader;
  using FS = typename TPipeline::FragmentShader;

  const size_t total_inputs =
      inputs.size() + (foreground_color.has_value() ? 1 : 0);
  if (total_inputs < 2) {
    return false;
  }

  auto dst_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  if (!dst_snapshot.has_value()) {
    return true;
  }
  auto maybe_dst_uvs = dst_snapshot->GetCoverageUVs(coverage);
  if (!maybe_dst_uvs.has_value()) {
    return true;
  }
  auto dst_uvs = maybe_dst_uvs.value();

  std::optional<Snapshot> src_snapshot;
  std::array<Point, 4> src_uvs;
  if (!foreground_color.has_value()) {
    src_snapshot = inputs[1]->GetSnapshot(renderer, entity);
    if (!src_snapshot.has_value()) {
      return true;
    }
    auto maybe_src_uvs = src_snapshot->GetCoverageUVs(coverage);
    if (!maybe_src_uvs.has_value()) {
      return true;
    }
    src_uvs = maybe_src_uvs.value();
  }

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

  typename FS::BlendInfo blend_info;
  if (foreground_color.has_value()) {
    blend_info.color_factor = 1;
    blend_info.color = foreground_color.value();
    // This texture will not be sampled from due to the color factor. But this
    // is present so that validation doesn't trip on a missing binding.
    FS::BindTextureSamplerSrc(cmd, dst_snapshot->texture, sampler);
  } else {
    blend_info.color_factor = 0;
    FS::BindTextureSamplerSrc(cmd, src_snapshot->texture, sampler);
  }
  auto blend_uniform = host_buffer.EmplaceUniform(blend_info);
  FS::BindBlendInfo(cmd, blend_uniform);

  typename VS::FrameInfo frame_info;
  frame_info.mvp = Matrix::MakeOrthographic(size);

  auto uniform_view = host_buffer.EmplaceUniform(frame_info);
  VS::BindFrameInfo(cmd, uniform_view);
  pass.AddCommand(cmd);

  return true;
}

static bool PipelineBlend(const FilterInput::Vector& inputs,
                          const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass,
                          const Rect& coverage,
                          Entity::BlendMode pipeline_blend,
                          std::optional<Color> foreground_color) {
  using VS = BlendPipeline::VertexShader;
  using FS = BlendPipeline::FragmentShader;

  auto& host_buffer = pass.GetTransientsBuffer();

  auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler({});

  Command cmd;
  cmd.label = "Pipeline Blend Filter";
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

  // Write subsequent textures using the selected blend mode.

  if (inputs.size() >= 2) {
    options.blend_mode = pipeline_blend;
    cmd.pipeline = renderer.GetBlendPipeline(options);

    for (auto texture_i = inputs.begin() + 1; texture_i < inputs.end();
         texture_i++) {
      auto input = texture_i->get()->GetSnapshot(renderer, entity);
      if (!add_blend_command(input)) {
        return true;
      }
    }
  }

  // If a foreground color is set, blend it in.

  if (foreground_color.has_value()) {
    auto contents = std::make_shared<SolidColorContents>();
    contents->SetPath(
        PathBuilder{}
            .AddRect(Rect::MakeSize(Size(pass.GetRenderTargetSize())))
            .TakePath());
    contents->SetColor(foreground_color.value());

    Entity foreground_entity;
    foreground_entity.SetBlendMode(pipeline_blend);
    foreground_entity.SetContents(contents);
    if (!foreground_entity.Render(renderer, pass)) {
      return false;
    }
  }

  return true;
}

#define BLEND_CASE(mode)                                                      \
  case Entity::BlendMode::k##mode:                                            \
    advanced_blend_proc_ =                                                    \
        [](const FilterInput::Vector& inputs, const ContentContext& renderer, \
           const Entity& entity, RenderPass& pass, const Rect& coverage,      \
           std::optional<Color> fg_color) {                                   \
          PipelineProc p = &ContentContext::GetBlend##mode##Pipeline;         \
          return AdvancedBlend<BlendScreenPipeline>(                          \
              inputs, renderer, entity, pass, coverage, fg_color, p);         \
        };                                                                    \
    break;

void BlendFilterContents::SetBlendMode(Entity::BlendMode blend_mode) {
  if (blend_mode > Entity::BlendMode::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " assigned to BlendFilterContents.";
  }

  blend_mode_ = blend_mode;

  if (blend_mode > Entity::BlendMode::kLastPipelineBlendMode) {
    static_assert(Entity::BlendMode::kLastAdvancedBlendMode ==
                  Entity::BlendMode::kLuminosity);

    switch (blend_mode) {
      BLEND_CASE(Screen)
      BLEND_CASE(Overlay)
      BLEND_CASE(Darken)
      BLEND_CASE(Lighten)
      BLEND_CASE(ColorDodge)
      BLEND_CASE(ColorBurn)
      BLEND_CASE(HardLight)
      BLEND_CASE(SoftLight)
      BLEND_CASE(Difference)
      BLEND_CASE(Exclusion)
      BLEND_CASE(Multiply)
      BLEND_CASE(Hue)
      BLEND_CASE(Saturation)
      BLEND_CASE(Color)
      BLEND_CASE(Luminosity)
      default:
        FML_UNREACHABLE();
    }
  }
}

void BlendFilterContents::SetForegroundColor(std::optional<Color> color) {
  foreground_color_ = color;
}

bool BlendFilterContents::RenderFilter(const FilterInput::Vector& inputs,
                                       const ContentContext& renderer,
                                       const Entity& entity,
                                       RenderPass& pass,
                                       const Rect& coverage) const {
  if (inputs.empty()) {
    return true;
  }

  if (inputs.size() == 1 && !foreground_color_.has_value()) {
    // Nothing to blend.
    return PipelineBlend(inputs, renderer, entity, pass, coverage,
                         Entity::BlendMode::kSource, std::nullopt);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastPipelineBlendMode) {
    return PipelineBlend(inputs, renderer, entity, pass, coverage, blend_mode_,
                         foreground_color_);
  }

  if (blend_mode_ <= Entity::BlendMode::kLastAdvancedBlendMode) {
    return advanced_blend_proc_(inputs, renderer, entity, pass, coverage,
                                foreground_color_);
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
