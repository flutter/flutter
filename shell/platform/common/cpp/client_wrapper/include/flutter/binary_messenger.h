// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_BINARY_MESSENGER_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_BINARY_MESSENGER_H_

#include <functional>
#include <string>

// TODO: Consider adding absl as a dependency and using absl::Span for all of
// the message/message_size pairs.
namespace flutter {

// A binary message reply callback.
//
// Used for submitting a binary reply back to a Flutter message sender.
typedef std::function<void(const uint8_t* reply, const size_t reply_size)>
    BinaryReply;

// A message handler callback.
//
// Used for receiving messages from Flutter and providing an asynchronous reply.
typedef std::function<
    void(const uint8_t* message, const size_t message_size, BinaryReply reply)>
    BinaryMessageHandler;

// A protocol for a class that handles communication of binary data on named
// channels to and from the Flutter engine.
class BinaryMessenger {
 public:
  virtual ~BinaryMessenger() = default;

  // Sends a binary message to the Flutter side on the specified channel,
  // expecting no reply.
  virtual void Send(const std::string& channel,
                    const uint8_t* message,
                    const size_t message_size) const = 0;

  // Sends a binary message to the Flutter side on the specified channel,
  // expecting a reply.
  virtual void Send(const std::string& channel,
                    const uint8_t* message,
                    const size_t message_size,
                    BinaryReply reply) const = 0;

  // Registers a message handler for incoming binary messages from the Flutter
  // side on the specified channel.
  //
  // Replaces any existing handler. Provide a null handler to unregister the
  // existing handler.
  virtual void SetMessageHandler(const std::string& channel,
                                 BinaryMessageHandler handler) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_BINARY_MESSENGER_H_
