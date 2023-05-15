// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/blend_filter_contents.h"

#include <array>
#include <memory>
#include <optional>

#include "impeller/core/formats.h"
#include "impeller/entity/contents/anonymous_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/sampler_library.h"
#include "impeller/renderer/snapshot.h"

namespace impeller {

BlendFilterContents::BlendFilterContents() {
  SetBlendMode(BlendMode::kSourceOver);
}

BlendFilterContents::~BlendFilterContents() = default;

using PipelineProc = std::shared_ptr<Pipeline<PipelineDescriptor>> (
    ContentContext::*)(ContentContextOptions) const;

template <typename TPipeline>
static std::optional<Entity> AdvancedBlend(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Rect& coverage,
    std::optional<Color> foreground_color,
    bool absorb_opacity,
    PipelineProc pipeline_proc,
    std::optional<Scalar> alpha) {
  using VS = typename TPipeline::VertexShader;
  using FS = typename TPipeline::FragmentShader;

  //----------------------------------------------------------------------------
  /// Handle inputs.
  ///

  const size_t total_inputs =
      inputs.size() + (foreground_color.has_value() ? 1 : 0);
  if (total_inputs < 2) {
    return std::nullopt;
  }

  auto dst_snapshot =
      inputs[0]->GetSnapshot("AdvancedBlend(Dst)", renderer, entity);
  if (!dst_snapshot.has_value()) {
    return std::nullopt;
  }
  auto maybe_dst_uvs = dst_snapshot->GetCoverageUVs(coverage);
  if (!maybe_dst_uvs.has_value()) {
    return std::nullopt;
  }
  auto dst_uvs = maybe_dst_uvs.value();

  std::optional<Snapshot> src_snapshot;
  std::array<Point, 4> src_uvs;
  if (!foreground_color.has_value()) {
    src_snapshot =
        inputs[1]->GetSnapshot("AdvancedBlend(Src)", renderer, entity);
    if (!src_snapshot.has_value()) {
      if (!dst_snapshot.has_value()) {
        return std::nullopt;
      }
      return Entity::FromSnapshot(dst_snapshot, entity.GetBlendMode(),
                                  entity.GetStencilDepth());
    }
    auto maybe_src_uvs = src_snapshot->GetCoverageUVs(coverage);
    if (!maybe_src_uvs.has_value()) {
      if (!dst_snapshot.has_value()) {
        return std::nullopt;
      }
      return Entity::FromSnapshot(dst_snapshot, entity.GetBlendMode(),
                                  entity.GetStencilDepth());
    }
    src_uvs = maybe_src_uvs.value();
  }

  //----------------------------------------------------------------------------
  /// Render to texture.
  ///

  ContentContext::SubpassCallback callback = [&](const ContentContext& renderer,
                                                 RenderPass& pass) {
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

    auto options = OptionsFromPass(pass);
    options.blend_mode = BlendMode::kSource;
    std::shared_ptr<Pipeline<PipelineDescriptor>> pipeline =
        std::invoke(pipeline_proc, renderer, options);

    Command cmd;
    cmd.label = "Advanced Blend Filter";
    cmd.BindVertices(vtx_buffer);
    cmd.pipeline = std::move(pipeline);

    typename FS::BlendInfo blend_info;
    typename VS::FrameInfo frame_info;

    auto dst_sampler_descriptor = dst_snapshot->sampler_descriptor;
    if (renderer.GetDeviceCapabilities().SupportsDecalTileMode()) {
      dst_sampler_descriptor.width_address_mode = SamplerAddressMode::kDecal;
      dst_sampler_descriptor.height_address_mode = SamplerAddressMode::kDecal;
    }
    auto dst_sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler(
        dst_sampler_descriptor);
    FS::BindTextureSamplerDst(cmd, dst_snapshot->texture, dst_sampler);
    frame_info.dst_y_coord_scale = dst_snapshot->texture->GetYCoordScale();
    blend_info.dst_input_alpha = absorb_opacity ? dst_snapshot->opacity : 1.0;

    if (foreground_color.has_value()) {
      blend_info.color_factor = 1;
      blend_info.color = foreground_color.value();
      // This texture will not be sampled from due to the color factor. But
      // this is present so that validation doesn't trip on a missing
      // binding.
      FS::BindTextureSamplerSrc(cmd, dst_snapshot->texture, dst_sampler);
    } else {
      auto src_sampler_descriptor = src_snapshot->sampler_descriptor;
      if (renderer.GetDeviceCapabilities().SupportsDecalTileMode()) {
        src_sampler_descriptor.width_address_mode = SamplerAddressMode::kDecal;
        src_sampler_descriptor.height_address_mode = SamplerAddressMode::kDecal;
      }
      auto src_sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          src_sampler_descriptor);
      blend_info.color_factor = 0;
      FS::BindTextureSamplerSrc(cmd, src_snapshot->texture, src_sampler);
      frame_info.src_y_coord_scale = src_snapshot->texture->GetYCoordScale();
    }
    auto blend_uniform = host_buffer.EmplaceUniform(blend_info);
    FS::BindBlendInfo(cmd, blend_uniform);

    frame_info.mvp = Matrix::MakeOrthographic(size);

    auto uniform_view = host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(cmd, uniform_view);
    pass.AddCommand(cmd);

    return true;
  };

