/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef LIB_TXT_SRC_PAINT_RECORD_H_
#define LIB_TXT_SRC_PAINT_RECORD_H_

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "placeholder_run.h"
#include "text_style.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace txt {

// PaintRecord holds the layout data after Paragraph::Layout() is called. This
// stores all necessary offsets, blobs, metrics, and more for Skia to draw the
// text.
class PaintRecord {
 public:
  PaintRecord() = delete;

  ~PaintRecord();

  PaintRecord(TextStyle style,
              SkPoint offset,
              sk_sp<SkTextBlob> text,
              SkFontMetrics metrics,
              size_t line,
              double x_start,
              double x_end,
              bool is_ghost);

  PaintRecord(TextStyle style,
              SkPoint offset,
              sk_sp<SkTextBlob> text,
              SkFontMetrics metrics,
              size_t line,
              double x_start,
              double x_end,
              bool is_ghost,
              PlaceholderRun* placeholder_run);

  PaintRecord(TextStyle style,
              sk_sp<SkTextBlob> text,
              SkFontMetrics metrics,
              size_t line,
              double x_start,
              double x_end,
              bool is_ghost);

  PaintRecord(PaintRecord&& other);

  PaintRecord& operator=(PaintRecord&& other);

  SkPoint offset() const { return offset_; }

  void SetOffset(SkPoint pt);

  SkTextBlob* text() const { return text_.get(); }

  const SkFontMetrics& metrics() const { return metrics_; }

  const TextStyle& style() const { return style_; }

  size_t line() const { return line_; }

  double x_start() const { return x_start_; }
  double x_end() const { return x_end_; }
  double GetRunWidth() const { return x_end_ - x_start_; }

  PlaceholderRun* GetPlaceholderRun() const { return placeholder_run_; }

  bool isGhost() const { return is_ghost_; }

  bool isPlaceholder() const { return placeholder_run_ == nullptr; }

 private:
  TextStyle style_;
  // offset_ is the overall offset of the origin of the SkTextBlob.
  SkPoint offset_;
  // SkTextBlob stores the glyphs and coordinates to draw them.
  sk_sp<SkTextBlob> text_;
  // FontMetrics stores the measurements of the font used.
  SkFontMetrics metrics_;
  size_t line_;
  double x_start_ = 0.0f;
  double x_end_ = 0.0f;
  // 'Ghost' runs represent trailing whitespace. 'Ghost' runs should not have
  // decorations painted on them and do not impact layout of visible glyphs.
  bool is_ghost_ = false;
  // Stores the corresponding PlaceholderRun that the record corresponds to.
  // When this is nullptr, then the record is of normal text and does not
  // represent an inline placeholder.
  PlaceholderRun* placeholder_run_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(PaintRecord);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PAINT_RECORD_H_
