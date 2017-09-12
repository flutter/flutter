/*
 *  Copyright (C) 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 *  Copyright (C) 2013 Intel Corporation. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_OWNPTR_H_
#define SKY_ENGINE_WTF_OWNPTR_H_

#include <algorithm>
#include "flutter/sky/engine/wtf/HashTableDeletedValueType.h"
#include "flutter/sky/engine/wtf/Noncopyable.h"
#include "flutter/sky/engine/wtf/NullPtr.h"
#include "flutter/sky/engine/wtf/OwnPtrCommon.h"

namespace WTF {

template <typename T>
class PassOwnPtr;

template <typename T>
class OwnPtr {
  // If rvalue references are not supported, the copy constructor is
  // public so OwnPtr cannot be marked noncopyable. See note below.
  WTF_MAKE_NONCOPYABLE(OwnPtr);
  WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(OwnPtr);

 public:
  typedef typename RemoveExtent<T>::Type ValueType;
  typedef ValueType* PtrType;

  OwnPtr() : m_ptr(0) {}
  OwnPtr(std::nullptr_t) : m_ptr(0) {}

  // See comment in PassOwnPtr.h for why this takes a const reference.
  OwnPtr(const PassOwnPtr<T>&);
  template <typename U>
  OwnPtr(const PassOwnPtr<U>&, EnsurePtrConvertibleArgDecl(U, T));

  // Hash table deleted values, which are only constructed and never copied or
  // destroyed.
  OwnPtr(HashTableDeletedValueType) : m_ptr(hashTableDeletedValue()) {}
  bool isHashTableDeletedValue() const {
    return m_ptr == hashTableDeletedValue();
  }

  ~OwnPtr() {
    OwnedPtrDeleter<T>::deletePtr(m_ptr);
    m_ptr = 0;
  }

  PtrType get() const { return m_ptr; }

  void clear();
  PassOwnPtr<T> release();
  PtrType leakPtr() WARN_UNUSED_RETURN;

  ValueType& operator*() const {
    ASSERT(m_ptr);
    return *m_ptr;
  }
  PtrType operator->() const {
    ASSERT(m_ptr);
    return m_ptr;
  }

  ValueType& operator[](std::ptrdiff_t i) const;

  bool operator!() const { return !m_ptr; }

  // This conversion operator allows implicit conversion to bool but not to
  // other integer types.
  typedef PtrType OwnPtr::*UnspecifiedBoolType;
  operator UnspecifiedBoolType() const { return m_ptr ? &OwnPtr::m_ptr : 0; }

  OwnPtr& operator=(const PassOwnPtr<T>&);
  OwnPtr& operator=(std::nullptr_t) {
    clear();
    return *this;
  }
  template <typename U>
  OwnPtr& operator=(const PassOwnPtr<U>&);

  OwnPtr(OwnPtr&&);
  template <typename U>
  OwnPtr(OwnPtr<U>&&);

  OwnPtr& operator=(OwnPtr&&);
  template <typename U>
  OwnPtr& operator=(OwnPtr<U>&&);

  void swap(OwnPtr& o) { std::swap(m_ptr, o.m_ptr); }

  static T* hashTableDeletedValue() { return reinterpret_cast<T*>(-1); }

 private:
  // We should never have two OwnPtrs for the same underlying object (otherwise
  // we'll get double-destruction), so these equality operators should never be
  // needed.
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

  PtrType m_ptr;
};

template <typename T>
inline OwnPtr<T>::OwnPtr(const PassOwnPtr<T>& o) : m_ptr(o.leakPtr()) {}

template <typename T>
template <typename U>
inline OwnPtr<T>::OwnPtr(const PassOwnPtr<U>& o,
                         EnsurePtrConvertibleArgDefn(U, T))
    : m_ptr(o.leakPtr()) {
  COMPILE_ASSERT(!IsArray<T>::value, Pointers_to_array_must_never_be_converted);
}

template <typename T>
inline void OwnPtr<T>::clear() {
  PtrType ptr = m_ptr;
  m_ptr = 0;
  OwnedPtrDeleter<T>::deletePtr(ptr);
}

template <typename T>
inline PassOwnPtr<T> OwnPtr<T>::release() {
  PtrType ptr = m_ptr;
  m_ptr = 0;
  return PassOwnPtr<T>(ptr);
}

template <typename T>
inline typename OwnPtr<T>::PtrType OwnPtr<T>::leakPtr() {
  PtrType ptr = m_ptr;
  m_ptr = 0;
  return ptr;
}

template <typename T>
inline typename OwnPtr<T>::ValueType& OwnPtr<T>::operator[](
    std::ptrdiff_t i) const {
  COMPILE_ASSERT(IsArray<T>::value,
                 Elements_access_is_possible_for_arrays_only);
  ASSERT(m_ptr);
  ASSERT(i >= 0);
  return m_ptr[i];
}

template <typename T>
inline OwnPtr<T>& OwnPtr<T>::operator=(const PassOwnPtr<T>& o) {
  PtrType ptr = m_ptr;
  m_ptr = o.leakPtr();
  ASSERT(!ptr || m_ptr != ptr);
  OwnedPtrDeleter<T>::deletePtr(ptr);
  return *this;
}

template <typename T>
template <typename U>
inline OwnPtr<T>& OwnPtr<T>::operator=(const PassOwnPtr<U>& o) {
  COMPILE_ASSERT(!IsArray<T>::value, Pointers_to_array_must_never_be_converted);
  PtrType ptr = m_ptr;
  m_ptr = o.leakPtr();
  ASSERT(!ptr || m_ptr != ptr);
  OwnedPtrDeleter<T>::deletePtr(ptr);
  return *this;
}

template <typename T>
inline OwnPtr<T>::OwnPtr(OwnPtr<T>&& o) : m_ptr(o.leakPtr()) {}

template <typename T>
template <typename U>
inline OwnPtr<T>::OwnPtr(OwnPtr<U>&& o) : m_ptr(o.leakPtr()) {
  COMPILE_ASSERT(!IsArray<T>::value, Pointers_to_array_must_never_be_converted);
}

template <typename T>
inline OwnPtr<T>& OwnPtr<T>::operator=(OwnPtr<T>&& o) {
  PtrType ptr = m_ptr;
  m_ptr = o.leakPtr();
  ASSERT(!ptr || m_ptr != ptr);
  OwnedPtrDeleter<T>::deletePtr(ptr);

  return *this;
}

template <typename T>
template <typename U>
inline OwnPtr<T>& OwnPtr<T>::operator=(OwnPtr<U>&& o) {
  COMPILE_ASSERT(!IsArray<T>::value, Pointers_to_array_must_never_be_converted);
  PtrType ptr = m_ptr;
  m_ptr = o.leakPtr();
  ASSERT(!ptr || m_ptr != ptr);
  OwnedPtrDeleter<T>::deletePtr(ptr);

  return *this;
}

template <typename T>
inline void swap(OwnPtr<T>& a, OwnPtr<T>& b) {
  a.swap(b);
}

template <typename T, typename U>
inline bool operator==(const OwnPtr<T>& a, U* b) {
  return a.get() == b;
}

template <typename T, typename U>
inline bool operator==(T* a, const OwnPtr<U>& b) {
  return a == b.get();
}

template <typename T, typename U>
inline bool operator!=(const OwnPtr<T>& a, U* b) {
  return a.get() != b;
}

template <typename T, typename U>
inline bool operator!=(T* a, const OwnPtr<U>& b) {
  return a != b.get();
}

template <typename T>
inline typename OwnPtr<T>::PtrType getPtr(const OwnPtr<T>& p) {
  return p.get();
}

}  // namespace WTF

using WTF::OwnPtr;

#endif  // SKY_ENGINE_WTF_OWNPTR_H_
