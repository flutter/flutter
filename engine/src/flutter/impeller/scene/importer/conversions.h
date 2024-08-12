// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_SCENE_IMPORTER_CONVERSIONS_H_
#define FLUTTER_IMPELLER_SCENE_IMPORTER_CONVERSIONS_H_

#include <cstddef>
#include <map>
#include <vector>

#include "impeller/geometry/matrix.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {

Matrix ToMatrix(const std::vector<double>& m);

//-----------------------------------------------------------------------------
/// Flatbuffers -> Impeller
///

Matrix ToMatrix(const fb::Matrix& m);

Vector2 ToVector2(const fb::Vec2& c);

Vector3 ToVector3(const fb::Vec3& c);

Vector4 ToVector4(const fb::Vec4& c);

Color ToColor(const fb::Color& c);

//-----------------------------------------------------------------------------
/// Impeller -> Flatbuffers
///

fb::Matrix ToFBMatrix(const Matrix& m);

std::unique_ptr<fb::Matrix> ToFBMatrixUniquePtr(const Matrix& m);

fb::Vec2 ToFBVec2(const Vector2 v);

fb::Vec3 ToFBVec3(const Vector3 v);

fb::Vec4 ToFBVec4(const Vector4 v);

fb::Color ToFBColor(const Color c);

std::unique_ptr<fb::Color> ToFBColor(const std::vector<double>& c);

}  // namespace importer
}  // namespace scene
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_SCENE_IMPORTER_CONVERSIONS_H_
