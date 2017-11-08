/*
 * Copyright (C) 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_PASSOWNPTR_H_
#define SKY_ENGINE_WTF_PASSOWNPTR_H_

#include "flutter/sky/engine/wtf/NullPtr.h"
#include "flutter/sky/engine/wtf/OwnPtrCommon.h"

namespace WTF {

template <typename T>
class OwnPtr;
template <typename T>
class PassOwnPtr;
template <typename T>
PassOwnPtr<T> adoptPtr(T*);
template <typename T>
PassOwnPtr<T[]> adoptArrayPtr(T*);

template <typename T>
class PassOwnPtr {
  WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(PassOwnPtr);

 public:
  typedef typename RemoveExtent<T>::Type ValueType;
  typedef ValueType* PtrType;

  PassOwnPtr() : m_ptr(0) {}
  PassOwnPtr(std::nullptr_t) : m_ptr(0) {}

  // It somewhat breaks the type system to allow transfer of ownership out of
  // a const PassOwnPtr. However, it makes it much easier to work with
  // PassOwnPtr temporaries, and we don't have a need to use real const
  // PassOwnPtrs anyway.
  PassOwnPtr(const PassOwnPtr& o) : m_ptr(o.leakPtr()) {}
  template <typename U>
  PassOwnPtr(const PassOwnPtr<U>&, EnsurePtrConvertibleArgDecl(U, T));

  ~PassOwnPtr() { OwnedPtrDeleter<T>::deletePtr(m_ptr); }

  PtrType get() const { return m_ptr; }

  PtrType leakPtr() const WARN_UNUSED_RETURN;

  ValueType& operator*() const {
    ASSERT(m_ptr);
    return *m_ptr;
  }
  PtrType operator->() const {
    ASSERT(m_ptr);
    return m_ptr;
  }

  bool operator!() const { return !m_ptr; }

  // This conversion operator allows implicit conversion to bool but not to
  // other integer types.
  typedef PtrType PassOwnPtr::*UnspecifiedBoolType;
  operator UnspecifiedBoolType() const {
    return m_ptr ? &PassOwnPtr::m_ptr : 0;
  }

  template <typename U>
  friend PassOwnPtr<U> adoptPtr(U*);
  template <typename U>
  friend PassOwnPtr<U[]> adoptArrayPtr(U*);
  template <typename U>
  friend class OwnPtr;

 private:
  explicit PassOwnPtr(PtrType ptr) : m_ptr(ptr) {}

  PassOwnPtr& operator=(const PassOwnPtr&) {
    COMPILE_ASSERT(!sizeof(T*), PassOwnPtr_should_never_be_assigned_to);
    return *this;
  }

  // We should never have two OwnPtrs for the same underlying object (otherwise
  // we'll get double-destruction), so these equality operators should never be
  // needed.
  template <typename U>
  bool operator==(const PassOwnPtr<U>&) const {
    COMPILE_ASSERT(!sizeof(U*), OwnPtrs_should_never_be_equal);
    return false;
  }
  template <typename U>
  bool operator!=(const PassOwnPtr<U>&) const {
    COMPILE_ASSERT(!sizeof(U*), OwnPtrs_should_never_be_equal);
    return false;
  }
  template <typename U>
  bool operator==(const OwnPtr<U>&) const {
    COMPILE_ASSERT(!sizeof(U*), OwnPtrs_should_never_be_equal);
    return false;
  }
  template <typename U>
  bool operator!=(const OwnPtr<U>&) const {
    COMPILE_ASSERT(!sizeof(U*), OwnPtrs_should_never_be_equal);
    return false;
  }

  mutable PtrType m_ptr;
};

template <typename T>
template <typename U>
inline PassOwnPtr<T>::PassOwnPtr(const PassOwnPtr<U>& o,
                                 EnsurePtrConvertibleArgDefn(U, T))
    : m_ptr(o.leakPtr()) {
  COMPILE_ASSERT(!IsArray<T>::value, Pointers_to_array_must_never_be_converted);
}

template <typename T>
inline typename PassOwnPtr<T>::PtrType PassOwnPtr<T>::leakPtr() const {
  PtrType ptr = m_ptr;
  m_ptr = 0;
  return ptr;
}

template <typename T, typename U>
inline bool operator==(const PassOwnPtr<T>& a, U* b) {
  return a.get() == b;
}

template <typename T, typename U>
inline bool operator==(T* a, const PassOwnPtr<U>& b) {
  return a == b.get();
}

template <typename T, typename U>
inline bool operator!=(const PassOwnPtr<T>& a, U* b) {
  return a.get() != b;
}

template <typename T, typename U>
inline bool operator!=(T* a, const PassOwnPtr<U>& b) {
  return a != b.get();
}

template <typename T>
inline PassOwnPtr<T> adoptPtr(T* ptr) {
  return PassOwnPtr<T>(ptr);
}

template <typename T>
inline PassOwnPtr<T[]> adoptArrayPtr(T* ptr) {
  return PassOwnPtr<T[]>(ptr);
}

template <typename T, typename U>
inline PassOwnPtr<T> static_pointer_cast(const PassOwnPtr<U>& p) {
  COMPILE_ASSERT(!IsArray<T>::value, Pointers_to_array_must_never_be_converted);
  return adoptPtr(static_cast<T*>(p.leakPtr()));
}

template <typename T>
inline T* getPtr(const PassOwnPtr<T>& p) {
  return p.get();
}

}  // namespace WTF

using WTF::adoptArrayPtr;
using WTF::adoptPtr;
using WTF::PassOwnPtr;
using WTF::static_pointer_cast;

#endif  // SKY_ENGINE_WTF_PASSOWNPTR_H_
