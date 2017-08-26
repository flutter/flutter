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

#include <unicode/uchar.h>

namespace minikin {

// Returns true if c is emoji.
bool isEmoji(uint32_t c);

// Returns true if c is emoji modifier base.
bool isEmojiBase(uint32_t c);

// Returns true if c is emoji modifier.
bool isEmojiModifier(uint32_t c);

// Bidi override for ICU that knows about new emoji.
UCharDirection emojiBidiOverride(const void* context, UChar32 c);

}  // namespace minikin
