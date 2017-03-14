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

#ifndef MINIKIN_INTERNAL_H
#define MINIKIN_INTERNAL_H

#include <hb.h>

#include <utils/Mutex.h>

#include <minikin/MinikinFont.h>

namespace minikin {

// All external Minikin interfaces are designed to be thread-safe.
// Presently, that's implemented by through a global lock, and having
// all external interfaces take that lock.

extern android::Mutex gMinikinLock;

// Aborts if gMinikinLock is not acquired. Do nothing on the release build.
void assertMinikinLocked();

// Returns true if c is emoji.
bool isEmoji(uint32_t c);

// Returns true if c is emoji modifier base.
bool isEmojiBase(uint32_t c);

// Returns true if c is emoji modifier.
bool isEmojiModifier(uint32_t c);

hb_blob_t* getFontTable(const MinikinFont* minikinFont, uint32_t tag);

// An RAII wrapper for hb_blob_t
class HbBlob {
public:
    // Takes ownership of hb_blob_t object, caller is no longer
    // responsible for calling hb_blob_destroy().
    explicit HbBlob(hb_blob_t* blob) : mBlob(blob) {
    }

    ~HbBlob() {
        hb_blob_destroy(mBlob);
    }

    const uint8_t* get() const {
        const char* data = hb_blob_get_data(mBlob, nullptr);
        return reinterpret_cast<const uint8_t*>(data);
    }

    size_t size() const {
        return (size_t)hb_blob_get_length(mBlob);
    }

private:
    hb_blob_t* mBlob;
};

}  // namespace minikin

#endif  // MINIKIN_INTERNAL_H
