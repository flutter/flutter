// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_PHYSICAL_MODEL_LAYER_H_
#define FLUTTER_FLOW_LAYERS_PHYSICAL_MODEL_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flow {

class PhysicalLayerShape;

class PhysicalModelLayer : public ContainerLayer {
 public:
  PhysicalModelLayer();
  ~PhysicalModelLayer() override;

  void set_shape(std::unique_ptr<PhysicalLayerShape> shape) {
    shape_ = std::move(shape);
  }
  void set_elevation(float elevation) { elevation_ = elevation; }
  void set_color(SkColor color) { color_ = color; }
  void set_device_pixel_ratio(SkScalar dpr) { device_pixel_ratio_ = dpr; }

  static void DrawShadow(SkCanvas* canvas,
                         const SkPath& path,
                         SkColor color,
                         float elevation,
                         bool transparentOccluder,
                         SkScalar dpr);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  std::unique_ptr<PhysicalLayerShape> shape_;
  float elevation_;
  SkColor color_;
  SkScalar device_pixel_ratio_;
};

// Common interface for the shape operations needed by PhysicalModelLayer.
//
// Once Scenic supports specifying physical layers with paths we can get rid
// of this class and the subclasses, and have a single implementation of
// PhysicalModelLayer that holds an SkPath.
// TODO(amirh): remove this once Scenic supports arbitrary shaped layers.
class PhysicalLayerShape {
 public:
  virtual const SkRect& getBounds() const = 0;
  virtual SkPath getPath() const = 0;
  virtual void clipCanvas(SkCanvas& canvas) const = 0;
  virtual bool isRect() const = 0;
#if defined(OS_FUCHSIA)
  virtual const SkRRect& getFrameRRect() const = 0;
#endif  // defined(OS_FUCHSIA)
};

class PhysicalLayerRRect final : public PhysicalLayerShape {
 public:
  PhysicalLayerRRect(const SkRRect& rrect) { rrect_ = rrect; }

  // |flow::PhysicalLayerShape|
  const SkRect& getBounds() const override { return rrect_.getBounds(); }

  // |flow::PhysicalLayerShape|
  SkPath getPath() const override;

  // |flow::PhysicalLayerShape|
  void clipCanvas(SkCanvas& canvas) const override {
    canvas.clipRRect(rrect_, true);
  }

  // |flow::PhysicalLayerShape|
  bool isRect() const override { return rrect_.isRect(); }

#if defined(OS_FUCHSIA)
  // |flow::PhysicalLayerShape|
  const SkRRect& getFrameRRect() const override { return rrect_; }
#endif  // defined(OS_FUCHSIA)

 private:
  SkRRect rrect_;
};

class PhysicalLayerPath final : public PhysicalLayerShape {
 public:
  PhysicalLayerPath(const SkPath& path) {
    path_ = path;
#if defined(OS_FUCHSIA)
    frameRRect_ = SkRRect::MakeRect(path.getBounds());
#endif  // defined(OS_FUCHSIA)
  }

  // |flow::PhysicalLayerShape|
  const SkRect& getBounds() const override { return path_.getBounds(); }

  // |flow::PhysicalLayerShape|
  SkPath getPath() const override { return path_; }

  // |flow::PhysicalLayerShape|
  void clipCanvas(SkCanvas& canvas) const override {
    canvas.clipPath(path_, true);
  }

  // |flow::PhysicalLayerShape|
  bool isRect() const override { return false; }

#if defined(OS_FUCHSIA)
  // Scenic does not currently support compositing arbitrary shaped layers,
  // so we just use the path's bounding rectangle.
  // |flow::PhysicalLayerShape|
  const SkRRect& getFrameRRect() const override { return frameRRect_; }
#endif  // defined(OS_FUCHSIA)
 private:
  SkPath path_;
#if defined(OS_FUCHSIA)
  SkRRect frameRRect_;
#endif  // defined(OS_FUCHSIA)
};

}  // namespace flow

#endif  // FLUTTER_FLOW_LAYERS_PHYSICAL_MODEL_LAYER_H_
