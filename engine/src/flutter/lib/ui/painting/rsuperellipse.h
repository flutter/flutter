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
  static void Create(Dart_Handle wrapper, const tonic::Float64List& values) {
    UIDartState::ThrowIfUIOperationsProhibited();
    auto res = fml::MakeRefCounted<RSuperellipse>(values);
    res->AssociateWithDartWrapper(wrapper);
  }

  ~RSuperellipse() override;

  double getValue(int index) const;
  bool contains(double x, double y) const;
  flutter::DlRoundSuperellipse rsuperellipse() const;

 private:
  // Index for the value vector. This list should be kept in sync with the same
  // list in RSuperellipse in geometry.dart.
  enum {
    kLeft = 0,
    kTop,
    kRight,
    kBottom,
    kTopLeftX,
    kTopLeftY,
    kTopRightX,
    kTopRightY,
    kBottomRightX,
    kBottomRightY,
    kBottomLeftX,
    kBottomLeftY,
    kValueCount
  };

  explicit RSuperellipse(const tonic::Float64List& values);

  flutter::DlScalar scalar_value(int index) const;
  flutter::DlRect bounds() const;
  impeller::RoundingRadii radii() const;
  const impeller::RoundSuperellipseParam& param() const;

  std::array<double, kValueCount> values_;
  mutable std::optional<impeller::RoundSuperellipseParam> cached_param_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_RSUPERELLIPSE_H_
