// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GEOMETRY_SHEAR_H_
#define FLUTTER_IMPELLER_GEOMETRY_SHEAR_H_

#include <string>

namespace impeller {

// cppcoreguidelines-pro-type-member-init doesn't understand that the
// anonymous struct and `e` share storage in the union below.
// NOLINTBEGIN(cppcoreguidelines-pro-type-member-init)
struct Shear {
  union {
    struct {
      double xy = 0.0;
      double xz = 0.0;
      double yz = 0.0;
    };
    double e[3];
  };

  Shear() {}

  Shear(double xy, double xz, double yz) : xy(xy), xz(xz), yz(yz) {}

  bool operator==(const Shear& o) const {
    return xy == o.xy && xz == o.xz && yz == o.yz;
  }
};
// NOLINTEND(cppcoreguidelines-pro-type-member-init)

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GEOMETRY_SHEAR_H_
