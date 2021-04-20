/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Vector.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Vector3::toString() const {
  std::stringstream stream;
  stream << "{" << x << ", " << y << ", " << z << "}";
  return stream.str();
}

std::string Vector4::toString() const {
  std::stringstream stream;
  stream << "{" << x << ", " << y << ", " << z << ", " << w << "}";
  return stream.str();
}

}  // namespace geom
}  // namespace rl
