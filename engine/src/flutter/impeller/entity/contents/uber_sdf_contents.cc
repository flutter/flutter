// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_contents.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/gradient_generator.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

namespace {

using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

Scalar ToShaderType(UberSDFParameters::Type type) {
  switch (type) {
    case UberSDFParameters::Type::kCircle:
      return 0.0f;
    case UberSDFParameters::Type::kRect:
      return 1.0f;
    case UberSDFParameters::Type::kOval:
      return 2.0f;
    case UberSDFParameters::Type::kRoundedRect:
      return 3.0f;
    case UberSDFParameters::Type::kRoundedSuperellipseSymmetric:
      return 4.0f;
  }
}

Scalar ToShaderStrokeJoin(Join join) {
  switch (join) {
    case Join::kMiter:
      return 0.0f;
    case Join::kBevel:
      return 1.0f;
    case Join::kRound:
      return 2.0f;
  }
}

Scalar ToShaderColorSourceType(const UberSDFParameters& params) {
  if (!params.gradient.has_value()) {
    return 0.0f;
  }
  switch (params.gradient->type) {
    case UberSDFParameters::GradientParameters::Type::kLinear:
      return 1.0f;
    case UberSDFParameters::GradientParameters::Type::kRadial:
      return 2.0f;
  }
}

struct SamplerBinding {
  std::shared_ptr<Texture> texture;
  raw_ptr<const Sampler> sampler;
};

/// @brief  Populates the gradient uniforms shared by both UberSDF variants.
template <typename FragInfo>
void SetupCommonGradientParameters(
    const UberSDFParameters::GradientParameters& gradient,
    FragInfo& frag_info) {
  frag_info.tile_mode = static_cast<Scalar>(gradient.tile_mode);
  if (gradient.type == UberSDFParameters::GradientParameters::Type::kLinear) {
    Point delta = gradient.end - gradient.start;
    Scalar length_sq = delta.x * delta.x + delta.y * delta.y;
    frag_info.gradient_coords =
        Vector4(gradient.start.x, gradient.start.y, delta.x, delta.y);
    frag_info.inv_gradient_length = length_sq > 0.0f ? 1.0f / length_sq : 0.0f;
  } else {
    frag_info.gradient_coords =
        Vector4(gradient.start.x, gradient.start.y, 0.0f, 0.0f);
    frag_info.inv_gradient_length =
        gradient.end.x > 0.0f ? 1.0f / gradient.end.x : 0.0f;
  }
}

/// @brief  Populates the `frag_info` fields shared by both UberSDF variants.
template <typename FragInfo>
void SetupCommonFragInfo(const UberSDFParameters& params,
                         Scalar opacity,
                         const Entity& entity,
                         FragInfo& frag_info) {
  frag_info.type = ToShaderType(params.type);
  frag_info.color_source_type = ToShaderColorSourceType(params);
  frag_info.color = params.color.WithAlpha(params.color.alpha * opacity);
  frag_info.center = params.center;
  frag_info.size = params.size;
  Vector2 pixel_size = entity.GetTransform().GetTransformedPixelSize();
  frag_info.pixel_size = Point(pixel_size.x, pixel_size.y);
  frag_info.stroked = params.stroke ? 1.0f : 0.0f;
  frag_info.stroke_width = params.stroke ? params.stroke->width : 0.0f;
  frag_info.stroke_join =
      params.stroke ? ToShaderStrokeJoin(params.stroke->join) : 0.0f;
  frag_info.aa_pixels = UberSDFParameters::kAntialiasPixels;
  frag_info.superellipse_degree = params.superellipse_degree;
  frag_info.angle_span = params.angle_span;
  frag_info.circle_center_top = params.circle_center_top;
  frag_info.circle_center_right = params.circle_center_right;
  frag_info.radii = params.radii;

  // Gradient parameter defaults; overwritten if there is a gradient.
  frag_info.gradient_coords = Vector4();
  frag_info.half_texel = 0.0f;
  frag_info.tile_mode = 0.0f;
  frag_info.inv_gradient_length = 0.0f;
  frag_info.colors_length = 0.0f;

  if (params.gradient) {
    SetupCommonGradientParameters(params.gradient.value(), frag_info);
  }
}

}  // namespace

