// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

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

const UInt8 DATE = 128;
const UInt8 PAIR = 129;

@interface ExtendedWriter : FlutterStandardWriter
- (void)writeValue:(id)value;
@end

@implementation ExtendedWriter
- (void)writeValue:(id)value {
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
    [super writeValue:value];
  }
}
@end

@interface ExtendedReader : FlutterStandardReader
- (id)readValueOfType:(UInt8)type;
@end

@implementation ExtendedReader
- (id)readValueOfType:(UInt8)type {
  switch (type) {
    case DATE: {
      SInt64 value;
      [self readBytes:&value length:8];
      NSTimeInterval time = [NSNumber numberWithLong:value].doubleValue / 1000.0;
      return [NSDate dateWithTimeIntervalSince1970:time];
    }
    case PAIR: {
      return [[Pair alloc] initWithLeft:[self readValue] right:[self readValue]];
    }
    default: return [super readValueOfType:type];
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
  // This integration test still uses the old way of registering platform
  // channels to test backwards compatibility after the UISceneDelegate
  // migration.
  id<FlutterPluginRegistrar> registrar = [self registrarForPlugin:@"platform-channel-test"];
  ExtendedReaderWriter* extendedReaderWriter = [ExtendedReaderWriter new];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"binary-msg"
                                       binaryMessenger:registrar.messenger
                                                 codec:[FlutterBinaryCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"string-msg"
                                       binaryMessenger:registrar.messenger
                                                 codec:[FlutterStringCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"json-msg"
                                       binaryMessenger:registrar.messenger
                                                 codec:[FlutterJSONMessageCodec sharedInstance]]];
  [self setupMessagingHandshakeOnChannel:
    [FlutterBasicMessageChannel messageChannelWithName:@"std-msg"
                                       binaryMessenger:registrar.messenger
                                                 codec:[FlutterStandardMessageCodec codecWithReaderWriter:extendedReaderWriter]]];
  [self setupMethodCallSuccessHandshakeOnChannel:
    [FlutterMethodChannel methodChannelWithName:@"json-method"
                                binaryMessenger:registrar.messenger
                                          codec:[FlutterJSONMethodCodec sharedInstance]]];
  [self setupMethodCallSuccessHandshakeOnChannel:
    [FlutterMethodChannel methodChannelWithName:@"std-method"
                                binaryMessenger:registrar.messenger
                                          codec:[FlutterStandardMethodCodec codecWithReaderWriter:extendedReaderWriter]]];

  [[FlutterBasicMessageChannel
      messageChannelWithName:@"std-echo"
             binaryMessenger:registrar.messenger
                       codec:[FlutterStandardMessageCodec
                                 codecWithReaderWriter:extendedReaderWriter]]
      setMessageHandler:^(id message, FlutterReply reply) {
        reply(message);
      }];

  return [super application:application
      didFinishLaunchingWithOptions:launchOptions];
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
