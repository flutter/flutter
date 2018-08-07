// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/default_layer_builder.h"

#include "flutter/flow/layers/backdrop_filter_layer.h"
#include "flutter/flow/layers/clip_path_layer.h"
#include "flutter/flow/layers/clip_rect_layer.h"
#include "flutter/flow/layers/clip_rrect_layer.h"
#include "flutter/flow/layers/color_filter_layer.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/flow/layers/opacity_layer.h"
#include "flutter/flow/layers/performance_overlay_layer.h"
#include "flutter/flow/layers/physical_shape_layer.h"
#include "flutter/flow/layers/picture_layer.h"
#include "flutter/flow/layers/shader_mask_layer.h"
#include "flutter/flow/layers/texture_layer.h"
#include "flutter/flow/layers/transform_layer.h"

#if defined(OS_FUCHSIA)
#include "flutter/flow/layers/child_scene_layer.h"
#endif  // defined(OS_FUCHSIA)

namespace flow {

static const SkRect kGiantRect = SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

DefaultLayerBuilder::DefaultLayerBuilder() {
  cull_rects_.push(kGiantRect);
}

DefaultLayerBuilder::~DefaultLayerBuilder() = default;

void DefaultLayerBuilder::PushTransform(const SkMatrix& sk_matrix) {
  SkMatrix inverse_sk_matrix;
  SkRect cullRect;
  // Perspective projections don't produce rectangles that are useful for
  // culling for some reason.
  if (!sk_matrix.hasPerspective() && sk_matrix.invert(&inverse_sk_matrix)) {
    inverse_sk_matrix.mapRect(&cullRect, cull_rects_.top());
  } else {
    cullRect = kGiantRect;
  }
  auto layer = std::make_unique<flow::TransformLayer>();
  layer->set_transform(sk_matrix);
  PushLayer(std::move(layer), cullRect);
}

void DefaultLayerBuilder::PushClipRect(const SkRect& clipRect,
                                       Clip clip_behavior) {
  SkRect cullRect;
  if (!cullRect.intersect(clipRect, cull_rects_.top())) {
    cullRect = SkRect::MakeEmpty();
  }
  auto layer = std::make_unique<flow::ClipRectLayer>(clip_behavior);
  layer->set_clip_rect(clipRect);
  PushLayer(std::move(layer), cullRect);
}

void DefaultLayerBuilder::PushClipRoundedRect(const SkRRect& rrect,
                                              Clip clip_behavior) {
  SkRect cullRect;
  if (!cullRect.intersect(rrect.rect(), cull_rects_.top())) {
    cullRect = SkRect::MakeEmpty();
  }
  auto layer = std::make_unique<flow::ClipRRectLayer>(clip_behavior);
  layer->set_clip_rrect(rrect);
  PushLayer(std::move(layer), cullRect);
}

void DefaultLayerBuilder::PushClipPath(const SkPath& path, Clip clip_behavior) {
  FML_DCHECK(clip_behavior != Clip::none);
  SkRect cullRect;
  if (!cullRect.intersect(path.getBounds(), cull_rects_.top())) {
    cullRect = SkRect::MakeEmpty();
  }
  auto layer = std::make_unique<flow::ClipPathLayer>(clip_behavior);
  layer->set_clip_path(path);
  PushLayer(std::move(layer), cullRect);
}

void DefaultLayerBuilder::PushOpacity(int alpha) {
  auto layer = std::make_unique<flow::OpacityLayer>();
  layer->set_alpha(alpha);
  PushLayer(std::move(layer), cull_rects_.top());
}

void DefaultLayerBuilder::PushColorFilter(SkColor color,
                                          SkBlendMode blend_mode) {
  auto layer = std::make_unique<flow::ColorFilterLayer>();
  layer->set_color(color);
  layer->set_blend_mode(blend_mode);
  PushLayer(std::move(layer), cull_rects_.top());
}

void DefaultLayerBuilder::PushBackdropFilter(sk_sp<SkImageFilter> filter) {
  auto layer = std::make_unique<flow::BackdropFilterLayer>();
  layer->set_filter(filter);
  PushLayer(std::move(layer), cull_rects_.top());
}

void DefaultLayerBuilder::PushShaderMask(sk_sp<SkShader> shader,
                                         const SkRect& rect,
                                         SkBlendMode blend_mode) {
  auto layer = std::make_unique<flow::ShaderMaskLayer>();
  layer->set_shader(shader);
  layer->set_mask_rect(rect);
  layer->set_blend_mode(blend_mode);
  PushLayer(std::move(layer), cull_rects_.top());
}

void DefaultLayerBuilder::PushPhysicalShape(const SkPath& sk_path,
                                            double elevation,
                                            SkColor color,
                                            SkColor shadow_color,
                                            SkScalar device_pixel_ratio,
                                            Clip clip_behavior) {
  SkRect cullRect;
  if (!cullRect.intersect(sk_path.getBounds(), cull_rects_.top())) {
    cullRect = SkRect::MakeEmpty();
  }
  auto layer = std::make_unique<flow::PhysicalShapeLayer>(clip_behavior);
  layer->set_path(sk_path);
  layer->set_elevation(elevation);
  layer->set_color(color);
  layer->set_shadow_color(shadow_color);
  layer->set_device_pixel_ratio(device_pixel_ratio);
  PushLayer(std::move(layer), cullRect);
}

void DefaultLayerBuilder::PushPerformanceOverlay(uint64_t enabled_options,
                                                 const SkRect& rect) {
  if (!current_layer_) {
    return;
  }
  auto layer = std::make_unique<flow::PerformanceOverlayLayer>(enabled_options);
  layer->set_paint_bounds(rect);
  current_layer_->Add(std::move(layer));
}

void DefaultLayerBuilder::PushPicture(const SkPoint& offset,
                                      SkiaGPUObject<SkPicture> picture,
                                      bool picture_is_complex,
                                      bool picture_will_change) {
  if (!current_layer_) {
    return;
  }
  SkRect pictureRect = picture.get()->cullRect();
  pictureRect.offset(offset.x(), offset.y());
  if (!SkRect::Intersects(pictureRect, cull_rects_.top())) {
    return;
  }
  auto layer = std::make_unique<flow::PictureLayer>();
  layer->set_offset(offset);
  layer->set_picture(std::move(picture));
  layer->set_is_complex(picture_is_complex);
  layer->set_will_change(picture_will_change);
  current_layer_->Add(std::move(layer));
}

void DefaultLayerBuilder::PushTexture(const SkPoint& offset,
                                      const SkSize& size,
                                      int64_t texture_id,
                                      bool freeze) {
  if (!current_layer_) {
    return;
  }
  auto layer = std::make_unique<flow::TextureLayer>();
  layer->set_offset(offset);
  layer->set_size(size);
  layer->set_texture_id(texture_id);
  layer->set_freeze(freeze);
  current_layer_->Add(std::move(layer));
}

#if defined(OS_FUCHSIA)
void DefaultLayerBuilder::PushChildScene(
    const SkPoint& offset,
    const SkSize& size,
    fml::RefPtr<flow::ExportNodeHolder> export_token_holder,
    bool hit_testable) {
  if (!current_layer_) {
    return;
  }
  SkRect sceneRect =
      SkRect::MakeXYWH(offset.x(), offset.y(), size.width(), size.height());
  if (!SkRect::Intersects(sceneRect, cull_rects_.top())) {
    return;
  }
  auto layer = std::make_unique<flow::ChildSceneLayer>();
  layer->set_offset(offset);
  layer->set_size(size);
  layer->set_export_node_holder(std::move(export_token_holder));
  layer->set_hit_testable(hit_testable);
  current_layer_->Add(std::move(layer));
}
#endif  // defined(OS_FUCHSIA)

void DefaultLayerBuilder::Pop() {
  if (!current_layer_) {
    return;
  }
  cull_rects_.pop();
  current_layer_ = current_layer_->parent();
}

std::unique_ptr<flow::Layer> DefaultLayerBuilder::TakeLayer() {
  return std::move(root_layer_);
}

void DefaultLayerBuilder::PushLayer(std::unique_ptr<flow::ContainerLayer> layer,
                                    const SkRect& cullRect) {
  FML_DCHECK(layer);

  cull_rects_.push(cullRect);

  if (!root_layer_) {
    root_layer_ = std::move(layer);
    current_layer_ = root_layer_.get();
    return;
  }

  if (!current_layer_) {
    return;
  }

  flow::ContainerLayer* newLayer = layer.get();
  current_layer_->Add(std::move(layer));
  current_layer_ = newLayer;
}

}  // namespace flow
