// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/scene_update_context.h"

#include <lib/ui/scenic/cpp/view_token_pair.h>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/matrix_decomposition.h"
#include "flutter/flow/view_holder.h"
#include "flutter/fml/trace_event.h"
#include "include/core/SkColor.h"

namespace flutter {

// Helper function to generate clip planes for a scenic::EntityNode.
static void SetEntityNodeClipPlanes(scenic::EntityNode& entity_node,
                                    const SkRect& bounds) {
  const float top = bounds.top();
  const float bottom = bounds.bottom();
  const float left = bounds.left();
  const float right = bounds.right();

  // We will generate 4 oriented planes, one for each edge of the bounding rect.
  std::vector<fuchsia::ui::gfx::Plane3> clip_planes;
  clip_planes.resize(4);

  // Top plane.
  clip_planes[0].dist = top;
  clip_planes[0].dir.x = 0.f;
  clip_planes[0].dir.y = 1.f;
  clip_planes[0].dir.z = 0.f;

  // Bottom plane.
  clip_planes[1].dist = -bottom;
  clip_planes[1].dir.x = 0.f;
  clip_planes[1].dir.y = -1.f;
  clip_planes[1].dir.z = 0.f;

  // Left plane.
  clip_planes[2].dist = left;
  clip_planes[2].dir.x = 1.f;
  clip_planes[2].dir.y = 0.f;
  clip_planes[2].dir.z = 0.f;

  // Right plane.
  clip_planes[3].dist = -right;
  clip_planes[3].dir.x = -1.f;
  clip_planes[3].dir.y = 0.f;
  clip_planes[3].dir.z = 0.f;

  entity_node.SetClipPlanes(std::move(clip_planes));
}

SceneUpdateContext::SceneUpdateContext(scenic::Session* session,
                                       SurfaceProducer* surface_producer)
    : session_(session), surface_producer_(surface_producer) {
  FML_DCHECK(surface_producer_ != nullptr);
}

void SceneUpdateContext::CreateFrame(scenic::EntityNode entity_node,
                                     const SkRRect& rrect,
                                     SkColor color,
                                     SkAlpha opacity,
                                     const SkRect& paint_bounds,
                                     std::vector<Layer*> paint_layers,
                                     Layer* layer) {
  FML_DCHECK(!rrect.isEmpty());

  // Frames always clip their children.
  SkRect shape_bounds = rrect.getBounds();
  SetEntityNodeClipPlanes(entity_node, shape_bounds);

  // and possibly for its texture.
  // TODO(SCN-137): Need to be able to express the radii as vectors.
  scenic::ShapeNode shape_node(session());
  scenic::Rectangle shape(session_,       // session
                          rrect.width(),  // width
                          rrect.height()  // height
  );
  shape_node.SetShape(shape);
  shape_node.SetTranslation(shape_bounds.width() * 0.5f + shape_bounds.left(),
                            shape_bounds.height() * 0.5f + shape_bounds.top(),
                            0.f);

  // Check whether the painted layers will be visible.
  if (paint_bounds.isEmpty() || !paint_bounds.intersects(shape_bounds))
    paint_layers.clear();

  scenic::Material material(session());
  shape_node.SetMaterial(material);
  entity_node.AddChild(shape_node);

  // Check whether a solid color will suffice.
  if (paint_layers.empty()) {
    SetMaterialColor(material, color, opacity);
  } else {
    // Apply current metrics and transformation scale factors.
    const float scale_x = ScaleX();
    const float scale_y = ScaleY();

    // Apply a texture to the whole shape.
    SetMaterialTextureAndColor(material, color, opacity, scale_x, scale_y,
                               shape_bounds, std::move(paint_layers), layer,
                               std::move(entity_node));
  }
}

void SceneUpdateContext::SetMaterialTextureAndColor(
    scenic::Material& material,
    SkColor color,
    SkAlpha opacity,
    SkScalar scale_x,
    SkScalar scale_y,
    const SkRect& paint_bounds,
    std::vector<Layer*> paint_layers,
    Layer* layer,
    scenic::EntityNode entity_node) {
  scenic::Image* image = GenerateImageIfNeeded(
      color, scale_x, scale_y, paint_bounds, std::move(paint_layers), layer,
      std::move(entity_node));

  if (image != nullptr) {
    // The final shape's color is material_color * texture_color.  The passed in
    // material color was already used as a background when generating the
    // texture, so set the model color to |SK_ColorWHITE| in order to allow
    // using the texture's color unmodified.
    SetMaterialColor(material, SK_ColorWHITE, opacity);
    material.SetTexture(*image);
  } else {
    // No texture was needed, so apply a solid color to the whole shape.
    SetMaterialColor(material, color, opacity);
  }
}

void SceneUpdateContext::SetMaterialColor(scenic::Material& material,
                                          SkColor color,
                                          SkAlpha opacity) {
  const SkAlpha color_alpha = static_cast<SkAlpha>(
      ((float)SkColorGetA(color) * (float)opacity) / 255.0f);
  material.SetColor(SkColorGetR(color), SkColorGetG(color), SkColorGetB(color),
                    color_alpha);
}

scenic::Image* SceneUpdateContext::GenerateImageIfNeeded(
    SkColor color,
    SkScalar scale_x,
    SkScalar scale_y,
    const SkRect& paint_bounds,
    std::vector<Layer*> paint_layers,
    Layer* layer,
    scenic::EntityNode entity_node) {
  // Bail if there's nothing to paint.
  if (paint_layers.empty())
    return nullptr;

  // Bail if the physical bounds are empty after rounding.
  SkISize physical_size = SkISize::Make(paint_bounds.width() * scale_x,
                                        paint_bounds.height() * scale_y);
  if (physical_size.isEmpty())
    return nullptr;

  // Acquire a surface from the surface producer and register the paint tasks.
  std::unique_ptr<SurfaceProducerSurface> surface =
      surface_producer_->ProduceSurface(
          physical_size,
          LayerRasterCacheKey(
              // Root frame has a nullptr layer
              layer ? layer->unique_id() : 0, Matrix()),
          std::make_unique<scenic::EntityNode>(std::move(entity_node)));

  if (!surface) {
    FML_LOG(ERROR) << "Could not acquire a surface from the surface producer "
                      "of size: "
                   << physical_size.width() << "x" << physical_size.height();
    return nullptr;
  }

  auto image = surface->GetImage();

  // Enqueue the paint task.
  paint_tasks_.push_back({.surface = std::move(surface),
                          .left = paint_bounds.left(),
                          .top = paint_bounds.top(),
                          .scale_x = scale_x,
                          .scale_y = scale_y,
                          .background_color = color,
                          .layers = std::move(paint_layers)});
  return image;
}

std::vector<
    std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>>
SceneUpdateContext::ExecutePaintTasks(CompositorContext::ScopedFrame& frame) {
  TRACE_EVENT0("flutter", "SceneUpdateContext::ExecutePaintTasks");
  std::vector<std::unique_ptr<SurfaceProducerSurface>> surfaces_to_submit;
  for (auto& task : paint_tasks_) {
    FML_DCHECK(task.surface);
    SkCanvas* canvas = task.surface->GetSkiaSurface()->getCanvas();
    Layer::PaintContext context = {canvas,
                                   canvas,
                                   frame.gr_context(),
                                   nullptr,
                                   frame.context().raster_time(),
                                   frame.context().ui_time(),
                                   frame.context().texture_registry(),
                                   &frame.context().raster_cache(),
                                   false,
                                   frame_physical_depth_,
                                   frame_device_pixel_ratio_};
    canvas->restoreToCount(1);
    canvas->save();
    canvas->clear(task.background_color);
    canvas->scale(task.scale_x, task.scale_y);
    canvas->translate(-task.left, -task.top);
    for (Layer* layer : task.layers) {
      layer->Paint(context);
    }
    surfaces_to_submit.emplace_back(std::move(task.surface));
  }
  paint_tasks_.clear();
  alpha_ = 1.f;
  topmost_global_scenic_elevation_ = kScenicZElevationBetweenLayers;
  scenic_elevation_ = 0.f;
  return surfaces_to_submit;
}

void SceneUpdateContext::UpdateScene(int64_t view_id,
                                     const SkPoint& offset,
                                     const SkSize& size) {
  auto* view_holder = ViewHolder::FromId(view_id);
  FML_DCHECK(view_holder);

  view_holder->SetProperties(size.width(), size.height(), 0, 0, 0, 0,
                             view_holder->focusable());
  view_holder->UpdateScene(*this, offset, size,
                           SkScalarRoundToInt(alphaf() * 255),
                           view_holder->hit_testable());
}

void SceneUpdateContext::CreateView(int64_t view_id,
                                    bool hit_testable,
                                    bool focusable) {
  zx_handle_t handle = (zx_handle_t)view_id;
  flutter::ViewHolder::Create(handle, nullptr,
                              scenic::ToViewHolderToken(zx::eventpair(handle)),
                              nullptr);
  auto* view_holder = ViewHolder::FromId(view_id);
  FML_DCHECK(view_holder);

  view_holder->set_hit_testable(hit_testable);
  view_holder->set_focusable(focusable);
}

void SceneUpdateContext::DestroyView(int64_t view_id) {
  ViewHolder::Destroy(view_id);
}

SceneUpdateContext::Entity::Entity(SceneUpdateContext& context)
    : context_(context),
      previous_entity_(context.top_entity_),
      entity_node_(context.session()) {
  if (previous_entity_)
    previous_entity_->embedder_node().AddChild(entity_node_);
  context.top_entity_ = this;
}

SceneUpdateContext::Entity::~Entity() {
  FML_DCHECK(context_.top_entity_ == this);
  context_.top_entity_ = previous_entity_;
}

SceneUpdateContext::Transform::Transform(SceneUpdateContext& context,
                                         const SkMatrix& transform)
    : Entity(context),
      previous_scale_x_(context.top_scale_x_),
      previous_scale_y_(context.top_scale_y_) {
  entity_node().SetLabel("flutter::Transform");
  if (!transform.isIdentity()) {
    // TODO(SCN-192): The perspective and shear components in the matrix
    // are not handled correctly.
    MatrixDecomposition decomposition(transform);
    if (decomposition.IsValid()) {
      // Don't allow clients to control the z dimension; we control that
      // instead to make sure layers appear in proper order.
      entity_node().SetTranslation(decomposition.translation().x,  //
                                   decomposition.translation().y,  //
                                   0.f                             //
      );

      entity_node().SetScale(decomposition.scale().x,  //
                             decomposition.scale().y,  //
                             1.f                       //
      );
      context.top_scale_x_ *= decomposition.scale().x;
      context.top_scale_y_ *= decomposition.scale().y;

      entity_node().SetRotation(decomposition.rotation().x,  //
                                decomposition.rotation().y,  //
                                decomposition.rotation().z,  //
                                decomposition.rotation().w   //
      );
    }
  }
}

SceneUpdateContext::Transform::Transform(SceneUpdateContext& context,
                                         float scale_x,
                                         float scale_y,
                                         float scale_z)
    : Entity(context),
      previous_scale_x_(context.top_scale_x_),
      previous_scale_y_(context.top_scale_y_) {
  entity_node().SetLabel("flutter::Transform");
  if (scale_x != 1.f || scale_y != 1.f || scale_z != 1.f) {
    entity_node().SetScale(scale_x, scale_y, scale_z);
    context.top_scale_x_ *= scale_x;
    context.top_scale_y_ *= scale_y;
  }
}

SceneUpdateContext::Transform::~Transform() {
  context().top_scale_x_ = previous_scale_x_;
  context().top_scale_y_ = previous_scale_y_;
}

SceneUpdateContext::Frame::Frame(SceneUpdateContext& context,
                                 const SkRRect& rrect,
                                 SkColor color,
                                 SkAlpha opacity,
                                 std::string label,
                                 float z_translation,
                                 Layer* layer)
    : Entity(context),
      rrect_(rrect),
      color_(color),
      opacity_(opacity),
      opacity_node_(context.session()),
      paint_bounds_(SkRect::MakeEmpty()),
      layer_(layer) {
  entity_node().SetLabel(label);
  entity_node().SetTranslation(0.f, 0.f, z_translation);
  entity_node().AddChild(opacity_node_);
  // Scenic currently lacks an API to enable rendering of alpha channel; alpha
  // channels are only rendered if there is a OpacityNode higher in the tree
  // with opacity != 1. For now, clamp to a infinitesimally smaller value than
  // 1, which does not cause visual problems in practice.
  opacity_node_.SetOpacity(std::min(kOneMinusEpsilon, opacity_ / 255.0f));
}

SceneUpdateContext::Frame::~Frame() {
  // We don't need a shape if the frame is zero size.
  if (rrect_.isEmpty())
    return;

  // isEmpty should account for this, but we are adding these experimental
  // checks to validate if this is the root cause for b/144933519.
  if (std::isnan(rrect_.width()) || std::isnan(rrect_.height())) {
    FML_LOG(ERROR) << "Invalid RoundedRectangle";
    return;
  }

  // Add a part which represents the frame's geometry for clipping purposes
  context().CreateFrame(std::move(entity_node()), rrect_, color_, opacity_,
                        paint_bounds_, std::move(paint_layers_), layer_);
}

void SceneUpdateContext::Frame::AddPaintLayer(Layer* layer) {
  FML_DCHECK(layer->needs_painting());
  paint_layers_.push_back(layer);
  paint_bounds_.join(layer->paint_bounds());
}

SceneUpdateContext::Clip::Clip(SceneUpdateContext& context,
                               const SkRect& shape_bounds)
    : Entity(context) {
  entity_node().SetLabel("flutter::Clip");
  SetEntityNodeClipPlanes(entity_node(), shape_bounds);
}

}  // namespace flutter
