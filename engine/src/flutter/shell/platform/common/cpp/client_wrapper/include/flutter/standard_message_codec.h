// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_STANDARD_MESSAGE_CODEC_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_STANDARD_MESSAGE_CODEC_H_

#include "encodable_value.h"
#include "message_codec.h"

namespace flutter {

// A binary message encoding/decoding mechanism for communications to/from the
// Flutter engine via message channels.
class StandardMessageCodec : public MessageCodec<EncodableValue> {
 public:
  // Returns the shared instance of the codec.
  static const StandardMessageCodec& GetInstance();

  ~StandardMessageCodec();

  // Prevent copying.
  StandardMessageCodec(StandardMessageCodec const&) = delete;
  StandardMessageCodec& operator=(StandardMessageCodec const&) = delete;

 protected:
  // Instances should be obtained via GetInstance.
  StandardMessageCodec();

  // |flutter::MessageCodec|
  std::unique_ptr<EncodableValue> DecodeMessageInternal(
      const uint8_t* binary_message,
      const size_t message_size) const override;

  // |flutter::MessageCodec|
  std::unique_ptr<std::vector<uint8_t>> EncodeMessageInternal(
      const EncodableValue& message) const override;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_STANDARD_MESSAGE_CODEC_H_
