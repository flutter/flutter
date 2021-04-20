/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Shear.h"
#include <sstream>

namespace rl {
namespace geom {

std::string Shear::toString() const {
  std::stringstream stream;
  stream << "{" << xy << ", " << xz << ", " << yz << "}";
  return stream.str();
}

}  // namespace geom
}  // namespace rl
