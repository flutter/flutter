/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Size.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Size::toString() const {
  std::stringstream stream;
  stream << width << "," << height;
  return stream.str();
}

void Size::fromString(const std::string& str) {
  std::stringstream stream(str);
  stream >> width;
  stream.ignore();
  stream >> height;
}

}  // namespace geom
}  // namespace rl
