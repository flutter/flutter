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

#include "paragraph_builder.h"
#include "paragraph_builder_txt.h"
#include "paragraph_style.h"
#include "third_party/icu/source/common/unicode/unistr.h"

#if FLUTTER_ENABLE_SKSHAPER
#include "flutter/third_party/txt/src/skia/paragraph_builder_skia.h"
#endif

namespace txt {

std::unique_ptr<ParagraphBuilder> ParagraphBuilder::CreateTxtBuilder(
    const ParagraphStyle& style,
    std::shared_ptr<FontCollection> font_collection) {
  return std::make_unique<ParagraphBuilderTxt>(style, font_collection);
}

#if FLUTTER_ENABLE_SKSHAPER

std::unique_ptr<ParagraphBuilder> ParagraphBuilder::CreateSkiaBuilder(
    const ParagraphStyle& style,
    std::shared_ptr<FontCollection> font_collection) {
  return std::make_unique<ParagraphBuilderSkia>(style, font_collection);
}

#endif  // FLUTTER_ENABLE_SKSHAPER

}  // namespace txt
