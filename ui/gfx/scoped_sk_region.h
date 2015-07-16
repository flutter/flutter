// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_SCOPED_SK_REGION_H_
#define UI_GFX_SCOPED_SK_REGION_H_

#include "third_party/skia/include/core/SkRegion.h"

namespace gfx {

// Wraps an SkRegion.
class ScopedSkRegion {
 public:
  ScopedSkRegion() : region_(NULL) {}
  explicit ScopedSkRegion(SkRegion* region) : region_(region) {}

  ~ScopedSkRegion() {
    delete region_;
  }

  void Set(SkRegion* region) {
    delete region_;
    region_ = region;
  }

  SkRegion* Get() {
    return region_;
  }

  SkRegion* release() {
    SkRegion* region = region_;
    region_ = NULL;
    return region;
  }

 private:
  SkRegion* region_;

  DISALLOW_COPY_AND_ASSIGN(ScopedSkRegion);
};

}  // namespace gfx

#endif  // UI_GFX_SCOPED_SK_REGION_H_
