/*
 * Copyright 2017 Google, Inc.
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

#include "text_style.h"
#include "font_style.h"
#include "font_weight.h"
#include "third_party/skia/include/core/SkColor.h"
#include "txt/platform.h"

namespace txt {

TextStyle::TextStyle() : font_family(GetDefaultFontFamily()) {}

bool TextStyle::equals(const TextStyle& other) const {
  if (color != other.color)
    return false;
  if (decoration != other.decoration)
    return false;
  if (decoration_color != other.decoration_color)
    return false;
  if (decoration_style != other.decoration_style)
    return false;
  if (decoration_thickness_multiplier != other.decoration_thickness_multiplier)
    return false;
  if (font_weight != other.font_weight)
    return false;
  if (font_style != other.font_style)
    return false;
  if (font_family != other.font_family)
    return false;
  if (letter_spacing != other.letter_spacing)
    return false;
  if (word_spacing != other.word_spacing)
    return false;
  if (height != other.height)
    return false;
  if (locale != other.locale)
    return false;
  if (foreground != other.foreground)
    return false;
  if (text_shadows.size() != other.text_shadows.size())
    return false;
  for (size_t shadow_index = 0; shadow_index < text_shadows.size();
       ++shadow_index) {
    if (text_shadows[shadow_index] != other.text_shadows[shadow_index])
      return false;
  }

  return true;
}

}  // namespace txt
