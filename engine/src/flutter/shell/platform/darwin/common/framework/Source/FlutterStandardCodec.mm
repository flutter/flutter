// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Source/FlutterStandardCodec_Internal.h"

#pragma mark - Codec for basic message channel

static const UInt8 kZeroBuffer[8] = {0, 0, 0, 0, 0, 0, 0, 0};
// Classes are cached in static variables to avoid the extra method calls in a
// highly traffic'd recursive function.
static const Class kNSNumberClass = [NSNumber class];
static const id kNSNull = [NSNull null];
static const Class kNSStringClass = [NSString class];
static const Class kNSDataClass = [NSData class];
static const Class kNSArrayClass = [NSArray class];
static const Class kNSDictionaryClass = [NSDictionary class];
static const Class kFlutterStandardTypedDataClass = [FlutterStandardTypedData class];

@implementation FlutterStandardMessageCodec {
  FlutterStandardReaderWriter* _readerWriter;
}
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    FlutterStandardReaderWriter* readerWriter =
        [[[FlutterStandardReaderWriter alloc] init] autorelease];
    _sharedInstance = [[FlutterStandardMessageCodec alloc] initWithReaderWriter:readerWriter];
  }
  return _sharedInstance;
}

+ (instancetype)codecWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  return [[[FlutterStandardMessageCodec alloc] initWithReaderWriter:readerWriter] autorelease];
}

- (instancetype)initWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _readerWriter = [readerWriter retain];
  return self;
}

- (void)dealloc {
  [_readerWriter release];
  [super dealloc];
}

- (NSData*)encode:(id)message {
  if (message == nil)
    return nil;
  NSMutableData* data = [NSMutableData dataWithCapacity:32];
  FlutterStandardWriter* writer = [_readerWriter writerWithData:data];
  [writer writeValue:message];
  return data;
}

- (id)decode:(NSData*)message {
  if ([message length] == 0)
    return nil;
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
    FlutterStandardReaderWriter* readerWriter =
        [[[FlutterStandardReaderWriter alloc] init] autorelease];
    _sharedInstance = [[FlutterStandardMethodCodec alloc] initWithReaderWriter:readerWriter];
  }
  return _sharedInstance;
}

+ (instancetype)codecWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  return [[[FlutterStandardMethodCodec alloc] initWithReaderWriter:readerWriter] autorelease];
}

- (instancetype)initWithReaderWriter:(FlutterStandardReaderWriter*)readerWriter {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _readerWriter = [readerWriter retain];
  return self;
}

- (void)dealloc {
  [_readerWriter release];
  [super dealloc];
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

+ (instancetype)typedDataWithFloat64:(NSData*)data {
  return [FlutterStandardTypedData typedDataWithData:data type:FlutterStandardDataTypeFloat64];
}

+ (instancetype)typedDataWithData:(NSData*)data type:(FlutterStandardDataType)type {
  return [[[FlutterStandardTypedData alloc] initWithData:data type:type] autorelease];
}

- (instancetype)initWithData:(NSData*)data type:(FlutterStandardDataType)type {
  UInt8 elementSize = elementSizeForFlutterStandardDataType(type);
  NSAssert(data, @"Data cannot be nil");
  NSAssert(data.length % elementSize == 0, @"Data must contain integral number of elements");
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _data = [data retain];
  _type = type;
  _elementSize = elementSize;
  _elementCount = data.length / elementSize;
  return self;
}

- (void)dealloc {
  [_data release];
  [super dealloc];
}

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;
  if (![object isKindOfClass:[FlutterStandardTypedData class]])
    return NO;
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
  _data = [data retain];
  return self;
}

- (void)dealloc {
  [_data release];
  [super dealloc];
}

static void WriteByte(CFMutableDataRef data, UInt8 value) {
  CFDataAppendBytes(data, &value, 1);
}

static void WriteBytes(CFMutableDataRef data, const void* bytes, NSUInteger length) {
  CFDataAppendBytes(data, (const UInt8*)bytes, length);
}

static void WriteData(CFMutableDataRef destination, NSData* source) {
  CFDataAppendBytes(destination, (const UInt8*)source.bytes, source.length);
}

static void WriteSize(CFMutableDataRef data, UInt32 size) {
  if (size < 254) {
    WriteByte(data, (UInt8)size);
  } else if (size <= 0xffff) {
    WriteByte(data, 254);
    UInt16 value = (UInt16)size;
    WriteBytes(data, &value, 2);
  } else {
    WriteByte(data, 255);
    WriteBytes(data, &size, 4);
  }
}