  auto out_texture = renderer.MakeSubpass("Advanced Blend Filter",
                                          ISize(coverage.size), callback);
  if (!out_texture) {
    return std::nullopt;
  }

  return Entity::FromSnapshot(
      Snapshot{.texture = out_texture,
               .transform = Matrix::MakeTranslation(coverage.origin),
               // Since we absorbed the transform of the inputs and used the
               // respective snapshot sampling modes when blending, pass on
               // the default NN clamp sampler.
               .sampler_descriptor = {},
               .opacity = (absorb_opacity ? 1.0f : dst_snapshot->opacity) *
                          alpha.value_or(1.0)},
      entity.GetBlendMode(), entity.GetStencilDepth());
}

std::optional<Entity> BlendFilterContents::CreateForegroundAdvancedBlend(
    const std::shared_ptr<FilterInput>& input,
    const ContentContext& renderer,
    const Entity& entity,
    const Rect& coverage,
    Color foreground_color,
    BlendMode blend_mode,
    std::optional<Scalar> alpha,
    bool absorb_opacity) const {
  auto dst_snapshot =
      input->GetSnapshot("ForegroundAdvancedBlend", renderer, entity);
  if (!dst_snapshot.has_value()) {
    return std::nullopt;
  }

  RenderProc render_proc = [foreground_color, coverage, dst_snapshot,
                            blend_mode, alpha, absorb_opacity](
                               const ContentContext& renderer,
                               const Entity& entity, RenderPass& pass) -> bool {
    using VS = BlendScreenPipeline::VertexShader;
    using FS = BlendScreenPipeline::FragmentShader;

    auto& host_buffer = pass.GetTransientsBuffer();

    auto maybe_dst_uvs = dst_snapshot->GetCoverageUVs(coverage);
    if (!maybe_dst_uvs.has_value()) {
      return false;
    }
    auto dst_uvs = maybe_dst_uvs.value();

    auto size = coverage.size;
    auto origin = coverage.origin;
    VertexBufferBuilder<VS::PerVertexData> vtx_builder;
    vtx_builder.AddVertices({
        {origin, dst_uvs[0], dst_uvs[0]},
        {Point(origin.x + size.width, origin.y), dst_uvs[1], dst_uvs[1]},
        {Point(origin.x + size.width, origin.y + size.height), dst_uvs[3],
         dst_uvs[3]},
        {origin, dst_uvs[0], dst_uvs[0]},
        {Point(origin.x + size.width, origin.y + size.height), dst_uvs[3],
         dst_uvs[3]},
        {Point(origin.x, origin.y + size.height), dst_uvs[2], dst_uvs[2]},
    });
    auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

    Command cmd;
    cmd.label = "Foreground Advanced Blend Filter";
    cmd.BindVertices(vtx_buffer);
    cmd.stencil_reference = entity.GetStencilDepth();
    auto options = OptionsFromPass(pass);

    switch (blend_mode) {
      case BlendMode::kScreen:
        cmd.pipeline = renderer.GetBlendScreenPipeline(options);
        break;
      case BlendMode::kOverlay:
        cmd.pipeline = renderer.GetBlendOverlayPipeline(options);
        break;
      case BlendMode::kDarken:
        cmd.pipeline = renderer.GetBlendDarkenPipeline(options);
        break;
      case BlendMode::kLighten:
        cmd.pipeline = renderer.GetBlendLightenPipeline(options);
        break;
      case BlendMode::kColorDodge:
        cmd.pipeline = renderer.GetBlendColorDodgePipeline(options);
        break;
      case BlendMode::kColorBurn:
        cmd.pipeline = renderer.GetBlendColorBurnPipeline(options);
        break;
      case BlendMode::kHardLight:
        cmd.pipeline = renderer.GetBlendHardLightPipeline(options);
        break;
      case BlendMode::kSoftLight:
        cmd.pipeline = renderer.GetBlendSoftLightPipeline(options);
        break;
      case BlendMode::kDifference:
        cmd.pipeline = renderer.GetBlendDifferencePipeline(options);
        break;
      case BlendMode::kExclusion:
        cmd.pipeline = renderer.GetBlendExclusionPipeline(options);
        break;
      case BlendMode::kMultiply:
        cmd.pipeline = renderer.GetBlendMultiplyPipeline(options);
        break;
      case BlendMode::kHue:
        cmd.pipeline = renderer.GetBlendHuePipeline(options);
        break;
      case BlendMode::kSaturation:
        cmd.pipeline = renderer.GetBlendSaturationPipeline(options);
        break;
      case BlendMode::kColor:
        cmd.pipeline = renderer.GetBlendColorPipeline(options);
        break;
      case BlendMode::kLuminosity:
        cmd.pipeline = renderer.GetBlendLuminosityPipeline(options);
        break;
      default:
        return false;
    }

    FS::BlendInfo blend_info;
    VS::FrameInfo frame_info;

    auto dst_sampler_descriptor = dst_snapshot->sampler_descriptor;
    if (renderer.GetDeviceCapabilities().SupportsDecalTileMode()) {
      dst_sampler_descriptor.width_address_mode = SamplerAddressMode::kDecal;
      dst_sampler_descriptor.height_address_mode = SamplerAddressMode::kDecal;
    }
    auto dst_sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler(
        dst_sampler_descriptor);
    FS::BindTextureSamplerDst(cmd, dst_snapshot->texture, dst_sampler);
    frame_info.dst_y_coord_scale = dst_snapshot->texture->GetYCoordScale();
    blend_info.dst_input_alpha =
        absorb_opacity ? dst_snapshot->opacity * alpha.value_or(1.0) : 1.0;

    blend_info.color_factor = 1;
    blend_info.color = foreground_color;
    // This texture will not be sampled from due to the color factor. But
    // this is present so that validation doesn't trip on a missing
    // binding.
    FS::BindTextureSamplerSrc(cmd, dst_snapshot->texture, dst_sampler);

    auto blend_uniform = host_buffer.EmplaceUniform(blend_info);
    FS::BindBlendInfo(cmd, blend_uniform);

    frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     entity.GetTransformation();

    auto uniform_view = host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(cmd, uniform_view);

    return pass.AddCommand(cmd);
  };
  CoverageProc coverage_proc =
      [coverage](const Entity& entity) -> std::optional<Rect> {
    return coverage.TransformBounds(entity.GetTransformation());
  };

  auto contents = AnonymousContents::Make(render_proc, coverage_proc);

  Entity sub_entity;
  sub_entity.SetContents(std::move(contents));
  sub_entity.SetStencilDepth(entity.GetStencilDepth());

  return sub_entity;
}

