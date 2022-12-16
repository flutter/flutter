// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Source/FlutterStandardCodecHelper.h"
#import "flutter/shell/platform/darwin/common/framework/Source/FlutterStandardCodec_Internal.h"

FLUTTER_ASSERT_ARC

#pragma mark - Codec for basic message channel

@implementation FlutterStandardMessageCodec {
  FlutterStandardReaderWriter* _readerWriter;
}
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    FlutterStandardReaderWriter* readerWriter = [[FlutterStandardReaderWriter alloc] init];
    _sharedInstance = [[FlutterStandardMessageCodec alloc] initWithReaderWriter:readerWriter];
  }
  return _sharedInstance;
}

+ (instancetype)codecWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  return [[FlutterStandardMessageCodec alloc] initWithReaderWriter:readerWriter];
}

- (instancetype)initWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _readerWriter = readerWriter;
  return self;
}

- (NSData*)encode:(id)message {
  if (message == nil) {
    return nil;
  }
  NSMutableData* data = [NSMutableData dataWithCapacity:32];
  FlutterStandardWriter* writer = [_readerWriter writerWithData:data];
  [writer writeValue:message];
  return data;
}

- (id)decode:(NSData*)message {
  if ([message length] == 0) {
    return nil;
  }
  FlutterStandardReader* reader = [_readerWriter readerWithData:message];
  id value = [reader readValue];
  NSAssert(![reader hasMore], @"Corrupted standard message");
  return value;
}
@end

#pragma mark - Codec for method channel

@implementation FlutterStandardMethodCodec {
  FlutterStandardReaderWriter* _readerWriter;
}
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    FlutterStandardReaderWriter* readerWriter = [[FlutterStandardReaderWriter alloc] init];
    _sharedInstance = [[FlutterStandardMethodCodec alloc] initWithReaderWriter:readerWriter];
  }
  return _sharedInstance;
}

+ (instancetype)codecWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  return [[FlutterStandardMethodCodec alloc] initWithReaderWriter:readerWriter];
}

- (instancetype)initWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _readerWriter = readerWriter;
  return self;
}

- (NSData*)encodeMethodCall:(FlutterMethodCall*)call {
  NSMutableData* data = [NSMutableData dataWithCapacity:32];
  FlutterStandardWriter* writer = [_readerWriter writerWithData:data];
  [writer writeValue:call.method];
  [writer writeValue:call.arguments];
  return data;
}

- (NSData*)encodeSuccessEnvelope:(id)result {
  NSMutableData* data = [NSMutableData dataWithCapacity:32];
  FlutterStandardWriter* writer = [_readerWriter writerWithData:data];
  [writer writeByte:0];
  [writer writeValue:result];
  return data;
}

- (NSData*)encodeErrorEnvelope:(FlutterError*)error {
  NSMutableData* data = [NSMutableData dataWithCapacity:32];
  FlutterStandardWriter* writer = [_readerWriter writerWithData:data];
  [writer writeByte:1];
  [writer writeValue:error.code];
  [writer writeValue:error.message];
  [writer writeValue:error.details];
  return data;
}

- (FlutterMethodCall*)decodeMethodCall:(NSData*)message {
  FlutterStandardReader* reader = [_readerWriter readerWithData:message];
  id value1 = [reader readValue];
  id value2 = [reader readValue];
  NSAssert(![reader hasMore], @"Corrupted standard method call");
  NSAssert([value1 isKindOfClass:[NSString class]], @"Corrupted standard method call");
  return [FlutterMethodCall methodCallWithMethodName:value1 arguments:value2];
}

- (id)decodeEnvelope:(NSData*)envelope {
  FlutterStandardReader* reader = [_readerWriter readerWithData:envelope];
  UInt8 flag = [reader readByte];
  NSAssert(flag <= 1, @"Corrupted standard envelope");
  id result;
  switch (flag) {
    case 0: {
      result = [reader readValue];
      NSAssert(![reader hasMore], @"Corrupted standard envelope");
    } break;
    case 1: {
      id code = [reader readValue];
      id message = [reader readValue];
      id details = [reader readValue];
      NSAssert(![reader hasMore], @"Corrupted standard envelope");
      NSAssert([code isKindOfClass:[NSString class]], @"Invalid standard envelope");
      NSAssert(message == nil || [message isKindOfClass:[NSString class]],
               @"Invalid standard envelope");
      result = [FlutterError errorWithCode:code message:message details:details];
    } break;
  }
  return result;
}
@end

using namespace flutter;

#pragma mark - Standard serializable types

@implementation FlutterStandardTypedData
+ (instancetype)typedDataWithBytes:(NSData*)data {
  return [FlutterStandardTypedData typedDataWithData:data type:FlutterStandardDataTypeUInt8];
}

