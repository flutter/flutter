// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_H_
#define FLUTTER_FML_MESSAGE_H_

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <memory>
#include <type_traits>
#include <utility>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"

namespace fml {

#define FML_SERIALIZE(message, value) \
  if (!message.Encode(value)) {       \
    return false;                     \
  }

#define FML_SERIALIZE_TRAITS(message, value, traits) \
  if (!message.Encode<traits>(value)) {              \
    return false;                                    \
  }

#define FML_DESERIALIZE(message, value) \
  if (!message.Decode(value)) {         \
    return false;                       \
  }

#define FML_DESERIALIZE_TRAITS(message, value, traits) \
  if (!message.Decode<traits>(value)) {                \
    return false;                                      \
  }

class Message;

class MessageSerializable {
 public:
  virtual ~MessageSerializable() = default;

  virtual bool Serialize(Message& message) const = 0;

  virtual bool Deserialize(Message& message) = 0;

  virtual size_t GetSerializableTag() const { return 0; };
};

// The traits passed to the encode/decode calls that accept traits should be
// something like the following.
//
// class MessageSerializableTraits {
//  static size_t GetSerializableTag(const T&);
//  static std::unique_ptr<T> CreateForSerializableTag(size_t tag);
// };

template <class T>
struct Serializable : public std::integral_constant<
                          bool,
                          std::is_trivially_copyable<T>::value ||
                              std::is_base_of<MessageSerializable, T>::value> {
};

// Utility class to encode and decode |Serializable| types to and from a buffer.
// Elements have to be read back into the same order they were written.
class Message {
 public:
  Message();

  ~Message();

  const uint8_t* GetBuffer() const;

  size_t GetBufferSize() const;

  size_t GetDataLength() const;

  size_t GetSizeRead() const;

  void ResetRead();

  // Encoders.

  template <typename T,
            typename = std::enable_if_t<std::is_trivially_copyable<T>::value>>
  FML_WARN_UNUSED_RESULT bool Encode(const T& value) {
    if (auto buffer = PrepareEncode(sizeof(T))) {
      ::memcpy(buffer, &value, sizeof(T));
      return true;
    }
    return false;
  }

  FML_WARN_UNUSED_RESULT bool Encode(const MessageSerializable& value) {
    return value.Serialize(*this);
  }

  template <typename Traits,
            typename T,
            typename = std::enable_if_t<
                std::is_base_of<MessageSerializable, T>::value>>
  FML_WARN_UNUSED_RESULT bool Encode(const std::unique_ptr<T>& value) {
    // Encode if null.
    if (!Encode(static_cast<bool>(value))) {
      return false;
    }

    if (!value) {
      return true;
    }

    // Encode the type.
    if (!Encode(Traits::GetSerializableTag(*value.get()))) {
      return false;
    }

    // Encode the value.
    if (!Encode(*value.get())) {
      return false;
    }

    return true;
  }

  // Decoders.

  template <typename T,
            typename = std::enable_if_t<std::is_trivially_copyable<T>::value>>
  FML_WARN_UNUSED_RESULT bool Decode(T& value) {
    if (auto buffer = PrepareDecode(sizeof(T))) {
      ::memcpy(&value, buffer, sizeof(T));
      return true;
    }
    return false;
  }

  FML_WARN_UNUSED_RESULT bool Decode(MessageSerializable& value) {
    return value.Deserialize(*this);
  }

  template <typename Traits,
            typename T,
            typename = std::enable_if_t<
                std::is_base_of<MessageSerializable, T>::value>>
  FML_WARN_UNUSED_RESULT bool Decode(std::unique_ptr<T>& value) {
    // Decode if null.
    bool is_null = false;
    if (!Decode(is_null)) {
      return false;
    }

    if (is_null) {
      return true;
    }

    // Decode type.
    size_t tag = 0;
    if (!Decode(tag)) {
      return false;
    }

    std::unique_ptr<T> new_value = Traits::CreateForSerializableTag(tag);
    if (!new_value) {
      return false;
    }

    // Decode value.
    if (!Decode(*new_value.get())) {
      return false;
    }

    std::swap(value, new_value);

    return true;
  }

 private:
  uint8_t* buffer_ = nullptr;
  size_t buffer_length_ = 0;
  size_t data_length_ = 0;
  size_t size_read_ = 0;

  FML_WARN_UNUSED_RESULT
  bool Reserve(size_t size);

  FML_WARN_UNUSED_RESULT
  bool Resize(size_t size);

  FML_WARN_UNUSED_RESULT
  uint8_t* PrepareEncode(size_t size);

  FML_WARN_UNUSED_RESULT
  uint8_t* PrepareDecode(size_t size);

  FML_DISALLOW_COPY_AND_ASSIGN(Message);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_H_
