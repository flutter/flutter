// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_METHOD_CHANNEL_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_METHOD_CHANNEL_H_

#include <iostream>
#include <string>

#include "binary_messenger.h"
#include "engine_method_result.h"
#include "method_call.h"
#include "method_codec.h"
#include "method_result.h"

namespace flutter {

// A handler for receiving a method call from the Flutter engine.
//
// Implementations must asynchronously call exactly one of the methods on
// |result| to indicate the result of the method call.
template <typename T>
using MethodCallHandler =
    std::function<void(const MethodCall<T>& call,
                       std::unique_ptr<MethodResult<T>> result)>;

// A channel for communicating with the Flutter engine using invocation of
// asynchronous methods.
template <typename T>
class MethodChannel {
 public:
  // Creates an instance that sends and receives method calls on the channel
  // named |name|, encoded with |codec| and dispatched via |messenger|.
  MethodChannel(BinaryMessenger* messenger,
                const std::string& name,
                const MethodCodec<T>* codec)
      : messenger_(messenger), name_(name), codec_(codec) {}

  ~MethodChannel() = default;

  // Prevent copying.
  MethodChannel(MethodChannel const&) = delete;
  MethodChannel& operator=(MethodChannel const&) = delete;

  // Sends a message to the Flutter engine on this channel.
  void InvokeMethod(const std::string& method, std::unique_ptr<T> arguments) {
    MethodCall<T> method_call(method, std::move(arguments));
    std::unique_ptr<std::vector<uint8_t>> message =
        codec_->EncodeMethodCall(method_call);
    messenger_->Send(name_, message->data(), message->size(), nullptr);
  }

  // Sends a message to the Flutter engine on this channel expecting a reply.
  void InvokeMethod(const std::string& method,
                    std::unique_ptr<T> arguments,
                    flutter::BinaryReply reply) {
    MethodCall<T> method_call(method, std::move(arguments));
    std::unique_ptr<std::vector<uint8_t>> message =
        codec_->EncodeMethodCall(method_call);
    messenger_->Send(name_, message->data(), message->size(), reply);
  }

  // Registers a handler that should be called any time a method call is
  // received on this channel.
  void SetMethodCallHandler(MethodCallHandler<T> handler) const {
    const auto* codec = codec_;
    std::string channel_name = name_;
    BinaryMessageHandler binary_handler = [handler, codec, channel_name](
                                              const uint8_t* message,
                                              const size_t message_size,
                                              BinaryReply reply) {
      // Use this channel's codec to decode the call and build a result handler.
      auto result =
          std::make_unique<EngineMethodResult<T>>(std::move(reply), codec);
      std::unique_ptr<MethodCall<T>> method_call =
          codec->DecodeMethodCall(message, message_size);
      if (!method_call) {
        std::cerr << "Unable to construct method call from message on channel "
                  << channel_name << std::endl;
        result->NotImplemented();
        return;
      }
      handler(*method_call, std::move(result));
    };
    messenger_->SetMessageHandler(name_, std::move(binary_handler));
  }

 private:
  BinaryMessenger* messenger_;
  std::string name_;
  const MethodCodec<T>* codec_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_METHOD_CHANNEL_H_
