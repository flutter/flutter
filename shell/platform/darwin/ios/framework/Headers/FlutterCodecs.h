// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERCODECS_H_
#define FLUTTER_FLUTTERCODECS_H_

#import <Foundation/Foundation.h>
#include "FlutterMacros.h"

FLUTTER_EXPORT
@protocol FlutterMessageCodec
+ (instancetype)sharedInstance;
- (NSData*)encode:(id)message;
- (id)decode:(NSData*)message;
@end

FLUTTER_EXPORT
@interface FlutterBinaryCodec : NSObject<FlutterMessageCodec>
@end

FLUTTER_EXPORT
@interface FlutterStringCodec : NSObject<FlutterMessageCodec>
@end

FLUTTER_EXPORT
@interface FlutterJSONMessageCodec : NSObject<FlutterMessageCodec>
@end

FLUTTER_EXPORT
@interface FlutterStandardMessageCodec : NSObject<FlutterMessageCodec>
@end

FLUTTER_EXPORT
@interface FlutterMethodCall : NSObject
+ (instancetype)methodCallWithMethodName:(NSString*)method
                               arguments:(id)arguments;
@property(readonly) NSString* method;
@property(readonly) id arguments;
@end

FLUTTER_EXPORT
@interface FlutterError : NSObject
+ (instancetype)errorWithCode:(NSString*)code
                      message:(NSString*)message
                      details:(id)details;
@property(readonly) NSString* code;
@property(readonly) NSString* message;
@property(readonly) id details;
@end

typedef NS_ENUM(NSInteger, FlutterStandardDataType) {
  FlutterStandardDataTypeUInt8,
  FlutterStandardDataTypeInt32,
  FlutterStandardDataTypeInt64,
  FlutterStandardDataTypeFloat64,
};

FLUTTER_EXPORT
@interface FlutterStandardTypedData : NSObject
+ (instancetype)typedDataWithBytes:(NSData*)data;
+ (instancetype)typedDataWithInt32:(NSData*)data;
+ (instancetype)typedDataWithInt64:(NSData*)data;
+ (instancetype)typedDataWithFloat64:(NSData*)data;
@property(readonly) NSData* data;
@property(readonly) FlutterStandardDataType type;
@property(readonly) UInt32 elementCount;
@property(readonly) UInt8 elementSize;
@end

FLUTTER_EXPORT
@interface FlutterStandardBigInteger : NSObject
+ (instancetype)bigIntegerWithHex:(NSString*)hex;
@property(readonly) NSString* hex;
@end

FLUTTER_EXPORT
@protocol FlutterMethodCodec
+ (instancetype)sharedInstance;
- (FlutterMethodCall*)decodeMethodCall:(NSData*)message;
- (NSData*)encodeSuccessEnvelope:(id)result;
- (NSData*)encodeErrorEnvelope:(FlutterError*)error;
@end

FLUTTER_EXPORT
@interface FlutterJSONMethodCodec : NSObject<FlutterMethodCodec>
@end

FLUTTER_EXPORT
@interface FlutterStandardMethodCodec : NSObject<FlutterMethodCodec>
@end

#endif  // FLUTTER_FLUTTERCODECS_H_
