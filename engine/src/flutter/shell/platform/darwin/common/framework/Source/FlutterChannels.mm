// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"

#pragma mark - Basic message channel

static NSString* const FlutterChannelBuffersChannel = @"dev.flutter/channel-buffers";

static void ResizeChannelBuffer(NSObject<FlutterBinaryMessenger>* binaryMessenger,
                                NSString* channel,
                                NSInteger newSize) {
  NSString* messageString = [NSString stringWithFormat:@"resize\r%@\r%@", channel, @(newSize)];
  NSData* message = [messageString dataUsingEncoding:NSUTF8StringEncoding];
  [binaryMessenger sendOnChannel:FlutterChannelBuffersChannel message:message];
}

@implementation FlutterBasicMessageChannel {
  NSObject<FlutterBinaryMessenger>* _messenger;
  NSString* _name;
  NSObject<FlutterMessageCodec>* _codec;
}
+ (instancetype)messageChannelWithName:(NSString*)name
                       binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  NSObject<FlutterMessageCodec>* codec = [FlutterStandardMessageCodec sharedInstance];
  return [FlutterBasicMessageChannel messageChannelWithName:name
                                            binaryMessenger:messenger
                                                      codec:codec];
}
+ (instancetype)messageChannelWithName:(NSString*)name
                       binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                                 codec:(NSObject<FlutterMessageCodec>*)codec {
  return [[[FlutterBasicMessageChannel alloc] initWithName:name
                                           binaryMessenger:messenger
                                                     codec:codec] autorelease];
}

- (instancetype)initWithName:(NSString*)name
             binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                       codec:(NSObject<FlutterMessageCodec>*)codec {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _name = [name retain];
  _messenger = [messenger retain];
  _codec = [codec retain];
  return self;
}

- (void)dealloc {
  [_name release];
  [_messenger release];
  [_codec release];
  [super dealloc];
}

- (void)sendMessage:(id)message {
  [_messenger sendOnChannel:_name message:[_codec encode:message]];
}

- (void)sendMessage:(id)message reply:(FlutterReply)callback {
  FlutterBinaryReply reply = ^(NSData* data) {
    if (callback)
      callback([_codec decode:data]);
  };
  [_messenger sendOnChannel:_name message:[_codec encode:message] binaryReply:reply];
}

- (void)setMessageHandler:(FlutterMessageHandler)handler {
  if (!handler) {
    [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:nil];
    return;
  }
  // Grab reference to avoid retain on self.
  NSObject<FlutterMessageCodec>* codec = _codec;
  FlutterBinaryMessageHandler messageHandler = ^(NSData* message, FlutterBinaryReply callback) {
    handler([codec decode:message], ^(id reply) {
      callback([codec encode:reply]);
    });
  };
  [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:messageHandler];
}

- (void)resizeChannelBuffer:(NSInteger)newSize {
  ResizeChannelBuffer(_messenger, _name, newSize);
}

@end

#pragma mark - Method channel

@implementation FlutterError
+ (instancetype)errorWithCode:(NSString*)code message:(NSString*)message details:(id)details {
  return [[[FlutterError alloc] initWithCode:code message:message details:details] autorelease];
}

- (instancetype)initWithCode:(NSString*)code message:(NSString*)message details:(id)details {
  NSAssert(code, @"Code cannot be nil");
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _code = [code retain];
  _message = [message retain];
  _details = [details retain];
  return self;
}

- (void)dealloc {
  [_code release];
  [_message release];
  [_details release];
  [super dealloc];
}

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;
  if (![object isKindOfClass:[FlutterError class]])
    return NO;
  FlutterError* other = (FlutterError*)object;
  return [self.code isEqual:other.code] &&
         ((!self.message && !other.message) || [self.message isEqual:other.message]) &&
         ((!self.details && !other.details) || [self.details isEqual:other.details]);
}

- (NSUInteger)hash {
  return [self.code hash] ^ [self.message hash] ^ [self.details hash];
}
@end

@implementation FlutterMethodCall
+ (instancetype)methodCallWithMethodName:(NSString*)method arguments:(id)arguments {
  return [[[FlutterMethodCall alloc] initWithMethodName:method arguments:arguments] autorelease];
}

- (instancetype)initWithMethodName:(NSString*)method arguments:(id)arguments {
  NSAssert(method, @"Method name cannot be nil");
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _method = [method retain];
  _arguments = [arguments retain];
  return self;
}

- (void)dealloc {
  [_method release];
  [_arguments release];
  [super dealloc];
}

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;
  if (![object isKindOfClass:[FlutterMethodCall class]])
    return NO;
  FlutterMethodCall* other = (FlutterMethodCall*)object;
  return [self.method isEqual:[other method]] &&
         ((!self.arguments && !other.arguments) || [self.arguments isEqual:other.arguments]);
}

- (NSUInteger)hash {
  return [self.method hash] ^ [self.arguments hash];
}
@end

NSObject const* FlutterMethodNotImplemented = [NSObject new];

@implementation FlutterMethodChannel {
  NSObject<FlutterBinaryMessenger>* _messenger;
  NSString* _name;
  NSObject<FlutterMethodCodec>* _codec;
}

+ (instancetype)methodChannelWithName:(NSString*)name
                      binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  NSObject<FlutterMethodCodec>* codec = [FlutterStandardMethodCodec sharedInstance];
  return [FlutterMethodChannel methodChannelWithName:name binaryMessenger:messenger codec:codec];
}

+ (instancetype)methodChannelWithName:(NSString*)name
                      binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                                codec:(NSObject<FlutterMethodCodec>*)codec {
  return [[[FlutterMethodChannel alloc] initWithName:name binaryMessenger:messenger
                                               codec:codec] autorelease];
}

