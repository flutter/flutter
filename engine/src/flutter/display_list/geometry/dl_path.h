// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_GEOMETRY_DL_PATH_H_
#define FLUTTER_DISPLAY_LIST_GEOMETRY_DL_PATH_H_

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/impeller/geometry/path.h"
#include "flutter/third_party/skia/include/core/SkPath.h"

namespace flutter {

class DlPath {
 public:
  DlPath() = default;
  explicit DlPath(const SkPath& path) : sk_path_(path) {}

  DlPath(const DlPath& path) = default;
  DlPath(DlPath&& path) = default;

  const SkPath& GetSkPath() const;
  impeller::Path GetPath() const;

  bool IsInverseFillType() const;

  bool IsRect(DlRect* rect, bool* is_closed = nullptr) const;
  bool IsOval(DlRect* bounds) const;

  bool IsSkRect(SkRect* rect, bool* is_closed = nullptr) const;
  bool IsSkOval(SkRect* bounds) const;
  bool IsSkRRect(SkRRect* rrect) const;

  SkRect GetSkBounds() const;
  DlRect GetBounds() const;

  bool operator==(const DlPath& other) const;

  bool IsConverted() const;

 private:
  const SkPath sk_path_;
  mutable impeller::Path path_;

  static impeller::Path ConvertToImpellerPath(const SkPath& path,
                                              const DlPoint& shift = DlPoint());
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_GEOMETRY_DL_PATH_H_
