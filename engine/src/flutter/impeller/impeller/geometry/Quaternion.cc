/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Quaternion.h"
#include <sstream>

namespace rl {
namespace geom {

Quaternion Quaternion::slerp(const Quaternion& to, double time) const {
  double cosine = dot(to);
  if (fabs(cosine) < 1.0 - 1e-3 /* epsilon */) {
    /*
     *  Spherical Interpolation.
     */
    auto sine = sqrt(1.0 - cosine * cosine);
    auto angle = atan2(sine, cosine);
    auto sineInverse = 1.0 / sine;
    auto c0 = sin((1.0 - time) * angle) * sineInverse;
    auto c1 = sin(time * angle) * sineInverse;
    return *this * c0 + to * c1;
  } else {
    /*
     *  Linear Interpolation.
     */
    return (*this * (1.0 - time) + to * time).normalize();
  }
}

std::string Quaternion::toString() const {
  std::stringstream stream;
  stream << "{" << x << ", "
         << ", " << y << ", " << z << ", " << w << "}";
  return stream.str();
}

}  // namespace geom
}  // namespace rl
