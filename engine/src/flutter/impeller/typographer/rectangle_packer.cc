// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/rectangle_packer.h"

#include <algorithm>
#include <vector>

namespace impeller {

// Pack rectangles and track the current silhouette
// Based, in part, on Jukka Jylanki's work at http://clb.demon.fi
// and ported from Skia's implementation
// https://github.com/google/skia/blob/b5de4b8ae95c877a9ecfad5eab0765bc22550301/src/gpu/RectanizerSkyline.cpp
class SkylineRectanglePacker final : public RectanglePacker {
 public:
  SkylineRectanglePacker(int w, int h) : RectanglePacker(w, h) {
    this->reset();
  }

  ~SkylineRectanglePacker() final {}

  void reset() final {
    area_so_far_ = 0;
    skyline_.clear();
    skyline_.push_back(SkylineSegment{0, 0, this->width()});
  }

  bool addRect(int w, int h, IPoint16* loc) final;

  float percentFull() const final {
    return area_so_far_ / ((float)this->width() * this->height());
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
  // the skyline segments >= 'skylineIndex'? If so, return true and fill in
  // 'y' with the y-location at which it fits (the x location is pulled from
  // 'skylineIndex's segment.
  bool rectangleFits(int skylineIndex, int width, int height, int* y) const;
  // Update the skyline structure to include a width x height rect located
  // at x,y.
  void addSkylineLevel(int skylineIndex, int x, int y, int width, int height);
};

bool SkylineRectanglePacker::addRect(int width, int height, IPoint16* loc) {
  if ((unsigned)width > (unsigned)this->width() ||
      (unsigned)height > (unsigned)this->height()) {
    return false;
  }

  // find position for new rectangle
  int bestWidth = this->width() + 1;
  int bestX = 0;
  int bestY = this->height() + 1;
  int bestIndex = -1;
  for (int i = 0; i < (int)skyline_.size(); ++i) {
    int y;
    if (this->rectangleFits(i, width, height, &y)) {
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
    this->addSkylineLevel(bestIndex, bestX, bestY, width, height);
    loc->x_ = bestX;
    loc->y_ = bestY;

    area_so_far_ += width * height;
    return true;
  }

  loc->x_ = 0;
  loc->y_ = 0;
  return false;
}

bool SkylineRectanglePacker::rectangleFits(int skylineIndex,
                                           int width,
                                           int height,
                                           int* ypos) const {
  int x = skyline_[skylineIndex].x_;
  if (x + width > this->width()) {
    return false;
  }

  int widthLeft = width;
  int i = skylineIndex;
  int y = skyline_[skylineIndex].y_;
  while (widthLeft > 0 && i < (int)skyline_.size()) {
    y = std::max(y, skyline_[i].y_);
    if (y + height > this->height()) {
      return false;
    }
    widthLeft -= skyline_[i].width_;
    ++i;
  }

  *ypos = y;
  return true;
}

void SkylineRectanglePacker::addSkylineLevel(int skylineIndex,
                                             int x,
                                             int y,
                                             int width,
                                             int height) {
  SkylineSegment newSegment;
  newSegment.x_ = x;
  newSegment.y_ = y + height;
  newSegment.width_ = width;
  skyline_.insert(std::next(skyline_.begin(), skylineIndex), newSegment);

  FML_DCHECK(newSegment.x_ + newSegment.width_ <= this->width());
  FML_DCHECK(newSegment.y_ <= this->height());

  // delete width of the new skyline segment from following ones
  for (int i = skylineIndex + 1; i < (int)skyline_.size(); ++i) {
    // The new segment subsumes all or part of skyline_[i]
    FML_DCHECK(skyline_[i - 1].x_ <= skyline_[i].x_);

    if (skyline_[i].x_ < skyline_[i - 1].x_ + skyline_[i - 1].width_) {
      int shrink = skyline_[i - 1].x_ + skyline_[i - 1].width_ - skyline_[i].x_;

      skyline_[i].x_ += shrink;
      skyline_[i].width_ -= shrink;

      if (skyline_[i].width_ <= 0) {
        // fully consumed, remove item at index i
        skyline_.erase(std::next(skyline_.begin(), i));
        --i;
      } else {
        // only partially consumed
        break;
      }
    } else {
      break;
    }
  }

  // merge skyline_s
  for (int i = 0; i < ((int)skyline_.size()) - 1; ++i) {
    if (skyline_[i].y_ == skyline_[i + 1].y_) {
      skyline_[i].width_ += skyline_[i + 1].width_;
      skyline_.erase(std::next(skyline_.begin(), i));
      --i;
    }
  }
}

std::unique_ptr<RectanglePacker> RectanglePacker::Factory(int width,
                                                          int height) {
  return std::make_unique<SkylineRectanglePacker>(width, height);
}

}  // namespace impeller
