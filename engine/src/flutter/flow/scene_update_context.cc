// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/scene_update_context.h"

#include <lib/ui/scenic/cpp/commands.h>
#include <lib/ui/scenic/cpp/view_token_pair.h>

#include "flutter/flow/layers/layer.h"
#include "flutter/flow/matrix_decomposition.h"
#include "flutter/flow/view_holder.h"
#include "flutter/fml/trace_event.h"
#include "include/core/SkColor.h"

namespace flutter {
namespace {

void SetEntityNodeClipPlanes(scenic::EntityNode& entity_node,
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

void SetMaterialColor(scenic::Material& material,
                      SkColor color,
                      SkAlpha opacity) {
  const SkAlpha color_alpha = static_cast<SkAlpha>(
      ((float)SkColorGetA(color) * (float)opacity) / 255.0f);
  material.SetColor(SkColorGetR(color), SkColorGetG(color), SkColorGetB(color),
                    color_alpha);
}

}  // namespace

SceneUpdateContext::SceneUpdateContext(std::string debug_label,
                                       fuchsia::ui::views::ViewToken view_token,
                                       scenic::ViewRefPair view_ref_pair,
                                       SessionWrapper& session,
                                       bool intercept_all_input)
    : session_(session),
      root_view_(session_.get(),
                 std::move(view_token),
                 std::move(view_ref_pair.control_ref),
                 std::move(view_ref_pair.view_ref),
                 debug_label),
      root_node_(session_.get()),
      intercept_all_input_(intercept_all_input) {
  root_view_.AddChild(root_node_);
  root_node_.SetEventMask(fuchsia::ui::gfx::kMetricsEventMask);

  session_.Present();
}

std::vector<SceneUpdateContext::PaintTask> SceneUpdateContext::GetPaintTasks() {
  std::vector<PaintTask> frame_paint_tasks = std::move(paint_tasks_);

  paint_tasks_.clear();

  return frame_paint_tasks;
}

void SceneUpdateContext::EnableWireframe(bool enable) {
  session_.get()->Enqueue(
      scenic::NewSetEnableDebugViewBoundsCmd(root_view_.id(), enable));
}

void SceneUpdateContext::Reset() {
  paint_tasks_.clear();
  top_entity_ = nullptr;
  top_scale_x_ = 1.f;
  top_scale_y_ = 1.f;
  top_elevation_ = 0.f;
  next_elevation_ = 0.f;
  alpha_ = 1.f;

  // We are going to be sending down a fresh node hierarchy every frame. So just
  // enqueue a detach op on the imported root node.
  session_.get()->Enqueue(scenic::NewDetachChildrenCmd(root_node_.id()));
}

void SceneUpdateContext::CreateFrame(scenic::EntityNode& entity_node,
                                     const SkRRect& rrect,
                                     SkColor color,
                                     SkAlpha opacity,
                                     const SkRect& paint_bounds,
                                     std::vector<Layer*> paint_layers) {
  // We don't need a shape if the frame is zero size.
  if (rrect.isEmpty())
    return;

  // Frames always clip their children.
  SkRect shape_bounds = rrect.getBounds();
  SetEntityNodeClipPlanes(entity_node, shape_bounds);

  // TODO(SCN-137): Need to be able to express the radii as vectors.
  scenic::ShapeNode shape_node(session_.get());
  scenic::Rectangle shape(session_.get(), rrect.width(), rrect.height());
  shape_node.SetShape(shape);
  shape_node.SetTranslation(shape_bounds.width() * 0.5f + shape_bounds.left(),
                            shape_bounds.height() * 0.5f + shape_bounds.top(),
                            0.f);

  // Check whether the painted layers will be visible.
  if (paint_bounds.isEmpty() || !paint_bounds.intersects(shape_bounds))
    paint_layers.clear();

  scenic::Material material(session_.get());
  shape_node.SetMaterial(material);
  entity_node.AddChild(shape_node);

  // Check whether a solid color will suffice.
  if (paint_layers.empty()) {
    SetMaterialColor(material, color, opacity);
  } else {
    // The final shape's color is material_color * texture_color.  The passed in
    // material color was already used as a background when generating the
    // texture, so set the model color to |SK_ColorWHITE| in order to allow
    // using the texture's color unmodified.
    SetMaterialColor(material, SK_ColorWHITE, opacity);

    // Enqueue a paint task for these layers, to apply a texture to the whole
    // shape.
    //
    // The task uses the |shape_bounds| as its rendering bounds instead of the
    // |paint_bounds|.  If the paint_bounds is large than the shape_bounds it
    // will be clipped.
    paint_tasks_.emplace_back(PaintTask{.paint_bounds = shape_bounds,
                                        .scale_x = top_scale_x_,
                                        .scale_y = top_scale_y_,
                                        .background_color = color,
                                        .material = std::move(material),
                                        .layers = std::move(paint_layers)});
  }
}

void SceneUpdateContext::UpdateView(int64_t view_id,
                                    const SkPoint& offset,
                                    const SkSize& size,
                                    std::optional<bool> override_hit_testable) {
  auto* view_holder = ViewHolder::FromId(view_id);
  FML_DCHECK(view_holder);

  if (size.width() > 0.f && size.height() > 0.f) {
    view_holder->SetProperties(size.width(), size.height(), 0, 0, 0, 0,
                               view_holder->focusable());
  }

  bool hit_testable = override_hit_testable.has_value()
                          ? *override_hit_testable
                          : view_holder->hit_testable();
  view_holder->UpdateScene(session_.get(), top_entity_->embedder_node(), offset,
                           size, SkScalarRoundToInt(alphaf() * 255),
                           hit_testable);

  // Assume embedded views are 10 "layers" wide.
  next_elevation_ += 10 * kScenicZElevationBetweenLayers;
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

void SceneUpdateContext::UpdateView(int64_t view_id,
                                    bool hit_testable,
                                    bool focusable) {
  auto* view_holder = ViewHolder::FromId(view_id);
  FML_DCHECK(view_holder);

  view_holder->set_hit_testable(hit_testable);
  view_holder->set_focusable(focusable);
}

void SceneUpdateContext::DestroyView(int64_t view_id) {
  ViewHolder::Destroy(view_id);
}

SceneUpdateContext::Entity::Entity(std::shared_ptr<SceneUpdateContext> context)
    : context_(context),
      previous_entity_(context->top_entity_),
      entity_node_(context->session_.get()) {
  context->top_entity_ = this;
}

SceneUpdateContext::Entity::~Entity() {
  if (previous_entity_) {
    previous_entity_->embedder_node().AddChild(entity_node_);
  } else {
    context_->root_node_.AddChild(entity_node_);
  }

  FML_DCHECK(context_->top_entity_ == this);
  context_->top_entity_ = previous_entity_;
}

SceneUpdateContext::Transform::Transform(
    std::shared_ptr<SceneUpdateContext> context,
    const SkMatrix& transform)
    : Entity(context),
      previous_scale_x_(context->top_scale_x_),
      previous_scale_y_(context->top_scale_y_) {
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
      context->top_scale_x_ *= decomposition.scale().x;
      context->top_scale_y_ *= decomposition.scale().y;

      entity_node().SetRotation(decomposition.rotation().x,  //
                                decomposition.rotation().y,  //
                                decomposition.rotation().z,  //
                                decomposition.rotation().w   //
      );
    }
  }
}

SceneUpdateContext::Transform::Transform(
    std::shared_ptr<SceneUpdateContext> context,
    float scale_x,
    float scale_y,
    float scale_z)
    : Entity(context),
      previous_scale_x_(context->top_scale_x_),
      previous_scale_y_(context->top_scale_y_) {
  entity_node().SetLabel("flutter::Transform");
  if (scale_x != 1.f || scale_y != 1.f || scale_z != 1.f) {
    entity_node().SetScale(scale_x, scale_y, scale_z);
    context->top_scale_x_ *= scale_x;
    context->top_scale_y_ *= scale_y;
  }
}

SceneUpdateContext::Transform::~Transform() {
  context()->top_scale_x_ = previous_scale_x_;
  context()->top_scale_y_ = previous_scale_y_;
}

SceneUpdateContext::Frame::Frame(std::shared_ptr<SceneUpdateContext> context,
                                 const SkRRect& rrect,
                                 SkColor color,
                                 SkAlpha opacity,
                                 std::string label)
    : Entity(context),
      previous_elevation_(context->top_elevation_),
      rrect_(rrect),
      color_(color),
      opacity_(opacity),
      opacity_node_(context->session_.get()),
      paint_bounds_(SkRect::MakeEmpty()) {
  // Increment elevation trackers before calculating any local elevation.
  // |UpdateView| can modify context->next_elevation_, which is why it is
  // neccesary to track this addtional state.
  context->top_elevation_ += kScenicZElevationBetweenLayers;
  context->next_elevation_ += kScenicZElevationBetweenLayers;

  float local_elevation = context->next_elevation_ - previous_elevation_;
  entity_node().SetTranslation(0.f, 0.f, -local_elevation);
  entity_node().SetLabel(label);
  entity_node().AddChild(opacity_node_);

  // Scenic currently lacks an API to enable rendering of alpha channel; alpha
  // channels are only rendered if there is a OpacityNode higher in the tree
  // with opacity != 1. For now, clamp to a infinitesimally smaller value than
  // 1, which does not cause visual problems in practice.
  opacity_node_.SetOpacity(std::min(kOneMinusEpsilon, opacity_ / 255.0f));

  if (context->intercept_all_input_) {
    context->input_interceptor_.emplace(context->session_.get());
    context->input_interceptor_->UpdateDimensions(
        context->session_.get(), rrect.width(), rrect.height(),
        -(local_elevation + kScenicZElevationBetweenLayers * 0.5f));
    entity_node().AddChild(context->input_interceptor_->node());
  }
}

SceneUpdateContext::Frame::~Frame() {
  context()->top_elevation_ = previous_elevation_;

  // Add a part which represents the frame's geometry for clipping purposes
  context()->CreateFrame(entity_node(), rrect_, color_, opacity_, paint_bounds_,
                         std::move(paint_layers_));
}

void SceneUpdateContext::Frame::AddPaintLayer(Layer* layer) {
  FML_DCHECK(!layer->is_empty());
  paint_layers_.push_back(layer);
  paint_bounds_.join(layer->paint_bounds());
}

SceneUpdateContext::Clip::Clip(std::shared_ptr<SceneUpdateContext> context,
                               const SkRect& shape_bounds)
    : Entity(context) {
  entity_node().SetLabel("flutter::Clip");
  SetEntityNodeClipPlanes(entity_node(), shape_bounds);
}

}  // namespace flutter
