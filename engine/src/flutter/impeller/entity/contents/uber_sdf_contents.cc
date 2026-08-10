// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_contents.h"

#include "fml/logging.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/contents/uber_sdf_parameters.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

namespace {

using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = UberSDFPipeline::VertexShader;
using FS = UberSDFPipeline::FragmentShader;

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

/// @brief  Populates the gradient uniform fields in `frag_info` and returns
///         the texture and sampler for the gradient.
SamplerBinding SetupGradientParameters(
    const UberSDFParameters::GradientParameters& gradient,
    const ContentContext& renderer,
    FS::FragInfo& frag_info) {
  FML_DCHECK(gradient.texture);
  frag_info.gradient_start = gradient.start;
  frag_info.gradient_end = gradient.end;
  frag_info.tile_mode = static_cast<Scalar>(gradient.tile_mode);
  auto texture_size = gradient.texture->GetSize();
  FML_DCHECK(!texture_size.IsEmpty());
  frag_info.half_texel =
      Point(0.5f, 0.5f) / Point(texture_size.width, texture_size.height);

  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;
  raw_ptr<const Sampler> sampler =
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc);

  return {gradient.texture, sampler};
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
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.type = ToShaderType(params_.type);
  frag_info.color_source_type = ToShaderColorSourceType(params_);
  frag_info.color =
      params_.color.WithAlpha(params_.color.alpha * GetOpacityFactor());
  frag_info.center = params_.center;
  frag_info.size = params_.size;
  frag_info.stroked = params_.stroke ? 1.0f : 0.0f;
  frag_info.stroke_width = params_.stroke ? params_.stroke->width : 0.0f;
  frag_info.stroke_join =
      params_.stroke ? ToShaderStrokeJoin(params_.stroke->join) : 0.0f;
  frag_info.aa_pixels = UberSDFParameters::kAntialiasPixels;
  frag_info.superellipse_degree = params_.superellipse_degree;
  frag_info.superellipse_semi_axis = params_.superellipse_semi_axis;
  frag_info.angle_span = params_.angle_span;
  frag_info.octant_offset_c = params_.octant_offset_c;
  frag_info.circle_center_top = params_.circle_center_top;
  frag_info.circle_center_right = params_.circle_center_right;
  frag_info.superellipse_scale = params_.superellipse_scale;
  frag_info.radii = params_.radii;

  SamplerBinding sampler_binding;
  if (params_.gradient) {
    sampler_binding =
        SetupGradientParameters(params_.gradient.value(), renderer, frag_info);
  } else {
    sampler_binding.texture = renderer.GetEmptyTexture();
    sampler_binding.sampler =
        renderer.GetContext()->GetSamplerLibrary()->GetSampler({});
  }

  auto geometry_result =
      GetGeometry()->GetPositionBuffer(renderer, entity, pass);

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetUberSDFPipeline(options);
      };

  return ColorSourceContents::DrawGeometry<VS>(
      this, GetGeometry(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &data_host_buffer,
       sampler_binding = std::move(sampler_binding)](RenderPass& pass) {
        FS::BindColorSourceSampler(pass, sampler_binding.texture,
                                   sampler_binding.sampler);
        FS::BindFragInfo(pass, data_host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("UberSDF");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/
      [geometry_result = std::move(geometry_result)](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass,
          const Geometry* geometry) { return geometry_result; });
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
