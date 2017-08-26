/*
 * Copyright (C) 2012 The Android Open Source Project
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

/* Implementation of Jenkins one-at-a-time hash function. These choices are
 * optimized for code size and portability, rather than raw speed. But speed
 * should still be quite good.
 **/

#include <stdlib.h>
#include <utils/JenkinsHash.h>

namespace android {

#ifdef __clang__
__attribute__((no_sanitize("integer")))
#endif
hash_t
JenkinsHashWhiten(uint32_t hash) {
  hash += (hash << 3);
  hash ^= (hash >> 11);
  hash += (hash << 15);
  return hash;
}

uint32_t JenkinsHashMixBytes(uint32_t hash, const uint8_t* bytes, size_t size) {
  if (size > UINT32_MAX) {
    abort();
  }
  hash = JenkinsHashMix(hash, (uint32_t)size);
  size_t i;
  for (i = 0; i < (size & -4); i += 4) {
    uint32_t data = bytes[i] | (bytes[i + 1] << 8) | (bytes[i + 2] << 16) |
                    (bytes[i + 3] << 24);
    hash = JenkinsHashMix(hash, data);
  }
  if (size & 3) {
    uint32_t data = bytes[i];
    data |= ((size & 3) > 1) ? (bytes[i + 1] << 8) : 0;
    data |= ((size & 3) > 2) ? (bytes[i + 2] << 16) : 0;
    hash = JenkinsHashMix(hash, data);
  }
  return hash;
}

uint32_t JenkinsHashMixShorts(uint32_t hash,
                              const uint16_t* shorts,
                              size_t size) {
  if (size > UINT32_MAX) {
    abort();
  }
  hash = JenkinsHashMix(hash, (uint32_t)size);
  size_t i;
  for (i = 0; i < (size & -2); i += 2) {
    uint32_t data = shorts[i] | (shorts[i + 1] << 16);
    hash = JenkinsHashMix(hash, data);
  }
  if (size & 1) {
    uint32_t data = shorts[i];
    hash = JenkinsHashMix(hash, data);
  }
  return hash;
}

}  // namespace android