- (instancetype)initWithName:(NSString*)name
             binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                       codec:(NSObject<FlutterMethodCodec>*)codec {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _name = [name retain];
  _messenger = [messenger retain];
  _codec = [codec retain];
  return self;
}

- (void)dealloc {
  [_name release];
  [_messenger release];
  [_codec release];
  [super dealloc];
}

- (void)invokeMethod:(NSString*)method arguments:(id)arguments {
  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:method
                                                                    arguments:arguments];
  NSData* message = [_codec encodeMethodCall:methodCall];
  [_messenger sendOnChannel:_name message:message];
}

- (void)invokeMethod:(NSString*)method arguments:(id)arguments result:(FlutterResult)callback {
  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:method
                                                                    arguments:arguments];
  NSData* message = [_codec encodeMethodCall:methodCall];
  FlutterBinaryReply reply = ^(NSData* data) {
    if (callback) {
      callback((data == nil) ? FlutterMethodNotImplemented : [_codec decodeEnvelope:data]);
    }
  };
  [_messenger sendOnChannel:_name message:message binaryReply:reply];
}

- (void)setMethodCallHandler:(FlutterMethodCallHandler)handler {
  if (!handler) {
    [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:nil];
    return;
  }
  // Make sure the block captures the codec, not self.
  NSObject<FlutterMethodCodec>* codec = _codec;
  FlutterBinaryMessageHandler messageHandler = ^(NSData* message, FlutterBinaryReply callback) {
    FlutterMethodCall* call = [codec decodeMethodCall:message];
    handler(call, ^(id result) {
      if (result == FlutterMethodNotImplemented)
        callback(nil);
      else if ([result isKindOfClass:[FlutterError class]])
        callback([codec encodeErrorEnvelope:(FlutterError*)result]);
      else
        callback([codec encodeSuccessEnvelope:result]);
    });
  };
  [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:messageHandler];
}

- (void)resizeChannelBuffer:(NSInteger)newSize {
  ResizeChannelBuffer(_messenger, _name, newSize);
}

@end

#pragma mark - Event channel

NSObject const* FlutterEndOfEventStream = [NSObject new];

@implementation FlutterEventChannel {
  NSObject<FlutterBinaryMessenger>* _messenger;
  NSString* _name;
  NSObject<FlutterMethodCodec>* _codec;
}
+ (instancetype)eventChannelWithName:(NSString*)name
                     binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  NSObject<FlutterMethodCodec>* codec = [FlutterStandardMethodCodec sharedInstance];
  return [FlutterEventChannel eventChannelWithName:name binaryMessenger:messenger codec:codec];
}

+ (instancetype)eventChannelWithName:(NSString*)name
                     binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                               codec:(NSObject<FlutterMethodCodec>*)codec {
  return [[[FlutterEventChannel alloc] initWithName:name binaryMessenger:messenger
                                              codec:codec] autorelease];
}

- (instancetype)initWithName:(NSString*)name
             binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                       codec:(NSObject<FlutterMethodCodec>*)codec {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _name = [name retain];
  _messenger = [messenger retain];
  _codec = [codec retain];
  return self;
}

- (void)dealloc {
  [_name release];
  [_codec release];
  [_messenger release];
  [super dealloc];
}

static void SetStreamHandlerMessageHandlerOnChannel(NSObject<FlutterStreamHandler>* handler,
                                                    NSString* name,
                                                    NSObject<FlutterBinaryMessenger>* messenger,
                                                    NSObject<FlutterMethodCodec>* codec) {
  __block FlutterEventSink currentSink = nil;
  FlutterBinaryMessageHandler messageHandler = ^(NSData* message, FlutterBinaryReply callback) {
    FlutterMethodCall* call = [codec decodeMethodCall:message];
    if ([call.method isEqual:@"listen"]) {
      if (currentSink) {
        FlutterError* error = [handler onCancelWithArguments:nil];
        if (error)
          NSLog(@"Failed to cancel existing stream: %@. %@ (%@)", error.code, error.message,
                error.details);
      }
      currentSink = ^(id event) {
        if (event == FlutterEndOfEventStream)
          [messenger sendOnChannel:name message:nil];
        else if ([event isKindOfClass:[FlutterError class]])
          [messenger sendOnChannel:name message:[codec encodeErrorEnvelope:(FlutterError*)event]];
        else
          [messenger sendOnChannel:name message:[codec encodeSuccessEnvelope:event]];
      };
      FlutterError* error = [handler onListenWithArguments:call.arguments eventSink:currentSink];
      if (error)
        callback([codec encodeErrorEnvelope:error]);
      else
        callback([codec encodeSuccessEnvelope:nil]);
    } else if ([call.method isEqual:@"cancel"]) {
      if (!currentSink) {
        callback(
            [codec encodeErrorEnvelope:[FlutterError errorWithCode:@"error"
                                                           message:@"No active stream to cancel"
                                                           details:nil]]);
        return;
      }
      currentSink = nil;
      FlutterError* error = [handler onCancelWithArguments:call.arguments];
      if (error)
        callback([codec encodeErrorEnvelope:error]);
      else
        callback([codec encodeSuccessEnvelope:nil]);
    } else {
      callback(nil);
    }
  };
  [messenger setMessageHandlerOnChannel:name binaryMessageHandler:messageHandler];
}

- (void)setStreamHandler:(NSObject<FlutterStreamHandler>*)handler {
  if (!handler) {
    [_messenger setMessageHandlerOnChannel:_name binaryMessageHandler:nil];
    return;
  }
  SetStreamHandlerMessageHandlerOnChannel(handler, _name, _messenger, _codec);
}
@end
