// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_
#define FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_

#include "flutter/flow/layers/container_layer.h"

namespace flutter {

// Don't add an OpacityLayer with no children to the layer tree. Painting an
// OpacityLayer is very costly due to the saveLayer call. If there's no child,
// having the OpacityLayer or not has the same effect. In debug_unopt build,
// |Preroll| will assert if there are no children.
class OpacityLayer : public ContainerLayer {
 public:
  // An offset is provided here because OpacityLayer.addToScene method in the
  // Flutter framework can take an optional offset argument.
  //
  // By default, that offset is always zero, and all the offsets are handled by
  // some parent TransformLayers. But we allow the offset to be non-zero for
  // backward compatibility. If it's non-zero, the old behavior is to propage
  // that offset to all the leaf layers (e.g., PictureLayer). That will make
  // the retained rendering inefficient as a small offset change could propagate
  // to many leaf layers. Therefore we try to capture that offset here to stop
  // the propagation as repainting the OpacityLayer is expensive.
  OpacityLayer(SkAlpha alpha, const SkPoint& offset);

  void Add(std::shared_ptr<Layer> layer) override;

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;

  void Paint(PaintContext& context) const override;

#if defined(OS_FUCHSIA)
  void UpdateScene(SceneUpdateContext& context) override;
#endif  // defined(OS_FUCHSIA)

 private:
  /**
   * @brief Returns the ContainerLayer used to hold all of the children
   * of the OpacityLayer.
   *
   * Often opacity layers will only have a single child since the associated
   * Flutter widget is specified with only a single child widget pointer.
   * But depending on the structure of the child tree that single widget at
   * the framework level can turn into multiple children at the engine
   * API level since there is no guarantee of a 1:1 correspondence of widgets
   * to engine layers. This synthetic child container layer is established to
   * hold all of the children in a single layer so that we can cache their
   * output, but this synthetic layer will typically not be the best choice
   * for the layer cache since the synthetic container is created fresh with
   * each new OpacityLayer, and so may not be stable from frame to frame.
   *
   * @see GetCacheableChild()
   * @return the ContainerLayer child used to hold the children
   */
  ContainerLayer* GetChildContainer() const;

  /**
   * @brief Returns the best choice for a Layer object that can be used
   * in RasterCache operations to cache the children of the OpacityLayer.
   *
   * The returned Layer must represent all children and try to remain stable
   * if the OpacityLayer is reconstructed in subsequent frames of the scene.
   *
   * Note that since the synthetic child container returned from the
   * GetChildContainer() method is created fresh with each new OpacityLayer,
   * its return value will not be a good candidate for caching. But if the
   * standard recommendations for animations are followed and the child widget
   * is wrapped with a RepaintBoundary widget at the framework level, then
   * the synthetic child container should contain the same single child layer
   * on each frame. Under those conditions, that single child of the child
   * container will be the best candidate for caching in the RasterCache
   * and this method will return that single child if possible to improve
   * the performance of caching the children.
   *
   * Note that if GetCacheableChild() does not find a single stable child of
   * the child container it will return the child container as a fallback.
   * Even though that child is new in each frame of an animation and thus we
   * cannot reuse the cached layer raster between animation frames, the single
   * container child will allow us to paint the child onto an offscreen buffer
   * during Preroll() which reduces one render target switch compared to
   * painting the child on the fly via an AutoSaveLayer in Paint() and thus
   * still improves our performance.
   *
   * @see GetChildContainer()
   * @return the best candidate Layer for caching the children
   */
  Layer* GetCacheableChild() const;

  SkAlpha alpha_;
  SkPoint offset_;
  SkRRect frameRRect_;

  FML_DISALLOW_COPY_AND_ASSIGN(OpacityLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_OPACITY_LAYER_H_
