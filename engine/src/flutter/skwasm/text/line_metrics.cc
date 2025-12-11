// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/export.h"
#include "flutter/skwasm/live_objects.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"

SKWASM_EXPORT skia::textlayout::LineMetrics* lineMetrics_create(
    bool hard_break,
    double ascent,
    double descent,
    double unscaled_ascent,
    double height,
    double width,
    double left,
    double baseline,
    size_t line_number) {
  Skwasm::live_line_metrics_count++;
  auto metrics = new skia::textlayout::LineMetrics();
  metrics->fHardBreak = hard_break;
  metrics->fAscent = ascent;
  metrics->fDescent = descent;
  metrics->fUnscaledAscent = unscaled_ascent;
  metrics->fHeight = height;
  metrics->fWidth = width;
  metrics->fLeft = left;
  metrics->fBaseline = baseline;
  metrics->fLineNumber = line_number;
  return metrics;
}

SKWASM_EXPORT void lineMetrics_dispose(skia::textlayout::LineMetrics* metrics) {
  Skwasm::live_line_metrics_count--;
  delete metrics;
}

SKWASM_EXPORT bool lineMetrics_getHardBreak(
    skia::textlayout::LineMetrics* metrics) {
  return metrics->fHardBreak;
}

SKWASM_EXPORT SkScalar
lineMetrics_getAscent(skia::textlayout::LineMetrics* metrics) {
  return metrics->fAscent;
}

SKWASM_EXPORT SkScalar
lineMetrics_getDescent(skia::textlayout::LineMetrics* metrics) {
  return metrics->fDescent;
}

SKWASM_EXPORT SkScalar
lineMetrics_getUnscaledAscent(skia::textlayout::LineMetrics* metrics) {
  return metrics->fUnscaledAscent;
}

SKWASM_EXPORT SkScalar
lineMetrics_getHeight(skia::textlayout::LineMetrics* metrics) {
  return metrics->fHeight;
}

SKWASM_EXPORT SkScalar
lineMetrics_getWidth(skia::textlayout::LineMetrics* metrics) {
  return metrics->fWidth;
}

SKWASM_EXPORT SkScalar
lineMetrics_getLeft(skia::textlayout::LineMetrics* metrics) {
  return metrics->fLeft;
}

SKWASM_EXPORT SkScalar
lineMetrics_getBaseline(skia::textlayout::LineMetrics* metrics) {
  return metrics->fBaseline;
}

SKWASM_EXPORT int lineMetrics_getLineNumber(
    skia::textlayout::LineMetrics* metrics) {
  return metrics->fLineNumber;
}

SKWASM_EXPORT size_t
lineMetrics_getStartIndex(skia::textlayout::LineMetrics* metrics) {
  return metrics->fStartIndex;
}

SKWASM_EXPORT size_t
lineMetrics_getEndIndex(skia::textlayout::LineMetrics* metrics) {
  return metrics->fEndIndex;
}
