// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/path_geometry_base.h"

namespace impeller {

PathGeometryBase::PathGeometryBase(const Rect& rect)
    : rect_source_(rect), source_(rect_source_) {}

PathGeometryBase::PathGeometryBase(const Oval& oval)
    : oval_source_(oval), source_(oval_source_) {}

PathGeometryBase::PathGeometryBase(const RoundRect& round_rect)
    : rrect_source_(round_rect), source_(rrect_source_) {}

PathGeometryBase::PathGeometryBase(const RoundSuperellipse& rse)
    : rse_source_(rse), source_(rse_source_) {}

PathGeometryBase::PathGeometryBase(const flutter::DlPath& path)
    : path_source_(path), source_(path_source_) {}

PathGeometryBase::~PathGeometryBase() {}

}  // namespace impeller
