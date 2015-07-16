// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_MAP_SERIALIZATION_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_MAP_SERIALIZATION_H_

#include "mojo/public/cpp/bindings/lib/array_internal.h"
#include "mojo/public/cpp/bindings/lib/map_data_internal.h"
#include "mojo/public/cpp/bindings/lib/map_internal.h"
#include "mojo/public/cpp/bindings/lib/string_serialization.h"
#include "mojo/public/cpp/bindings/map.h"

namespace mojo {

template <typename Key, typename Value>
inline size_t GetSerializedSize_(const Map<Key, Value>& input);

template <typename ValidateParams, typename E, typename F>
inline void SerializeArray_(
    Array<E> input,
    internal::Buffer* buf,
    internal::Array_Data<F>** output,
    const internal::ArrayValidateParams* validate_params);

namespace internal {

template <typename MapType,
          typename DataType,
          bool value_is_move_only_type = IsMoveOnlyType<MapType>::value,
          bool is_union =
              IsUnionDataType<typename RemovePointer<DataType>::type>::value>
struct MapSerializer;

template <typename MapType, typename DataType>
struct MapSerializer<MapType, DataType, false, false> {
  static size_t GetBaseArraySize(size_t count) {
    return Align(count * sizeof(DataType));
  }
  static size_t GetItemSize(const MapType& item) { return 0; }
};

template <>
struct MapSerializer<bool, bool, false, false> {
  static size_t GetBaseArraySize(size_t count) {
    return Align((count + 7) / 8);
  }
  static size_t GetItemSize(bool item) { return 0; }
};

template <typename H>
struct MapSerializer<ScopedHandleBase<H>, H, true, false> {
  static size_t GetBaseArraySize(size_t count) {
    return Align(count * sizeof(H));
  }
  static size_t GetItemSize(const ScopedHandleBase<H>& item) { return 0; }
};

// This template must only apply to pointer mojo entity (structs and arrays).
// This is done by ensuring that WrapperTraits<S>::DataType is a pointer.
template <typename S>
struct MapSerializer<
    S,
    typename EnableIf<IsPointer<typename WrapperTraits<S>::DataType>::value,
                      typename WrapperTraits<S>::DataType>::type,
    true,
    false> {
  typedef
      typename RemovePointer<typename WrapperTraits<S>::DataType>::type S_Data;
  static size_t GetBaseArraySize(size_t count) {
    return count * sizeof(StructPointer<S_Data>);
  }
  static size_t GetItemSize(const S& item) { return GetSerializedSize_(item); }
};

template <typename U, typename U_Data>
struct MapSerializer<U, U_Data*, true, true> {
  static size_t GetBaseArraySize(size_t count) {
    return count * sizeof(U_Data);
  }
  static size_t GetItemSize(const U& item) {
    return GetSerializedSize_(item, true);
  }
};

template <>
struct MapSerializer<String, String_Data*, false, false> {
  static size_t GetBaseArraySize(size_t count) {
    return count * sizeof(StringPointer);
  }
  static size_t GetItemSize(const String& item) {
    return GetSerializedSize_(item);
  }
};

}  // namespace internal

// TODO(erg): This can't go away yet. We still need to calculate out the size
// of a struct header, and two arrays.
template <typename MapKey, typename MapValue>
inline size_t GetSerializedSize_(const Map<MapKey, MapValue>& input) {
  if (!input)
    return 0;
  typedef typename internal::WrapperTraits<MapKey>::DataType DataKey;
  typedef typename internal::WrapperTraits<MapValue>::DataType DataValue;

  size_t count = input.size();
  size_t struct_overhead = sizeof(mojo::internal::Map_Data<DataKey, DataValue>);
  size_t key_base_size =
      sizeof(internal::ArrayHeader) +
      internal::MapSerializer<MapKey, DataKey>::GetBaseArraySize(count);
  size_t value_base_size =
      sizeof(internal::ArrayHeader) +
      internal::MapSerializer<MapValue, DataValue>::GetBaseArraySize(count);

  size_t key_data_size = 0;
  size_t value_data_size = 0;
  for (auto it = input.begin(); it != input.end(); ++it) {
    key_data_size +=
        internal::MapSerializer<MapKey, DataKey>::GetItemSize(it.GetKey());
    value_data_size +=
        internal::MapSerializer<MapValue, DataValue>::GetItemSize(
            it.GetValue());
  }

  return struct_overhead + key_base_size + key_data_size + value_base_size +
         value_data_size;
}

// We don't need an ArrayValidateParams instance for key validation since
// we can deduce it from the Key type. (which can only be primitive types or
// non-nullable strings.)
template <typename MapKey,
          typename MapValue,
          typename DataKey,
          typename DataValue>
inline void SerializeMap_(
    Map<MapKey, MapValue> input,
    internal::Buffer* buf,
    internal::Map_Data<DataKey, DataValue>** output,
    const internal::ArrayValidateParams* value_validate_params) {
  if (input) {
    internal::Map_Data<DataKey, DataValue>* result =
        internal::Map_Data<DataKey, DataValue>::New(buf);
    if (result) {
      Array<MapKey> keys;
      Array<MapValue> values;
      input.DecomposeMapTo(&keys, &values);
      const internal::ArrayValidateParams* key_validate_params =
          internal::MapKeyValidateParamsFactory<DataKey>::Get();
      SerializeArray_(keys.Pass(), buf, &result->keys.ptr, key_validate_params);
      SerializeArray_(values.Pass(), buf, &result->values.ptr,
                      value_validate_params);
    }
    *output = result;
  } else {
    *output = nullptr;
  }
}

template <typename MapKey,
          typename MapValue,
          typename DataKey,
          typename DataValue>
inline void Deserialize_(internal::Map_Data<DataKey, DataValue>* input,
                         Map<MapKey, MapValue>* output) {
  if (input) {
    Array<MapKey> keys;
    Array<MapValue> values;

    Deserialize_(input->keys.ptr, &keys);
    Deserialize_(input->values.ptr, &values);

    *output = Map<MapKey, MapValue>(keys.Pass(), values.Pass());
  } else {
    output->reset();
  }
}

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_MAP_SERIALIZATION_H_
