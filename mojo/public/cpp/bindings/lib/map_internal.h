// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_MAP_INTERNAL_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_MAP_INTERNAL_H_

#include <map>

#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/lib/template_util.h"

namespace mojo {
namespace internal {

template <typename Key, typename Value, bool kValueIsMoveOnlyType>
struct MapTraits {};

// Defines traits of a map for which Value is not a move-only type.
template <typename Key, typename Value>
struct MapTraits<Key, Value, false> {
  // Map keys can't be move only types.
  static_assert(!internal::IsMoveOnlyType<Key>::value,
                "Map keys cannot be move only types.");

  typedef Key KeyStorageType;
  typedef Key& KeyRefType;
  typedef const Key& KeyConstRefType;
  typedef KeyConstRefType KeyForwardType;

  typedef Value ValueStorageType;
  typedef Value& ValueRefType;
  typedef const Value& ValueConstRefType;
  typedef ValueConstRefType ValueForwardType;

  static inline void InitializeFrom(
      std::map<KeyStorageType, ValueStorageType>* m,
      mojo::Array<Key> keys,
      mojo::Array<Value> values) {
    for (size_t i = 0; i < keys.size(); ++i)
      Insert(m, keys[i], values[i]);
  }
  static inline void Decompose(std::map<KeyStorageType, ValueStorageType>* m,
                               mojo::Array<Key>* keys,
                               mojo::Array<Value>* values) {
    keys->resize(m->size());
    values->resize(m->size());
    int i = 0;
    for (typename std::map<KeyStorageType, ValueStorageType>::iterator
             it = m->begin();
         it != m->end();
         ++it, ++i) {
      (*keys)[i] = it->first;
      (*values)[i] = it->second;
    }
  }
  static inline void Finalize(std::map<KeyStorageType, ValueStorageType>* m) {}
  static inline ValueRefType at(std::map<KeyStorageType, ValueStorageType>* m,
                                KeyForwardType key) {
    // We don't have C++11 library support yet, so we have to emulate the crash
    // on a non-existent key.
    auto it = m->find(key);
    MOJO_CHECK(it != m->end());
    return it->second;
  }
  static inline ValueConstRefType at(
      const std::map<KeyStorageType, ValueStorageType>* m,
      KeyForwardType key) {
    // We don't have C++11 library support yet, so we have to emulate the crash
    // on a non-existent key.
    auto it = m->find(key);
    MOJO_CHECK(it != m->end());
    return it->second;
  }
  static inline ValueRefType GetOrInsert(
      std::map<KeyStorageType, ValueStorageType>* m,
      KeyForwardType key) {
    // This is the backing for the index operator (operator[]).
    return (*m)[key];
  }
  static inline void Insert(std::map<KeyStorageType, ValueStorageType>* m,
                            KeyForwardType key,
                            ValueForwardType value) {
    m->insert(std::make_pair(key, value));
  }
  static inline KeyConstRefType GetKey(
      const typename std::map<KeyStorageType, ValueStorageType>::const_iterator&
          it) {
    return it->first;
  }
  static inline ValueConstRefType GetValue(
      const typename std::map<KeyStorageType, ValueStorageType>::const_iterator&
          it) {
    return it->second;
  }
  static inline ValueRefType GetValue(
      const typename std::map<KeyStorageType, ValueStorageType>::iterator& it) {
    return it->second;
  }
  static inline void Clone(
      const std::map<KeyStorageType, ValueStorageType>& src,
      std::map<KeyStorageType, ValueStorageType>* dst) {
    dst->clear();
    for (auto it = src.begin(); it != src.end(); ++it)
      dst->insert(*it);
  }
};

// Defines traits of a map for which Value is a move-only type.
template <typename Key, typename Value>
struct MapTraits<Key, Value, true> {
  // Map keys can't be move only types.
  static_assert(!internal::IsMoveOnlyType<Key>::value,
                "Map keys cannot be move only types.");

