// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSurrogateBinaryMessenger.h"
#include "gtest/gtest.h"

@interface MockBinaryMessenger : NSObject <FlutterBinaryMessenger>
@property(nonatomic, assign) int sendOnChannel_message_count;
@end

@implementation MockBinaryMessenger
- (void)sendOnChannel:(NSString*)channel message:(NSData* _Nullable)message {
  _sendOnChannel_message_count++;
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData* _Nullable)message
          binaryReply:(FlutterBinaryReply _Nullable)callback {
}

- (void)setMessageHandlerOnChannel:(NSString*)channel
              binaryMessageHandler:(FlutterBinaryMessageHandler _Nullable)handler {
}
@end

@interface MockSurrogateBinaryMessenger
    : NSObject <FlutterBinaryMessenger, FlutterSurrogateBinaryMessenger>
@property(nonatomic, strong) MockBinaryMessenger* surrogate;
@property(nonatomic, assign) int sendOnChannel_message_count;
@end

@implementation MockSurrogateBinaryMessenger
- (instancetype)init {
  self = [super init];
  if (self) {
    _surrogate = [[[MockBinaryMessenger alloc] init] retain];
  }
  return self;
}

- (void)dealloc {
  [_surrogate release];
  [super dealloc];
}

- (void)sendOnChannel:(NSString*)channel message:(NSData* _Nullable)message {
  _sendOnChannel_message_count++;
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData* _Nullable)message
          binaryReply:(FlutterBinaryReply _Nullable)callback {
}

- (void)setMessageHandlerOnChannel:(NSString*)channel
              binaryMessageHandler:(FlutterBinaryMessageHandler _Nullable)handler {
}

- (NSObject<FlutterBinaryMessenger>*)surrogateBinaryMessenger {
  return _surrogate;
}

@end

TEST(FlutterChannels, BasicMessageChannelUsesSurrogate) {
  MockSurrogateBinaryMessenger* binaryMessenger =
      [[[MockSurrogateBinaryMessenger alloc] init] autorelease];
  NSObject<FlutterMessageCodec>* codec = [FlutterStandardMessageCodec sharedInstance];
  FlutterBasicMessageChannel* channel =
      [[[FlutterBasicMessageChannel alloc] initWithName:@"channel-name"
                                        binaryMessenger:binaryMessenger
                                                  codec:codec] autorelease];
  ASSERT_TRUE(channel != nil);
  [channel sendMessage:nil];
  ASSERT_EQ(1, binaryMessenger.surrogate.sendOnChannel_message_count);
  ASSERT_EQ(0, binaryMessenger.sendOnChannel_message_count);
}

TEST(FlutterChannels, MethodChannelUsesSurrogate) {
  MockSurrogateBinaryMessenger* binaryMessenger =
      [[[MockSurrogateBinaryMessenger alloc] init] autorelease];
  NSObject<FlutterMethodCodec>* codec = [FlutterStandardMethodCodec sharedInstance];
  FlutterMethodChannel* channel = [[[FlutterMethodChannel alloc] initWithName:@"channel-name"
                                                              binaryMessenger:binaryMessenger
                                                                        codec:codec] autorelease];
  ASSERT_TRUE(channel != nil);
  [channel invokeMethod:@"foo" arguments:nil];
  ASSERT_EQ(1, binaryMessenger.surrogate.sendOnChannel_message_count);
  ASSERT_EQ(0, binaryMessenger.sendOnChannel_message_count);
}

TEST(FlutterChannels, EventChannelRetainsSurrogate) {
  MockSurrogateBinaryMessenger* binaryMessenger =
      [[[MockSurrogateBinaryMessenger alloc] init] autorelease];
  NSObject<FlutterMethodCodec>* codec = [FlutterStandardMethodCodec sharedInstance];
  NSUInteger binaryMessengerRetainCount = [binaryMessenger retainCount];
  NSUInteger surrogateRetainCount = [binaryMessenger.surrogate retainCount];

  FlutterEventChannel* channel = [[[FlutterEventChannel alloc] initWithName:@"channel-name"
                                                            binaryMessenger:binaryMessenger
                                                                      codec:codec] autorelease];
  ASSERT_TRUE(channel != nil);
  ASSERT_EQ(binaryMessengerRetainCount, binaryMessenger.retainCount);
  ASSERT_EQ(surrogateRetainCount + 1, binaryMessenger.surrogate.retainCount);
}
