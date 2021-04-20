/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

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
