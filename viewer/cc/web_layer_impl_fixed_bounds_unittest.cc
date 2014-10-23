// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>
#include "sky/viewer/cc/web_layer_impl_fixed_bounds.h"
#include "cc/layers/picture_image_layer.h"
#include "cc/test/fake_layer_tree_host.h"
#include "cc/test/geometry_test_utils.h"
#include "cc/trees/layer_tree_host_common.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "sky/engine/public/platform/WebFloatPoint.h"
#include "sky/engine/public/platform/WebSize.h"
#include "third_party/skia/include/utils/SkMatrix44.h"
#include "ui/gfx/point3_f.h"

using blink::WebFloatPoint;
using blink::WebSize;

namespace sky_viewer_cc {
namespace {

TEST(WebLayerImplFixedBoundsTest, IdentityBounds) {
  scoped_ptr<WebLayerImplFixedBounds> layer(new WebLayerImplFixedBounds());
  layer->SetFixedBounds(gfx::Size(100, 100));
  layer->setBounds(WebSize(100, 100));
  EXPECT_EQ(WebSize(100, 100), layer->bounds());
  EXPECT_EQ(gfx::Size(100, 100), layer->layer()->bounds());
  EXPECT_EQ(gfx::Transform(), layer->layer()->transform());
}

gfx::Point3F TransformPoint(const gfx::Transform& transform,
                            const gfx::Point3F& point) {
  gfx::Point3F result = point;
  transform.TransformPoint(&result);
  return result;
}

void CheckBoundsScaleSimple(WebLayerImplFixedBounds* layer,
                            const WebSize& bounds,
                            const gfx::Size& fixed_bounds) {
  layer->setBounds(bounds);
  layer->SetFixedBounds(fixed_bounds);

  EXPECT_EQ(bounds, layer->bounds());
  EXPECT_EQ(fixed_bounds, layer->layer()->bounds());
  EXPECT_TRUE(layer->transform().isIdentity());

  // An arbitrary point to check the scale and transforms.
  gfx::Point3F original_point(10, 20, 1);
  gfx::Point3F scaled_point(
      original_point.x() * bounds.width / fixed_bounds.width(),
      original_point.y() * bounds.height / fixed_bounds.height(),
      original_point.z());
  // Test if the bounds scale is correctly applied in transform.
  EXPECT_POINT3F_EQ(
      scaled_point,
      TransformPoint(layer->layer()->transform(), original_point));
}

TEST(WebLayerImplFixedBoundsTest, BoundsScaleSimple) {
  scoped_ptr<WebLayerImplFixedBounds> layer(new WebLayerImplFixedBounds());
  CheckBoundsScaleSimple(layer.get(), WebSize(100, 200), gfx::Size(150, 250));
  // Change fixed_bounds.
  CheckBoundsScaleSimple(layer.get(), WebSize(100, 200), gfx::Size(75, 100));
  // Change bounds.
  CheckBoundsScaleSimple(layer.get(), WebSize(300, 100), gfx::Size(75, 100));
}

void ExpectEqualLayerRectsInTarget(cc::Layer* layer1, cc::Layer* layer2) {
  gfx::RectF layer1_rect_in_target(layer1->content_bounds());
  layer1->draw_transform().TransformRect(&layer1_rect_in_target);

  gfx::RectF layer2_rect_in_target(layer2->content_bounds());
  layer2->draw_transform().TransformRect(&layer2_rect_in_target);

  EXPECT_FLOAT_RECT_EQ(layer1_rect_in_target, layer2_rect_in_target);
}

void CompareFixedBoundsLayerAndNormalLayer(const WebFloatPoint& anchor_point,
                                           const gfx::Transform& transform) {
  const gfx::Size kDeviceViewportSize(800, 600);
  const float kDeviceScaleFactor = 2.f;
  const float kPageScaleFactor = 1.5f;

  WebSize bounds(150, 200);
  WebFloatPoint position(20, 30);
  gfx::Size fixed_bounds(160, 70);

  scoped_ptr<WebLayerImplFixedBounds> root_layer(new WebLayerImplFixedBounds());

  WebLayerImplFixedBounds* fixed_bounds_layer =
      new WebLayerImplFixedBounds(cc::PictureImageLayer::Create());
  fixed_bounds_layer->setBounds(bounds);
  fixed_bounds_layer->SetFixedBounds(fixed_bounds);
  fixed_bounds_layer->setTransform(transform.matrix());
  fixed_bounds_layer->setPosition(position);
  root_layer->addChild(fixed_bounds_layer);

  WebLayerImpl* normal_layer(new WebLayerImpl(cc::PictureImageLayer::Create()));

  normal_layer->setBounds(bounds);
  normal_layer->setTransform(transform.matrix());
  normal_layer->setPosition(position);
  root_layer->addChild(normal_layer);

  scoped_ptr<cc::FakeLayerTreeHost> host = cc::FakeLayerTreeHost::Create();
  host->SetRootLayer(root_layer->layer());

  {
    cc::RenderSurfaceLayerList render_surface_layer_list;
    cc::LayerTreeHostCommon::CalcDrawPropsMainInputsForTesting inputs(
        root_layer->layer(), kDeviceViewportSize, &render_surface_layer_list);
    inputs.device_scale_factor = kDeviceScaleFactor;
    inputs.page_scale_factor = kPageScaleFactor;
    inputs.page_scale_application_layer = root_layer->layer(),
    cc::LayerTreeHostCommon::CalculateDrawProperties(&inputs);

    ExpectEqualLayerRectsInTarget(normal_layer->layer(),
                                  fixed_bounds_layer->layer());
  }

  // Change of fixed bounds should not affect the target geometries.
  fixed_bounds_layer->SetFixedBounds(
      gfx::Size(fixed_bounds.width() / 2, fixed_bounds.height() * 2));

  {
    cc::RenderSurfaceLayerList render_surface_layer_list;
    cc::LayerTreeHostCommon::CalcDrawPropsMainInputsForTesting inputs(
        root_layer->layer(), kDeviceViewportSize, &render_surface_layer_list);
    inputs.device_scale_factor = kDeviceScaleFactor;
    inputs.page_scale_factor = kPageScaleFactor;
    inputs.page_scale_application_layer = root_layer->layer(),
    cc::LayerTreeHostCommon::CalculateDrawProperties(&inputs);

    ExpectEqualLayerRectsInTarget(normal_layer->layer(),
                                  fixed_bounds_layer->layer());
  }
}

// TODO(perkj): CompareToWebLayerImplSimple disabled on LSAN due to crbug/386080
#if defined(LEAK_SANITIZER)
#define MAYBE_CompareToWebLayerImplSimple DISABLED_CompareToWebLayerImplSimple
#else
#define MAYBE_CompareToWebLayerImplSimple CompareToWebLayerImplSimple
#endif
// A black box test that ensures WebLayerImplFixedBounds won't change target
// geometries. Simple case: identity transforms and zero anchor point.
TEST(WebLayerImplFixedBoundsTest, MAYBE_CompareToWebLayerImplSimple) {
  CompareFixedBoundsLayerAndNormalLayer(WebFloatPoint(0, 0), gfx::Transform());
}

// TODO(perkj): CompareToWebLayerImplComplex disabled on LSAN due to
// crbug/386080
#if defined(LEAK_SANITIZER)
#define MAYBE_CompareToWebLayerImplComplex DISABLED_CompareToWebLayerImplComplex
#else
#define MAYBE_CompareToWebLayerImplComplex CompareToWebLayerImplComplex
#endif
// A black box test that ensures WebLayerImplFixedBounds won't change target
// geometries. Complex case: complex transforms and non-zero anchor point.
TEST(WebLayerImplFixedBoundsTest, MAYBE_CompareToWebLayerImplComplex) {
  gfx::Transform transform;
  // These are arbitrary values that should not affect the results.
  transform.Translate3d(50, 60, 70);
  transform.Scale3d(2, 3, 4);
  transform.RotateAbout(gfx::Vector3dF(33, 44, 55), 99);

  CompareFixedBoundsLayerAndNormalLayer(WebFloatPoint(0, 0), transform);

  // With non-zero anchor point, WebLayerImplFixedBounds will fall back to
  // WebLayerImpl.
  CompareFixedBoundsLayerAndNormalLayer(WebFloatPoint(0.4f, 0.6f), transform);
}

}  // namespace
}  // namespace sky_viewer_cc
