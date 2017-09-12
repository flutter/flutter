/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/RefPtr.h"
#include "flutter/sky/engine/wtf/ThreadRestrictionVerifier.h"
#include "flutter/sky/engine/wtf/Vector.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace WTF {

#if ENABLE(ASSERT) || ENABLE(SECURITY_ASSERT)
// The debug/assertion version may get bigger.
struct SameSizeAsRefCounted {
  int a;
#if ENABLE(SECURITY_ASSERT)
  bool b;
#endif
#if ENABLE(ASSERT)
  bool c;
  ThreadRestrictionVerifier d;
#endif
};
#else
struct SameSizeAsRefCounted {
  int a;
  // Don't add anything here because this should stay small.
};
#endif
template <typename T, unsigned inlineCapacity = 0>
struct SameSizeAsVectorWithInlineCapacity;

template <typename T>
struct SameSizeAsVectorWithInlineCapacity<T, 0> {
  void* bufferPointer;
  unsigned capacity;
  unsigned size;
};

template <typename T, unsigned inlineCapacity>
struct SameSizeAsVectorWithInlineCapacity {
  SameSizeAsVectorWithInlineCapacity<T, 0> baseCapacity;
  AlignedBuffer<inlineCapacity * sizeof(T), WTF_ALIGN_OF(T)> inlineBuffer;
};

COMPILE_ASSERT(sizeof(OwnPtr<int>) == sizeof(int*), OwnPtr_should_stay_small);
COMPILE_ASSERT(sizeof(PassRefPtr<RefCounted<int>>) == sizeof(int*),
               PassRefPtr_should_stay_small);
COMPILE_ASSERT(sizeof(RefCounted<int>) == sizeof(SameSizeAsRefCounted),
               RefCounted_should_stay_small);
COMPILE_ASSERT(sizeof(RefPtr<RefCounted<int>>) == sizeof(int*),
               RefPtr_should_stay_small);
COMPILE_ASSERT(sizeof(String) == sizeof(int*), String_should_stay_small);
COMPILE_ASSERT(sizeof(AtomicString) == sizeof(String),
               AtomicString_should_stay_small);
COMPILE_ASSERT(sizeof(Vector<int>) ==
                   sizeof(SameSizeAsVectorWithInlineCapacity<int>),
               Vector_should_stay_small);
COMPILE_ASSERT(sizeof(Vector<int, 1>) ==
                   sizeof(SameSizeAsVectorWithInlineCapacity<int, 1>),
               Vector_should_stay_small);
COMPILE_ASSERT(sizeof(Vector<int, 2>) ==
                   sizeof(SameSizeAsVectorWithInlineCapacity<int, 2>),
               Vector_should_stay_small);
COMPILE_ASSERT(sizeof(Vector<int, 3>) ==
                   sizeof(SameSizeAsVectorWithInlineCapacity<int, 3>),
               Vector_should_stay_small);
}  // namespace WTF
