// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This header defines cross-platform ByteSwap() implementations for 16, 32 and
// 64-bit values, and NetToHostXX() / HostToNextXX() functions equivalent to
// the traditional ntohX() and htonX() functions.
// Use the functions defined here rather than using the platform-specific
// functions directly.

#ifndef BASE_SYS_BYTEORDER_H_
#define BASE_SYS_BYTEORDER_H_

#include "base/basictypes.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include <winsock2.h>
#else
#include <arpa/inet.h>
#endif

namespace base {

// Returns a value with all bytes in |x| swapped, i.e. reverses the endianness.
inline uint16 ByteSwap(uint16 x) {
  return ((x & 0x00ff) << 8) | ((x & 0xff00) >> 8);
}

inline uint32 ByteSwap(uint32 x) {
  return ((x & 0x000000fful) << 24) | ((x & 0x0000ff00ul) << 8) |
      ((x & 0x00ff0000ul) >> 8) | ((x & 0xff000000ul) >> 24);
}

inline uint64 ByteSwap(uint64 x) {
  return ((x & 0x00000000000000ffull) << 56) |
      ((x & 0x000000000000ff00ull) << 40) |
      ((x & 0x0000000000ff0000ull) << 24) |
      ((x & 0x00000000ff000000ull) << 8) |
      ((x & 0x000000ff00000000ull) >> 8) |
      ((x & 0x0000ff0000000000ull) >> 24) |
      ((x & 0x00ff000000000000ull) >> 40) |
      ((x & 0xff00000000000000ull) >> 56);
}

// Converts the bytes in |x| from host order (endianness) to little endian, and
// returns the result.
inline uint16 ByteSwapToLE16(uint16 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return x;
#else
  return ByteSwap(x);
#endif
}
inline uint32 ByteSwapToLE32(uint32 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return x;
#else
  return ByteSwap(x);
#endif
}
inline uint64 ByteSwapToLE64(uint64 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return x;
#else
  return ByteSwap(x);
#endif
}

// Converts the bytes in |x| from network to host order (endianness), and
// returns the result.
inline uint16 NetToHost16(uint16 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return ByteSwap(x);
#else
  return x;
#endif
}
inline uint32 NetToHost32(uint32 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return ByteSwap(x);
#else
  return x;
#endif
}
inline uint64 NetToHost64(uint64 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return ByteSwap(x);
#else
  return x;
#endif
}

// Converts the bytes in |x| from host to network order (endianness), and
// returns the result.
inline uint16 HostToNet16(uint16 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return ByteSwap(x);
#else
  return x;
#endif
}
inline uint32 HostToNet32(uint32 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return ByteSwap(x);
#else
  return x;
#endif
}
inline uint64 HostToNet64(uint64 x) {
#if defined(ARCH_CPU_LITTLE_ENDIAN)
  return ByteSwap(x);
#else
  return x;
#endif
}

}  // namespace base

#endif  // BASE_SYS_BYTEORDER_H_
