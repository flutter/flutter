// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "conical_gradient_contents.h"

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/gradient.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

namespace {
ConicalKind GetConicalKind(Point center,
                           Scalar radius,
                           std::optional<Point> focus,
                           Scalar focus_radius) {
  ConicalKind kind = ConicalKind::kConical;
  if (!focus.has_value() ||
      center.GetDistance(focus.value()) < kEhCloseEnough) {
    kind = ConicalKind::kRadial;
  }
  if (focus.has_value() && std::fabsf(radius - focus_radius) < kEhCloseEnough) {
    if (kind == ConicalKind::kRadial) {
      kind = ConicalKind::kStripAndRadial;
    } else {
      kind = ConicalKind::kStrip;
    }
  }
  return kind;
}

}  // namespace

ConicalGradientContents::ConicalGradientContents() = default;

ConicalGradientContents::~ConicalGradientContents() = default;

void ConicalGradientContents::SetCenterAndRadius(Point center, Scalar radius) {
  center_ = center;
  radius_ = radius;
}

void ConicalGradientContents::SetTileMode(Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

void ConicalGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
}

void ConicalGradientContents::SetStops(std::vector<Scalar> stops) {
  stops_ = std::move(stops);
}

const std::vector<Color>& ConicalGradientContents::GetColors() const {
  return colors_;
}

const std::vector<Scalar>& ConicalGradientContents::GetStops() const {
  return stops_;
}

void ConicalGradientContents::SetFocus(std::optional<Point> focus,
                                       Scalar radius) {
  focus_ = focus;
  focus_radius_ = radius;
}

#define ARRAY_LEN(a) (sizeof(a) / sizeof(a[0]))
#define UNIFORM_FRAG_INFO(t) \
  t##GradientUniformFillConicalPipeline::FragmentShader::FragInfo
#define UNIFORM_COLOR_SIZE ARRAY_LEN(UNIFORM_FRAG_INFO(Conical)::colors)
#define UNIFORM_STOP_SIZE ARRAY_LEN(UNIFORM_FRAG_INFO(Conical)::stop_pairs)
static_assert(UNIFORM_COLOR_SIZE == kMaxUniformGradientStops);
static_assert(UNIFORM_STOP_SIZE == kMaxUniformGradientStops / 2);

bool ConicalGradientContents::Render(const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) const {
  if (renderer.GetDeviceCapabilities().SupportsSSBO()) {
    return RenderSSBO(renderer, entity, pass);
  }
  if (colors_.size() <= kMaxUniformGradientStops &&
      stops_.size() <= kMaxUniformGradientStops) {
    return RenderUniform(renderer, entity, pass);
  }
  return RenderTexture(renderer, entity, pass);
}

bool ConicalGradientContents::RenderSSBO(const ContentContext& renderer,
                                         const Entity& entity,
                                         RenderPass& pass) const {
  using VS = ConicalGradientSSBOFillPipeline::VertexShader;
  using FS = ConicalGradientSSBOFillPipeline::FragmentShader;

  VS::FrameInfo frame_info;
  frame_info.matrix = GetInverseEffectTransform();

  ConicalKind kind = GetConicalKind(center_, radius_, focus_, focus_radius_);
  PipelineBuilderCallback pipeline_callback =
      [&renderer, kind](ContentContextOptions options) {
        return renderer.GetConicalGradientSSBOFillPipeline(options, kind);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      renderer, entity, pass, pipeline_callback, frame_info,
      [this, &renderer, &entity](RenderPass& pass) {
        FS::FragInfo frag_info;
        frag_info.center = center_;
        frag_info.radius = radius_;
        frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
        frag_info.decal_border_color = decal_border_color_;
        frag_info.alpha =
            GetOpacityFactor() *
            GetGeometry()->ComputeAlphaCoverage(entity.GetTransform());
        if (focus_) {
          frag_info.focus = focus_.value();
          frag_info.focus_radius = focus_radius_;
        } else {
          frag_info.focus = center_;
          frag_info.focus_radius = 0.0;
        }

        auto& data_host_buffer = renderer.GetTransientsDataBuffer();
        auto colors = CreateGradientColors(colors_, stops_);

        frag_info.colors_length = colors.size();
        auto color_buffer = data_host_buffer.Emplace(
            colors.data(), colors.size() * sizeof(StopData),
            renderer.GetDeviceCapabilities()
                .GetMinimumStorageBufferAlignment());

        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        FS::BindColorData(pass, color_buffer);

        pass.SetCommandLabel("ConicalGradientSSBOFill");
        return true;
      });
}

