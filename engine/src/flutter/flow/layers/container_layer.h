// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
#define FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_

#include <vector>
#include "flutter/flow/layers/layer.h"

namespace flutter {

class ContainerLayer : public Layer {
 public:
  ContainerLayer();

  virtual void Add(std::shared_ptr<Layer> layer);

  void Preroll(PrerollContext* context, const SkMatrix& matrix) override;
  void Paint(PaintContext& context) const override;
#if defined(LEGACY_FUCHSIA_EMBEDDER)
  void CheckForChildLayerBelow(PrerollContext* context) override;
  void UpdateScene(SceneUpdateContext& context) override;
#endif

  const std::vector<std::shared_ptr<Layer>>& layers() const { return layers_; }

 protected:
  void PrerollChildren(PrerollContext* context,
                       const SkMatrix& child_matrix,
                       SkRect* child_paint_bounds);
  void PaintChildren(PaintContext& context) const;

#if defined(LEGACY_FUCHSIA_EMBEDDER)
  void UpdateSceneChildren(SceneUpdateContext& context);
#endif

  // Try to prepare the raster cache for a given layer.
  //
  // The raster cache would fail if either of the followings is true:
  // 1. The context has a platform view.
  // 2. The context does not have a valid raster cache.
  // 3. The layer's paint bounds does not intersect with the cull rect.
  //
  // We make this a static function instead of a member function that directy
  // uses the "this" pointer as the layer because we sometimes need to raster
  // cache a child layer and one can't access its child's protected method.
  static void TryToPrepareRasterCache(PrerollContext* context,
                                      Layer* layer,
                                      const SkMatrix& matrix);

 private:
  std::vector<std::shared_ptr<Layer>> layers_;

  FML_DISALLOW_COPY_AND_ASSIGN(ContainerLayer);
};

//------------------------------------------------------------------------------
/// Some ContainerLayer objects perform a rendering operation or filter on
/// the rendered output of their children. Often that operation is changed
/// slightly from frame to frame as part of an animation. During such an
/// animation, the children can be cached if they are stable to avoid having
/// to render them on every frame. Even if the children are not stable,
/// rendering them into the raster cache during a Preroll operation will save
/// an extra change of rendering surface during the Paint phase as compared
/// to using the SaveLayer that would otherwise be needed with no caching.
///
/// Typically the Flutter Widget objects that lead to the creation of these
/// layers will try to enforce only a single child Widget by their design.
/// Unfortunately, the process of turning Widgets eventually into engine
/// layers is not a 1:1 process so this layer might end up with multiple
/// child layers even if the Widget only had a single child Widget.
///
/// When such a layer goes to cache the output of its children, it will
/// need to supply a single layer to the cache mechanism since the raster
/// cache uses a layer unique_id() as part of the cache key. If this layer
/// ended up with multiple children, then it must first collect them into
/// one layer for the cache mechanism. In order to provide a single layer
/// for all of the children, this utility class will implicitly collect
/// the children into a secondary ContainerLayer called the child container.
///
/// A by-product of creating a hidden child container, though, is that the
/// child container is created new every time this layer is created with
/// different properties, such as during an animation. In that scenario,
/// it would be best to cache the single real child of this layer if it
/// is unique and if it is stable from frame to frame. To facilitate this
/// optimal caching strategy, this class implements two accessor methods
/// to be used for different purposes:
///
/// When the layer needs to recurse to perform some operation on its children,
/// it can call GetChildContainer() to return the hidden container containing
/// all of the real children.
///
/// When the layer wants to cache the rendered contents of its children, it
/// should call GetCacheableChild() for best performance. This method may
/// end up returning the same layer as GetChildContainer(), but only if the
/// conditions for optimal caching of a single child are not met.
///
class MergedContainerLayer : public ContainerLayer {
 public:
  MergedContainerLayer();

  void Add(std::shared_ptr<Layer> layer) override;

 protected:
  /**
   * @brief Returns the ContainerLayer used to hold all of the children of the
   * MergedContainerLayer. Note that this may not be the best layer to use
   * for caching the children.
   *
   * @see GetCacheableChild()
   * @return the ContainerLayer child used to hold the children
   */
  ContainerLayer* GetChildContainer() const;

  /**
   * @brief Returns the best choice for a Layer object that can be used
   * in RasterCache operations to cache the children.
   *
   * The returned Layer must represent all children and try to remain stable
   * if the MergedContainerLayer is reconstructed in subsequent frames of
   * the scene.
   *
   * @see GetChildContainer()
   * @return the best candidate Layer for caching the children
   */
  Layer* GetCacheableChild() const;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MergedContainerLayer);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_CONTAINER_LAYER_H_
