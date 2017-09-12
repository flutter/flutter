/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_BYTESWAP_H_
#define SKY_ENGINE_WTF_BYTESWAP_H_

#include "flutter/sky/engine/wtf/CPU.h"
#include "flutter/sky/engine/wtf/Compiler.h"

#include <stdint.h>

namespace WTF {

inline uint32_t wswap32(uint32_t x) {
  return ((x & 0xffff0000) >> 16) | ((x & 0x0000ffff) << 16);
}

ALWAYS_INLINE uint64_t bswap64(uint64_t x) {
  return __builtin_bswap64(x);
}
ALWAYS_INLINE uint32_t bswap32(uint32_t x) {
  return __builtin_bswap32(x);
}
// GCC 4.6 lacks __builtin_bswap16. Newer versions have it but we support 4.6.
#if COMPILER(CLANG)
ALWAYS_INLINE uint16_t bswap16(uint16_t x) {
  return __builtin_bswap16(x);
}
#else
inline uint16_t bswap16(uint16_t x) {
  return ((x & 0xff00) >> 8) | ((x & 0x00ff) << 8);
}
#endif

#if CPU(64BIT)

ALWAYS_INLINE size_t bswapuintptrt(size_t x) {
  return bswap64(x);
}

#else

ALWAYS_INLINE size_t bswapuintptrt(size_t x) {
  return bswap32(x);
}

#endif

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_BYTESWAP_H_
