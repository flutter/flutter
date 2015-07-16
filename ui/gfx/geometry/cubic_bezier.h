// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_GEOMETRY_CUBIC_BEZIER_H_
#define UI_GFX_GEOMETRY_CUBIC_BEZIER_H_

#include "base/macros.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

class GFX_EXPORT CubicBezier {
 public:
  CubicBezier(double x1, double y1, double x2, double y2);
  ~CubicBezier();

  // Returns an approximation of y at the given x.
  double Solve(double x) const;

  // Returns an approximation of dy/dx at the given x.
  double Slope(double x) const;

  // Sets |min| and |max| to the bezier's minimum and maximium y values in the
  // interval [0, 1].
  void Range(double* min, double* max) const;

 private:
  double x1_;
  double y1_;
  double x2_;
  double y2_;

  DISALLOW_ASSIGN(CubicBezier);
};

}  // namespace gfx

#endif  // UI_GFX_GEOMETRY_CUBIC_BEZIER_H_
