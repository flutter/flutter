// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERCODECS_H_
#define FLUTTER_FLUTTERCODECS_H_

#import <Foundation/Foundation.h>
#include "FlutterMacros.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A message encoding/decoding mechanism.
 */
FLUTTER_EXPORT
@protocol FlutterMessageCodec
/**
 Returns a shared instance of this `FlutterMessageCodec`.
 */
+ (instancetype)sharedInstance;

/**
 Encodes the specified message into binary.

 - Parameter message: The message.
 - Returns: The binary encoding, or `nil`, if `message` was `nil`.
 */
- (NSData* _Nullable)encode:(id _Nullable)message;

/**
 Decodes the specified message from binary.

 - Parameter message: The message.
 - Returns: The decoded message, or `nil`, if `message` was `nil`.
 */
- (id _Nullable)decode:(NSData* _Nullable)message;
@end

/**
 A `FlutterMessageCodec` using unencoded binary messages, represented as
 `NSData` instances.

 This codec is guaranteed to be compatible with the corresponding
 [BinaryCodec](https://docs.flutter.io/flutter/services/BinaryCodec-class.html)
 on the Dart side. These parts of the Flutter SDK are evolved synchronously.

 On the Dart side, messages are represented using `ByteData`.
 */
FLUTTER_EXPORT
@interface FlutterBinaryCodec : NSObject<FlutterMessageCodec>
@end

/**
 A `FlutterMessageCodec` using UTF-8 encoded `NSString` messages.

 This codec is guaranteed to be compatible with the corresponding
 [StringCodec](https://docs.flutter.io/flutter/services/StringCodec-class.html)
 on the Dart side. These parts of the Flutter SDK are evolved synchronously.
 */
FLUTTER_EXPORT
@interface FlutterStringCodec : NSObject<FlutterMessageCodec>
@end

/**
 A `FlutterMessageCodec` using UTF-8 encoded JSON messages.

 This codec is guaranteed to be compatible with the corresponding
 [JSONMessageCodec](https://docs.flutter.io/flutter/services/JSONMessageCodec-class.html)
 on the Dart side. These parts of the Flutter SDK are evolved synchronously.

 Supports values accepted by `NSJSONSerialization` plus top-level
 `nil`, `NSNumber`, and `NSString`.

 On the Dart side, JSON messages are handled by the JSON facilities of the
 [`dart:convert`](https://api.dartlang.org/stable/dart-convert/JSON-constant.html)
 package.
 */
FLUTTER_EXPORT
@interface FlutterJSONMessageCodec : NSObject<FlutterMessageCodec>
@end

/**
 A `FlutterMessageCodec` using the Flutter standard binary encoding.

 This codec is guaranteed to be compatible with the corresponding
 [StandardMessageCodec](https://docs.flutter.io/flutter/services/StandardMessageCodec-class.html)
 on the Dart side. These parts of the Flutter SDK are evolved synchronously.

 Supported messages are acyclic values of these forms:

 - `nil` or `NSNull`
 - `NSNumber` (including their representation of Boolean values)
 - `FlutterStandardBigInteger`
 - `NSString`
 - `FlutterStandardTypedData`
 - `NSArray` of supported values
 - `NSDictionary` with supported keys and values

 On the Dart side, these values are represented as follows:

 - `nil` or `NSNull`: `null`
 - `NSNumber`: `bool`, `int`, or `double`, depending on the contained value.
 - `FlutterStandardBigInteger`: `int`
 - `NSString`: `String`
 - `FlutterStandardTypedData`: `Uint8List`, `Int32List`, `Int64List`, or `Float64List`
 - `NSArray`: `List`
 - `NSDictionary`: `Map`
 */
FLUTTER_EXPORT
@interface FlutterStandardMessageCodec : NSObject<FlutterMessageCodec>
@end

/**
 Command object representing a method call on a `FlutterMethodChannel`.
 */
FLUTTER_EXPORT
@interface FlutterMethodCall : NSObject
/**
 Creates a method call for invoking the specified named method with the
 specified arguments.

 - Parameters:
   - method: the name of the method to call.
   - arguments: the arguments value.
 */
+ (instancetype)methodCallWithMethodName:(NSString*)method arguments:(id _Nullable)arguments;

/**
 The method name.
 */
@property(readonly, nonatomic) NSString* method;

/**
 The arguments.
 */
@property(readonly, nonatomic, nullable) id arguments;
@end

/**
 Error object representing an unsuccessful outcome of invoking a method
 on a `FlutterMethodChannel`, or an error event on a `FlutterEventChannel`.
 */
FLUTTER_EXPORT
@interface FlutterError : NSObject
/**
 Creates a `FlutterError` with the specified error code, message, and details.

 - Parameters:
   - code: An error code string for programmatic use.
   - message: A human-readable error message.
   - details: Custom error details.
 */
+ (instancetype)errorWithCode:(NSString*)code
                      message:(NSString* _Nullable)message
                      details:(id _Nullable)details;
/**
 The error code.
 */
@property(readonly, nonatomic) NSString* code;

/**
 The error message.
 */
@property(readonly, nonatomic, nullable) NSString* message;

/**
 The error details.
 */
@property(readonly, nonatomic, nullable) id details;
@end

/**
 Type of numeric data items encoded in a `FlutterStandardDataType`.

 - FlutterStandardDataTypeUInt8: plain bytes
 - FlutterStandardDataTypeInt32: 32-bit signed integers
 - FlutterStandardDataTypeInt64: 64-bit signed integers
 - FlutterStandardDataTypeFloat64: 64-bit floats
 */
typedef NS_ENUM(NSInteger, FlutterStandardDataType) {
  FlutterStandardDataTypeUInt8,
  FlutterStandardDataTypeInt32,
  FlutterStandardDataTypeInt64,
  FlutterStandardDataTypeFloat64,
};

