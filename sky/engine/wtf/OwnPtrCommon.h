/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile, Inc.
 * Copyright (C) 2010 Company 100 Inc.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_WTF_OWNPTRCOMMON_H_
#define SKY_ENGINE_WTF_OWNPTRCOMMON_H_

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/TypeTraits.h"

namespace WTF {

class RefCountedBase;
class ThreadSafeRefCountedBase;

template <typename T>
struct IsRefCounted {
  static const bool value = IsSubclass<T, RefCountedBase>::value ||
                            IsSubclass<T, ThreadSafeRefCountedBase>::value;
};

template <typename T>
struct OwnedPtrDeleter {
  static void deletePtr(T* ptr) {
    COMPILE_ASSERT(!IsRefCounted<T>::value, UseRefPtrForRefCountedObjects);
    COMPILE_ASSERT(sizeof(T) > 0, TypeMustBeComplete);
    delete ptr;
  }
};

template <typename T>
struct OwnedPtrDeleter<T[]> {
  static void deletePtr(T* ptr) {
    COMPILE_ASSERT(!IsRefCounted<T>::value, UseRefPtrForRefCountedObjects);
    COMPILE_ASSERT(sizeof(T) > 0, TypeMustBeComplete);
    delete[] ptr;
  }
};

template <class T, int n>
struct OwnedPtrDeleter<T[n]> {
  COMPILE_ASSERT(sizeof(T) < 0, DoNotUseArrayWithSizeAsType);
};

}  // namespace WTF

#endif  // SKY_ENGINE_WTF_OWNPTRCOMMON_H_
