#include "impeller/entity/contents/uber_sdf_contents.h"

#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

namespace {
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;

using VS = UberSDFPipeline::VertexShader;
using FS = UberSDFPipeline::FragmentShader;

Scalar kAntialiasPixels = 1.0;
}  // namespace

std::unique_ptr<UberSDFContents> UberSDFContents::MakeRect(
    Rect rect,
    Color color,
    Scalar stroke_width,
    bool stroked,
    std::unique_ptr<FillRectGeometry> geometry) {
  return std::unique_ptr<UberSDFContents>(new UberSDFContents(
      Type::kRect, rect, color, stroke_width, stroked, std::move(geometry)));
}

std::unique_ptr<UberSDFContents> UberSDFContents::MakeCircle(
    Rect rect,
    Color color,
    Scalar stroke_width,
    bool stroked,
    std::unique_ptr<CircleGeometry> geometry) {
  return std::unique_ptr<UberSDFContents>(new UberSDFContents(
      Type::kCircle, rect, color, stroke_width, stroked, std::move(geometry)));
}

UberSDFContents::UberSDFContents(Type type,
                                 Rect rect,
                                 Color color,
                                 Scalar stroke_width,
                                 bool stroked,
                                 std::unique_ptr<Geometry> geometry)
    : type_(type),
      rect_(rect),
      color_(color),
      stroke_width_(stroke_width),
      stroked_(stroked),
      geometry_(std::move(geometry)) {}

UberSDFContents::~UberSDFContents() = default;

bool UberSDFContents::Render(const ContentContext& renderer,
                             const Entity& entity,
                             RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color = color_.WithAlpha(color_.alpha * GetOpacityFactor());
  frag_info.center = rect_.GetCenter();
  frag_info.size = Point(rect_.GetWidth() / 2.0f, rect_.GetHeight() / 2.0f);
  frag_info.stroke_width = stroke_width_;
  frag_info.aa_pixels = kAntialiasPixels;
  frag_info.stroked = stroked_ ? 1.0f : 0.0f;
  frag_info.type = type_ == Type::kCircle ? 0.0f : 1.0f;

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