constexpr std::array<std::array<Scalar, 5>, 15> kPorterDuffCoefficients = {{
    {0, 0, 0, 0, 0},    // Clear
    {1, 0, 0, 0, 0},    // Source
    {0, 0, 1, 0, 0},    // Destination
    {1, 0, 1, -1, 0},   // SourceOver
    {1, -1, 1, 0, 0},   // DestinationOver
    {0, 1, 0, 0, 0},    // SourceIn
    {0, 0, 0, 1, 0},    // DestinationIn
    {1, -1, 0, 0, 0},   // SourceOut
    {0, 0, 1, -1, 0},   // DestinationOut
    {0, 1, 1, -1, 0},   // SourceATop
    {1, -1, 0, 1, 0},   // DestinationATop
    {1, -1, 1, -1, 0},  // Xor
    {1, 0, 1, 0, 0},    // Plus
    {0, 0, 0, 0, 1},    // Modulate
    {0, 0, 1, 0, -1},   // Screen
}};

std::optional<Entity> BlendFilterContents::CreateForegroundPorterDuffBlend(
    const std::shared_ptr<FilterInput>& input,
    const ContentContext& renderer,
    const Entity& entity,
    const Rect& coverage,
    Color foreground_color,
    BlendMode blend_mode,
    std::optional<Scalar> alpha,
    bool absorb_opacity) const {
  auto dst_snapshot =
      input->GetSnapshot("ForegroundPorterDuffBlend", renderer, entity);
  if (!dst_snapshot.has_value()) {
    return std::nullopt;
  }

  if (blend_mode == BlendMode::kClear) {
    return std::nullopt;
  }

  if (blend_mode == BlendMode::kDestination) {
    return Entity::FromSnapshot(dst_snapshot, entity.GetBlendMode(),
                                entity.GetStencilDepth());
  }

  if (blend_mode == BlendMode::kSource) {
    auto contents = std::make_shared<SolidColorContents>();
    contents->SetGeometry(Geometry::MakeRect(coverage));
    contents->SetColor(foreground_color);

    Entity foreground_entity;
    foreground_entity.SetBlendMode(entity.GetBlendMode());
    foreground_entity.SetStencilDepth(entity.GetStencilDepth());
    foreground_entity.SetContents(std::move(contents));
    return foreground_entity;
  }

  RenderProc render_proc = [foreground_color, coverage, dst_snapshot,
                            blend_mode, absorb_opacity, alpha](
                               const ContentContext& renderer,
                               const Entity& entity, RenderPass& pass) -> bool {
    using VS = PorterDuffBlendPipeline::VertexShader;
    using FS = PorterDuffBlendPipeline::FragmentShader;

    auto& host_buffer = pass.GetTransientsBuffer();

    auto maybe_dst_uvs = dst_snapshot->GetCoverageUVs(coverage);
    if (!maybe_dst_uvs.has_value()) {
      return false;
    }
    auto dst_uvs = maybe_dst_uvs.value();

    auto size = coverage.size;
    auto origin = coverage.origin;
    VertexBufferBuilder<VS::PerVertexData> vtx_builder;
    vtx_builder.AddVertices({
        {origin, dst_uvs[0]},
        {Point(origin.x + size.width, origin.y), dst_uvs[1]},
        {Point(origin.x + size.width, origin.y + size.height), dst_uvs[3]},
        {origin, dst_uvs[0]},
        {Point(origin.x + size.width, origin.y + size.height), dst_uvs[3]},
        {Point(origin.x, origin.y + size.height), dst_uvs[2]},
    });
    auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

    Command cmd;
    cmd.label = "Foreground PorterDuff Blend Filter";
    cmd.BindVertices(vtx_buffer);
    cmd.stencil_reference = entity.GetStencilDepth();
    auto options = OptionsFromPass(pass);
    cmd.pipeline = renderer.GetPorterDuffBlendPipeline(options);

    FS::FragInfo frag_info;
    VS::FrameInfo frame_info;

    auto dst_sampler_descriptor = dst_snapshot->sampler_descriptor;
    if (renderer.GetDeviceCapabilities().SupportsDecalTileMode()) {
      dst_sampler_descriptor.width_address_mode = SamplerAddressMode::kDecal;
      dst_sampler_descriptor.height_address_mode = SamplerAddressMode::kDecal;
    }
    auto dst_sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler(
        dst_sampler_descriptor);
    FS::BindTextureSamplerDst(cmd, dst_snapshot->texture, dst_sampler);
    frame_info.texture_sampler_y_coord_scale =
        dst_snapshot->texture->GetYCoordScale();

    frag_info.color = foreground_color.Premultiply();
    frag_info.input_alpha =
        absorb_opacity ? dst_snapshot->opacity * alpha.value_or(1.0) : 1.0;

    auto blend_coefficients =
        kPorterDuffCoefficients[static_cast<int>(blend_mode)];
    frag_info.src_coeff = blend_coefficients[0];
    frag_info.src_coeff_dst_alpha = blend_coefficients[1];
    frag_info.dst_coeff = blend_coefficients[2];
    frag_info.dst_coeff_src_alpha = blend_coefficients[3];
    frag_info.dst_coeff_src_color = blend_coefficients[4];

    FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));

    frame_info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
                     entity.GetTransformation();

    auto uniform_view = host_buffer.EmplaceUniform(frame_info);
    VS::BindFrameInfo(cmd, uniform_view);

    return pass.AddCommand(cmd);
  };

  CoverageProc coverage_proc =
      [coverage](const Entity& entity) -> std::optional<Rect> {
    return coverage.TransformBounds(entity.GetTransformation());
  };

  auto contents = AnonymousContents::Make(render_proc, coverage_proc);

  Entity sub_entity;
  sub_entity.SetContents(std::move(contents));
  sub_entity.SetStencilDepth(entity.GetStencilDepth());

  return sub_entity;
}

