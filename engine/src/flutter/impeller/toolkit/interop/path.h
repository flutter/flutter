// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_PATH_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_PATH_H_

#include "flutter/third_party/skia/include/core/SkPath.h"
#include "flutter/third_party/skia/include/core/SkPathBuilder.h"
#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/object.h"

namespace impeller::interop {

class Path final
    : public Object<Path, IMPELLER_INTERNAL_HANDLE_NAME(ImpellerPath)> {
 public:
  explicit Path(const SkPath& path);

  ~Path();

  Path(const Path&) = delete;

  Path& operator=(const Path&) = delete;

  SkPath GetPath() const;

  ImpellerRect GetBounds() const;

 private:
  SkPathBuilder path_;
};

}  // namespace impeller::interop

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_PATH_H_
