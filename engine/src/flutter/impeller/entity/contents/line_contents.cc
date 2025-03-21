// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/line_contents.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/renderer/texture_util.h"

namespace impeller {

using VS = LinePipeline::VertexShader;
using FS = LinePipeline::FragmentShader;

namespace {
using BindFragmentCallback = std::function<bool(RenderPass& pass)>;
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;
using CreateGeometryCallback =
    std::function<GeometryResult(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass,
                                 const Geometry* geometry)>;

const int32_t kCurveResolution = 32;
const Scalar kSampleRadius = 0.5f;

struct LineInfo {
  Vector3 e0;
  Vector3 e1;
  Vector3 e2;
  Vector3 e3;
};

LineInfo CalculateLineInfo(Point p0, Point p1, Scalar width, Scalar radius) {
  Vector2 diff = p0 - p1;
  float k = 2.0 / ((2.0 * radius + width) * sqrt(diff.Dot(diff)));

  return LineInfo{
      .e0 = Vector3(k * (p0.y - p1.y),  //
                    k * (p1.x - p0.x),  //
                    1.0 + k * (p0.x * p1.y - p1.x * p0.y)),
      .e1 = Vector3(
          k * (p1.x - p0.x),  //
          k * (p1.y - p0.y),  //
          1.0 + k * (p0.x * p0.x + p0.y * p0.y - p0.x * p1.x - p0.y * p1.y)),
      .e2 = Vector3(k * (p1.y - p0.y),  //
                    k * (p0.x - p1.x),  //
                    1.0 + k * (p1.x * p0.y - p0.x * p1.y)),
      .e3 = Vector3(
          k * (p0.x - p1.x),  //
          k * (p0.y - p1.y),  //
          1.0 + k * (p1.x * p1.x + p1.y * p1.y - p0.x * p1.x - p0.y * p1.y)),
  };
}

uint8_t DoubleToUint8(double x) {
  return static_cast<uint8_t>(std::clamp(std::round(x * 255.0), 0.0, 255.0));
}

/// See also: CreateGradientTexture
std::shared_ptr<Texture> CreateCurveTexture(
    Scalar width,
    const std::shared_ptr<impeller::Context>& context) {
  //
  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR8UNormInt;
  texture_descriptor.size = {kCurveResolution, 1};

  std::vector<uint8_t> curve_data;
  curve_data.reserve(kCurveResolution);
  for (int i = 0; i < kCurveResolution; ++i) {
    double norm = (static_cast<double>(i) + 1.0) / 32.0;
    double loc = norm * (kSampleRadius + width / 2.0);
    double den = kSampleRadius * 2.0 + 1.0;
    curve_data.push_back(DoubleToUint8(loc / den));
  }

  return CreateTexture(texture_descriptor, curve_data, context, "LineCurve");
}

GeometryResult CreateGeometry(const ContentContext& renderer,
                              const Entity& entity,
                              RenderPass& pass,
                              const Geometry* geometry) {
  using PerVertexData = LineVertexShader::PerVertexData;
  const LineGeometry* line_geometry =
      static_cast<const LineGeometry*>(geometry);

  auto& transform = entity.GetTransform();

  Point corners[4];
  if (!LineGeometry::ComputeCorners(
          corners, transform,
          /*extend_endpoints=*/line_geometry->GetCap() != Cap::kButt,
          line_geometry->GetP0(), line_geometry->GetP1(),
          line_geometry->GetWidth() + kSampleRadius)) {
    return kEmptyResult;
  }

  auto& host_buffer = renderer.GetTransientsBuffer();

  size_t count = 4;
  LineInfo line_info =
      CalculateLineInfo(line_geometry->GetP0(), line_geometry->GetP1(),
                        line_geometry->GetWidth(), kSampleRadius);
  BufferView vertex_buffer = host_buffer.Emplace(
      count * sizeof(PerVertexData), alignof(PerVertexData),
      [&corners, &line_info](uint8_t* buffer) {
        auto vertices = reinterpret_cast<PerVertexData*>(buffer);
        for (auto& corner : corners) {
          *vertices++ = {
              .position = corner,
              .e0 = line_info.e0,
              .e1 = line_info.e1,
              .e2 = line_info.e2,
              .e3 = line_info.e3,
          };
        }
      });

  std::shared_ptr<Texture> curve_texture =
      CreateCurveTexture(line_geometry->GetWidth(), renderer.GetContext());

  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;

  FS::BindCurve(
      pass, curve_texture,
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc));

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = vertex_buffer,
              .vertex_count = count,
              .index_type = IndexType::kNone,
          },
      .transform = entity.GetShaderTransform(pass),
  };
}
}  // namespace

std::unique_ptr<LineContents> LineContents::Make(
    std::unique_ptr<LineGeometry> geometry,
    Color color) {
  return std::unique_ptr<LineContents>(
      new LineContents(std::move(geometry), color));
}

LineContents::LineContents(std::unique_ptr<LineGeometry> geometry, Color color)
    : geometry_(std::move(geometry)), color_(color) {}

bool LineContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  auto& host_buffer = renderer.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.Premultiply();

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetLinePipeline(options);
      };
  return ColorSourceContents::DrawGeometry<VS>(
      this, geometry_.get(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/
      [&frag_info, &host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("Line");
        return true;
      },
      /*force_stencil=*/false,
      /*create_geom_callback=*/CreateGeometry);
}

std::optional<Rect> LineContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

}  // namespace impeller
