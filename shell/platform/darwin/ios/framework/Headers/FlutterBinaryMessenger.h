// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERBINARYMESSAGES_H_
#define FLUTTER_FLUTTERBINARYMESSAGES_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

typedef void (^FlutterBinaryReplyHandler)(NSData* reply);
typedef void (^FlutterBinaryMessageHandler)(
    NSData* message,
    FlutterBinaryReplyHandler replyHandler);

FLUTTER_EXPORT
@protocol FlutterBinaryMessenger<NSObject>
- (void)sendBinaryMessage:(NSData*)message channelName:(NSString*)channelName;

- (void)sendBinaryMessage:(NSData*)message
              channelName:(NSString*)channelName
       binaryReplyHandler:(FlutterBinaryReplyHandler)handler;

- (void)setBinaryMessageHandlerOnChannel:(NSString*)channelName
                    binaryMessageHandler:(FlutterBinaryMessageHandler)handler;
@end

#endif  // FLUTTER_FLUTTERBINARYMESSAGES_H_