+ (instancetype)typedDataWithInt32:(NSData*)data {
  return [FlutterStandardTypedData typedDataWithData:data type:FlutterStandardDataTypeInt32];
}

+ (instancetype)typedDataWithInt64:(NSData*)data {
  return [FlutterStandardTypedData typedDataWithData:data type:FlutterStandardDataTypeInt64];
}

+ (instancetype)typedDataWithFloat32:(NSData*)data {
  return [FlutterStandardTypedData typedDataWithData:data type:FlutterStandardDataTypeFloat32];
}

+ (instancetype)typedDataWithFloat64:(NSData*)data {
  return [FlutterStandardTypedData typedDataWithData:data type:FlutterStandardDataTypeFloat64];
}

+ (instancetype)typedDataWithData:(NSData*)data type:(FlutterStandardDataType)type {
  return [[FlutterStandardTypedData alloc] initWithData:data type:type];
}

- (instancetype)initWithData:(NSData*)data type:(FlutterStandardDataType)type {
  UInt8 elementSize = elementSizeForFlutterStandardDataType(type);
  NSAssert(data, @"Data cannot be nil");
  NSAssert(data.length % elementSize == 0, @"Data must contain integral number of elements");
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _data = [data copy];
  _type = type;
  _elementSize = elementSize;
  _elementCount = data.length / elementSize;
  return self;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FlutterStandardTypedData class]]) {
    return NO;
  }
  FlutterStandardTypedData* other = (FlutterStandardTypedData*)object;
  return self.type == other.type && self.elementCount == other.elementCount &&
         [self.data isEqual:other.data];
}

- (NSUInteger)hash {
  return [self.data hash] ^ self.type;
}
@end

#pragma mark - Writer and reader of standard codec

@implementation FlutterStandardWriter {
  NSMutableData* _data;
}

- (instancetype)initWithData:(NSMutableData*)data {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _data = data;
  return self;
}

- (void)writeByte:(UInt8)value {
  [_data appendBytes:&value length:1];
}

- (void)writeBytes:(const void*)bytes length:(NSUInteger)length {
  [_data appendBytes:bytes length:length];
}

- (void)writeData:(NSData*)data {
  [_data appendData:data];
}

- (void)writeSize:(UInt32)size {
  if (size < 254) {
    [self writeByte:(UInt8)size];
  } else if (size <= 0xffff) {
    [self writeByte:254];
    UInt16 value = (UInt16)size;
    [self writeBytes:&value length:2];
  } else {
    [self writeByte:255];
    [self writeBytes:&size length:4];
  }
}

- (void)writeAlignment:(UInt8)alignment {
  UInt8 mod = _data.length % alignment;
  if (mod) {
    for (int i = 0; i < (alignment - mod); i++) {
      [self writeByte:0];
    }
  }
}

- (void)writeUTF8:(NSString*)value {
  UInt32 length = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  [self writeSize:length];
  [self writeBytes:value.UTF8String length:length];
}

- (void)writeValue:(id)value {
  if (value == nil || value == [NSNull null]) {
    [self writeByte:FlutterStandardFieldNil];
  } else if ([value isKindOfClass:[NSNumber class]]) {
    CFNumberRef number = (__bridge CFNumberRef)value;
    BOOL success = NO;
    if (CFGetTypeID(number) == CFBooleanGetTypeID()) {
      BOOL b = CFBooleanGetValue((CFBooleanRef)number);
      [self writeByte:(b ? FlutterStandardFieldTrue : FlutterStandardFieldFalse)];
      success = YES;
    } else if (CFNumberIsFloatType(number)) {
      Float64 f;
      success = CFNumberGetValue(number, kCFNumberFloat64Type, &f);
      if (success) {
        [self writeByte:FlutterStandardFieldFloat64];
        [self writeAlignment:8];
        [self writeBytes:(UInt8*)&f length:8];
      }
    } else if (CFNumberGetByteSize(number) <= 4) {
      SInt32 n;
      success = CFNumberGetValue(number, kCFNumberSInt32Type, &n);
      if (success) {
        [self writeByte:FlutterStandardFieldInt32];
        [self writeBytes:(UInt8*)&n length:4];
      }
    } else if (CFNumberGetByteSize(number) <= 8) {
      SInt64 n;
      success = CFNumberGetValue(number, kCFNumberSInt64Type, &n);
      if (success) {
        [self writeByte:FlutterStandardFieldInt64];
        [self writeBytes:(UInt8*)&n length:8];
      }
    }
    if (!success) {
      NSLog(@"Unsupported value: %@ of number type %ld", value, CFNumberGetType(number));
      NSAssert(NO, @"Unsupported value for standard codec");
    }
  } else if ([value isKindOfClass:[NSString class]]) {
    NSString* string = value;
    [self writeByte:FlutterStandardFieldString];
    [self writeUTF8:string];
  } else if ([value isKindOfClass:[FlutterStandardTypedData class]]) {
    FlutterStandardTypedData* typedData = value;
    [self writeByte:FlutterStandardFieldForDataType(typedData.type)];
    [self writeSize:typedData.elementCount];
    [self writeAlignment:typedData.elementSize];
    [self writeData:typedData.data];
  } else if ([value isKindOfClass:[NSData class]]) {
    [self writeValue:[FlutterStandardTypedData typedDataWithBytes:value]];
  } else if ([value isKindOfClass:[NSArray class]]) {
    NSArray* array = value;
    [self writeByte:FlutterStandardFieldList];
    [self writeSize:array.count];
    for (id object in array) {
      [self writeValue:object];
    }
  } else if ([value isKindOfClass:[NSDictionary class]]) {
    NSDictionary* dict = value;
    [self writeByte:FlutterStandardFieldMap];
    [self writeSize:dict.count];
    for (id key in dict) {
      [self writeValue:key];
      [self writeValue:[dict objectForKey:key]];
    }
  } else {
    NSLog(@"Unsupported value: %@ of type %@", value, [value class]);
    NSAssert(NO, @"Unsupported value for standard codec");
  }
}
@end

