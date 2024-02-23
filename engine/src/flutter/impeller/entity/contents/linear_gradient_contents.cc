// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "linear_gradient_contents.h"

#include "impeller/core/formats.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

LinearGradientContents::LinearGradientContents() = default;

LinearGradientContents::~LinearGradientContents() = default;

void LinearGradientContents::SetEndPoints(Point start_point, Point end_point) {
  start_point_ = start_point;
  end_point_ = end_point;
}

void LinearGradientContents::SetColors(std::vector<Color> colors) {
  colors_ = std::move(colors);
}

void LinearGradientContents::SetStops(std::vector<Scalar> stops) {
  stops_ = std::move(stops);
}

const std::vector<Color>& LinearGradientContents::GetColors() const {
  return colors_;
}

const std::vector<Scalar>& LinearGradientContents::GetStops() const {
  return stops_;
}

void LinearGradientContents::SetTileMode(Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

bool LinearGradientContents::IsOpaque() const {
  if (GetOpacityFactor() < 1 || tile_mode_ == Entity::TileMode::kDecal) {
    return false;
  }
  for (auto color : colors_) {
    if (!color.IsOpaque()) {
      return false;
    }
  }
  return true;
}

bool LinearGradientContents::Render(const ContentContext& renderer,
                                    const Entity& entity,
                                    RenderPass& pass) const {
  if (renderer.GetDeviceCapabilities().SupportsSSBO()) {
    return RenderSSBO(renderer, entity, pass);
  }
  return RenderTexture(renderer, entity, pass);
}

bool LinearGradientContents::RenderTexture(const ContentContext& renderer,
                                           const Entity& entity,
                                           RenderPass& pass) const {
  using VS = LinearGradientFillPipeline::VertexShader;
  using FS = LinearGradientFillPipeline::FragmentShader;

  VS::FrameInfo frame_info;
  frame_info.matrix = GetInverseEffectTransform();

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetLinearGradientFillPipeline(options);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      renderer, entity, pass, pipeline_callback, frame_info,
      [this, &renderer](RenderPass& pass) {
        auto gradient_data = CreateGradientBuffer(colors_, stops_);
        auto gradient_texture =
            CreateGradientTexture(gradient_data, renderer.GetContext());
        if (gradient_texture == nullptr) {
          return false;
        }

        FS::FragInfo frag_info;
        frag_info.start_point = start_point_;
        frag_info.end_point = end_point_;
        frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
        frag_info.decal_border_color = decal_border_color_;
        frag_info.texture_sampler_y_coord_scale =
            gradient_texture->GetYCoordScale();
        frag_info.alpha = GetOpacityFactor();
        frag_info.half_texel =
            Vector2(0.5 / gradient_texture->GetSize().width,
                    0.5 / gradient_texture->GetSize().height);

        pass.SetCommandLabel("LinearGradientFill");

        SamplerDescriptor sampler_desc;
        sampler_desc.min_filter = MinMagFilter::kLinear;
        sampler_desc.mag_filter = MinMagFilter::kLinear;

        FS::BindTextureSampler(
            pass, std::move(gradient_texture),
            renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                sampler_desc));
        FS::BindFragInfo(
            pass, renderer.GetTransientsBuffer().EmplaceUniform(frag_info));
        return true;
      });
}

bool LinearGradientContents::RenderSSBO(const ContentContext& renderer,
                                        const Entity& entity,
                                        RenderPass& pass) const {
  using VS = LinearGradientSSBOFillPipeline::VertexShader;
  using FS = LinearGradientSSBOFillPipeline::FragmentShader;

  VS::FrameInfo frame_info;
  frame_info.matrix = GetInverseEffectTransform();

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetLinearGradientSSBOFillPipeline(options);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      renderer, entity, pass, pipeline_callback, frame_info,
      [this, &renderer](RenderPass& pass) {
        FS::FragInfo frag_info;
        frag_info.start_point = start_point_;
        frag_info.end_point = end_point_;
        frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
        frag_info.decal_border_color = decal_border_color_;
        frag_info.alpha = GetOpacityFactor();

        auto& host_buffer = renderer.GetTransientsBuffer();
        auto colors = CreateGradientColors(colors_, stops_);

        frag_info.colors_length = colors.size();
        auto color_buffer =
            host_buffer.Emplace(colors.data(), colors.size() * sizeof(StopData),
                                DefaultUniformAlignment());

        pass.SetCommandLabel("LinearGradientSSBOFill");

        FS::BindFragInfo(
            pass, renderer.GetTransientsBuffer().EmplaceUniform(frag_info));
        FS::BindColorData(pass, color_buffer);

        return true;
      });
}

bool LinearGradientContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  for (Color& color : colors_) {
    color = color_filter_proc(color);
  }
  decal_border_color_ = color_filter_proc(decal_border_color_);
  return true;
}

}  // namespace impeller
