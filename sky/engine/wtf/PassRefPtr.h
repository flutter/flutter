/*
 *  Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc.
 *  All rights reserved.
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

#ifndef SKY_ENGINE_WTF_PASSREFPTR_H_
#define SKY_ENGINE_WTF_PASSREFPTR_H_

#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/Compiler.h"
#include "flutter/sky/engine/wtf/NullPtr.h"
#include "flutter/sky/engine/wtf/RawPtr.h"
#include "flutter/sky/engine/wtf/TypeTraits.h"

namespace WTF {

template <typename T>
class RefPtr;
template <typename T>
class PassRefPtr;
template <typename T>
PassRefPtr<T> adoptRef(T*);

inline void adopted(const void*) {}

// requireAdoption() is not overloaded for WTF::RefCounted, which has a
// built-in assumption that adoption is required. requireAdoption() is
// for bootstrapping alternate reference count classes that are compatible
// with ReftPtr/PassRefPtr but cannot have adoption checks enabled
// by default, such as skia's SkRefCnt. The purpose of requireAdoption()
// is to enable adoption checks only once it is known that the object will
// be used with RefPtr/PassRefPtr.
inline void requireAdoption(const void*) {}

template <typename T>
ALWAYS_INLINE void refIfNotNull(T* ptr) {
  if (LIKELY(ptr != 0)) {
    requireAdoption(ptr);
    ptr->ref();
  }
}

template <typename T>
ALWAYS_INLINE void derefIfNotNull(T* ptr) {
  if (LIKELY(ptr != 0))
    ptr->deref();
}

template <typename T>
class PassRefPtr {
  WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(PassRefPtr);

 public:
  PassRefPtr() : m_ptr(0) {}
  PassRefPtr(std::nullptr_t) : m_ptr(0) {}
  PassRefPtr(T* ptr) : m_ptr(ptr) { refIfNotNull(ptr); }
  template <typename U>
  PassRefPtr(const RawPtr<U>& ptr, EnsurePtrConvertibleArgDecl(U, T))
      : m_ptr(ptr.get()) {
    refIfNotNull(m_ptr);
  }
  explicit PassRefPtr(T& ptr) : m_ptr(&ptr) { m_ptr->ref(); }
  // It somewhat breaks the type system to allow transfer of ownership out of
  // a const PassRefPtr. However, it makes it much easier to work with
  // PassRefPtr temporaries, and we don't have a need to use real const
  // PassRefPtrs anyway.
  PassRefPtr(const PassRefPtr& o) : m_ptr(o.leakRef()) {}
  template <typename U>
  PassRefPtr(const PassRefPtr<U>& o, EnsurePtrConvertibleArgDecl(U, T))
      : m_ptr(o.leakRef()) {}

  ALWAYS_INLINE ~PassRefPtr() { derefIfNotNull(m_ptr); }

  template <typename U>
  PassRefPtr(const RefPtr<U>&, EnsurePtrConvertibleArgDecl(U, T));

  T* get() const { return m_ptr; }

  T* leakRef() const WARN_UNUSED_RETURN;

  T& operator*() const { return *m_ptr; }
  T* operator->() const { return m_ptr; }

  bool operator!() const { return !m_ptr; }

  // This conversion operator allows implicit conversion to bool but not to
  // other integer types.
  typedef T*(PassRefPtr::*UnspecifiedBoolType);
  operator UnspecifiedBoolType() const {
    return m_ptr ? &PassRefPtr::m_ptr : 0;
  }

  friend PassRefPtr adoptRef<T>(T*);

 private:
  enum AdoptRefTag { AdoptRef };
  PassRefPtr(T* ptr, AdoptRefTag) : m_ptr(ptr) {}

  PassRefPtr& operator=(const PassRefPtr&) {
    COMPILE_ASSERT(!sizeof(T*), PassRefPtr_should_never_be_assigned_to);
    return *this;
  }

  mutable T* m_ptr;
};

template <typename T>
template <typename U>
inline PassRefPtr<T>::PassRefPtr(const RefPtr<U>& o,
                                 EnsurePtrConvertibleArgDefn(U, T))
    : m_ptr(o.get()) {
  T* ptr = m_ptr;
  refIfNotNull(ptr);
}

template <typename T>
inline T* PassRefPtr<T>::leakRef() const {
  T* ptr = m_ptr;
  m_ptr = 0;
  return ptr;
}

template <typename T, typename U>
inline bool operator==(const PassRefPtr<T>& a, const PassRefPtr<U>& b) {
  return a.get() == b.get();
}

template <typename T, typename U>
inline bool operator==(const PassRefPtr<T>& a, const RefPtr<U>& b) {
  return a.get() == b.get();
}

template <typename T, typename U>
inline bool operator==(const RefPtr<T>& a, const PassRefPtr<U>& b) {
  return a.get() == b.get();
}

template <typename T, typename U>
inline bool operator==(const PassRefPtr<T>& a, U* b) {
  return a.get() == b;
}

template <typename T, typename U>
inline bool operator==(T* a, const PassRefPtr<U>& b) {
  return a == b.get();
}

template <typename T, typename U>
inline bool operator==(const PassRefPtr<T>& a, const RawPtr<U>& b) {
  return a.get() == b.get();
}

template <typename T, typename U>
inline bool operator==(const RawPtr<T>& a, const PassRefPtr<U>& b) {
  return a.get() == b.get();
}

template <typename T, typename U>
inline bool operator!=(const PassRefPtr<T>& a, const PassRefPtr<U>& b) {
  return a.get() != b.get();
}

template <typename T, typename U>
inline bool operator!=(const PassRefPtr<T>& a, const RefPtr<U>& b) {
  return a.get() != b.get();
}

template <typename T, typename U>
inline bool operator!=(const RefPtr<T>& a, const PassRefPtr<U>& b) {
  return a.get() != b.get();
}

template <typename T, typename U>
inline bool operator!=(const PassRefPtr<T>& a, U* b) {
  return a.get() != b;
}

template <typename T, typename U>
inline bool operator!=(T* a, const PassRefPtr<U>& b) {
  return a != b.get();
}

template <typename T, typename U>
inline bool operator!=(const PassRefPtr<T>& a, const RawPtr<U>& b) {
  return a.get() != b.get();
}

template <typename T, typename U>
inline bool operator!=(const RawPtr<T>& a, const PassRefPtr<U>& b) {
  return a.get() != b.get();
}

template <typename T>
PassRefPtr<T> adoptRef(T* p) {
  adopted(p);
  return PassRefPtr<T>(p, PassRefPtr<T>::AdoptRef);
}

template <typename T, typename U>
inline PassRefPtr<T> static_pointer_cast(const PassRefPtr<U>& p) {
  return adoptRef(static_cast<T*>(p.leakRef()));
}

template <typename T>
inline T* getPtr(const PassRefPtr<T>& p) {
  return p.get();
}

}  // namespace WTF

using WTF::adoptRef;
using WTF::PassRefPtr;
using WTF::static_pointer_cast;

#endif  // SKY_ENGINE_WTF_PASSREFPTR_H_