/**
 A byte buffer holding `UInt8`, `SInt32`, `SInt64`, or `Float64` values, used
 with `FlutterStandardMessageCodec` and `FlutterStandardMethodCodec`.

 Two's complement encoding is used for signed integers. IEEE754
 double-precision representation is used for floats. The platform's native
 endianness is assumed.
 */
FLUTTER_EXPORT
@interface FlutterStandardTypedData : NSObject
/**
 Creates a `FlutterStandardTypedData` which interprets the specified data
 as plain bytes.

 - Parameter data: the byte data.
 */
+ (instancetype)typedDataWithBytes:(NSData*)data;

/**
 Creates a `FlutterStandardTypedData` which interprets the specified data
 as 32-bit signed integers.

 - Parameter data: the byte data. The length must be divisible by 4.
 */
+ (instancetype)typedDataWithInt32:(NSData*)data;

/**
 Creates a `FlutterStandardTypedData` which interprets the specified data
 as 64-bit signed integers.

 - Parameter data: the byte data. The length must be divisible by 8.
 */
+ (instancetype)typedDataWithInt64:(NSData*)data;

/**
 Creates a `FlutterStandardTypedData` which interprets the specified data
 as 64-bit floats.

 - Parameter data: the byte data. The length must be divisible by 8.
 */
+ (instancetype)typedDataWithFloat64:(NSData*)data;

/**
 The raw underlying data buffer.
 */
@property(readonly, nonatomic) NSData* data;

/**
 The type of the encoded values.
 */
@property(readonly, nonatomic) FlutterStandardDataType type;

/**
 The number of value items encoded.
 */
@property(readonly, nonatomic) UInt32 elementCount;

/**
 The number of bytes used by the encoding of a single value item.
 */
@property(readonly, nonatomic) UInt8 elementSize;
@end

/**
 An arbitrarily large integer value, used with `FlutterStandardMessageCodec`
 and `FlutterStandardMethodCodec`.
 */
FLUTTER_EXPORT
@interface FlutterStandardBigInteger : NSObject
/**
 Creates a `FlutterStandardBigInteger` from a hexadecimal representation.

 - Parameter hex: a hexadecimal string.
 */
+ (instancetype)bigIntegerWithHex:(NSString*)hex;

/**
 The hexadecimal string representation of this integer.
 */
@property(readonly, nonatomic) NSString* hex;
@end

/**
 A codec for method calls and enveloped results.

 Method calls are encoded as binary messages with enough structure that the
 codec can extract a method name `NSString` and an arguments `NSObject`,
 possibly `nil`. These data items are used to populate a `FlutterMethodCall`.

 Result envelopes are encoded as binary messages with enough structure that
 the codec can determine whether the result was successful or an error. In
 the former case, the codec can extract the result `NSObject`, possibly `nil`.
 In the latter case, the codec can extract an error code `NSString`, a
 human-readable `NSString` error message (possibly `nil`), and a custom
 error details `NSObject`, possibly `nil`. These data items are used to
 populate a `FlutterError`.
 */
FLUTTER_EXPORT
@protocol FlutterMethodCodec
/**
 Provides access to a shared instance this codec.

 - Returns: The shared instance.
 */
+ (instancetype)sharedInstance;

/**
 Encodes the specified method call into binary.

 - Parameter methodCall: The method call. The arguments value
   must be supported by this codec.
 - Returns: The binary encoding.
 */
- (NSData*)encodeMethodCall:(FlutterMethodCall*)methodCall;

/**
 Decodes the specified method call from binary.

 - Parameter methodCall: The method call to decode.
 - Returns: The decoded method call.
 */
- (FlutterMethodCall*)decodeMethodCall:(NSData*)methodCall;

/**
 Encodes the specified successful result into binary.

 - Parameter result: The result. Must be a value supported by this codec.
 - Returns: The binary encoding.
 */
- (NSData*)encodeSuccessEnvelope:(id _Nullable)result;

/**
 Encodes the specified error result into binary.

 - Parameter error: The error object. The error details value must be supported
   by this codec.
 - Returns: The binary encoding.
 */
- (NSData*)encodeErrorEnvelope:(FlutterError*)error;

/**
 Deccodes the specified result envelope from binary.

 - Parameter error: The error object.
 - Returns: The result value, if the envelope represented a successful result,
   or a `FlutterError` instance, if not.
 */
- (id _Nullable)decodeEnvelope:(NSData*)envelope;
@end

/**
 A `FlutterMethodCodec` using UTF-8 encoded JSON method calls and result
 envelopes.

 This codec is guaranteed to be compatible with the corresponding
 [JSONMethodCodec](https://docs.flutter.io/flutter/services/JSONMethodCodec-class.html)
 on the Dart side. These parts of the Flutter SDK are evolved synchronously.

 Values supported as methods arguments and result payloads are
 those supported as top-level or leaf values by `FlutterJSONMessageCodec`.
 */
FLUTTER_EXPORT
@interface FlutterJSONMethodCodec : NSObject<FlutterMethodCodec>
@end

/**
 A `FlutterMethodCodec` using the Flutter standard binary encoding.

 This codec is guaranteed to be compatible with the corresponding
 [StandardMethodCodec](https://docs.flutter.io/flutter/services/StandardMethodCodec-class.html)
 on the Dart side. These parts of the Flutter SDK are evolved synchronously.

 Values supported as method arguments and result payloads are those supported by
 `FlutterStandardMessageCodec`.
 */
FLUTTER_EXPORT
@interface FlutterStandardMethodCodec : NSObject<FlutterMethodCodec>
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_FLUTTERCODECS_H_