static std::optional<Entity> PipelineBlend(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Rect& coverage,
    BlendMode pipeline_blend,
    std::optional<Color> foreground_color,
    bool absorb_opacity,
    std::optional<Scalar> alpha) {
  using VS = BlendPipeline::VertexShader;
  using FS = BlendPipeline::FragmentShader;

  auto dst_snapshot =
      inputs[0]->GetSnapshot("PipelineBlend(Dst)", renderer, entity);

  ContentContext::SubpassCallback callback = [&](const ContentContext& renderer,
                                                 RenderPass& pass) {
    auto& host_buffer = pass.GetTransientsBuffer();

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

      auto sampler = renderer.GetContext()->GetSamplerLibrary()->GetSampler(
          input->sampler_descriptor);
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
      frame_info.texture_sampler_y_coord_scale =
          input->texture->GetYCoordScale();

      FS::FragInfo frag_info;
      frag_info.input_alpha = absorb_opacity ? input->opacity : 1.0;
      FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));
      VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));

      pass.AddCommand(cmd);
      return true;
    };

    // Draw the first texture using kSource.
    options.blend_mode = BlendMode::kSource;
    cmd.pipeline = renderer.GetBlendPipeline(options);
    if (!add_blend_command(dst_snapshot)) {
      return true;
    }

    // Write subsequent textures using the selected blend mode.

    if (inputs.size() >= 2) {
      options.blend_mode = pipeline_blend;
      cmd.pipeline = renderer.GetBlendPipeline(options);

      for (auto texture_i = inputs.begin() + 1; texture_i < inputs.end();
           texture_i++) {
        auto src_input = texture_i->get()->GetSnapshot("PipelineBlend(Src)",
                                                       renderer, entity);
        if (!add_blend_command(src_input)) {
          return true;
        }
      }
    }

    // If a foreground color is set, blend it in.

    if (foreground_color.has_value()) {
      auto contents = std::make_shared<SolidColorContents>();
      contents->SetGeometry(
          Geometry::MakeRect(Rect::MakeSize(pass.GetRenderTargetSize())));
      contents->SetColor(foreground_color.value());

      Entity foreground_entity;
      foreground_entity.SetBlendMode(pipeline_blend);
      foreground_entity.SetContents(contents);
      if (!foreground_entity.Render(renderer, pass)) {
        return false;
      }
    }

    return true;
  };

  auto out_texture = renderer.MakeSubpass("Pipeline Blend Filter",
                                          ISize(coverage.size), callback);
  if (!out_texture) {
    return std::nullopt;
  }

  return Entity::FromSnapshot(
      Snapshot{.texture = out_texture,
               .transform = Matrix::MakeTranslation(coverage.origin),
               // Since we absorbed the transform of the inputs and used the
               // respective snapshot sampling modes when blending, pass on
               // the default NN clamp sampler.
               .sampler_descriptor = {},
               .opacity = (absorb_opacity ? 1.0f : dst_snapshot->opacity) *
                          alpha.value_or(1.0)},
      entity.GetBlendMode(), entity.GetStencilDepth());
}

