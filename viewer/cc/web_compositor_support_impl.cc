// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_compositor_support_impl.h"

#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop_proxy.h"
#include "cc/animation/transform_operations.h"
#include "sky/viewer/cc/web_animation_impl.h"
#include "sky/viewer/cc/web_content_layer_impl.h"
#include "sky/viewer/cc/web_external_texture_layer_impl.h"
#include "sky/viewer/cc/web_filter_animation_curve_impl.h"
#include "sky/viewer/cc/web_filter_operations_impl.h"
#include "sky/viewer/cc/web_float_animation_curve_impl.h"
#include "sky/viewer/cc/web_image_layer_impl.h"
#include "sky/viewer/cc/web_layer_impl.h"
#include "sky/viewer/cc/web_scroll_offset_animation_curve_impl.h"
#include "sky/viewer/cc/web_scrollbar_layer_impl.h"
#include "sky/viewer/cc/web_transform_animation_curve_impl.h"
#include "sky/viewer/cc/web_transform_operations_impl.h"
#include "cc/output/output_surface.h"
#include "cc/output/software_output_device.h"

using blink::WebCompositorAnimation;
using blink::WebCompositorAnimationCurve;
using blink::WebContentLayer;
using blink::WebContentLayerClient;
using blink::WebExternalTextureLayer;
using blink::WebExternalTextureLayerClient;
using blink::WebFilterAnimationCurve;
using blink::WebFilterOperations;
using blink::WebFloatAnimationCurve;
using blink::WebImageLayer;
using blink::WebLayer;
using blink::WebScrollbar;
using blink::WebScrollbarLayer;
using blink::WebScrollbarThemeGeometry;
using blink::WebScrollbarThemePainter;
using blink::WebScrollOffsetAnimationCurve;
using blink::WebTransformAnimationCurve;
using blink::WebTransformOperations;

namespace sky_viewer_cc {

WebCompositorSupportImpl::WebCompositorSupportImpl() {
}

WebCompositorSupportImpl::~WebCompositorSupportImpl() {
}

WebLayer* WebCompositorSupportImpl::createLayer() {
  return new WebLayerImpl();
}

WebContentLayer* WebCompositorSupportImpl::createContentLayer(
    WebContentLayerClient* client) {
  return new WebContentLayerImpl(client);
}

WebExternalTextureLayer* WebCompositorSupportImpl::createExternalTextureLayer(
    WebExternalTextureLayerClient* client) {
  return new WebExternalTextureLayerImpl(client);
}

blink::WebImageLayer* WebCompositorSupportImpl::createImageLayer() {
  return new WebImageLayerImpl();
}

WebScrollbarLayer* WebCompositorSupportImpl::createScrollbarLayer(
    WebScrollbar* scrollbar,
    WebScrollbarThemePainter painter,
    WebScrollbarThemeGeometry* geometry) {
  return new WebScrollbarLayerImpl(scrollbar, painter, geometry);
}

WebScrollbarLayer* WebCompositorSupportImpl::createSolidColorScrollbarLayer(
    WebScrollbar::Orientation orientation,
    int thumb_thickness,
    int track_start,
    bool is_left_side_vertical_scrollbar) {
  return new WebScrollbarLayerImpl(orientation,
                                   thumb_thickness,
                                   track_start,
                                   is_left_side_vertical_scrollbar);
}

WebCompositorAnimation* WebCompositorSupportImpl::createAnimation(
    const blink::WebCompositorAnimationCurve& curve,
    blink::WebCompositorAnimation::TargetProperty target,
    int animation_id) {
  return new WebCompositorAnimationImpl(curve, target, animation_id, 0);
}

WebFilterAnimationCurve*
WebCompositorSupportImpl::createFilterAnimationCurve() {
  return new WebFilterAnimationCurveImpl();
}

WebFloatAnimationCurve* WebCompositorSupportImpl::createFloatAnimationCurve() {
  return new WebFloatAnimationCurveImpl();
}

WebScrollOffsetAnimationCurve*
WebCompositorSupportImpl::createScrollOffsetAnimationCurve(
    blink::WebFloatPoint target_value,
    blink::WebCompositorAnimationCurve::TimingFunctionType timing_function) {
  return new WebScrollOffsetAnimationCurveImpl(target_value, timing_function);
}

WebTransformAnimationCurve*
WebCompositorSupportImpl::createTransformAnimationCurve() {
  return new WebTransformAnimationCurveImpl();
}

WebTransformOperations* WebCompositorSupportImpl::createTransformOperations() {
  return new WebTransformOperationsImpl();
}

WebFilterOperations* WebCompositorSupportImpl::createFilterOperations() {
  return new WebFilterOperationsImpl();
}

}  // namespace sky_viewer_cc
