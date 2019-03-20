// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/json_message_codec.h"

#include <iostream>
#include <string>

#ifdef USE_RAPID_JSON
#include "rapidjson/error/en.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"
#endif

namespace flutter {

// static
const JsonMessageCodec& JsonMessageCodec::GetInstance() {
  static JsonMessageCodec sInstance;
  return sInstance;
}

std::unique_ptr<std::vector<uint8_t>> JsonMessageCodec::EncodeMessageInternal(
    const JsonValueType& message) const {
#ifdef USE_RAPID_JSON
  // TODO: Look into alternate writers that would avoid the buffer copy.
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  message.Accept(writer);
  const char* buffer_start = buffer.GetString();
  return std::make_unique<std::vector<uint8_t>>(
      buffer_start, buffer_start + buffer.GetSize());
#else
  Json::StreamWriterBuilder writer_builder;
  std::string serialization = Json::writeString(writer_builder, message);
  return std::make_unique<std::vector<uint8_t>>(serialization.begin(),
                                                serialization.end());
#endif
}

std::unique_ptr<JsonValueType> JsonMessageCodec::DecodeMessageInternal(
    const uint8_t* binary_message,
    const size_t message_size) const {
  auto raw_message = reinterpret_cast<const char*>(binary_message);
  auto json_message = std::make_unique<JsonValueType>();
  std::string parse_errors;
  bool parsing_successful = false;
#ifdef USE_RAPID_JSON
  rapidjson::ParseResult result =
      json_message->Parse(raw_message, message_size);
  parsing_successful = result == rapidjson::ParseErrorCode::kParseErrorNone;
  if (!parsing_successful) {
    parse_errors = rapidjson::GetParseError_En(result.Code());
  }
#else
  Json::CharReaderBuilder reader_builder;
  std::unique_ptr<Json::CharReader> parser(reader_builder.newCharReader());
  parsing_successful = parser->parse(raw_message, raw_message + message_size,
                                     json_message.get(), &parse_errors);
#endif
  if (!parsing_successful) {
    std::cerr << "Unable to parse JSON message:" << std::endl
              << parse_errors << std::endl;
    return nullptr;
  }
  return json_message;
}

}  // namespace flutter