static void WriteAlignment(CFMutableDataRef data, UInt8 alignment) {
  NSCAssert(alignment <= 8, @"Alignment larger than kZeroBuffer.");
  UInt8 mod = CFDataGetLength(data) % alignment;
  if (mod) {
    WriteBytes(data, kZeroBuffer, alignment - mod);
  }
}

static void WriteUTF8(CFMutableDataRef data, NSString* value) {
  UInt32 length = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  WriteSize(data, length);
  WriteBytes(data, value.UTF8String, length);
}

static void WriteValue(CFMutableDataRef data, id value) {
  if (value == nil || value == kNSNull) {
    WriteByte(data, FlutterStandardFieldNil);
  } else if ([value isKindOfClass:kNSNumberClass]) {
    CFNumberRef number = (CFNumberRef)value;
    BOOL success = NO;
    if (CFGetTypeID(number) == CFBooleanGetTypeID()) {
      BOOL b = CFBooleanGetValue((CFBooleanRef)number);
      WriteByte(data, (b ? FlutterStandardFieldTrue : FlutterStandardFieldFalse));
      success = YES;
    } else if (CFNumberIsFloatType(number)) {
      Float64 f;
      success = CFNumberGetValue(number, kCFNumberFloat64Type, &f);
      if (success) {
        WriteByte(data, FlutterStandardFieldFloat64);
        WriteAlignment(data, 8);
        WriteBytes(data, (UInt8*)&f, 8);
      }
    } else if (CFNumberGetByteSize(number) <= 4) {
      SInt32 n;
      success = CFNumberGetValue(number, kCFNumberSInt32Type, &n);
      if (success) {
        WriteByte(data, FlutterStandardFieldInt32);
        WriteBytes(data, (UInt8*)&n, 4);
      }
    } else if (CFNumberGetByteSize(number) <= 8) {
      SInt64 n;
      success = CFNumberGetValue(number, kCFNumberSInt64Type, &n);
      if (success) {
        WriteByte(data, FlutterStandardFieldInt64);
        WriteBytes(data, (UInt8*)&n, 8);
      }
    }
    if (!success) {
      NSLog(@"Unsupported value: %@ of number type %ld", value, CFNumberGetType(number));
      NSCAssert(NO, @"Unsupported value for standard codec.");
    }
  } else if ([value isKindOfClass:kNSStringClass]) {
    NSString* string = value;
    WriteByte(data, FlutterStandardFieldString);
    WriteUTF8(data, string);
  } else if ([value isKindOfClass:kFlutterStandardTypedDataClass]) {
    FlutterStandardTypedData* typedData = value;
    WriteByte(data, FlutterStandardFieldForDataType(typedData.type));
    WriteSize(data, typedData.elementCount);
    WriteAlignment(data, typedData.elementSize);
    WriteData(data, typedData.data);
  } else if ([value isKindOfClass:kNSDataClass]) {
    WriteValue(data, [FlutterStandardTypedData typedDataWithBytes:value]);
  } else if ([value isKindOfClass:kNSArrayClass]) {
    NSArray* array = value;
    WriteByte(data, FlutterStandardFieldList);
    WriteSize(data, array.count);
    for (id object in array) {
      WriteValue(data, object);
    }
  } else if ([value isKindOfClass:kNSDictionaryClass]) {
    NSDictionary* dict = value;
    WriteByte(data, FlutterStandardFieldMap);
    WriteSize(data, dict.count);
    for (id key in dict) {
      WriteValue(data, key);
      WriteValue(data, [dict objectForKey:key]);
    }
  } else {
    NSLog(@"Unsupported value: %@ of type %@", value, [value class]);
    NSCAssert(NO, @"Unsupported value for standard codec.");
  }
}

- (void)writeByte:(UInt8)value {
  WriteByte((__bridge CFMutableDataRef)_data, value);
}

- (void)writeBytes:(const void*)bytes length:(NSUInteger)length {
  WriteBytes((__bridge CFMutableDataRef)_data, bytes, length);
}

- (void)writeData:(NSData*)data {
  WriteData((__bridge CFMutableDataRef)_data, data);
}

- (void)writeSize:(UInt32)size {
  WriteSize((__bridge CFMutableDataRef)_data, size);
}

- (void)writeAlignment:(UInt8)alignment {
  WriteAlignment((__bridge CFMutableDataRef)_data, alignment);
}

