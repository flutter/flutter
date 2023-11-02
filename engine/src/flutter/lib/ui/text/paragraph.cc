// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/task_runner.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/skia/modules/skparagraph/include/DartTypes.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, Paragraph);

Paragraph::Paragraph(std::unique_ptr<txt::Paragraph> paragraph)
    : m_paragraph(std::move(paragraph)) {}

Paragraph::~Paragraph() = default;

double Paragraph::width() {
  return m_paragraph->GetMaxWidth();
}

double Paragraph::height() {
  return m_paragraph->GetHeight();
}

double Paragraph::longestLine() {
  return m_paragraph->GetLongestLine();
}

double Paragraph::minIntrinsicWidth() {
  return m_paragraph->GetMinIntrinsicWidth();
}

double Paragraph::maxIntrinsicWidth() {
  return m_paragraph->GetMaxIntrinsicWidth();
}

double Paragraph::alphabeticBaseline() {
  return m_paragraph->GetAlphabeticBaseline();
}

double Paragraph::ideographicBaseline() {
  return m_paragraph->GetIdeographicBaseline();
}

bool Paragraph::didExceedMaxLines() {
  return m_paragraph->DidExceedMaxLines();
}

void Paragraph::layout(double width) {
  m_paragraph->Layout(width);
}

void Paragraph::paint(Canvas* canvas, double x, double y) {
  if (!m_paragraph || !canvas) {
    // disposed.
    return;
  }

  DisplayListBuilder* builder = canvas->builder();
  if (builder) {
    m_paragraph->Paint(builder, x, y);
  }
}

static tonic::Float32List EncodeTextBoxes(
    const std::vector<txt::Paragraph::TextBox>& boxes) {
  // Layout:
  // First value is the number of values.
  // Then there are boxes.size() groups of 5 which are LTRBD, where D is the
  // text direction index.
  tonic::Float32List result(
      Dart_NewTypedData(Dart_TypedData_kFloat32, boxes.size() * 5));
  uint64_t position = 0;
  for (uint64_t i = 0; i < boxes.size(); i++) {
    const txt::Paragraph::TextBox& box = boxes[i];
    result[position++] = box.rect.fLeft;
    result[position++] = box.rect.fTop;
    result[position++] = box.rect.fRight;
    result[position++] = box.rect.fBottom;
    result[position++] = static_cast<float>(box.direction);
  }
  return result;
}

tonic::Float32List Paragraph::getRectsForRange(unsigned start,
                                               unsigned end,
                                               unsigned boxHeightStyle,
                                               unsigned boxWidthStyle) {
  std::vector<txt::Paragraph::TextBox> boxes = m_paragraph->GetRectsForRange(
      start, end, static_cast<txt::Paragraph::RectHeightStyle>(boxHeightStyle),
      static_cast<txt::Paragraph::RectWidthStyle>(boxWidthStyle));
  return EncodeTextBoxes(boxes);
}

tonic::Float32List Paragraph::getRectsForPlaceholders() {
  std::vector<txt::Paragraph::TextBox> boxes =
      m_paragraph->GetRectsForPlaceholders();
  return EncodeTextBoxes(boxes);
}

Dart_Handle Paragraph::getPositionForOffset(double dx, double dy) {
  txt::Paragraph::PositionWithAffinity pos =
      m_paragraph->GetGlyphPositionAtCoordinate(dx, dy);
  std::vector<size_t> result = {
      pos.position,                      // size_t already
      static_cast<size_t>(pos.affinity)  // affinity (enum)
  };
  return tonic::DartConverter<decltype(result)>::ToDart(result);
}

Dart_Handle Paragraph::getWordBoundary(unsigned offset) {
  txt::Paragraph::Range<size_t> point = m_paragraph->GetWordBoundary(offset);
  std::vector<size_t> result = {point.start, point.end};
  return tonic::DartConverter<decltype(result)>::ToDart(result);
}

Dart_Handle Paragraph::getLineBoundary(unsigned utf16Offset) {
  std::vector<txt::LineMetrics> metrics = m_paragraph->GetLineMetrics();
  int line_start = -1;
  int line_end = -1;
  for (txt::LineMetrics& line : metrics) {
    if (utf16Offset >= line.start_index && utf16Offset <= line.end_index) {
      line_start = line.start_index;
      line_end = line.end_index;
      break;
    }
  }
  std::vector<int> result = {line_start, line_end};
  return tonic::DartConverter<decltype(result)>::ToDart(result);
}

tonic::Float64List Paragraph::computeLineMetrics() const {
  std::vector<txt::LineMetrics> metrics = m_paragraph->GetLineMetrics();

  // Layout:
  // boxes.size() groups of 9 which are the line metrics
  // properties
  tonic::Float64List result(
      Dart_NewTypedData(Dart_TypedData_kFloat64, metrics.size() * 9));
  uint64_t position = 0;
  for (uint64_t i = 0; i < metrics.size(); i++) {
    const txt::LineMetrics& line = metrics[i];
    result[position++] = static_cast<double>(line.hard_break);
    result[position++] = line.ascent;
    result[position++] = line.descent;
    result[position++] = line.unscaled_ascent;
    // We add then round to get the height. The
    // definition of height here is different
    // than the one in LibTxt.
    result[position++] = round(line.ascent + line.descent);
    result[position++] = line.width;
    result[position++] = line.left;
    result[position++] = line.baseline;
    result[position++] = static_cast<double>(line.line_number);
  }

  return result;
}

Dart_Handle Paragraph::getLineMetricsAt(int lineNumber,
                                        Dart_Handle constructor) const {
  skia::textlayout::LineMetrics line;
  const bool found = m_paragraph->GetLineMetricsAt(lineNumber, &line);
  if (!found) {
    return Dart_Null();
  }
  std::array<Dart_Handle, 9> arguments = {
      Dart_NewBoolean(line.fHardBreak),
      Dart_NewDouble(line.fAscent),
      Dart_NewDouble(line.fDescent),
      Dart_NewDouble(line.fUnscaledAscent),
      // We add then round to get the height. The
      // definition of height here is different
      // than the one in LibTxt.
      Dart_NewDouble(round(line.fAscent + line.fDescent)),
      Dart_NewDouble(line.fWidth),
      Dart_NewDouble(line.fLeft),
      Dart_NewDouble(line.fBaseline),
      Dart_NewInteger(line.fLineNumber),
  };

  Dart_Handle handle =
      Dart_InvokeClosure(constructor, arguments.size(), arguments.data());
  tonic::CheckAndHandleError(handle);
  return handle;
}

size_t Paragraph::getNumberOfLines() const {
  return m_paragraph->GetNumberOfLines();
}

int Paragraph::getLineNumberAt(size_t utf16Offset) const {
  return m_paragraph->GetLineNumberAt(utf16Offset);
}

void Paragraph::dispose() {
  m_paragraph.reset();
  ClearDartWrapper();
}

}  // namespace flutter