#define BLEND_CASE(mode)                                                     \
  case BlendMode::k##mode:                                                   \
    advanced_blend_proc_ = [](const FilterInput::Vector& inputs,             \
                              const ContentContext& renderer,                \
                              const Entity& entity, const Rect& coverage,    \
                              std::optional<Color> fg_color,                 \
                              bool absorb_opacity,                           \
                              std::optional<Scalar> alpha) {                 \
      PipelineProc p = &ContentContext::GetBlend##mode##Pipeline;            \
      return AdvancedBlend<Blend##mode##Pipeline>(inputs, renderer, entity,  \
                                                  coverage, fg_color,        \
                                                  absorb_opacity, p, alpha); \
    };                                                                       \
    break;

void BlendFilterContents::SetBlendMode(BlendMode blend_mode) {
  if (blend_mode > Entity::kLastAdvancedBlendMode) {
    VALIDATION_LOG << "Invalid blend mode " << static_cast<int>(blend_mode)
                   << " assigned to BlendFilterContents.";
  }

  blend_mode_ = blend_mode;

  if (blend_mode > Entity::kLastPipelineBlendMode) {
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

std::optional<Entity> BlendFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage,
    const std::optional<Rect>& coverage_hint) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  if (inputs.size() == 1 && !foreground_color_.has_value()) {
    // Nothing to blend.
    return PipelineBlend(inputs, renderer, entity, coverage, BlendMode::kSource,
                         std::nullopt, GetAbsorbOpacity(), GetAlpha());
  }

  if (blend_mode_ <= Entity::kLastPipelineBlendMode) {
    if (inputs.size() == 1 && foreground_color_.has_value() &&
        GetAbsorbOpacity()) {
      return CreateForegroundPorterDuffBlend(
          inputs[0], renderer, entity, coverage, foreground_color_.value(),
          blend_mode_, GetAlpha(), GetAbsorbOpacity());
    }
    return PipelineBlend(inputs, renderer, entity, coverage, blend_mode_,
                         foreground_color_, GetAbsorbOpacity(), GetAlpha());
  }

  if (blend_mode_ <= Entity::kLastAdvancedBlendMode) {
    if (inputs.size() == 1 && foreground_color_.has_value() &&
        GetAbsorbOpacity()) {
      return CreateForegroundAdvancedBlend(
          inputs[0], renderer, entity, coverage, foreground_color_.value(),
          blend_mode_, GetAlpha(), GetAbsorbOpacity());
    }
    return advanced_blend_proc_(inputs, renderer, entity, coverage,
                                foreground_color_, GetAbsorbOpacity(),
                                GetAlpha());
  }

  FML_UNREACHABLE();
}

}  // namespace impeller