- (void)writeUTF8:(NSString*)value {
  WriteUTF8((__bridge CFMutableDataRef)_data, value);
}

- (void)writeValue:(id)value {
  WriteValue((__bridge CFMutableDataRef)_data, value);
}
@end

@implementation FlutterStandardReader {
  NSData* _data;
  NSRange _range;
}

- (instancetype)initWithData:(NSData*)data {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _data = [data retain];
  _range = NSMakeRange(0, 0);
  return self;
}

- (void)dealloc {
  [_data release];
  [super dealloc];
}

- (BOOL)hasMore {
  return _range.location < _data.length;
}

- (void)readBytes:(void*)destination length:(NSUInteger)length {
  _range.length = length;
  [_data getBytes:destination range:_range];
  _range.location += _range.length;
}

- (UInt8)readByte {
  UInt8 value;
  [self readBytes:&value length:1];
  return value;
}

- (UInt32)readSize {
  UInt8 byte = [self readByte];
  if (byte < 254) {
    return (UInt32)byte;
  } else if (byte == 254) {
    UInt16 value;
    [self readBytes:&value length:2];
    return value;
  } else {
    UInt32 value;
    [self readBytes:&value length:4];
    return value;
  }
}

- (NSData*)readData:(NSUInteger)length {
  _range.length = length;
  NSData* data = [_data subdataWithRange:_range];
  _range.location += _range.length;
  return data;
}

- (NSString*)readUTF8 {
  NSData* bytes = [self readData:[self readSize]];
  return [[[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding] autorelease];
}

- (void)readAlignment:(UInt8)alignment {
  UInt8 mod = _range.location % alignment;
  if (mod) {
    _range.location += (alignment - mod);
  }
}

- (FlutterStandardTypedData*)readTypedDataOfType:(FlutterStandardDataType)type {
  UInt32 elementCount = [self readSize];
  UInt8 elementSize = elementSizeForFlutterStandardDataType(type);
  [self readAlignment:elementSize];
  NSData* data = [self readData:elementCount * elementSize];
  return [FlutterStandardTypedData typedDataWithData:data type:type];
}

- (nullable id)readValue {
  return [self readValueOfType:[self readByte]];
}

- (nullable id)readValueOfType:(UInt8)type {
  FlutterStandardField field = (FlutterStandardField)type;
  switch (field) {
    case FlutterStandardFieldNil:
      return nil;
    case FlutterStandardFieldTrue:
      return @YES;
    case FlutterStandardFieldFalse:
      return @NO;
    case FlutterStandardFieldInt32: {
      SInt32 value;
      [self readBytes:&value length:4];
      return @(value);
    }
    case FlutterStandardFieldInt64: {
      SInt64 value;
      [self readBytes:&value length:8];
      return @(value);
    }
    case FlutterStandardFieldFloat64: {
      Float64 value;
      [self readAlignment:8];
      [self readBytes:&value length:8];
      return [NSNumber numberWithDouble:value];
    }
    case FlutterStandardFieldIntHex:
    case FlutterStandardFieldString:
      return [self readUTF8];
    case FlutterStandardFieldUInt8Data:
    case FlutterStandardFieldInt32Data:
    case FlutterStandardFieldInt64Data:
    case FlutterStandardFieldFloat64Data:
      return [self readTypedDataOfType:FlutterStandardDataTypeForField(field)];
    case FlutterStandardFieldList: {
      UInt32 length = [self readSize];
      NSMutableArray* array = [NSMutableArray arrayWithCapacity:length];
      for (UInt32 i = 0; i < length; i++) {
        id value = [self readValue];
        [array addObject:(value == nil ? kNSNull : value)];
      }
      return array;
    }
    case FlutterStandardFieldMap: {
      UInt32 size = [self readSize];
      NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:size];
      for (UInt32 i = 0; i < size; i++) {
        id key = [self readValue];
        id val = [self readValue];
        [dict setObject:(val == nil ? kNSNull : val) forKey:(key == nil ? kNSNull : key)];
      }
      return dict;
    }
    default:
      NSAssert(NO, @"Corrupted standard message");
  }
}
@end

@implementation FlutterStandardReaderWriter
- (FlutterStandardWriter*)writerWithData:(NSMutableData*)data {
  return [[[FlutterStandardWriter alloc] initWithData:data] autorelease];
}

- (FlutterStandardReader*)readerWithData:(NSData*)data {
  return [[[FlutterStandardReader alloc] initWithData:data] autorelease];
}
@end
