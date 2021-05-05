// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <string>

namespace rl {
namespace geom {

struct Shear {
  union {
    struct {
      double xy;
      double xz;
      double yz;
    };
    double e[3];
  };

  Shear() : xy(0.0), xz(0.0), yz(0.0) {}

  Shear(double xy, double xz, double yz) : xy(xy), xz(xz), yz(yz) {}

  bool operator==(const Shear& o) const {
    return xy == o.xy && xz == o.xz && yz == o.yz;
  }

  bool operator!=(const Shear& o) const { return !(*this == o); }

  std::string toString() const;
};

}  // namespace geom
}  // namespace rl
