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

// Definitions internal to Minikin
#define LOG_TAG "Minikin"

#include "MinikinInternal.h"
#include "HbFontCache.h"

#include <log/log.h>

namespace minikin {

#ifdef __clang__
[[clang::no_destroy]]
#endif
std::recursive_mutex gMinikinLock;

void assertMinikinLocked() {
#ifdef ENABLE_RACE_DETECTION
  LOG_ALWAYS_FATAL_IF(gMinikinLock.tryLock() == 0);
#endif
}

hb_blob_t* getFontTable(const MinikinFont* minikinFont, uint32_t tag) {
  assertMinikinLocked();
  hb_font_t* font = getHbFontLocked(minikinFont);
  hb_face_t* face = hb_font_get_face(font);
  hb_blob_t* blob = hb_face_reference_table(face, tag);
  hb_font_destroy(font);
  return blob;
}

}  // namespace minikin
