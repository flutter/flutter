// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "skia/ext/platform_device.h"

#include "skia/ext/skia_utils_win.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRegion.h"
#include "third_party/skia/include/core/SkUtils.h"

namespace skia {

void InitializeDC(HDC context) {
  // Enables world transformation.
  // If the GM_ADVANCED graphics mode is set, GDI always draws arcs in the
  // counterclockwise direction in logical space. This is equivalent to the
  // statement that, in the GM_ADVANCED graphics mode, both arc control points
  // and arcs themselves fully respect the device context's world-to-device
  // transformation.
  BOOL res = SetGraphicsMode(context, GM_ADVANCED);
  SkASSERT(res != 0);

  // Enables dithering.
  res = SetStretchBltMode(context, HALFTONE);
  SkASSERT(res != 0);
  // As per SetStretchBltMode() documentation, SetBrushOrgEx() must be called
  // right after.
  res = SetBrushOrgEx(context, 0, 0, NULL);
  SkASSERT(res != 0);

  // Sets up default orientation.
  res = SetArcDirection(context, AD_CLOCKWISE);
  SkASSERT(res != 0);

  // Sets up default colors.
  res = SetBkColor(context, RGB(255, 255, 255));
  SkASSERT(res != CLR_INVALID);
  res = SetTextColor(context, RGB(0, 0, 0));
  SkASSERT(res != CLR_INVALID);
  res = SetDCBrushColor(context, RGB(255, 255, 255));
  SkASSERT(res != CLR_INVALID);
  res = SetDCPenColor(context, RGB(0, 0, 0));
  SkASSERT(res != CLR_INVALID);

  // Sets up default transparency.
  res = SetBkMode(context, OPAQUE);
  SkASSERT(res != 0);
  res = SetROP2(context, R2_COPYPEN);
  SkASSERT(res != 0);
}

PlatformSurface PlatformDevice::BeginPlatformPaint() {
  return 0;
}

void PlatformDevice::EndPlatformPaint() {
  // We don't clear the DC here since it will be likely to be used again.
  // Flushing will be done in onAccessBitmap.
}

// static
bool PlatformDevice::LoadPathToDC(HDC context, const SkPath& path) {
  switch (path.getFillType()) {
    case SkPath::kWinding_FillType: {
      int res = SetPolyFillMode(context, WINDING);
      SkASSERT(res != 0);
      break;
    }
    case SkPath::kEvenOdd_FillType: {
      int res = SetPolyFillMode(context, ALTERNATE);
      SkASSERT(res != 0);
      break;
    }
    default: {
      SkASSERT(false);
      break;
    }
  }
  BOOL res = BeginPath(context);
  if (!res) {
      return false;
  }

  CubicPaths paths;
  if (!SkPathToCubicPaths(&paths, path))
    return false;

  std::vector<POINT> points;
  for (CubicPaths::const_iterator path(paths.begin()); path != paths.end();
       ++path) {
    if (!path->size())
      continue;
    points.resize(0);
    points.reserve(path->size() * 3 / 4 + 1);
    points.push_back(SkPointToPOINT(path->front().p[0]));
    for (CubicPath::const_iterator point(path->begin()); point != path->end();
       ++point) {
      // Never add point->p[0]
      points.push_back(SkPointToPOINT(point->p[1]));
      points.push_back(SkPointToPOINT(point->p[2]));
      points.push_back(SkPointToPOINT(point->p[3]));
    }
    SkASSERT((points.size() - 1) % 3 == 0);
    // This is slightly inefficient since all straight line and quadratic lines
    // are "upgraded" to a cubic line.
    // TODO(maruel):  http://b/1147346 We should use
    // PolyDraw/PolyBezier/Polyline whenever possible.
    res = PolyBezier(context, &points.front(),
                     static_cast<DWORD>(points.size()));
    SkASSERT(res != 0);
    if (res == 0)
      break;
  }
  if (res == 0) {
    // Make sure the path is discarded.
    AbortPath(context);
  } else {
    res = EndPath(context);
    SkASSERT(res != 0);
  }
  return true;
}

// static
void PlatformDevice::LoadTransformToDC(HDC dc, const SkMatrix& matrix) {
  XFORM xf;
  xf.eM11 = matrix[SkMatrix::kMScaleX];
  xf.eM21 = matrix[SkMatrix::kMSkewX];
  xf.eDx = matrix[SkMatrix::kMTransX];
  xf.eM12 = matrix[SkMatrix::kMSkewY];
  xf.eM22 = matrix[SkMatrix::kMScaleY];
  xf.eDy = matrix[SkMatrix::kMTransY];
  SetWorldTransform(dc, &xf);
}

// static
bool PlatformDevice::SkPathToCubicPaths(CubicPaths* paths,
                                        const SkPath& skpath) {
  paths->clear();
  CubicPath* current_path = NULL;
  SkPoint current_points[4];
  CubicPoints points_to_add;
  SkPath::Iter iter(skpath, false);
  for (SkPath::Verb verb = iter.next(current_points);
       verb != SkPath::kDone_Verb;
       verb = iter.next(current_points)) {
    switch (verb) {
      case SkPath::kMove_Verb: {  // iter.next returns 1 point
        // Ignores it since the point is copied in the next operation. See
        // SkPath::Iter::next() for reference.
        paths->push_back(CubicPath());
        current_path = &paths->back();
        // Skip point addition.
        continue;
      }
      case SkPath::kLine_Verb: {  // iter.next returns 2 points
        points_to_add.p[0] = current_points[0];
        points_to_add.p[1] = current_points[0];
        points_to_add.p[2] = current_points[1];
        points_to_add.p[3] = current_points[1];
        break;
      }
      case SkPath::kQuad_Verb: {  // iter.next returns 3 points
        points_to_add.p[0] = current_points[0];
        points_to_add.p[1] = current_points[1];
        points_to_add.p[2] = current_points[2];
        points_to_add.p[3] = current_points[2];
        break;
      }
      case SkPath::kCubic_Verb: {  // iter.next returns 4 points
        points_to_add.p[0] = current_points[0];
        points_to_add.p[1] = current_points[1];
        points_to_add.p[2] = current_points[2];
        points_to_add.p[3] = current_points[3];
        break;
      }
      case SkPath::kClose_Verb: {  // iter.next returns 1 point (the last point)
        paths->push_back(CubicPath());
        current_path = &paths->back();
        continue;
      }
      default: {
        current_path = NULL;
        // Will return false.
        break;
      }
    }
    SkASSERT(current_path);
    if (!current_path) {
      paths->clear();
      return false;
    }
    current_path->push_back(points_to_add);
  }
  return true;
}

// static
void PlatformDevice::LoadClippingRegionToDC(HDC context,
                                            const SkRegion& region,
                                            const SkMatrix& transformation) {
  HRGN hrgn;
  if (region.isEmpty()) {
    // region can be empty, in which case everything will be clipped.
    hrgn = CreateRectRgn(0, 0, 0, 0);
  } else if (region.isRect()) {
    // We don't apply transformation, because the translation is already applied
    // to the region.
    hrgn = CreateRectRgnIndirect(&SkIRectToRECT(region.getBounds()));
  } else {
    // It is complex.
    SkPath path;
    region.getBoundaryPath(&path);
    // Clip. Note that windows clipping regions are not affected by the
    // transform so apply it manually.
    // Since the transform is given as the original translation of canvas, we
    // should apply it in reverse.
    SkMatrix t(transformation);
    t.setTranslateX(-t.getTranslateX());
    t.setTranslateY(-t.getTranslateY());
    path.transform(t);
    LoadPathToDC(context, path);
    hrgn = PathToRegion(context);
  }
  int result = SelectClipRgn(context, hrgn);
  SkASSERT(result != ERROR);
  result = DeleteObject(hrgn);
  SkASSERT(result != 0);
}

}  // namespace skia
