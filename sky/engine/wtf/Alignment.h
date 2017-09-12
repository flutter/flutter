/*
 *  Copyright (C) 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_WTF_ALIGNMENT_H_
#define SKY_ENGINE_WTF_ALIGNMENT_H_

#include <stdint.h>
#include <algorithm>
#include <cstddef>
#include "flutter/sky/engine/wtf/Compiler.h"

namespace WTF {

#if COMPILER(GCC)
#define WTF_ALIGN_OF(type) __alignof__(type)
#define WTF_ALIGNED(variable_type, variable, n) \
  variable_type variable __attribute__((__aligned__(n)))
#else
#error WTF_ALIGN macros need alignment control.
#endif

#if COMPILER(GCC)
typedef char __attribute__((__may_alias__)) AlignedBufferChar;
#else
typedef char AlignedBufferChar;
#endif

template <size_t size, size_t alignment>
struct AlignedBuffer;
template <size_t size>
struct AlignedBuffer<size, 1> {
  AlignedBufferChar buffer[size];
};
template <size_t size>
struct AlignedBuffer<size, 2> {
  WTF_ALIGNED(AlignedBufferChar, buffer[size], 2);
};
template <size_t size>
struct AlignedBuffer<size, 4> {
  WTF_ALIGNED(AlignedBufferChar, buffer[size], 4);
};
template <size_t size>
struct AlignedBuffer<size, 8> {
  WTF_ALIGNED(AlignedBufferChar, buffer[size], 8);
};
template <size_t size>
struct AlignedBuffer<size, 16> {
  WTF_ALIGNED(AlignedBufferChar, buffer[size], 16);
};
template <size_t size>
struct AlignedBuffer<size, 32> {
  WTF_ALIGNED(AlignedBufferChar, buffer[size], 32);
};
template <size_t size>
struct AlignedBuffer<size, 64> {
  WTF_ALIGNED(AlignedBufferChar, buffer[size], 64);
};

template <size_t size, size_t alignment>
void swap(AlignedBuffer<size, alignment>& a,
          AlignedBuffer<size, alignment>& b) {
  for (size_t i = 0; i < size; ++i)
    std::swap(a.buffer[i], b.buffer[i]);
}

template <uintptr_t mask>
inline bool isAlignedTo(const void* pointer) {
  return !(reinterpret_cast<uintptr_t>(pointer) & mask);
}
}  // namespace WTF

#endif  // SKY_ENGINE_WTF_ALIGNMENT_H_
