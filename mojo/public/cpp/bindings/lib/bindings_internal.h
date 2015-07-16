// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_BINDINGS_INTERNAL_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_BINDINGS_INTERNAL_H_

#include "mojo/public/cpp/bindings/lib/template_util.h"
#include "mojo/public/cpp/bindings/struct_ptr.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {
class String;

template <typename T>
class Array;

template <typename K, typename V>
class Map;

namespace internal {
template <typename T>
class Array_Data;

#pragma pack(push, 1)

struct StructHeader {
  uint32_t num_bytes;
  uint32_t version;
};
static_assert(sizeof(StructHeader) == 8, "Bad sizeof(StructHeader)");

struct ArrayHeader {
  uint32_t num_bytes;
  uint32_t num_elements;
};
static_assert(sizeof(ArrayHeader) == 8, "Bad_sizeof(ArrayHeader)");

template <typename T>
union StructPointer {
  uint64_t offset;
  T* ptr;
};
static_assert(sizeof(StructPointer<char>) == 8, "Bad_sizeof(StructPointer)");

template <typename T>
union ArrayPointer {
  uint64_t offset;
  Array_Data<T>* ptr;
};
static_assert(sizeof(ArrayPointer<char>) == 8, "Bad_sizeof(ArrayPointer)");

union StringPointer {
  uint64_t offset;
  Array_Data<char>* ptr;
};
static_assert(sizeof(StringPointer) == 8, "Bad_sizeof(StringPointer)");

struct Interface_Data {
  MessagePipeHandle handle;
  uint32_t version;
};
static_assert(sizeof(Interface_Data) == 8, "Bad_sizeof(Interface_Data)");

template <typename T>
union UnionPointer {
  uint64_t offset;
  T* ptr;
};
static_assert(sizeof(UnionPointer<char>) == 8, "Bad_sizeof(UnionPointer)");

#pragma pack(pop)

template <typename T>
void ResetIfNonNull(T* ptr) {
  if (ptr)
    *ptr = T();
}

template <typename T>
T FetchAndReset(T* ptr) {
  T temp = *ptr;
  *ptr = T();
  return temp;
}

template <typename H>
struct IsHandle {
  enum { value = IsBaseOf<Handle, H>::value };
};

template <typename T>
struct IsUnionDataType {
  template <typename U>
  static YesType Test(const typename U::MojomUnionDataType*);

  template <typename U>
  static NoType Test(...);

  static const bool value =
      sizeof(Test<T>(0)) == sizeof(YesType) && !IsConst<T>::value;
};

template <typename T, bool move_only = IsMoveOnlyType<T>::value>
struct WrapperTraits;

template <typename T>
struct WrapperTraits<T, false> {
  typedef T DataType;
};
template <typename H>
struct WrapperTraits<ScopedHandleBase<H>, true> {
  typedef H DataType;
};
template <typename S>
struct WrapperTraits<StructPtr<S>, true> {
  typedef typename S::Data_* DataType;
};
template <typename S>
struct WrapperTraits<InlinedStructPtr<S>, true> {
  typedef typename S::Data_* DataType;
};
template <typename S>
struct WrapperTraits<S, true> {
  typedef typename S::Data_* DataType;
};

template <typename T, typename Enable = void>
struct ValueTraits {
  static bool Equals(const T& a, const T& b) { return a == b; }
};

template <typename T>
struct ValueTraits<
    T,
    typename EnableIf<IsSpecializationOf<Array, T>::value ||
                      IsSpecializationOf<Map, T>::value ||
                      IsSpecializationOf<StructPtr, T>::value ||
                      IsSpecializationOf<InlinedStructPtr, T>::value>::type> {
  static bool Equals(const T& a, const T& b) { return a.Equals(b); }
};

template <typename T>
struct ValueTraits<ScopedHandleBase<T>> {
  static bool Equals(const ScopedHandleBase<T>& a,
                     const ScopedHandleBase<T>& b) {
    return a.get().value() == b.get().value();
  }
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_BINDINGS_INTERNAL_H_
