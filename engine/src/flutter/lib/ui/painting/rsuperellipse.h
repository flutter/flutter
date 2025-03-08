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

  flutter::DlRoundSuperellipse rsuperellipse() const;

 private:
  static constexpr int kValueCount = 12;

  explicit RSuperellipse(const tonic::Float64List& values);

  impeller::Scalar _value32(int index) const;

  std::array<double, kValueCount> values_;
  std::optional<impeller::RoundSuperellipseParam> rse_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_RSUPERELLIPSE_H_
