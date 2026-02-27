// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/toolkit/interop/line_metrics.h"

namespace impeller::interop {

LineMetrics::LineMetrics(const std::vector<txt::LineMetrics>& metrics) {
  // There aren't any guarantees (documented or otherwise) that metrics will
  // have line numbers that are sorted or contiguous.
  for (const auto& metric : metrics) {
    metrics_[metric.line_number] = metric;
  }
}

LineMetrics::~LineMetrics() = default;

double LineMetrics::GetAscent(size_t line) const {
  return GetLine(line).ascent;
}

double LineMetrics::GetUnscaledAscent(size_t line) const {
  return GetLine(line).unscaled_ascent;
}

double LineMetrics::GetDescent(size_t line) const {
  return GetLine(line).descent;
}

double LineMetrics::GetBaseline(size_t line) const {
  return GetLine(line).baseline;
}

bool LineMetrics::IsHardbreak(size_t line) const {
  return GetLine(line).hard_break;
}

double LineMetrics::GetWidth(size_t line) const {
  return GetLine(line).width;
}

double LineMetrics::GetHeight(size_t line) const {
  return GetLine(line).height;
}

double LineMetrics::GetLeft(size_t line) const {
  return GetLine(line).left;
}

size_t LineMetrics::GetCodeUnitStartIndex(size_t line) const {
  return GetLine(line).start_index;
}

size_t LineMetrics::GetCodeUnitEndIndex(size_t line) const {
  return GetLine(line).end_index;
}

size_t LineMetrics::GetCodeUnitEndIndexExcludingWhitespace(size_t line) const {
  return GetLine(line).end_excluding_whitespace;
}

size_t LineMetrics::GetCodeUnitEndIndexIncludingNewline(size_t line) const {
  return GetLine(line).end_including_newline;
}

const txt::LineMetrics& LineMetrics::GetLine(size_t line) const {
  auto found = metrics_.find(line);
  if (found != metrics_.end()) {
    return found->second;
  }
  static txt::LineMetrics kDefaultMetrics = {};
  return kDefaultMetrics;
}

}  // namespace impeller::interop
