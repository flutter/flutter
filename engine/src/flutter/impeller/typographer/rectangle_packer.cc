// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/rectangle_packer.h"

#include <algorithm>
#include <memory>
#include <vector>

#include "flutter/fml/logging.h"

namespace impeller {

// Pack rectangles and track the current silhouette
// Based, in part, on Jukka Jylanki's work at http://clb.demon.fi
// and ported from Skia's implementation
// https://github.com/google/skia/blob/b5de4b8ae95c877a9ecfad5eab0765bc22550301/src/gpu/RectanizerSkyline.cpp
class SkylineRectanglePacker final : public RectanglePacker {
 public:
  SkylineRectanglePacker(int w, int h) : RectanglePacker(w, h) { Reset(); }

  ~SkylineRectanglePacker() final {}

  void Reset() final {
    area_so_far_ = 0;
    skyline_.clear();
    skyline_.push_back(SkylineSegment{0, 0, width()});
  }

  bool GrowTo(int w, int h) override;

  bool AddRect(int w, int h, IPoint16* loc) final;

  Scalar PercentFull() const final {
    return 100.0f * area_so_far_ / (static_cast<float>(width()) * height());
  }

 private:
  struct SkylineSegment {
    int x_;
    int y_;
    int width_;
  };

  std::vector<SkylineSegment> skyline_;

  int32_t area_so_far_;

  // Can a width x height rectangle fit in the free space represented by
  // the skyline segments >= 'skyline_index'? If so, return true and fill in
  // 'y' with the y-location at which it fits (the x location is pulled from
  // 'skyline_index's segment.
  bool RectangleFits(size_t skyline_index, int width, int height, int* y) const;
  // Update the skyline structure to include a width x height rect located
  // at x,y.
  void AddSkylineLevel(size_t skylineIndex,
                       int x,
                       int y,
                       int width,
                       int height);
};

static constexpr bool kImproveEfficiency = true;

bool SkylineRectanglePacker::GrowTo(int w, int h) {
  // We might potentially be able to reduce the size of the area if there
  // are no rectangles already packed at those edges, but really there
  // should be no reason to shrink the packer area so we just forbit it.
  int old_width = width();
  int old_height = height();
  if (w < old_width || h < old_height) {
    return false;
  }

  if (kImproveEfficiency) {
    // Update the skyline to match the new width before we change it.
    if (w > old_width) {
      SkylineSegment& last = skyline_.back();
      if (last.y_ == 0) {
        // There was a segment at the end of the list that still started at
        // the bottom of the area, simply extend it to the new width.
        last.width_ = w - last.x_;
      } else {
        // We have a brand new segment of empty space at the end of the list.
        skyline_.emplace_back(old_width, 0, w - old_width);
      }
    }
    // We can freely expand the height without invalidating the skyline
    // segments.
  } else {
    // Just reduce the skyline to a single flat plane at the old height
    // so all new allocations go into the new area we just added. This
    // technique only works if we are growing it in height as it relies
    // on recreating the skyline itself as a single "floor".
    //
    // This code block matches the old behavior of growing the Impeller
    // glyph cache in which the old packer was abandoned completely and
    // a new packer allocated that only saw the new space.
    FML_DCHECK(h > old_height);
    skyline_.clear();
    skyline_.emplace_back(0, old_height, w);
  }

  width_ = w;
  height_ = h;

  return true;
}

bool SkylineRectanglePacker::AddRect(int p_width, int p_height, IPoint16* loc) {
  if (static_cast<unsigned>(p_width) > static_cast<unsigned>(width()) ||
      static_cast<unsigned>(p_height) > static_cast<unsigned>(height())) {
    return false;
  }

  // find position for new rectangle
  int bestWidth = width() + 1;
  int bestX = 0;
  int bestY = height() + 1;
  int bestIndex = -1;
  for (auto i = 0u; i < skyline_.size(); ++i) {
    int y;
    if (RectangleFits(i, p_width, p_height, &y)) {
      // minimize y position first, then width of skyline
      if (y < bestY || (y == bestY && skyline_[i].width_ < bestWidth)) {
        bestIndex = i;
        bestWidth = skyline_[i].width_;
        bestX = skyline_[i].x_;
        bestY = y;
      }
    }
  }

  // add rectangle to skyline
  if (-1 != bestIndex) {
    AddSkylineLevel(bestIndex, bestX, bestY, p_width, p_height);
    loc->x_ = bestX;
    loc->y_ = bestY;

    area_so_far_ += p_width * p_height;
    return true;
  }

  loc->x_ = 0;
  loc->y_ = 0;
  return false;
}

bool SkylineRectanglePacker::RectangleFits(size_t skyline_index,
                                           int p_width,
                                           int p_height,
                                           int* ypos) const {
  int x = skyline_[skyline_index].x_;
  if (x + p_width > width()) {
    return false;
  }

  int widthLeft = p_width;
  size_t i = skyline_index;
  int y = skyline_[skyline_index].y_;
  while (widthLeft > 0) {
    y = std::max(y, skyline_[i].y_);
    if (y + p_height > height()) {
      return false;
    }
    widthLeft -= skyline_[i].width_;
    i++;
    FML_CHECK(i < skyline_.size() || widthLeft <= 0);
  }

  *ypos = y;
  return true;
}

void SkylineRectanglePacker::AddSkylineLevel(size_t skyline_index,
                                             int x,
                                             int y,
                                             int p_width,
                                             int p_height) {
  SkylineSegment newSegment;
  newSegment.x_ = x;
  newSegment.y_ = y + p_height;
  newSegment.width_ = p_width;
  skyline_.insert(skyline_.begin() + skyline_index, newSegment);

  FML_DCHECK(newSegment.x_ + newSegment.width_ <= width());
  FML_DCHECK(newSegment.y_ <= height());

  // delete width of the new skyline segment from following ones
  for (auto i = skyline_index + 1; i < skyline_.size(); ++i) {
    // The new segment subsumes all or part of skyline_[i]
    FML_DCHECK(skyline_[i - 1].x_ <= skyline_[i].x_);

    if (skyline_[i].x_ < skyline_[i - 1].x_ + skyline_[i - 1].width_) {
      int shrink = skyline_[i - 1].x_ + skyline_[i - 1].width_ - skyline_[i].x_;

      skyline_[i].x_ += shrink;
      skyline_[i].width_ -= shrink;

      if (skyline_[i].width_ <= 0) {
        // fully consumed
        skyline_.erase(skyline_.begin() + i);
        --i;
      } else {
        // only partially consumed
        break;
      }
    } else {
      break;
    }
  }

  // merge skylines
  for (auto i = 0u; i < skyline_.size() - 1; ++i) {
    if (skyline_[i].y_ == skyline_[i + 1].y_) {
      skyline_[i].width_ += skyline_[i + 1].width_;
      skyline_.erase(skyline_.begin() + i + 1);
      --i;
    }
  }
}

std::shared_ptr<RectanglePacker> RectanglePacker::Factory(int width,
                                                          int height) {
  return std::make_shared<SkylineRectanglePacker>(width, height);
}

}  // namespace impeller
