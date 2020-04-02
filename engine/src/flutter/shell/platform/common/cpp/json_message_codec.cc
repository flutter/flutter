// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/json_message_codec.h"

#include <iostream>
#include <string>

#include "rapidjson/error/en.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

namespace flutter {

// static
const JsonMessageCodec& JsonMessageCodec::GetInstance() {
  static JsonMessageCodec sInstance;
  return sInstance;
}

std::unique_ptr<std::vector<uint8_t>> JsonMessageCodec::EncodeMessageInternal(
    const rapidjson::Document& message) const {
  // TODO: Look into alternate writers that would avoid the buffer copy.
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  message.Accept(writer);
  const char* buffer_start = buffer.GetString();
  return std::make_unique<std::vector<uint8_t>>(
      buffer_start, buffer_start + buffer.GetSize());
}

std::unique_ptr<rapidjson::Document> JsonMessageCodec::DecodeMessageInternal(
    const uint8_t* binary_message,
    const size_t message_size) const {
  auto raw_message = reinterpret_cast<const char*>(binary_message);
  auto json_message = std::make_unique<rapidjson::Document>();
  rapidjson::ParseResult result =
      json_message->Parse(raw_message, message_size);
  bool parsing_successful =
      result == rapidjson::ParseErrorCode::kParseErrorNone;
  if (!parsing_successful) {
    std::cerr << "Unable to parse JSON message:" << std::endl
              << rapidjson::GetParseError_En(result.Code()) << std::endl;
    return nullptr;
  }
  return json_message;
}

}  // namespace flutter
