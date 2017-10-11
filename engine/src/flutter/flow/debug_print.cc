// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/debug_print.h"

#include <ostream>

#include "third_party/skia/include/core/SkString.h"

std::ostream& operator<<(std::ostream& os, const flow::MatrixDecomposition& m) {
  if (!m.IsValid()) {
    os << "Invalid Matrix!" << std::endl;
    return os;
  }

  os << "Translation (x, y, z): " << m.translation() << std::endl;
  os << "Scale (z, y, z): " << m.scale() << std::endl;
  os << "Shear (zy, yz, zx): " << m.shear() << std::endl;
  os << "Perspective (x, y, z, w): " << m.perspective() << std::endl;
  os << "Rotation (x, y, z, w): " << m.rotation() << std::endl;

  return os;
}

std::ostream& operator<<(std::ostream& os, const SkMatrix& m) {
  SkString string;
  m.toString(&string);
  os << string.c_str();
  return os;
}

std::ostream& operator<<(std::ostream& os, const SkMatrix44& m) {
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

std::ostream& operator<<(std::ostream& os, const SkVector3& v) {
  os << v.x() << ", " << v.y() << ", " << v.z();
  return os;
}

std::ostream& operator<<(std::ostream& os, const SkVector4& v) {
  os << v.fData[0] << ", " << v.fData[1] << ", " << v.fData[2] << ", "
     << v.fData[3];
  return os;
}

std::ostream& operator<<(std::ostream& os, const SkRect& r) {
  os << "LTRB: " << r.fLeft << ", " << r.fTop << ", " << r.fRight << ", "
     << r.fBottom;
  return os;
}

std::ostream& operator<<(std::ostream& os, const SkRRect& r) {
  os << "LTRB: " << r.rect().fLeft << ", " << r.rect().fTop << ", "
     << r.rect().fRight << ", " << r.rect().fBottom;
  return os;
}

std::ostream& operator<<(std::ostream& os, const SkPoint& r) {
  os << "XY: " << r.fX << ", " << r.fY;
  return os;
}

std::ostream& operator<<(std::ostream& os, const flow::RasterCacheKey& k) {
  os << "Picture: " << k.picture_id() << " Scale: " << k.scale_key().width()
     << ", " << k.scale_key().height();
  return os;
}
