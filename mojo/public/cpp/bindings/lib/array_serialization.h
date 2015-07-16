// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_ARRAY_SERIALIZATION_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_ARRAY_SERIALIZATION_H_

#include <string.h>  // For |memcpy()|.

#include <vector>

#include "mojo/public/c/system/macros.h"
#include "mojo/public/cpp/bindings/lib/array_internal.h"
#include "mojo/public/cpp/bindings/lib/map_serialization.h"
#include "mojo/public/cpp/bindings/lib/string_serialization.h"
#include "mojo/public/cpp/bindings/lib/template_util.h"
#include "mojo/public/cpp/bindings/lib/validation_errors.h"

namespace mojo {

template <typename E>
inline size_t GetSerializedSize_(const Array<E>& input);

template <typename E, typename F>
inline void SerializeArray_(
    Array<E> input,
    internal::Buffer* buf,
    internal::Array_Data<F>** output,
    const internal::ArrayValidateParams* validate_params);

template <typename E, typename F>
inline void Deserialize_(internal::Array_Data<F>* data, Array<E>* output);

namespace internal {

template <typename E,
          typename F,
          bool is_union =
              IsUnionDataType<typename RemovePointer<F>::type>::value>
struct ArraySerializer;

// Handles serialization and deserialization of arrays of pod types.
template <typename E, typename F>
struct ArraySerializer<E, F, false> {
  static_assert(sizeof(E) == sizeof(F), "Incorrect array serializer");
  static size_t GetSerializedSize(const Array<E>& input) {
    return sizeof(Array_Data<F>) + Align(input.size() * sizeof(E));
  }

  static void SerializeElements(Array<E> input,
                                Buffer* buf,
                                Array_Data<F>* output,
                                const ArrayValidateParams* validate_params) {
    MOJO_DCHECK(!validate_params->element_is_nullable)
        << "Primitive type should be non-nullable";
    MOJO_DCHECK(!validate_params->element_validate_params)
        << "Primitive type should not have array validate params";

    if (input.size())
      memcpy(output->storage(), &input.storage()[0], input.size() * sizeof(E));
  }
  static void DeserializeElements(Array_Data<F>* input, Array<E>* output) {
    std::vector<E> result(input->size());
    if (input->size())
      memcpy(&result[0], input->storage(), input->size() * sizeof(E));
    output->Swap(&result);
  }
};

// Serializes and deserializes arrays of bools.
template <>
struct ArraySerializer<bool, bool, false> {
  static size_t GetSerializedSize(const Array<bool>& input) {
    return sizeof(Array_Data<bool>) + Align((input.size() + 7) / 8);
  }

  static void SerializeElements(Array<bool> input,
                                Buffer* buf,
                                Array_Data<bool>* output,
                                const ArrayValidateParams* validate_params) {
    MOJO_DCHECK(!validate_params->element_is_nullable)
        << "Primitive type should be non-nullable";
    MOJO_DCHECK(!validate_params->element_validate_params)
        << "Primitive type should not have array validate params";

    // TODO(darin): Can this be a memcpy somehow instead of a bit-by-bit copy?
    for (size_t i = 0; i < input.size(); ++i)
      output->at(i) = input[i];
  }
  static void DeserializeElements(Array_Data<bool>* input,
                                  Array<bool>* output) {
    Array<bool> result(input->size());
    // TODO(darin): Can this be a memcpy somehow instead of a bit-by-bit copy?
    for (size_t i = 0; i < input->size(); ++i)
      result.at(i) = input->at(i);
    output->Swap(&result);
  }
};

// Serializes and deserializes arrays of handles.
template <typename H>
struct ArraySerializer<ScopedHandleBase<H>, H, false> {
  static size_t GetSerializedSize(const Array<ScopedHandleBase<H>>& input) {
    return sizeof(Array_Data<H>) + Align(input.size() * sizeof(H));
  }

