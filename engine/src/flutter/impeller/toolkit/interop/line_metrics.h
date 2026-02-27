// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TOOLKIT_INTEROP_LINE_METRICS_H_
#define FLUTTER_IMPELLER_TOOLKIT_INTEROP_LINE_METRICS_H_

#include <map>

#include "flutter/txt/src/txt/line_metrics.h"
#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/object.h"

namespace impeller::interop {

//------------------------------------------------------------------------------
/// @brief      Internal C++ peer of ImpellerLineMetrics. For detailed
///             documentation, refer to the headerdocs in the public API in
///             impeller.h.
///
///             Accessing metrics of missing lines returns default initialized
///             values.
///
class LineMetrics final
    : public Object<LineMetrics,
                    IMPELLER_INTERNAL_HANDLE_NAME(ImpellerLineMetrics)> {
 public:
  explicit LineMetrics(const std::vector<txt::LineMetrics>& metrics);

  ~LineMetrics();

  LineMetrics(const LineMetrics&) = delete;

  LineMetrics& operator=(const LineMetrics&) = delete;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetAscent.
  ///
  double GetAscent(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetUnscaledAscent.
  ///
  double GetUnscaledAscent(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetDescent.
  ///
  double GetDescent(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetBaseline.
  ///
  double GetBaseline(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsIsHardbreak.
  ///
  bool IsHardbreak(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetWidth.
  ///
  double GetWidth(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetHeight.
  ///
  double GetHeight(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetLeft.
  ///
  double GetLeft(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetCodeUnitStartIndex.
  ///
  size_t GetCodeUnitStartIndex(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetCodeUnitEndIndex.
  ///
  size_t GetCodeUnitEndIndex(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetCodeUnitEndIndexExcludingWhitespace.
  ///
  size_t GetCodeUnitEndIndexExcludingWhitespace(size_t line) const;

  //----------------------------------------------------------------------------
  /// @see      ImpellerLineMetricsGetCodeUnitEndIndexIncludingNewline.
  ///
  size_t GetCodeUnitEndIndexIncludingNewline(size_t line) const;

 private:
  std::map<size_t /* line number */, txt::LineMetrics> metrics_;

  const txt::LineMetrics& GetLine(size_t line) const;
};

}  // namespace impeller::interop

#endif  // FLUTTER_IMPELLER_TOOLKIT_INTEROP_LINE_METRICS_H_
