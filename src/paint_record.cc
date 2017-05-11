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

#include "lib/txt/src/paint_record.h"

namespace txt {

PaintRecord::PaintRecord() = default;

PaintRecord::~PaintRecord() = default;

PaintRecord::PaintRecord(SkColor color, SkPoint offset, sk_sp<SkTextBlob> text)
    : color_(color), offset_(offset), text_(std::move(text)) {}

PaintRecord::PaintRecord(PaintRecord&& other) {
  color_ = other.color_;
  offset_ = other.offset_;
  text_ = std::move(other.text_);
}

PaintRecord& PaintRecord::operator=(PaintRecord&& other) {
  color_ = other.color_;
  offset_ = other.offset_;
  text_ = std::move(other.text_);
  return *this;
}

}  // namespace txt
