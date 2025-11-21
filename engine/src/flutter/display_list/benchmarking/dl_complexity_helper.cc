// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/benchmarking/dl_complexity_helper.h"

#include "flutter/display_list/geometry/dl_path.h"

namespace {

using DlPoint = flutter::DlPoint;
using DlScalar = flutter::DlScalar;

class DlComplexityPathReceiver : public flutter::DlPathReceiver {
 public:
  void MoveTo(const DlPoint& p2, bool will_be_closed) override {}
  void LineTo(const DlPoint& p2) override { line_verb_count++; }
  void QuadTo(const DlPoint& cp, const DlPoint& p2) override {
    quad_verb_count++;
  }
  bool ConicTo(const DlPoint& cp, const DlPoint& p2, DlScalar weight) override {
    conic_verb_count++;
    return true;
  }
  void CubicTo(const DlPoint& cp1,
               const DlPoint& cp2,
               const DlPoint& p2) override {
    cubic_verb_count++;
  }
  void Close() override {}

  uint32_t line_verb_count;
  uint32_t quad_verb_count;
  uint32_t conic_verb_count;
  uint32_t cubic_verb_count;
};

}  // namespace

namespace flutter {

unsigned int ComplexityCalculatorHelper::CalculatePathComplexity(
    const DlPath& dl_path,
    unsigned int line_verb_cost,
    unsigned int quad_verb_cost,
    unsigned int conic_verb_cost,
    unsigned int cubic_verb_cost) {
  DlComplexityPathReceiver receiver;
  dl_path.Dispatch(receiver);
  return (line_verb_cost * receiver.line_verb_count) +
         (quad_verb_cost * receiver.quad_verb_count) +
         (conic_verb_cost * receiver.conic_verb_count) +
         (cubic_verb_cost * receiver.cubic_verb_count);
}

}  // namespace flutter
