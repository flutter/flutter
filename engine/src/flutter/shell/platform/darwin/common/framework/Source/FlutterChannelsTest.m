// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

@interface MockBinaryMessenger : NSObject <FlutterBinaryMessenger>
@property(nonatomic, copy) NSString* channel;
@property(nonatomic, strong) NSData* message;
@property(nonatomic, strong) NSMutableDictionary<NSString*, FlutterBinaryMessageHandler>* handlers;
@end
@implementation MockBinaryMessenger
- (instancetype)init {
  self = [super init];
  if (self) {
    _handlers = [[NSMutableDictionary<NSString*, FlutterBinaryMessageHandler> alloc] init];
  }
  return self;
}

- (void)sendOnChannel:(NSString*)channel message:(NSData* _Nullable)message {
  [self sendOnChannel:channel message:message binaryReply:nil];
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData* _Nullable)message
          binaryReply:(FlutterBinaryReply _Nullable)callback {
  self.channel = channel;
  self.message = message;
}

- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString*)channel
                                          binaryMessageHandler:
                                              (FlutterBinaryMessageHandler _Nullable)handler {
  [self.handlers setObject:handler forKey:channel];
  return 0;
}

- (void)cleanupConnection:(FlutterBinaryMessengerConnection)connection {
}

@end

@interface FlutterChannelsTest : XCTestCase
@end

@implementation FlutterChannelsTest