  static void SerializeElements(Array<ScopedHandleBase<H>> input,
                                Buffer* buf,
                                Array_Data<H>* output,
                                const ArrayValidateParams* validate_params) {
    MOJO_DCHECK(!validate_params->element_validate_params)
        << "Handle type should not have array validate params";

    for (size_t i = 0; i < input.size(); ++i) {
      output->at(i) = input[i].release();  // Transfer ownership of the handle.
      MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING(
          !validate_params->element_is_nullable && !output->at(i).is_valid(),
          VALIDATION_ERROR_UNEXPECTED_INVALID_HANDLE,
          MakeMessageWithArrayIndex(
              "invalid handle in array expecting valid handles", input.size(),
              i));
    }
  }
  static void DeserializeElements(Array_Data<H>* input,
                                  Array<ScopedHandleBase<H>>* output) {
    Array<ScopedHandleBase<H>> result(input->size());
    for (size_t i = 0; i < input->size(); ++i)
      result.at(i) = MakeScopedHandle(FetchAndReset(&input->at(i)));
    output->Swap(&result);
  }
};

// This template must only apply to pointer mojo entity (structs and arrays).
// This is done by ensuring that WrapperTraits<S>::DataType is a pointer.
template <typename S>
struct ArraySerializer<
    S,
    typename EnableIf<IsPointer<typename WrapperTraits<S>::DataType>::value,
                      typename WrapperTraits<S>::DataType>::type,
    false> {
  typedef
      typename RemovePointer<typename WrapperTraits<S>::DataType>::type S_Data;
  static size_t GetSerializedSize(const Array<S>& input) {
    size_t size = sizeof(Array_Data<S_Data*>) +
                  input.size() * sizeof(StructPointer<S_Data>);
    for (size_t i = 0; i < input.size(); ++i)
      size += GetSerializedSize_(input[i]);
    return size;
  }

  static void SerializeElements(Array<S> input,
                                Buffer* buf,
                                Array_Data<S_Data*>* output,
                                const ArrayValidateParams* validate_params) {
    for (size_t i = 0; i < input.size(); ++i) {
      S_Data* element;
      SerializeCaller<S>::Run(input[i].Pass(), buf, &element,
                              validate_params->element_validate_params);
      output->at(i) = element;
      MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING(
          !validate_params->element_is_nullable && !element,
          VALIDATION_ERROR_UNEXPECTED_NULL_POINTER,
          MakeMessageWithArrayIndex("null in array expecting valid pointers",
                                    input.size(), i));
    }
  }
  static void DeserializeElements(Array_Data<S_Data*>* input,
                                  Array<S>* output) {
    Array<S> result(input->size());
    for (size_t i = 0; i < input->size(); ++i) {
      Deserialize_(input->at(i), &result[i]);
    }
    output->Swap(&result);
  }

 private:
  template <typename T>
  struct SerializeCaller {
    static void Run(T input,
                    Buffer* buf,
                    typename WrapperTraits<T>::DataType* output,
                    const ArrayValidateParams* validate_params) {
      MOJO_DCHECK(!validate_params)
          << "Struct type should not have array validate params";

      Serialize_(input.Pass(), buf, output);
    }
  };

  template <typename T>
  struct SerializeCaller<Array<T>> {
    static void Run(Array<T> input,
                    Buffer* buf,
                    typename Array<T>::Data_** output,
                    const ArrayValidateParams* validate_params) {
      SerializeArray_(input.Pass(), buf, output, validate_params);
    }
  };

  template <typename T, typename U>
  struct SerializeCaller<Map<T, U>> {
    static void Run(Map<T, U> input,
                    Buffer* buf,
                    typename Map<T, U>::Data_** output,
                    const ArrayValidateParams* validate_params) {
      SerializeMap_(input.Pass(), buf, output, validate_params);
    }
  };
};

// Handles serialization and deserialization of arrays of unions.
template <typename U, typename U_Data>
struct ArraySerializer<U, U_Data, true> {
  static size_t GetSerializedSize(const Array<U>& input) {
    size_t size = sizeof(Array_Data<U_Data>);
    for (size_t i = 0; i < input.size(); ++i) {
      // GetSerializedSize_ will account for both the data in the union and the
      // space in the array used to hold the union.
      size += GetSerializedSize_(input[i], false);
    }
    return size;
  }