@implementation FlutterStandardReader {
  NSData* _data;
  NSRange _range;
}

- (instancetype)initWithData:(NSData*)data {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _data = [data copy];
  _range = NSMakeRange(0, 0);
  return self;
}

- (BOOL)hasMore {
  return _range.location < _data.length;
}

- (void)readBytes:(void*)destination length:(NSUInteger)length {
  FlutterStandardCodecHelperReadBytes(&_range.location, length, destination,
                                      (__bridge CFDataRef)_data);
}

- (UInt8)readByte {
  return FlutterStandardCodecHelperReadByte(&_range.location, (__bridge CFDataRef)_data);
}

- (UInt32)readSize {
  return FlutterStandardCodecHelperReadSize(&_range.location, (__bridge CFDataRef)_data);
}

- (NSData*)readData:(NSUInteger)length {
  _range.length = length;
  NSData* data = [_data subdataWithRange:_range];
  _range.location += _range.length;
  return data;
}

- (NSString*)readUTF8 {
  return (__bridge NSString*)FlutterStandardCodecHelperReadUTF8(&_range.location,
                                                                (__bridge CFDataRef)_data);
}

- (void)readAlignment:(UInt8)alignment {
  FlutterStandardCodecHelperReadAlignment(&_range.location, alignment);
}

- (nullable id)readValue {
  return (__bridge id)ReadValue((__bridge CFTypeRef)self);
}

static CFTypeRef ReadValue(CFTypeRef user_data) {
  FlutterStandardReader* reader = (__bridge FlutterStandardReader*)user_data;
  uint8_t type = FlutterStandardCodecHelperReadByte(&reader->_range.location,
                                                    (__bridge CFDataRef)reader->_data);
  return (__bridge CFTypeRef)[reader readValueOfType:type];
}

static CFTypeRef ReadTypedDataOfType(FlutterStandardField field, CFTypeRef user_data) {
  FlutterStandardReader* reader = (__bridge FlutterStandardReader*)user_data;
  unsigned long* location = &reader->_range.location;
  CFDataRef data = (__bridge CFDataRef)reader->_data;
  FlutterStandardDataType type = FlutterStandardDataTypeForField(field);

  UInt64 elementCount = FlutterStandardCodecHelperReadSize(location, data);
  UInt64 elementSize = elementSizeForFlutterStandardDataType(type);
  FlutterStandardCodecHelperReadAlignment(location, elementSize);
  UInt64 length = elementCount * elementSize;
  NSRange range = NSMakeRange(*location, length);
  // Note: subdataWithRange performs better than CFDataCreate and
  // CFDataCreateBytesNoCopy crashes.
  NSData* bytes = [(__bridge NSData*)data subdataWithRange:range];
  *location += length;
  return (__bridge CFTypeRef)[FlutterStandardTypedData typedDataWithData:bytes type:type];
}

- (nullable id)readValueOfType:(UInt8)type {
  return (__bridge id)FlutterStandardCodecHelperReadValueOfType(
      &_range.location, (__bridge CFDataRef)_data, type, ReadValue, ReadTypedDataOfType,
      (__bridge CFTypeRef)self);
}
@end

@implementation FlutterStandardReaderWriter
- (FlutterStandardWriter*)writerWithData:(NSMutableData*)data {
  return [[FlutterStandardWriter alloc] initWithData:data];
}

- (FlutterStandardReader*)readerWithData:(NSData*)data {
  return [[FlutterStandardReader alloc] initWithData:data];
}
@end
