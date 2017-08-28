/*
 * Copyright (C) 2014 The Android Open Source Project
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

#include <minikin/Emoji.h>

namespace minikin {

bool isEmoji(uint32_t c) {
  return u_hasBinaryProperty(c, UCHAR_EMOJI);
}

bool isEmojiModifier(uint32_t c) {
  return u_hasBinaryProperty(c, UCHAR_EMOJI_MODIFIER);
}

bool isEmojiBase(uint32_t c) {
  // These two characters were removed from Emoji_Modifier_Base in Emoji 4.0,
  // but we need to keep them as emoji modifier bases since there are fonts and
  // user-generated text out there that treats these as potential emoji bases.
  if (c == 0x1F91D || c == 0x1F93C) {
    return true;
  }
  return u_hasBinaryProperty(c, UCHAR_EMOJI_MODIFIER_BASE);
}

UCharDirection emojiBidiOverride(const void* /* context */, UChar32 c) {
  return u_charDirection(c);
}

}  // namespace minikin
