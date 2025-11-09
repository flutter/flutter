// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TOOLS_PATH_OPS_PATH_OPS_H_
#define FLUTTER_TOOLS_PATH_OPS_PATH_OPS_H_

#include "third_party/skia/include/core/SkPathBuilder.h"
#include "third_party/skia/include/core/SkPathTypes.h"
#include "third_party/skia/include/pathops/SkPathOps.h"

#ifdef _WIN32
#define API __declspec(dllexport)
#else
#define API __attribute__((visibility("default")))
#endif

extern "C" {

namespace flutter {

API SkPathBuilder* CreatePath(SkPathFillType fill_type);

API void DestroyPath(SkPathBuilder* path);

API void MoveTo(SkPathBuilder* path, SkScalar x, SkScalar y);

API void LineTo(SkPathBuilder* path, SkScalar x, SkScalar y);

API void CubicTo(SkPathBuilder* path,
                 SkScalar x1,
                 SkScalar y1,
                 SkScalar x2,
                 SkScalar y2,
                 SkScalar x3,
                 SkScalar y3);

API void Close(SkPathBuilder* path);

API void Reset(SkPathBuilder* path);

API void Op(SkPathBuilder* one, SkPathBuilder* two, SkPathOp op);

API int GetFillType(SkPathBuilder* path);

struct API PathData {
  uint8_t* verbs;
  size_t verb_count;
  float* points;
  size_t point_count;
};

API struct PathData* Data(SkPathBuilder* path);

API void DestroyData(PathData* data);

}  // namespace flutter
}

#endif  // FLUTTER_TOOLS_PATH_OPS_PATH_OPS_H_
