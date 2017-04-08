// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERBINARYMESSENGER_H_
#define FLUTTER_FLUTTERBINARYMESSENGER_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

NS_ASSUME_NONNULL_BEGIN
/**
 A strategy for handling a binary message reply.
 */
typedef void (^FlutterBinaryReplyHandler)(NSData* _Nullable reply);

/**
 A strategy for handling incoming binary messages and to send asynchronous
 replies.
 */
typedef void (^FlutterBinaryMessageHandler)(
    NSData* _Nullable message,
    FlutterBinaryReplyHandler replyHandler);

/**
 A facility for communicating with the Flutter side using asynchronous message
 passing with binary messages.

 - SeeAlso:
   - `FlutterMessageChannel`, which supports communication using structured messages.
   - `FlutterMethodChannel`, which supports communication using asynchronous method calls.
   - `FlutterEventChannel`, which supports commuication using event streams.
 */
FLUTTER_EXPORT
@protocol FlutterBinaryMessenger<NSObject>
/**
 Sends a binary message to the Flutter side on the specified channel, expecting
 no reply.

 - Parameters:
   - message: The message.
   - channelName: The channel name.
 */
- (void)sendBinaryMessage:(NSData* _Nullable)message
              channelName:(NSString*)channelName;

/**
 Sends a binary message to the Flutter side on the specified channel, expecting
 an asynchronous reply.

 - Parameters:
   - message: The message.
   - channelName: The channel name.
   - handler: A reply handler.
 */
- (void)sendBinaryMessage:(NSData* _Nullable)message
              channelName:(NSString*)channelName
       binaryReplyHandler:(FlutterBinaryReplyHandler _Nullable)handler;

/**
 Registers a message handler for incoming binary messages from the Flutter side
 on the specified channel.

 Replaces any existing handler. Use a `nil` handler for unregistering the
 existing handler.

 - Parameters:
   - channelName: The channel name.
   - handler: The message handler.
 */
- (void)setBinaryMessageHandlerOnChannel:(NSString*)channelName
                    binaryMessageHandler:(FlutterBinaryMessageHandler _Nullable)handler;
@end
NS_ASSUME_NONNULL_END
#endif  // FLUTTER_FLUTTERBINARYMESSENGER_H_
