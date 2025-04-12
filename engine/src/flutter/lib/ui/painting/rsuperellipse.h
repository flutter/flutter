// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_RSUPERELLIPSE_H_
#define FLUTTER_LIB_UI_PAINTING_RSUPERELLIPSE_H_

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/impeller/geometry/round_superellipse_param.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/typed_data/typed_list.h"

namespace flutter {

class RSuperellipse : public RefCountedDartWrappable<RSuperellipse> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(RSuperellipse);

 public:
  static void Create(Dart_Handle wrapper,
                     double left,
                     double top,
                     double right,
                     double bottom,
                     double tl_radius_x,
                     double tl_radius_y,
                     double tr_radius_x,
                     double tr_radius_y,
                     double br_radius_x,
                     double br_radius_y,
                     double bl_radius_x,
                     double bl_radius_y);

  ~RSuperellipse() override;

  bool contains(double x, double y);

  flutter::DlRoundSuperellipse rsuperellipse() const;
  impeller::RoundSuperellipseParam param() const;
  flutter::DlRect bounds() const { return bounds_; }
  impeller::RoundingRadii radii() const { return radii_; }

 private:
  RSuperellipse(flutter::DlRect bounds, impeller::RoundingRadii radii);

  flutter::DlScalar scalar_value(int index) const;

  flutter::DlRect bounds_;
  impeller::RoundingRadii radii_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_RSUPERELLIPSE_H_