std::unique_ptr<UberSDFContents> UberSDFContents::Make(
    const UberSDFParameters& params,
    std::unique_ptr<Geometry> geometry) {
  return std::unique_ptr<UberSDFContents>(
      new UberSDFContents(params, std::move(geometry)));
}

UberSDFContents::UberSDFContents(const UberSDFParameters& params,
                                 std::unique_ptr<Geometry> geometry)
    : params_(params), geometry_(std::move(geometry)) {}

UberSDFContents::~UberSDFContents() = default;

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  if (renderer.GetDeviceCapabilities().SupportsSSBO()) {
    return RenderSSBO(renderer, entity, pass);
  }
  return RenderTexture(renderer, entity, pass);
}

bool UberSDFContents::RenderTexture(const ContentContext& renderer,
                                    const Entity& entity,
                                    RenderPass& pass) const {
  using VS = UberSDFPipeline::VertexShader;
  using FS = UberSDFPipeline::FragmentShader;

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  SetupCommonFragInfo(params_, GetOpacityFactor(), entity, frag_info);

  SamplerBinding sampler_binding;
  if (params_.gradient) {
    FML_DCHECK(params_.gradient->texture);
    auto texture_size = params_.gradient->texture->GetSize();
    FML_DCHECK(!texture_size.IsEmpty());
    frag_info.half_texel = 0.5f / texture_size.width;

    SamplerDescriptor sampler_desc;
    sampler_desc.min_filter = MinMagFilter::kLinear;
    sampler_desc.mag_filter = MinMagFilter::kLinear;
    sampler_binding.texture = params_.gradient->texture;
    sampler_binding.sampler =
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc);
  } else {
    sampler_binding.texture = renderer.GetEmptyTexture();
    sampler_binding.sampler =
        renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
  }

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetUberSDFPipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, GetGeometry(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer, &sampler_binding](RenderPass& pass) {
        FS::BindColorSourceSampler(pass, sampler_binding.texture,
                                   sampler_binding.sampler);
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("UberSDF");
        return true;
      });
}

bool UberSDFContents::RenderSSBO(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  using VS = UberSDFSSBOPipeline::VertexShader;
  using FS = UberSDFSSBOPipeline::FragmentShader;

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  SetupCommonFragInfo(params_, GetOpacityFactor(), entity, frag_info);

  std::vector<StopData> color_stops;
  if (params_.gradient) {
    color_stops =
        CreateGradientColors(params_.gradient->colors, params_.gradient->stops);
  } else {
    // The bound ColorData is required to be non-empty to be valid. This entry
    // is unused in the shader.
    color_stops.resize(1);
  }
  FML_DCHECK(!color_stops.empty());
  frag_info.colors_length = static_cast<Scalar>(color_stops.size());

  BufferView color_buffer = data_host_buffer.Emplace(
      color_stops.data(), color_stops.size() * sizeof(StopData),
      renderer.GetDeviceCapabilities().GetMinimumStorageBufferAlignment());

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetUberSDFSSBOPipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, GetGeometry(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer, &color_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        FS::BindColorData(pass, color_buffer);
        pass.SetCommandLabel("UberSDFSSBO");
        return true;
      });
}

std::optional<Rect> UberSDFContents::GetCoverage(const Entity& entity) const {
  return GetGeometry()->GetCoverage(entity.GetTransform());
}

const Geometry* UberSDFContents::GetGeometry() const {
  return geometry_.get();
}

Color UberSDFContents::GetColor() const {
  return params_.color;
}

bool UberSDFContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  if (params_.gradient.has_value()) {
    return false;
  }
  params_.color = color_filter_proc(params_.color);
  return true;
}

std::optional<Color> UberSDFContents::AsBackgroundColor(
    const Entity& entity,
    ISize target_size) const {
  if (params_.type != UberSDFParameters::Type::kRect ||
      params_.gradient.has_value()) {
    return std::nullopt;
  }
  const Geometry* geometry = GetGeometry();
  if (geometry == nullptr) {
    return std::nullopt;
  }
  IRect target_rect = IRect::MakeSize(target_size);
  return geometry->CoversArea(entity.GetTransform(), target_rect)
             ? GetColor()
             : std::optional<Color>();
}

}  // namespace impeller
