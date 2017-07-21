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

#include "lib/ftl/logging.h"
#include "lib/ftl/macros.h"
#include "lib/txt/src/text_style.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace txt {

class PaintRecord {
 public:
  PaintRecord() = delete;

  ~PaintRecord();

  PaintRecord(TextStyle style,
              SkPoint offset,
              sk_sp<SkTextBlob> text,
              SkPaint::FontMetrics metrics,
              int line);

  PaintRecord(TextStyle style,
              sk_sp<SkTextBlob> text,
              SkPaint::FontMetrics metrics,
              int line);

  PaintRecord(PaintRecord&& other);

  PaintRecord& operator=(PaintRecord&& other);

  SkPoint offset() const { return offset_; }

  void SetOffset(SkPoint pt);

  void SetWidthModifier(double val);

  double GetWidthModifier() const { return width_modifier_; }

  SkTextBlob* text() const { return text_.get(); }

  const SkPaint::FontMetrics& metrics() const { return metrics_; }

  const TextStyle& style() const { return style_; }

  size_t line() const { return line_; }

 private:
  TextStyle style_;
  SkPoint offset_;
  sk_sp<SkTextBlob> text_;
  SkPaint::FontMetrics metrics_;
  size_t line_;
  // Change in width when using a non-left text alignment.
  double width_modifier_ = 0.0f;

  FTL_DISALLOW_COPY_AND_ASSIGN(PaintRecord);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PAINT_RECORD_H_