bool ConicalGradientContents::RenderUniform(const ContentContext& renderer,
                                            const Entity& entity,
                                            RenderPass& pass) const {
  using VS = ConicalGradientUniformFillConicalPipeline::VertexShader;
  using FS = ConicalGradientUniformFillConicalPipeline::FragmentShader;

  VS::FrameInfo frame_info;
  frame_info.matrix = GetInverseEffectTransform();

  ConicalKind kind = GetConicalKind(center_, radius_, focus_, focus_radius_);
  PipelineBuilderCallback pipeline_callback =
      [&renderer, kind](ContentContextOptions options) {
        return renderer.GetConicalGradientUniformFillPipeline(options, kind);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      renderer, entity, pass, pipeline_callback, frame_info,
      [this, &renderer, &entity](RenderPass& pass) {
        FS::FragInfo frag_info;
        frag_info.center = center_;
        if (focus_) {
          frag_info.focus = focus_.value();
          frag_info.focus_radius = focus_radius_;
        } else {
          frag_info.focus = center_;
          frag_info.focus_radius = 0.0;
        }
        frag_info.radius = radius_;
        frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
        frag_info.alpha =
            GetOpacityFactor() *
            GetGeometry()->ComputeAlphaCoverage(entity.GetTransform());
        frag_info.colors_length = PopulateUniformGradientColors(
            colors_, stops_, frag_info.colors, frag_info.stop_pairs);
        frag_info.decal_border_color = decal_border_color_;

        pass.SetCommandLabel("ConicalGradientUniformFill");

        FS::BindFragInfo(
            pass, renderer.GetTransientsDataBuffer().EmplaceUniform(frag_info));

        return true;
      });
}

bool ConicalGradientContents::RenderTexture(const ContentContext& renderer,
                                            const Entity& entity,
                                            RenderPass& pass) const {
  using VS = ConicalGradientFillConicalPipeline::VertexShader;
  using FS = ConicalGradientFillConicalPipeline::FragmentShader;

  auto gradient_data = CreateGradientBuffer(colors_, stops_);
  auto gradient_texture =
      CreateGradientTexture(gradient_data, renderer.GetContext());
  if (gradient_texture == nullptr) {
    return false;
  }

  VS::FrameInfo frame_info;
  frame_info.matrix = GetInverseEffectTransform();

  ConicalKind kind = GetConicalKind(center_, radius_, focus_, focus_radius_);
  PipelineBuilderCallback pipeline_callback =
      [&renderer, kind](ContentContextOptions options) {
        return renderer.GetConicalGradientFillPipeline(options, kind);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      renderer, entity, pass, pipeline_callback, frame_info,
      [this, &renderer, &gradient_texture, &entity](RenderPass& pass) {
        FS::FragInfo frag_info;
        frag_info.center = center_;
        frag_info.radius = radius_;
        frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
        frag_info.decal_border_color = decal_border_color_;
        frag_info.texture_sampler_y_coord_scale =
            gradient_texture->GetYCoordScale();
        frag_info.alpha =
            GetOpacityFactor() *
            GetGeometry()->ComputeAlphaCoverage(entity.GetTransform());
        frag_info.half_texel =
            Vector2(0.5 / gradient_texture->GetSize().width,
                    0.5 / gradient_texture->GetSize().height);
        if (focus_) {
          frag_info.focus = focus_.value();
          frag_info.focus_radius = focus_radius_;
        } else {
          frag_info.focus = center_;
          frag_info.focus_radius = 0.0;
        }

        pass.SetCommandLabel("ConicalGradientFill");

        FS::BindFragInfo(
            pass, renderer.GetTransientsDataBuffer().EmplaceUniform(frag_info));
        SamplerDescriptor sampler_desc;
        sampler_desc.min_filter = MinMagFilter::kLinear;
        sampler_desc.mag_filter = MinMagFilter::kLinear;
        FS::BindTextureSampler(
            pass, gradient_texture,
            renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                sampler_desc));

        return true;
      });
}

bool ConicalGradientContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  for (Color& color : colors_) {
    color = color_filter_proc(color);
  }
  decal_border_color_ = color_filter_proc(decal_border_color_);
  return true;
}

}  // namespace impeller
