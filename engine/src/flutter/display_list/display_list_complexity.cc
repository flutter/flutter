// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_complexity.h"
#include "flutter/display_list/display_list.h"

namespace flutter {

DisplayListNaiveComplexityCalculator*
    DisplayListNaiveComplexityCalculator::instance_ = nullptr;

DisplayListComplexityCalculator*
DisplayListNaiveComplexityCalculator::GetInstance() {
  if (instance_ == nullptr) {
    instance_ = new DisplayListNaiveComplexityCalculator();
  }
  return instance_;
}

DisplayListComplexityCalculator* DisplayListComplexityCalculator::GetForBackend(
    GrBackendApi backend) {
  switch (backend) {
    default:
      return DisplayListNaiveComplexityCalculator::GetInstance();
  }
}

DisplayListComplexityCalculator*
DisplayListComplexityCalculator::GetForSoftware() {
  return DisplayListNaiveComplexityCalculator::GetInstance();
}

}  // namespace flutter