- (void)testMethodInvoke {
  NSString* channelName = @"foo";
  id binaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterMethodChannel* channel = [[FlutterMethodChannel alloc] initWithName:channelName
                                                             binaryMessenger:binaryMessenger
                                                                       codec:codec];
  XCTAssertNotNil(channel);
  NSData* encodedMethodCall = [@"hey" dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([codec encodeMethodCall:[OCMArg any]]).andReturn(encodedMethodCall);
  [channel invokeMethod:@"foo" arguments:@[ @(1) ]];
  OCMVerify([binaryMessenger sendOnChannel:channelName message:encodedMethodCall]);
}

- (void)testMethodInvokeWithReply {
  NSString* channelName = @"foo";
  id binaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterMethodChannel* channel = [[FlutterMethodChannel alloc] initWithName:channelName
                                                             binaryMessenger:binaryMessenger
                                                                       codec:codec];
  XCTAssertNotNil(channel);
  NSData* encodedMethodCall = [@"hey" dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([codec encodeMethodCall:[OCMArg any]]).andReturn(encodedMethodCall);
  XCTestExpectation* didCallReply = [self expectationWithDescription:@"didCallReply"];
  OCMExpect([binaryMessenger sendOnChannel:channelName
                                   message:encodedMethodCall
                               binaryReply:[OCMArg checkWithBlock:^BOOL(id obj) {
                                 FlutterBinaryReply reply = obj;
                                 reply(nil);
                                 return YES;
                               }]]);
  [channel invokeMethod:@"foo"
              arguments:@[ @1 ]
                 result:^(id _Nullable result) {
                   [didCallReply fulfill];
                   XCTAssertEqual(FlutterMethodNotImplemented, result);
                 }];
  OCMVerifyAll(binaryMessenger);
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testMethodMessageHandler {
  NSString* channelName = @"foo";
  id binaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterMethodChannel* channel = [[FlutterMethodChannel alloc] initWithName:channelName
                                                             binaryMessenger:binaryMessenger
                                                                       codec:codec];
  XCTAssertNotNil(channel);

  NSData* encodedMethodCall = [@"hey" dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([codec encodeMethodCall:[OCMArg any]]).andReturn(encodedMethodCall);
  FlutterMethodCallHandler handler =
      ^(FlutterMethodCall* _Nonnull call, FlutterResult _Nonnull result) {
        NSLog(@"hey");
      };
  [channel setMethodCallHandler:handler];
  OCMVerify([binaryMessenger setMessageHandlerOnChannel:channelName
                                   binaryMessageHandler:[OCMArg isNotNil]]);
}

- (void)testCallMethodHandler {
  NSString* channelName = @"foo";
  MockBinaryMessenger* binaryMessenger = [[MockBinaryMessenger alloc] init];
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterMethodChannel* channel = [[FlutterMethodChannel alloc] initWithName:channelName
                                                             binaryMessenger:binaryMessenger
                                                                       codec:codec];
  XCTAssertNotNil(channel);

  NSData* encodedMethodCall = [@"encoded" dataUsingEncoding:NSUTF8StringEncoding];
  NSData* replyData = [@"reply" dataUsingEncoding:NSUTF8StringEncoding];
  NSData* replyEnvelopeData = [@"reply-envelope" dataUsingEncoding:NSUTF8StringEncoding];
  FlutterMethodCall* methodCall = [[FlutterMethodCall alloc] init];
  OCMStub([codec decodeMethodCall:encodedMethodCall]).andReturn(methodCall);
  OCMStub([codec encodeSuccessEnvelope:replyData]).andReturn(replyEnvelopeData);
  XCTestExpectation* didCallHandler = [self expectationWithDescription:@"didCallHandler"];
  XCTestExpectation* didCallReply = [self expectationWithDescription:@"didCallReply"];
  FlutterMethodCallHandler handler =
      ^(FlutterMethodCall* _Nonnull call, FlutterResult _Nonnull result) {
        XCTAssertEqual(methodCall, call);
        [didCallHandler fulfill];
        result(replyData);
      };
  [channel setMethodCallHandler:handler];
  binaryMessenger.handlers[channelName](encodedMethodCall, ^(NSData* reply) {
    [didCallReply fulfill];
    XCTAssertEqual(replyEnvelopeData, reply);
  });
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testResize {
  NSString* channelName = @"foo";
  id binaryMessenger = OCMStrictProtocolMock(@protocol(FlutterBinaryMessenger));
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterBasicMessageChannel* channel =
      [[FlutterBasicMessageChannel alloc] initWithName:channelName
                                       binaryMessenger:binaryMessenger
                                                 codec:codec];
  XCTAssertNotNil(channel);

  NSString* expectedMessageString =
      [NSString stringWithFormat:@"resize\r%@\r%@", channelName, @100];
  NSData* expectedMessage = [expectedMessageString dataUsingEncoding:NSUTF8StringEncoding];
  OCMExpect([binaryMessenger sendOnChannel:@"dev.flutter/channel-buffers" message:expectedMessage]);
  [channel resizeChannelBuffer:100];
  OCMVerifyAll(binaryMessenger);
  [binaryMessenger stopMocking];
}

- (void)testBasicMessageChannelCleanup {
  NSString* channelName = @"foo";
  FlutterBinaryMessengerConnection connection = 123;
  id binaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterBasicMessageChannel* channel =
      [[FlutterBasicMessageChannel alloc] initWithName:channelName
                                       binaryMessenger:binaryMessenger
                                                 codec:codec];
  FlutterMessageHandler handler = ^(id _Nullable message, FlutterReply callback) {
    NSLog(@"hey");
  };
  OCMStub([binaryMessenger setMessageHandlerOnChannel:channelName
                                 binaryMessageHandler:[OCMArg any]])
      .andReturn(connection);
  [channel setMessageHandler:handler];
  OCMVerify([binaryMessenger setMessageHandlerOnChannel:channelName
                                   binaryMessageHandler:[OCMArg isNotNil]]);
  [channel setMessageHandler:nil];
  OCMVerify([binaryMessenger cleanupConnection:connection]);
}

- (void)testMethodChannelCleanup {
  NSString* channelName = @"foo";
  FlutterBinaryMessengerConnection connection = 123;
  id binaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id codec = OCMProtocolMock(@protocol(FlutterMethodCodec));
  FlutterMethodChannel* channel = [[FlutterMethodChannel alloc] initWithName:channelName
                                                             binaryMessenger:binaryMessenger
                                                                       codec:codec];
  XCTAssertNotNil(channel);

  OCMStub([binaryMessenger setMessageHandlerOnChannel:channelName
                                 binaryMessageHandler:[OCMArg any]])
      .andReturn(connection);

  FlutterMethodCallHandler handler =
      ^(FlutterMethodCall* _Nonnull call, FlutterResult _Nonnull result) {
      };
  [channel setMethodCallHandler:handler];
  OCMVerify([binaryMessenger setMessageHandlerOnChannel:channelName
                                   binaryMessageHandler:[OCMArg isNotNil]]);
  [channel setMethodCallHandler:nil];
  OCMVerify([binaryMessenger cleanupConnection:connection]);
}

@end
