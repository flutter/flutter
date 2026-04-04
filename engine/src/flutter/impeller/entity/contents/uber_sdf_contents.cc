// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/uber_sdf_contents.h"

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

namespace {

constexpr Scalar kAntialiasPadding = 1.0f;

using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = UberSDFPipeline::VertexShader;
using FS = UberSDFPipeline::FragmentShader;

Join AdjustRectStrokeJoin(const StrokeParameters& stroke) {
  return (stroke.join == Join::kMiter && stroke.miter_limit < kSqrt2)
             ? Join::kBevel
             : stroke.join;
}

}  // namespace

std::unique_ptr<UberSDFContents> UberSDFContents::MakeRect(
    Color color,
    const Rect& rect,
    std::optional<StrokeParameters> stroke) {
  std::optional<StrokeParameters> adjusted_stroke =
      stroke ? std::make_optional(StrokeParameters(
                   {.width = stroke->width,
                    .join = AdjustRectStrokeJoin(stroke.value())}))
             : std::nullopt;
  auto stroke_padding = stroke ? stroke->width * 0.5f : 0.0f;
  std::unique_ptr<FillRectGeometry> geometry =
      std::make_unique<FillRectGeometry>(rect.Expand(stroke_padding));
  // Size is is the x and y extents from the center of the rect.
  Point size = Point(rect.GetSize() * 0.5f);
  return std::make_unique<UberSDFContents>(Type::kRect, color, rect.GetCenter(),
                                           size, adjusted_stroke,
                                           std::move(geometry));
}

std::unique_ptr<UberSDFContents> UberSDFContents::MakeCircle(
    Color color,
    const Point& center,
    Scalar radius,
    std::optional<StrokeParameters> stroke) {
  auto stroke_padding = stroke ? stroke->width * 0.5f : 0.0f;
  Rect geometry_rect = Rect::MakeXYWH(center.x - radius, center.y - radius,
                                      radius * 2, radius * 2);
  // Size x value is the radius of the circle, y value is ignored.
  Point size = Point(radius, 0.0f);
  std::unique_ptr<FillRectGeometry> geometry =
      std::make_unique<FillRectGeometry>(geometry_rect.Expand(stroke_padding));
  return std::make_unique<UberSDFContents>(Type::kCircle, color, center, size,
                                           stroke, std::move(geometry));
}

UberSDFContents::UberSDFContents(Type type,
                                 Color color,
                                 Point center,
                                 Point size,
                                 std::optional<StrokeParameters> stroke,
                                 std::unique_ptr<FillRectGeometry> geometry)
    : type_(type),
      color_(color),
      center_(center),
      size_(size),
      stroke_(stroke),
      geometry_(std::move(geometry)) {
  geometry_->SetAntialiasPadding(kAntialiasPadding);
}

UberSDFContents::~UberSDFContents() = default;

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info = {};
  frag_info.type = type_ == Type::kCircle ? 0.0f : 1.0f;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.center = center_;
  frag_info.size = size_;
  frag_info.stroked = stroke_ ? 1.0f : 0.0f;
  if (stroke_) {
    frag_info.stroke_width = stroke_->width;
    switch (stroke_->join) {
      case Join::kMiter:
        frag_info.stroke_join = 0.0f;
        break;
      case Join::kBevel:
        frag_info.stroke_join = 1.0f;
        break;
      case Join::kRound:
        frag_info.stroke_join = 2.0f;
        break;
    }
  }
  frag_info.aa_pixels = kAntialiasPadding;

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
      [&frag_info, &data_host_buffer](RenderPass& pass) {
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
  return color_;
}

bool UberSDFContents::ApplyColorFilter(
    const ColorFilterProc& color_filter_proc) {
  color_ = color_filter_proc(color_);
  return true;
}

}  // namespace impeller
