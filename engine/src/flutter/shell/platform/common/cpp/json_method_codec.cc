// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/json_method_codec.h"

#include "flutter/shell/platform/common/cpp/json_message_codec.h"

namespace flutter {

namespace {
// Keys used in MethodCall encoding.
constexpr char kMessageMethodKey[] = "method";
constexpr char kMessageArgumentsKey[] = "args";
}  // namespace

// static
const JsonMethodCodec& JsonMethodCodec::GetInstance() {
  static JsonMethodCodec sInstance;
  return sInstance;
}

std::unique_ptr<MethodCall<rapidjson::Document>>
JsonMethodCodec::DecodeMethodCallInternal(const uint8_t* message,
                                          const size_t message_size) const {
  std::unique_ptr<rapidjson::Document> json_message =
      JsonMessageCodec::GetInstance().DecodeMessage(message, message_size);
  if (!json_message) {
    return nullptr;
  }

  auto method_name_iter = json_message->FindMember(kMessageMethodKey);
  if (method_name_iter == json_message->MemberEnd()) {
    return nullptr;
  }
  if (!method_name_iter->value.IsString()) {
    return nullptr;
  }
  std::string method_name(method_name_iter->value.GetString());
  auto arguments_iter = json_message->FindMember(kMessageArgumentsKey);
  std::unique_ptr<rapidjson::Document> arguments;
  if (arguments_iter != json_message->MemberEnd()) {
    // Pull the arguments subtree up to the root of json_message. This is
    // destructive to json_message, but the full value is no longer needed, and
    // this avoids a subtree copy.
    // Note: The static_cast is for compatibility with RapidJSON 1.1; master
    // already allows swapping a Document with a Value directly. Once there is
    // a new RapidJSON release (at which point clients can be expected to have
    // that change in the version they depend on) remove the cast.
    static_cast<rapidjson::Value*>(json_message.get())
        ->Swap(arguments_iter->value);
    // Swap it into |arguments|. This moves the allocator ownership, so that
    // the data won't be deleted when json_message goes out of scope.
    arguments = std::make_unique<rapidjson::Document>();
    arguments->Swap(*json_message);
  }
  return std::make_unique<MethodCall<rapidjson::Document>>(
      method_name, std::move(arguments));
}

std::unique_ptr<std::vector<uint8_t>> JsonMethodCodec::EncodeMethodCallInternal(
    const MethodCall<rapidjson::Document>& method_call) const {
  // TODO: Consider revisiting the codec APIs to avoid the need to copy
  // everything when doing encoding (e.g., by having a version that takes
  // owership of the object to encode, so that it can be moved instead).
  rapidjson::Document message(rapidjson::kObjectType);
  auto& allocator = message.GetAllocator();
  rapidjson::Value name(method_call.method_name(), allocator);
  rapidjson::Value arguments;
  if (method_call.arguments()) {
    arguments.CopyFrom(*method_call.arguments(), allocator);
  }
  message.AddMember(kMessageMethodKey, name, allocator);
  message.AddMember(kMessageArgumentsKey, arguments, allocator);

  return JsonMessageCodec::GetInstance().EncodeMessage(message);
}

std::unique_ptr<std::vector<uint8_t>>
JsonMethodCodec::EncodeSuccessEnvelopeInternal(
    const rapidjson::Document* result) const {
  rapidjson::Document envelope;
  envelope.SetArray();
  rapidjson::Value result_value;
  if (result) {
    result_value.CopyFrom(*result, envelope.GetAllocator());
  }
  envelope.PushBack(result_value, envelope.GetAllocator());

  return JsonMessageCodec::GetInstance().EncodeMessage(envelope);
}

std::unique_ptr<std::vector<uint8_t>>
JsonMethodCodec::EncodeErrorEnvelopeInternal(
    const std::string& error_code,
    const std::string& error_message,
    const rapidjson::Document* error_details) const {
  rapidjson::Document envelope(rapidjson::kArrayType);
  auto& allocator = envelope.GetAllocator();
  envelope.PushBack(rapidjson::Value(error_code, allocator), allocator);
  envelope.PushBack(rapidjson::Value(error_message, allocator), allocator);
  rapidjson::Value details_value;
  if (error_details) {
    details_value.CopyFrom(*error_details, allocator);
  }
  envelope.PushBack(details_value, allocator);

  return JsonMessageCodec::GetInstance().EncodeMessage(envelope);
}

}  // namespace flutter
