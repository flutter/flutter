// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_JSON_MESSAGE_CODEC_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_JSON_MESSAGE_CODEC_H_

#include "json_type.h"
#include "message_codec.h"

namespace flutter {

// A message encoding/decoding mechanism for communications to/from the
// Flutter engine via JSON channels.
class JsonMessageCodec : public MessageCodec<JsonValueType> {
 public:
  // Returns the shared instance of the codec.
  static const JsonMessageCodec& GetInstance();

  ~JsonMessageCodec() = default;

  // Prevent copying.
  JsonMessageCodec(JsonMessageCodec const&) = delete;
  JsonMessageCodec& operator=(JsonMessageCodec const&) = delete;

 protected:
  // Instances should be obtained via GetInstance.
  JsonMessageCodec() = default;

  // |flutter::MessageCodec|
  std::unique_ptr<JsonValueType> DecodeMessageInternal(
      const uint8_t* binary_message,
      const size_t message_size) const override;

  // |flutter::MessageCodec|
  std::unique_ptr<std::vector<uint8_t>> EncodeMessageInternal(
      const JsonValueType& message) const override;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_JSON_MESSAGE_CODEC_H_
