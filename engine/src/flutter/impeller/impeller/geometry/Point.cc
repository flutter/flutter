/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Point.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Point::toString() const {
  std::stringstream stream;
  stream << x << "," << y;
  return stream.str();
}

void Point::fromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> x;
  stream.ignore();
  stream >> y;
}

}  // namespace geom
}  // namespace rl
