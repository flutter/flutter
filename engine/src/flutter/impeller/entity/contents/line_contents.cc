// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/line_contents.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

namespace {
using BindFragmentCallback = std::function<bool(RenderPass& pass)>;
using PipelineBuilderCallback =
    std::function<PipelineRef(ContentContextOptions)>;
using CreateGeometryCallback =
    std::function<GeometryResult(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass,
                                 const Geometry* geom)>;

GeometryResult DefaultCreateGeometryCallback(const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass,
                                             const Geometry* geom) {
  return geom->GetPositionBuffer(renderer, entity, pass);
}

template <typename VertexShaderT>
bool DrawGeometry(const Contents* contents,
                  const Geometry* geometry,
                  const ContentContext& renderer,
                  const Entity& entity,
                  RenderPass& pass,
                  const PipelineBuilderCallback& pipeline_callback,
                  typename VertexShaderT::FrameInfo frame_info,
                  const BindFragmentCallback& bind_fragment_callback,
                  bool force_stencil = false,
                  const CreateGeometryCallback& create_geom_callback =
                      DefaultCreateGeometryCallback) {
  auto options = OptionsFromPassAndEntity(pass, entity);

  GeometryResult::Mode geometry_mode = geometry->GetResultMode();
  bool do_cover_draw = false;
  Rect cover_area = {};

  bool is_stencil_then_cover =
      geometry_mode == GeometryResult::Mode::kNonZero ||
      geometry_mode == GeometryResult::Mode::kEvenOdd;
  if (!is_stencil_then_cover && force_stencil) {
    geometry_mode = GeometryResult::Mode::kNonZero;
    is_stencil_then_cover = true;
  }

  if (is_stencil_then_cover) {
    pass.SetStencilReference(0);

    /// Stencil preparation draw.

    GeometryResult stencil_geometry_result =
        geometry->GetPositionBuffer(renderer, entity, pass);
    if (stencil_geometry_result.vertex_buffer.vertex_count == 0u) {
      return true;
    }
    pass.SetVertexBuffer(std::move(stencil_geometry_result.vertex_buffer));
    options.primitive_type = stencil_geometry_result.type;

    options.blend_mode = BlendMode::kDestination;
    switch (stencil_geometry_result.mode) {
      case GeometryResult::Mode::kNonZero:
        pass.SetCommandLabel("Stencil preparation (NonZero)");
        options.stencil_mode =
            ContentContextOptions::StencilMode::kStencilNonZeroFill;
        break;
      case GeometryResult::Mode::kEvenOdd:
        pass.SetCommandLabel("Stencil preparation (EvenOdd)");
        options.stencil_mode =
            ContentContextOptions::StencilMode::kStencilEvenOddFill;
        break;
      default:
        if (force_stencil) {
          pass.SetCommandLabel("Stencil preparation (NonZero)");
          options.stencil_mode =
              ContentContextOptions::StencilMode::kStencilNonZeroFill;
          break;
        }
        FML_UNREACHABLE();
    }
    pass.SetPipeline(renderer.GetClipPipeline(options));
    ClipPipeline::VertexShader::FrameInfo clip_frame_info;
    clip_frame_info.depth = entity.GetShaderClipDepth();
    clip_frame_info.mvp = stencil_geometry_result.transform;
    ClipPipeline::VertexShader::BindFrameInfo(
        pass, renderer.GetTransientsBuffer().EmplaceUniform(clip_frame_info));

    if (!pass.Draw().ok()) {
      return false;
    }

    /// Cover draw.

    options.blend_mode = entity.GetBlendMode();
    options.stencil_mode = ContentContextOptions::StencilMode::kCoverCompare;
    std::optional<Rect> maybe_cover_area = geometry->GetCoverage({});
    if (!maybe_cover_area.has_value()) {
      return true;
    }
    do_cover_draw = true;
    cover_area = maybe_cover_area.value();
  }

  GeometryResult geometry_result;
  if (do_cover_draw) {
    RectGeometry geom(cover_area);
    geometry_result = create_geom_callback(renderer, entity, pass, &geom);
  } else {
    geometry_result = create_geom_callback(renderer, entity, pass, geometry);
  }

  if (geometry_result.vertex_buffer.vertex_count == 0u) {
    return true;
  }
  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));
  options.primitive_type = geometry_result.type;

  // Enable depth writing for all opaque entities in order to allow
  // reordering. Opaque entities are coerced to source blending by
  // `EntityPass::AddEntity`.
  options.depth_write_enabled = options.blend_mode == BlendMode::kSource;

  // Take the pre-populated vertex shader uniform struct and set managed
  // values.
  frame_info.mvp = geometry_result.transform;

  // If overdraw prevention is enabled (like when drawing stroke paths), we
  // increment the stencil buffer as we draw, preventing overlapping fragments
  // from drawing. Afterwards, we need to append another draw call to clean up
  // the stencil buffer (happens below in this method). This can be skipped
  // for draws that are fully opaque or use src blend mode.
  if (geometry_result.mode == GeometryResult::Mode::kPreventOverdraw &&
      options.blend_mode != BlendMode::kSource) {
    options.stencil_mode =
        ContentContextOptions::StencilMode::kOverdrawPreventionIncrement;
  }
  pass.SetStencilReference(0);

  VertexShaderT::BindFrameInfo(
      pass, renderer.GetTransientsBuffer().EmplaceUniform(frame_info));

  // The reason we need to have a callback mechanism here is that this routine
  // may insert draw calls before the main draw call below. For example, for
  // sufficiently complex paths we may opt to use stencil-then-cover to avoid
  // tessellation.
  if (!bind_fragment_callback(pass)) {
    return false;
  }

  pass.SetPipeline(pipeline_callback(options));

  if (!pass.Draw().ok()) {
    return false;
  }

  // If we performed overdraw prevention, a subsection of the clip heightmap
  // was incremented by 1 in order to self-clip. So simply append a clip
  // restore to clean it up.
  if (geometry_result.mode == GeometryResult::Mode::kPreventOverdraw &&
      options.blend_mode != BlendMode::kSource) {
    return RenderClipRestore(renderer, pass, entity.GetClipDepth(),
                             contents->GetCoverage(entity));
  }
  return true;
}
}  // namespace

std::unique_ptr<LineContents> LineContents::Make(
    std::unique_ptr<LineGeometry> geometry) {
  return std::unique_ptr<LineContents>(new LineContents(std::move(geometry)));
}

LineContents::LineContents(std::unique_ptr<LineGeometry> geometry)
    : geometry_(std::move(geometry)) {}

bool LineContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  using VS = LinePipeline::VertexShader;
  using FS = LinePipeline::FragmentShader;

  auto& host_buffer = renderer.GetTransientsBuffer();

  VS::FrameInfo frame_info;
  FS::FragInfo frag_info;
  frag_info.color =
      Color(/*r=*/1.0, /*g=*/0.0, /*b=*/0.0, /*a=*/1.0).Premultiply();

  PipelineBuilderCallback pipeline_callback =
      [&renderer](ContentContextOptions options) {
        return renderer.GetLinePipeline(options);
      };
  return DrawGeometry<VS>(
      this, geometry_.get(), renderer, entity, pass, pipeline_callback,
      frame_info,
      /*bind_fragment_callback=*/[&frag_info, &host_buffer](RenderPass& pass) {
        FS::BindFragInfo(pass, host_buffer.EmplaceUniform(frag_info));
        pass.SetCommandLabel("Line");
        return true;
      });
}

std::optional<Rect> LineContents::GetCoverage(const Entity& entity) const {
  return geometry_->GetCoverage(entity.GetTransform());
}

}  // namespace impeller
