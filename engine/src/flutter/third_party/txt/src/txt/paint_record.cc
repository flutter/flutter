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

#include "paint_record.h"
#include "flutter/fml/logging.h"

namespace txt {

PaintRecord::~PaintRecord() = default;

PaintRecord::PaintRecord(TextStyle style,
                         SkPoint offset,
                         sk_sp<SkTextBlob> text,
                         SkFontMetrics metrics,
                         size_t line,
                         double run_width)
    : style_(style),
      offset_(offset),
      text_(std::move(text)),
      metrics_(metrics),
      line_(line),
      run_width_(run_width) {}

PaintRecord::PaintRecord(TextStyle style,
                         sk_sp<SkTextBlob> text,
                         SkFontMetrics metrics,
                         size_t line,
                         double run_width)
    : style_(style),
      text_(std::move(text)),
      metrics_(metrics),
      line_(line),
      run_width_(run_width) {}

PaintRecord::PaintRecord(PaintRecord&& other) {
  style_ = other.style_;
  offset_ = other.offset_;
  text_ = std::move(other.text_);
  metrics_ = other.metrics_;
  line_ = other.line_;
  run_width_ = other.run_width_;
}

PaintRecord& PaintRecord::operator=(PaintRecord&& other) {
  style_ = other.style_;
  offset_ = other.offset_;
  text_ = std::move(other.text_);
  metrics_ = other.metrics_;
  line_ = other.line_;
  run_width_ = other.run_width_;
  return *this;
}

void PaintRecord::SetOffset(SkPoint pt) {
  offset_ = pt;
}

}  // namespace txt
