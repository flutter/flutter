// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCodecs.h"

@implementation FlutterBinaryCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [FlutterBinaryCodec new];
  }
  return _sharedInstance;
}

- (NSData*)encode:(NSData*)message {
  return message;
}

- (NSData*)decode:(NSData*)message {
  return message;
}
@end

@implementation FlutterStringCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [FlutterStringCodec new];
  }
  return _sharedInstance;
}

- (NSData*)encode:(NSString*)message {
  if (!message.length) {
    return [NSData data];
  }
  const char* utf8 = message.UTF8String;
  return [NSData dataWithBytes:utf8 length:strlen(utf8)];
}

- (NSString*)decode:(NSData*)message {
  return [[[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding]
      autorelease];
}
@end

@implementation FlutterJSONMessageCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [FlutterJSONMessageCodec new];
  }
  return _sharedInstance;
}

- (NSData*)encode:(id)message {
  NSData* encoding =
      [NSJSONSerialization dataWithJSONObject:message options:0 error:nil];
  NSAssert(encoding, @"Invalid JSON message, encoding failed");
  return encoding;
}

- (id)decode:(NSData*)message {
  id decoded =
      [NSJSONSerialization JSONObjectWithData:message options:0 error:nil];
  NSAssert(decoded, @"Invalid JSON message, decoding failed");
  return decoded;
}
@end

@implementation FlutterJSONMethodCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [FlutterJSONMethodCodec new];
  }
  return _sharedInstance;
}

- (NSData*)encodeSuccessEnvelope:(id)result {
  return [[FlutterJSONMessageCodec sharedInstance] encode:@[ result ]];
}

- (NSData*)encodeErrorEnvelope:(FlutterError*)error {
  return [[FlutterJSONMessageCodec sharedInstance]
      encode:@[ error.code, error.message, error.details ]];
}

- (FlutterMethodCall*)decodeMethodCall:(NSData*)message {
  NSArray* call = [[FlutterJSONMessageCodec sharedInstance] decode:message];
  NSAssert(call.count == 2, @"Invalid JSON method call");
  NSAssert([call[0] isKindOfClass:[NSString class]],
           @"Invalid JSON method call");
  return [FlutterMethodCall methodCallWithMethodName:call[0] arguments:call[1]];
}
@end
