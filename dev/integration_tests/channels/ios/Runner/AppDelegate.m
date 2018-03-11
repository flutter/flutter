// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@interface Pair : NSObject
@property(atomic, readonly, strong, nullable) NSObject* left;
@property(atomic, readonly, strong, nullable) NSObject* right;
- (instancetype)initWithLeft:(NSObject*)first right:(NSObject*)right;
@end

@implementation Pair
- (instancetype)initWithLeft:(NSObject*)left right:(NSObject*)right {
  self = [super init];
  _left = left;
  _right = right;
  return self;
}
@end

const uint8_t DATE = 0;
const uint8_t PAIR = 1;

@interface ExtendedWriter : FlutterStandardWriter
- (void)writeUnknownValue:(id)value;
@end

@implementation ExtendedWriter
- (void)writeUnknownValue:(id)value {
  if ([value isKindOfClass:[NSDate class]]) {
    [self writeByte:DATE];
    NSDate* date = value;
    NSTimeInterval time = date.timeIntervalSince1970;
    SInt64 ms = (SInt64) (time * 1000.0);
    [self writeBytes:&ms length:8];
  } else if ([value isKindOfClass:[Pair class]]) {
    Pair* pair = value;
    [self writeByte:PAIR];
    [self writeValue:pair.left];
    [self writeValue:pair.right];
  } else {
    [super writeUnknownValue:value];
  }
}
@end

@interface ExtendedReader : FlutterStandardReader
- (id)readUnknownValue;
@end

@implementation ExtendedReader
- (id)readUnknownValue {
  uint8_t field = [self readByte];
  switch (field) {
    case DATE: {
      SInt64 value;
      [self readBytes:&value length:8];
      NSTimeInterval time = [NSNumber numberWithLong:value].doubleValue / 1000.0;
      return [NSDate dateWithTimeIntervalSince1970:time];
    }
    case PAIR: {
      return [[Pair alloc] initWithLeft:[self readValue] right:[self readValue]];
    }
    default: return [super readUnknownValue];
  }
}
@end

@interface ExtendedReaderWriter : FlutterStandardReaderWriter
- (FlutterStandardWriter*)writerWithData:(NSMutableData*)data;
- (FlutterStandardReader*)readerWithData:(NSData*)data;
@end

@implementation ExtendedReaderWriter
- (FlutterStandardWriter*)writerWithData:(NSMutableData*)data {
  return [[ExtendedWriter alloc] initWithData:data];
}
- (FlutterStandardReader*)readerWithData:(NSData*)data {
  return [[ExtendedReader alloc] initWithData:data];
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  FlutterViewController *flutterController =
      (FlutterViewController *)self.window.rootViewController;

  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"binary-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterBinaryCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"string-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterStringCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"json-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterJSONMessageCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"std-msg"
                                       binaryMessenger:flutterController
                                                 codec:[FlutterStandardMessageCodec withReaderWriter:[ExtendedReaderWriter new]]]];
  [self setupMethodCallSuccessHandshakeOnChannel:
    [FlutterMethodChannel methodChannelWithName:@"json-method"
                                binaryMessenger:flutterController
                                          codec:[FlutterJSONMethodCodec sharedInstance]]];
  [self setupMethodCallSuccessHandshakeOnChannel:
    [FlutterMethodChannel methodChannelWithName:@"std-method"
                                binaryMessenger:flutterController
                                          codec:[FlutterStandardMethodCodec withReaderWriter:[ExtendedReaderWriter new]]]];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)setupMessagingHandshakeOnChannel:(FlutterBasicMessageChannel*)channel {
  [channel setMessageHandler:^(id message, FlutterReply reply) {
    [channel sendMessage:message reply:^(id messageReply) {
      [channel sendMessage:messageReply];
      reply(message);
    }];
  }];
}

- (void)setupMethodCallSuccessHandshakeOnChannel:(FlutterMethodChannel*)channel {
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    if ([call.method isEqual:@"success"]) {
      [channel invokeMethod:call.method arguments:call.arguments result:^(id value) {
        [channel invokeMethod:call.method arguments:value];
        result(call.arguments);
      }];
    } else if ([call.method isEqual:@"error"]) {
      [channel invokeMethod:call.method arguments:call.arguments result:^(id value) {
        FlutterError* error = (FlutterError*) value;
        [channel invokeMethod:call.method arguments:error.details];
        result(error);
      }];
    } else {
      [channel invokeMethod:call.method arguments:call.arguments result:^(id value) {
        NSAssert(value == FlutterMethodNotImplemented, @"Result must be not implemented");
        [channel invokeMethod:call.method arguments:nil];
        result(FlutterMethodNotImplemented);
      }];
    }
  }];
}
@end