  static void SerializeElements(Array<U> input,
                                Buffer* buf,
                                Array_Data<U_Data>* output,
                                const ArrayValidateParams* validate_params) {
    for (size_t i = 0; i < input.size(); ++i) {
      U_Data* result = output->storage() + i;
      SerializeUnion_(input[i].Pass(), buf, &result, true);
      MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING(
          !validate_params->element_is_nullable && output->at(i).is_null(),
          VALIDATION_ERROR_UNEXPECTED_NULL_POINTER,
          MakeMessageWithArrayIndex("null in array expecting valid unions",
                                    input.size(), i));
    }
  }

  static void DeserializeElements(Array_Data<U_Data>* input, Array<U>* output) {
    Array<U> result(input->size());
    for (size_t i = 0; i < input->size(); ++i) {
      Deserialize_(&input->at(i), &result[i]);
    }
    output->Swap(&result);
  }
};

// Handles serialization and deserialization of arrays of strings.
template <>
struct ArraySerializer<String, String_Data*> {
  static size_t GetSerializedSize(const Array<String>& input) {
    size_t size =
        sizeof(Array_Data<String_Data*>) + input.size() * sizeof(StringPointer);
    for (size_t i = 0; i < input.size(); ++i)
      size += GetSerializedSize_(input[i]);
    return size;
  }

  static void SerializeElements(Array<String> input,
                                Buffer* buf,
                                Array_Data<String_Data*>* output,
                                const ArrayValidateParams* validate_params) {
    MOJO_DCHECK(
        validate_params->element_validate_params &&
        !validate_params->element_validate_params->element_validate_params &&
        !validate_params->element_validate_params->element_is_nullable &&
        validate_params->element_validate_params->expected_num_elements == 0)
        << "String type has unexpected array validate params";

    for (size_t i = 0; i < input.size(); ++i) {
      String_Data* element;
      Serialize_(input[i], buf, &element);
      output->at(i) = element;
      MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING(
          !validate_params->element_is_nullable && !element,
          VALIDATION_ERROR_UNEXPECTED_NULL_POINTER,
          MakeMessageWithArrayIndex("null in array expecting valid strings",
                                    input.size(), i));
    }
  }
  static void DeserializeElements(Array_Data<String_Data*>* input,
                                  Array<String>* output) {
    Array<String> result(input->size());
    for (size_t i = 0; i < input->size(); ++i)
      Deserialize_(input->at(i), &result[i]);
    output->Swap(&result);
  }
};

}  // namespace internal

template <typename E>
inline size_t GetSerializedSize_(const Array<E>& input) {
  if (!input)
    return 0;
  typedef typename internal::WrapperTraits<E>::DataType F;
  return internal::ArraySerializer<E, F>::GetSerializedSize(input);
}

template <typename E, typename F>
inline void SerializeArray_(
    Array<E> input,
    internal::Buffer* buf,
    internal::Array_Data<F>** output,
    const internal::ArrayValidateParams* validate_params) {
  if (input) {
    MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING(
        validate_params->expected_num_elements != 0 &&
            input.size() != validate_params->expected_num_elements,
        internal::VALIDATION_ERROR_UNEXPECTED_ARRAY_HEADER,
        internal::MakeMessageWithExpectedArraySize(
            "fixed-size array has wrong number of elements", input.size(),
            validate_params->expected_num_elements));

    internal::Array_Data<F>* result =
        internal::Array_Data<F>::New(input.size(), buf);
    if (result) {
      internal::ArraySerializer<E, F>::SerializeElements(
          internal::Forward(input), buf, result, validate_params);
    }
    *output = result;
  } else {
    *output = nullptr;
  }
}

template <typename E, typename F>
inline void Deserialize_(internal::Array_Data<F>* input, Array<E>* output) {
  if (input) {
    internal::ArraySerializer<E, F>::DeserializeElements(input, output);
  } else {
    output->reset();
  }
}

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_ARRAY_SERIALIZATION_H_
