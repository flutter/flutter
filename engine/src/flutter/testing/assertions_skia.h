// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_ASSERTIONS_SKIA_H_
#define FLUTTER_TESTING_ASSERTIONS_SKIA_H_

#include <ostream>

#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkMatrix44.h"
#include "third_party/skia/include/core/SkPoint3.h"
#include "third_party/skia/include/core/SkRRect.h"

//------------------------------------------------------------------------------
// Printing
//------------------------------------------------------------------------------

inline std::ostream& operator<<(std::ostream& os, const SkMatrix& m) {
  os << std::endl;
  os << "Scale X: " << m[SkMatrix::kMScaleX] << ", ";
  os << "Skew  X: " << m[SkMatrix::kMSkewX] << ", ";
  os << "Trans X: " << m[SkMatrix::kMTransX] << std::endl;
  os << "Skew  Y: " << m[SkMatrix::kMSkewY] << ", ";
  os << "Scale Y: " << m[SkMatrix::kMScaleY] << ", ";
  os << "Trans Y: " << m[SkMatrix::kMTransY] << std::endl;
  os << "Persp X: " << m[SkMatrix::kMPersp0] << ", ";
  os << "Persp Y: " << m[SkMatrix::kMPersp1] << ", ";
  os << "Persp Z: " << m[SkMatrix::kMPersp2];
  os << std::endl;
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkMatrix44& m) {
  os << m.get(0, 0) << ", " << m.get(0, 1) << ", " << m.get(0, 2) << ", "
     << m.get(0, 3) << std::endl;
  os << m.get(1, 0) << ", " << m.get(1, 1) << ", " << m.get(1, 2) << ", "
     << m.get(1, 3) << std::endl;
  os << m.get(2, 0) << ", " << m.get(2, 1) << ", " << m.get(2, 2) << ", "
     << m.get(2, 3) << std::endl;
  os << m.get(3, 0) << ", " << m.get(3, 1) << ", " << m.get(3, 2) << ", "
     << m.get(3, 3);
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkVector3& v) {
  os << v.x() << ", " << v.y() << ", " << v.z();
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkVector4& v) {
  os << v.fData[0] << ", " << v.fData[1] << ", " << v.fData[2] << ", "
     << v.fData[3];
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkRect& r) {
  os << "LTRB: " << r.fLeft << ", " << r.fTop << ", " << r.fRight << ", "
     << r.fBottom;
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkRRect& r) {
  os << "LTRB: " << r.rect().fLeft << ", " << r.rect().fTop << ", "
     << r.rect().fRight << ", " << r.rect().fBottom;
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkPoint& r) {
  os << "XY: " << r.fX << ", " << r.fY;
  return os;
}

inline std::ostream& operator<<(std::ostream& os, const SkISize& size) {
  os << size.width() << ", " << size.height();
  return os;
}

#endif  // FLUTTER_TESTING_ASSERTIONS_SKIA_H_
