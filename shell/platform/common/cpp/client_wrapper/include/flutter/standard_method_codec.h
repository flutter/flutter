// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_STANDARD_METHOD_CODEC_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_STANDARD_METHOD_CODEC_H_

#include "encodable_value.h"
#include "method_call.h"
#include "method_codec.h"

namespace flutter {

// An implementation of MethodCodec that uses a binary serialization.
class StandardMethodCodec : public MethodCodec<EncodableValue> {
 public:
  // Returns the shared instance of the codec.
  static const StandardMethodCodec& GetInstance();

  ~StandardMethodCodec() = default;

  // Prevent copying.
  StandardMethodCodec(StandardMethodCodec const&) = delete;
  StandardMethodCodec& operator=(StandardMethodCodec const&) = delete;

 protected:
  // Instances should be obtained via GetInstance.
  StandardMethodCodec() = default;

  // |flutter::MethodCodec|
  std::unique_ptr<MethodCall<EncodableValue>> DecodeMethodCallInternal(
      const uint8_t* message,
      size_t message_size) const override;

  // |flutter::MethodCodec|
  std::unique_ptr<std::vector<uint8_t>> EncodeMethodCallInternal(
      const MethodCall<EncodableValue>& method_call) const override;

  // |flutter::MethodCodec|
  std::unique_ptr<std::vector<uint8_t>> EncodeSuccessEnvelopeInternal(
      const EncodableValue* result) const override;

  // |flutter::MethodCodec|
  std::unique_ptr<std::vector<uint8_t>> EncodeErrorEnvelopeInternal(
      const std::string& error_code,
      const std::string& error_message,
      const EncodableValue* error_details) const override;

  // |flutter::MethodCodec|
  bool DecodeAndProcessResponseEnvelopeInternal(
      const uint8_t* response,
      size_t response_size,
      MethodResult<EncodableValue>* result) const override;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_STANDARD_METHOD_CODEC_H_