  typedef Key KeyStorageType;
  typedef Key& KeyRefType;
  typedef const Key& KeyConstRefType;
  typedef KeyConstRefType KeyForwardType;

  struct ValueStorageType {
    // Make 8-byte aligned.
    char buf[sizeof(Value) + (8 - (sizeof(Value) % 8)) % 8];
  };
  typedef Value& ValueRefType;
  typedef const Value& ValueConstRefType;
  typedef Value ValueForwardType;

  static inline void InitializeFrom(
      std::map<KeyStorageType, ValueStorageType>* m,
      mojo::Array<Key> keys,
      mojo::Array<Value> values) {
    for (size_t i = 0; i < keys.size(); ++i)
      Insert(m, keys[i], values[i]);
  }
  static inline void Decompose(std::map<KeyStorageType, ValueStorageType>* m,
                               mojo::Array<Key>* keys,
                               mojo::Array<Value>* values) {
    keys->resize(m->size());
    values->resize(m->size());
    int i = 0;
    for (typename std::map<KeyStorageType, ValueStorageType>::iterator
             it = m->begin();
         it != m->end();
         ++it, ++i) {
      (*keys)[i] = it->first;
      (*values)[i] = GetValue(it).Pass();
    }
  }
  static inline void Finalize(std::map<KeyStorageType, ValueStorageType>* m) {
    for (auto& pair : *m)
      reinterpret_cast<Value*>(pair.second.buf)->~Value();
  }
  static inline ValueRefType at(std::map<KeyStorageType, ValueStorageType>* m,
                                KeyForwardType key) {
    // We don't have C++11 library support yet, so we have to emulate the crash
    // on a non-existent key.
    auto it = m->find(key);
    MOJO_CHECK(it != m->end());
    return GetValue(it);
  }
  static inline ValueConstRefType at(
      const std::map<KeyStorageType, ValueStorageType>* m,
      KeyForwardType key) {
    // We don't have C++11 library support yet, so we have to emulate the crash
    // on a non-existent key.
    auto it = m->find(key);
    MOJO_CHECK(it != m->end());
    return GetValue(it);
  }
  static inline ValueRefType GetOrInsert(
      std::map<KeyStorageType, ValueStorageType>* m,
      KeyForwardType key) {
    // This is the backing for the index operator (operator[]).
    auto it = m->find(key);
    if (it == m->end()) {
      it = m->insert(std::make_pair(key, ValueStorageType())).first;
      new (it->second.buf) Value();
    }

    return GetValue(it);
  }
  static inline void Insert(std::map<KeyStorageType, ValueStorageType>* m,
                            KeyForwardType key,
                            ValueRefType value) {
    // STL insert() doesn't insert |value| if |key| is already part of |m|. We
    // have to use operator[] to initialize into the storage buffer, but we
    // have to do a manual check so that we don't overwrite an existing object.
    auto it = m->find(key);
    if (it == m->end())
      new ((*m)[key].buf) Value(value.Pass());
  }
  static inline KeyConstRefType GetKey(
      const typename std::map<KeyStorageType, ValueStorageType>::const_iterator&
          it) {
    return it->first;
  }
  static inline ValueConstRefType GetValue(
      const typename std::map<KeyStorageType, ValueStorageType>::const_iterator&
          it) {
    return *reinterpret_cast<const Value*>(it->second.buf);
  }
  static inline ValueRefType GetValue(
      const typename std::map<KeyStorageType, ValueStorageType>::iterator& it) {
    return *reinterpret_cast<Value*>(it->second.buf);
  }
  static inline void Clone(
      const std::map<KeyStorageType, ValueStorageType>& src,
      std::map<KeyStorageType, ValueStorageType>* dst) {
    Finalize(dst);
    dst->clear();
    for (auto it = src.begin(); it != src.end(); ++it)
      new ((*dst)[it->first].buf) Value(GetValue(it).Clone());
  }
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MAP_INTERNAL_H_
