// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/importer/conversions.h"

#include <cstring>

#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {

Matrix ToMatrix(const std::vector<double>& m) {
  return Matrix(m[0], m[1], m[2], m[3],    //
                m[4], m[5], m[6], m[7],    //
                m[8], m[9], m[10], m[11],  //
                m[12], m[13], m[14], m[15]);
}

//-----------------------------------------------------------------------------
/// Flatbuffers -> Impeller
///

Matrix ToMatrix(const fb::Matrix& m) {
  auto& a = *m.m();
  return Matrix(a[0], a[1], a[2], a[3],    //
                a[4], a[5], a[6], a[7],    //
                a[8], a[9], a[10], a[11],  //
                a[12], a[13], a[14], a[15]);
}

Vector2 ToVector2(const fb::Vec2& v) {
  return Vector2(v.x(), v.y());
}

Vector3 ToVector3(const fb::Vec3& v) {
  return Vector3(v.x(), v.y(), v.z());
}

Vector4 ToVector4(const fb::Vec4& v) {
  return Vector4(v.x(), v.y(), v.z(), v.w());
}

Color ToColor(const fb::Color& c) {
  return Color(c.r(), c.g(), c.b(), c.a());
}

//-----------------------------------------------------------------------------
/// Impeller -> Flatbuffers
///

fb::Matrix ToFBMatrix(const Matrix& m) {
  auto array = std::array<Scalar, 16>{m.m[0],  m.m[1],  m.m[2],  m.m[3],   //
                                      m.m[4],  m.m[5],  m.m[6],  m.m[7],   //
                                      m.m[8],  m.m[9],  m.m[10], m.m[11],  //
                                      m.m[12], m.m[13], m.m[14], m.m[15]};
  return fb::Matrix(array);
}

std::unique_ptr<fb::Matrix> ToFBMatrixUniquePtr(const Matrix& m) {
  auto array = std::array<Scalar, 16>{m.m[0],  m.m[1],  m.m[2],  m.m[3],   //
                                      m.m[4],  m.m[5],  m.m[6],  m.m[7],   //
                                      m.m[8],  m.m[9],  m.m[10], m.m[11],  //
                                      m.m[12], m.m[13], m.m[14], m.m[15]};
  return std::make_unique<fb::Matrix>(array);
}

fb::Vec2 ToFBVec2(const Vector2 v) {
  return fb::Vec2(v.x, v.y);
}

fb::Vec3 ToFBVec3(const Vector3 v) {
  return fb::Vec3(v.x, v.y, v.z);
}

fb::Vec4 ToFBVec4(const Vector4 v) {
  return fb::Vec4(v.x, v.y, v.z, v.w);
}

fb::Color ToFBColor(const Color c) {
  return fb::Color(c.red, c.green, c.blue, c.alpha);
}

std::unique_ptr<fb::Color> ToFBColor(const std::vector<double>& c) {
  auto* color = new fb::Color(c.size() > 0 ? c[0] : 1,  //
                              c.size() > 1 ? c[1] : 1,  //
                              c.size() > 2 ? c[2] : 1,  //
                              c.size() > 3 ? c[3] : 1);
  return std::unique_ptr<fb::Color>(color);
}

}  // namespace importer
}  // namespace scene
}  // namespace impeller
