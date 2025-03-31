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

uint8_t DoubleToUint8(double x) {
  return static_cast<uint8_t>(std::clamp(std::round(x * 255.0), 0.0, 255.0));
}

/// See also: CreateGradientTexture
std::shared_ptr<Texture> CreateCurveTexture(
    Scalar width,
    Scalar radius,
    Scalar scale,
    const std::shared_ptr<impeller::Context>& context) {
  //
  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR8UNormInt;
  texture_descriptor.size = {kCurveResolution, 1};

  std::vector<uint8_t> curve_data =
      LineContents::CreateCurveData(width, radius, scale);

  return CreateTexture(texture_descriptor, curve_data, context, "LineCurve");
}

std::pair<LineContents::EffectiveLineParameters, GeometryResult> CreateGeometry(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass,
    const Geometry* geometry) {
  using PerVertexData = LineVertexShader::PerVertexData;
  const LineGeometry* line_geometry =
      static_cast<const LineGeometry*>(geometry);

  auto& transform = entity.GetTransform();
  auto& host_buffer = renderer.GetTransientsBuffer();

  size_t count = 4;
  fml::StatusOr<LineContents::EffectiveLineParameters> calculate_status =
      LineContents::EffectiveLineParameters{.width = 0, .radius = 0};
  BufferView vertex_buffer = host_buffer.Emplace(
      count * sizeof(PerVertexData), alignof(PerVertexData),
      [line_geometry, &transform, &calculate_status](uint8_t* buffer) {
        auto vertices = reinterpret_cast<PerVertexData*>(buffer);
        calculate_status = LineContents::CalculatePerVertex(
            vertices, line_geometry, transform);
      });
  if (!calculate_status.ok()) {
    return std::make_pair(
        LineContents::EffectiveLineParameters{
            .width = line_geometry->GetWidth(),
            .radius = LineContents::kSampleRadius},
        kEmptyResult);
  }

  // We do the math in CalculatePerVertex in unrotated space.  This then applies
  // the rotation to the line.
  Point diff = line_geometry->GetP1() - line_geometry->GetP0();
  Scalar angle = std::atan2(diff.y, diff.x);
  Entity rotated_entity = entity.Clone();
  Matrix matrix = entity.GetTransform();
  matrix = matrix * Matrix::MakeTranslation(line_geometry->GetP0()) *
           Matrix::MakeRotationZ(Radians(angle)) *
           Matrix::MakeTranslation(-1 * line_geometry->GetP0());
  rotated_entity.SetTransform(matrix);

  return std::make_pair(
      calculate_status.value(),
      GeometryResult{
          .type = PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              {
                  .vertex_buffer = vertex_buffer,
                  .vertex_count = count,
                  .index_type = IndexType::kNone,
              },
          .transform = rotated_entity.GetShaderTransform(pass),
      });
}

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
}  // namespace

const Scalar LineContents::kSampleRadius = 1.f;

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
  frag_info.color = color_;

  Scalar scale = entity.GetTransform().GetMaxBasisLengthXY();

  auto geometry_result =
      CreateGeometry(renderer, entity, pass, geometry_.get());

  std::shared_ptr<Texture> curve_texture = CreateCurveTexture(
      geometry_->GetWidth(), kSampleRadius, scale, renderer.GetContext());

  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = MinMagFilter::kLinear;
  sampler_desc.mag_filter = MinMagFilter::kLinear;

  FS::BindCurve(
      pass, curve_texture,
      renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc));

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
      /*create_geom_callback=*/
      [geometry_result = std::move(geometry_result)](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass,
          const Geometry* geometry) { return geometry_result.second; });
}

std::optional<Rect> LineContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

std::vector<uint8_t> LineContents::CreateCurveData(Scalar width,
                                                   Scalar radius,
                                                   Scalar scale) {
  std::vector<uint8_t> curve_data;
  curve_data.reserve(kCurveResolution);
  // More simply written as rise / run:
  // double slope = 1.0 / ((radius * 2) / (scale * width + radius));
  double slope = (scale * width + radius) / (radius * 2);
  for (int i = 0; i < kCurveResolution; ++i) {
    double norm =
        (static_cast<double>(i)) / static_cast<double>(kCurveResolution - 1);
    double scaled = slope * norm;
    curve_data.push_back(DoubleToUint8(scaled));
  }
  return curve_data;
}

namespace {
void ExpandLine(std::array<Point, 4>& corners, Point expansion) {
  Point along = (corners[1] - corners[0]).Normalize();
  Point across = (corners[2] - corners[0]).Normalize();
  corners[0] += -1 * (across * expansion.x) + -1 * (along * expansion.y);
  corners[1] += -1 * (across * expansion.x) + (along * expansion.y);
  corners[2] += (across * expansion.x) + -1 * (along * expansion.y);
  corners[3] += (across * expansion.x) + (along * expansion.y);
}
}  // namespace

fml::StatusOr<LineContents::EffectiveLineParameters>
LineContents::CalculatePerVertex(LineVertexShader::PerVertexData* per_vertex,
                                 const LineGeometry* geometry,
                                 const Matrix& entity_transform) {
  Scalar scale = entity_transform.GetMaxBasisLengthXY();

  // Transform the line into unrotated space by rotating p1 to be horizontal
  // with p0. We do this because there seems to be a flaw in the eN calculations
  // where they create thinner lines for diagonal lines.
  Point diff = geometry->GetP1() - geometry->GetP0();
  Scalar magnitude = diff.GetLength();
  Point p1_prime = Point(geometry->GetP0().x + magnitude, geometry->GetP0().y);

  std::array<Point, 4> corners;
  // Make sure we get kSampleRadius pixels to sample from.
  Scalar expand_size = std::max(kSampleRadius / scale, kSampleRadius);
  if (!LineGeometry::ComputeCorners(
          corners.data(), entity_transform,
          /*extend_endpoints=*/geometry->GetCap() != Cap::kButt,
          geometry->GetP0(), p1_prime, geometry->GetWidth())) {
    return fml::Status(fml::StatusCode::kAborted, "No valid corners");
  }
  Scalar effective_line_width = std::fabsf((corners[2] - corners[0]).y);
  ExpandLine(corners, Point(expand_size, expand_size));
  Scalar padded_line_width = std::fabsf((corners[2] - corners[0]).y);
  Scalar effective_sample_radius =
      (padded_line_width - effective_line_width) / 2.f;
  LineInfo line_info =
      CalculateLineInfo(geometry->GetP0(), p1_prime, effective_line_width,
                        effective_sample_radius);
  for (auto& corner : corners) {
    *per_vertex++ = {
        .position = corner,
        .e0 = line_info.e0,
        .e1 = line_info.e1,
        .e2 = line_info.e2,
        .e3 = line_info.e3,
    };
  }

  return EffectiveLineParameters{.width = effective_line_width,
                                 .radius = effective_sample_radius};
}
}  // namespace impeller
