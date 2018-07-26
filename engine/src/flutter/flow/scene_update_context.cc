// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/scene_update_context.h"

#include "flutter/flow/export_node.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/matrix_decomposition.h"
#include "flutter/fml/trace_event.h"

namespace flow {

SceneUpdateContext::SceneUpdateContext(scenic::Session* session,
                                       SurfaceProducer* surface_producer)
    : session_(session), surface_producer_(surface_producer) {
  FML_DCHECK(surface_producer_ != nullptr);
}

SceneUpdateContext::~SceneUpdateContext() {
  // Release Mozart session resources for all ExportNodes.
  for (auto export_node : export_nodes_) {
    export_node->Dispose(false);
  }
};

void SceneUpdateContext::AddChildScene(ExportNode* export_node,
                                       SkPoint offset,
                                       bool hit_testable) {
  FML_DCHECK(top_entity_);

  export_node->Bind(*this, top_entity_->entity_node(), offset, hit_testable);
}

void SceneUpdateContext::AddExportNode(ExportNode* export_node) {
  export_nodes_.insert(export_node);  // Might already have been added.
}

void SceneUpdateContext::RemoveExportNode(ExportNode* export_node) {
  export_nodes_.erase(export_node);
}

void SceneUpdateContext::CreateFrame(scenic::EntityNode& entity_node,
                                     const SkRRect& rrect,
                                     SkColor color,
                                     const SkRect& paint_bounds,
                                     std::vector<Layer*> paint_layers) {
  // Frames always clip their children.
  entity_node.SetClip(0u, true /* clip to self */);

  // We don't need a shape if the frame is zero size.
  if (rrect.isEmpty())
    return;

  // Add a part which represents the frame's geometry for clipping purposes
  // and possibly for its texture.
  // TODO(MZ-137): Need to be able to express the radii as vectors.
  SkRect shape_bounds = rrect.getBounds();
  scenic::RoundedRectangle shape(
      session_,                                      // session
      rrect.width(),                                 // width
      rrect.height(),                                // height
      rrect.radii(SkRRect::kUpperLeft_Corner).x(),   // top_left_radius
      rrect.radii(SkRRect::kUpperRight_Corner).x(),  // top_right_radius
      rrect.radii(SkRRect::kLowerRight_Corner).x(),  // bottom_right_radius
      rrect.radii(SkRRect::kLowerLeft_Corner).x()    // bottom_left_radius
  );
  scenic::ShapeNode shape_node(session_);
  shape_node.SetShape(shape);
  shape_node.SetTranslation(shape_bounds.width() * 0.5f + shape_bounds.left(),
                            shape_bounds.height() * 0.5f + shape_bounds.top(),
                            0.f);
  entity_node.AddPart(shape_node);

  // Check whether the painted layers will be visible.
  if (paint_bounds.isEmpty() || !paint_bounds.intersects(shape_bounds))
    paint_layers.clear();

  // Check whether a solid color will suffice.
  if (paint_layers.empty()) {
    SetShapeColor(shape_node, color);
    return;
  }

  // Apply current metrics and transformation scale factors.
  const float scale_x = metrics_->scale_x * top_scale_x_;
  const float scale_y = metrics_->scale_y * top_scale_y_;

  // If the painted area only covers a portion of the frame then we can
  // reduce the texture size by drawing just that smaller area.
  SkRect inner_bounds = shape_bounds;
  inner_bounds.intersect(paint_bounds);
  if (inner_bounds != shape_bounds && rrect.contains(inner_bounds)) {
    SetShapeColor(shape_node, color);

    scenic::Rectangle inner_shape(session_, inner_bounds.width(),
                                  inner_bounds.height());
    scenic::ShapeNode inner_node(session_);
    inner_node.SetShape(inner_shape);
    inner_node.SetTranslation(inner_bounds.width() * 0.5f + inner_bounds.left(),
                              inner_bounds.height() * 0.5f + inner_bounds.top(),
                              0.f);
    entity_node.AddPart(inner_node);
    SetShapeTextureOrColor(inner_node, color, scale_x, scale_y, inner_bounds,
                           std::move(paint_layers));
    return;
  }

  // Apply a texture to the whole shape.
  SetShapeTextureOrColor(shape_node, color, scale_x, scale_y, shape_bounds,
                         std::move(paint_layers));
}

void SceneUpdateContext::SetShapeTextureOrColor(
    scenic::ShapeNode& shape_node,
    SkColor color,
    SkScalar scale_x,
    SkScalar scale_y,
    const SkRect& paint_bounds,
    std::vector<Layer*> paint_layers) {
  scenic::Image* image = GenerateImageIfNeeded(
      color, scale_x, scale_y, paint_bounds, std::move(paint_layers));
  if (image != nullptr) {
    scenic::Material material(session_);
    material.SetTexture(*image);
    shape_node.SetMaterial(material);
    return;
  }

  SetShapeColor(shape_node, color);
}

void SceneUpdateContext::SetShapeColor(scenic::ShapeNode& shape_node,
                                       SkColor color) {
  if (SkColorGetA(color) == 0)
    return;

  scenic::Material material(session_);
  material.SetColor(SkColorGetR(color), SkColorGetG(color), SkColorGetB(color),
                    SkColorGetA(color));
  shape_node.SetMaterial(material);
}

scenic::Image* SceneUpdateContext::GenerateImageIfNeeded(
    SkColor color,
    SkScalar scale_x,
    SkScalar scale_y,
    const SkRect& paint_bounds,
    std::vector<Layer*> paint_layers) {
  // Bail if there's nothing to paint.
  if (paint_layers.empty())
    return nullptr;

  // Bail if the physical bounds are empty after rounding.
  SkISize physical_size = SkISize::Make(paint_bounds.width() * scale_x,
                                        paint_bounds.height() * scale_y);
  if (physical_size.isEmpty())
    return nullptr;

  // Acquire a surface from the surface producer and register the paint tasks.
  auto surface = surface_producer_->ProduceSurface(physical_size);

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

std::vector<std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>>
SceneUpdateContext::ExecutePaintTasks(CompositorContext::ScopedFrame& frame) {
  TRACE_EVENT0("flutter", "SceneUpdateContext::ExecutePaintTasks");
  std::vector<std::unique_ptr<SurfaceProducerSurface>> surfaces_to_submit;
  for (auto& task : paint_tasks_) {
    FML_DCHECK(task.surface);
    SkCanvas* canvas = task.surface->GetSkiaSurface()->getCanvas();
    Layer::PaintContext context = {*canvas, frame.context().frame_time(),
                                   frame.context().engine_time(),
                                   frame.context().texture_registry(), false};
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
  return surfaces_to_submit;
}

SceneUpdateContext::Entity::Entity(SceneUpdateContext& context)
    : context_(context),
      previous_entity_(context.top_entity_),
      entity_node_(context.session()) {
  if (previous_entity_)
    previous_entity_->entity_node_.AddChild(entity_node_);
  context.top_entity_ = this;
}

SceneUpdateContext::Entity::~Entity() {
  FML_DCHECK(context_.top_entity_ == this);
  context_.top_entity_ = previous_entity_;
}

SceneUpdateContext::Clip::Clip(SceneUpdateContext& context,
                               scenic::Shape& shape,
                               const SkRect& shape_bounds)
    : Entity(context) {
  scenic::ShapeNode shape_node(context.session());
  shape_node.SetShape(shape);
  shape_node.SetTranslation(shape_bounds.width() * 0.5f + shape_bounds.left(),
                            shape_bounds.height() * 0.5f + shape_bounds.top(),
                            0.f);

  entity_node().AddPart(shape_node);
  entity_node().SetClip(0u, true /* clip to self */);
}

SceneUpdateContext::Clip::~Clip() = default;

SceneUpdateContext::Transform::Transform(SceneUpdateContext& context,
                                         const SkMatrix& transform)
    : Entity(context),
      previous_scale_x_(context.top_scale_x_),
      previous_scale_y_(context.top_scale_y_) {
  if (!transform.isIdentity()) {
    // TODO(MZ-192): The perspective and shear components in the matrix
    // are not handled correctly.
    MatrixDecomposition decomposition(transform);
    if (decomposition.IsValid()) {
      entity_node().SetTranslation(decomposition.translation().x(),  //
                                   decomposition.translation().y(),  //
                                   decomposition.translation().z()   //
      );

      entity_node().SetScale(decomposition.scale().x(),  //
                             decomposition.scale().y(),  //
                             decomposition.scale().z()   //
      );
      context.top_scale_x_ *= decomposition.scale().x();
      context.top_scale_y_ *= decomposition.scale().y();

      entity_node().SetRotation(decomposition.rotation().fData[0],  //
                                decomposition.rotation().fData[1],  //
                                decomposition.rotation().fData[2],  //
                                decomposition.rotation().fData[3]   //
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
                                 float elevation)
    : Entity(context),
      rrect_(rrect),
      color_(color),
      paint_bounds_(SkRect::MakeEmpty()) {
  if (elevation != 0.0)
    entity_node().SetTranslation(0.f, 0.f, elevation);
}

SceneUpdateContext::Frame::~Frame() {
  context().CreateFrame(entity_node(), rrect_, color_, paint_bounds_,
                        std::move(paint_layers_));
}

void SceneUpdateContext::Frame::AddPaintedLayer(Layer* layer) {
  FML_DCHECK(layer->needs_painting());
  paint_layers_.push_back(layer);
  paint_bounds_.join(layer->paint_bounds());
}

}  // namespace flow
