// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DIFF_CONTEXT_H_
#define FLUTTER_FLOW_DIFF_CONTEXT_H_

#include <map>
#include <vector>
#include "flutter/flow/paint_region.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkRect.h"

namespace flutter {

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

class Layer;

// Represents area that needs to be updated in front buffer (frame_damage) and
// area that is going to be painted to in back buffer (buffer_damage).
struct Damage {
  // This is the damage between current and previous frame;
  // If embedder supports partial update, this is the region that needs to be
  // repainted.
  // Corresponds to "surface damage" from EGL_KHR_partial_update.
  SkIRect frame_damage;

  // Reflects actual change to target framebuffer; This is frame_damage +
  // damage previously acumulated for target framebuffer.
  // All drawing will be clipped to this region. Knowing the affected area
  // upfront may be useful for tile based GPUs.
  // Corresponds to "buffer damage" from EGL_KHR_partial_update.
  SkIRect buffer_damage;
};

// Layer Unique Id to PaintRegion
using PaintRegionMap = std::map<uint64_t, PaintRegion>;

// Tracks state during tree diffing process and computes resulting damage
class DiffContext {
 public:
  explicit DiffContext(SkISize frame_size,
                       double device_pixel_aspect_ratio,
                       PaintRegionMap& this_frame_paint_region_map,
                       const PaintRegionMap& last_frame_paint_region_map);

  // Starts a new subtree.
  void BeginSubtree();

  // Ends current subtree; All modifications to state (transform, cullrect,
  // dirty) will be restored
  void EndSubtree();

  // Creates subtree in current scope and closes it on scope exit
  class AutoSubtreeRestore {
    FML_DISALLOW_COPY_ASSIGN_AND_MOVE(AutoSubtreeRestore);

   public:
    explicit AutoSubtreeRestore(DiffContext* context) : context_(context) {
      context->BeginSubtree();
    }
    ~AutoSubtreeRestore() { context_->EndSubtree(); }

   private:
    DiffContext* context_;
  };

  // Pushes additional transform for current subtree
  void PushTransform(const SkMatrix& transform);

  // Pushes cull rect for current subtree
  bool PushCullRect(const SkRect& clip);

  // Returns transform matrix for current subtree
  const SkMatrix& GetTransform() const { return state_.transform; }

  // Return cull rect for current subtree (in local coordinates)
  const SkRect& GetCullRect() const { return state_.cull_rect; }

  // Sets the dirty flag on current subtree;
  //
  // previous_paint_region, which should represent region of previous subtree
  // at this level will be added to damage area.
  //
  // Each paint region added to dirty subtree (through AddPaintRegion) is also
  // added to damage.
  void MarkSubtreeDirty(
      const PaintRegion& previous_paint_region = PaintRegion());

  bool IsSubtreeDirty() const { return state_.dirty; }

  // Add layer bounds to current paint region; rect is in "local" (layer)
  // coordinates.
  void AddLayerBounds(const SkRect& rect);

  // Add entire paint region of retained layer for current subtree. This can
  // only be used in subtrees that are not dirty, otherwise ancestor transforms
  // or clips may result in different paint region.
  void AddExistingPaintRegion(const PaintRegion& region);

  // The idea of readback region is that if any part of the readback region
  // needs to be repainted, then the whole readback region must be repainted;
  //
  // Readback rect is in screen coordinates.
  void AddReadbackRegion(const SkIRect& rect);

  // Returns the paint region for current subtree; Each rect in paint region is
  // in screen coordinates; Once a layer accumulates the paint regions of its
  // children, this PaintRegion value can be associated with the current layer
  // using DiffContext::SetLayerPaintRegion.
  PaintRegion CurrentSubtreeRegion() const;

  // Computes final damage
  //
  // additional_damage is the previously accumulated frame_damage for
  // current framebuffer
  Damage ComputeDamage(const SkIRect& additional_damage) const;

  double frame_device_pixel_ratio() const { return frame_device_pixel_ratio_; };

  // Adds the region to current damage. Used for removed layers, where instead
  // of diffing the layer its paint region is direcly added to damage.
  void AddDamage(const PaintRegion& damage);

  // Associates the paint region with specified layer and current layer tree.
  // The paint region can not be stored directly in layer itself, because same
  // retained layer instance can possibly paint in different locations depending
  // on ancestor layers.
  void SetLayerPaintRegion(const Layer* layer, const PaintRegion& region);

  // Retrieves the paint region associated with specified layer and previous
  // frame layer tree.
  PaintRegion GetOldLayerPaintRegion(const Layer* layer) const;

  class Statistics {
   public:
    // Picture replaced by different picture
    void AddNewPicture() { ++new_pictures_; }

    // Picture that would require deep comparison but was considered too complex
    // to serialize and thus was treated as new picture
    void AddPictureTooComplexToCompare() { ++pictures_too_complex_to_compare_; }

    // Picture that has identical instance between frames
    void AddSameInstancePicture() { ++same_instance_pictures_; };

    // Picture that had to be serialized to compare for equality
    void AddDeepComparePicture() { ++deep_compare_pictures_; }

    // Picture that had to be serialized to compare (different instances),
    // but were equal
    void AddDifferentInstanceButEqualPicture() {
      ++different_instance_but_equal_pictures_;
    };

    // Logs the statistics to trace counter
    void LogStatistics();

   private:
    int new_pictures_ = 0;
    int pictures_too_complex_to_compare_ = 0;
    int same_instance_pictures_ = 0;
    int deep_compare_pictures_ = 0;
    int different_instance_but_equal_pictures_ = 0;
  };

  Statistics& statistics() { return statistics_; }

 private:
  struct State {
    State();

    bool dirty;
    SkRect cull_rect;
    SkMatrix transform;
    size_t rect_index_;
  };

  std::shared_ptr<std::vector<SkRect>> rects_;
  State state_;
  SkISize frame_size_;
  double frame_device_pixel_ratio_;
  std::vector<State> state_stack_;

  SkRect damage_ = SkRect::MakeEmpty();

  PaintRegionMap& this_frame_paint_region_map_;
  const PaintRegionMap& last_frame_paint_region_map_;

  void AddDamage(const SkRect& rect);

  struct Readback {
    // Index of rects_ entry that this readback belongs to. Used to
    // determine if subtree has any readback
    size_t position;

    // readback area, in screen coordinates
    SkIRect rect;
  };

  std::vector<Readback> readbacks_;
  Statistics statistics_;
};

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

}  // namespace flutter

#endif  // FLUTTER_FLOW_DIFF_CONTEXT_H_
