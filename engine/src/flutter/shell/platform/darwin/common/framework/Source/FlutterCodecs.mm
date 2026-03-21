// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"

#include <cstring>
#include <malloc.h>

FLUTTER_ASSERT_ARC

@implementation FlutterBinaryCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [[FlutterBinaryCodec alloc] init];
  }
  return _sharedInstance;
}

- (NSData*)encode:(id)message {
  NSAssert(!message || [message isKindOfClass:[NSData class]], @"");
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
    _sharedInstance = [[FlutterStringCodec alloc] init];
  }
  return _sharedInstance;
}

- (NSData*)encode:(id)message {
  if (message == nil) {
    return nil;
  }
  NSAssert([message isKindOfClass:[NSString class]], @"");
  NSString* stringMessage = message;
  const char* utf8 = stringMessage.UTF8String;
  return [NSData dataWithBytes:utf8 length:strlen(utf8)];
}

- (NSString*)decode:(NSData*)message {
  if (message == nil) {
    return nil;
  }
  return [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
}
@end

// Sanitize a string for JSON serialization by removing unpaired UTF-16 surrogates.
//
// Root cause of the crash: on iOS, deleting an SMP character (e.g. 𝑹 U+1D479,
// stored as surrogate pair 0xD835/0xDC79) one code unit at a time leaves an
// orphaned surrogate in NSString. NSJSONSerialization rejects such strings with
// "failed to convert to UTF8" and returns nil, triggering the NSAssert crash.
//
// Fix: scan the UTF-16 code units directly and reconstruct the string with only
// valid BMP characters and valid surrogate pairs, dropping lone surrogates.
// This does NOT rely on dataUsingEncoding:, which may itself return nil or
// silently mis-encode orphaned surrogates on some iOS versions.
// Core sanitizer. Removes unpaired UTF-16 surrogates from |str| and returns
// the cleaned string.
//
// If |outDropBefore| is non-NULL it is set to a malloc'd array of
// (originalLength+1) elements where outDropBefore[i] equals the number of
// orphaned surrogates that were dropped at positions strictly less than i in
// the original string. Callers that need to remap cursor/selection indices
// must free() this array when done.
// If no surrogates were found *outDropBefore is set to NULL.
static NSString* sanitizeUTF8StringFull(NSString* str,
                                        NSUInteger** outDropBefore,
                                        NSUInteger* outOriginalLen) {
  if (!str) {
    if (outDropBefore) *outDropBefore = NULL;
    if (outOriginalLen) *outOriginalLen = 0;
    return str;
  }
  NSUInteger length = str.length;
  if (outOriginalLen) *outOriginalLen = length;

  // Fast path: if no code unit falls in the surrogate range, return immediately.
  BOOL hasSurrogate = NO;
  for (NSUInteger i = 0; i < length; i++) {
    unichar ch = [str characterAtIndex:i];
    if (ch >= 0xD800 && ch <= 0xDFFF) {
      hasSurrogate = YES;
      break;
    }
  }
  if (!hasSurrogate) {
    if (outDropBefore) *outDropBefore = NULL;
    return str;
  }

  // Allocate the drop-count array: dropBefore[i] = # orphans dropped before position i.
  NSUInteger* dropBefore = (NSUInteger*)calloc(length + 1, sizeof(NSUInteger));

  // Rebuild the string: keep valid surrogate pairs, drop lone surrogates.
  unichar* buf = (unichar*)malloc(length * sizeof(unichar));
  if (!buf) {
    free(dropBefore);
    if (outDropBefore) *outDropBefore = NULL;
    return @"";
  }
  NSUInteger out = 0;
  NSUInteger dropped = 0;
   for (NSUInteger i = 0; i < length; i++) {
    dropBefore[i] = dropped;
     unichar ch = [str characterAtIndex:i];
    if (ch >= 0xD800 && ch <= 0xDBFF) {          // high surrogate
      if (i + 1 < length) {
        unichar lo = [str characterAtIndex:i + 1];
        if (lo >= 0xDC00 && lo <= 0xDFFF) {       // valid pair — keep both
          buf[out++] = ch;
          buf[out++] = lo;
          i++;                            // skip lo in this iteration
          dropBefore[i] = dropped;        // record drop count for the lo position too
          continue;
        }
      }
      // Unpaired high surrogate — drop it.
      dropped++;
    } else if (ch >= 0xDC00 && ch <= 0xDFFF) {   // unpaired low surrogate — drop it
      dropped++;
    } else {
      buf[out++] = ch;
    }
   }
  dropBefore[length] = dropped;  // sentinel: total dropped

  NSString* result = [NSString stringWithCharacters:buf length:out];
  free(buf);

  if (outDropBefore) {
    *outDropBefore = dropBefore;
  } else {
    free(dropBefore);
  }
  return result ?: @"";
}

// Convenience wrapper — no position mapping needed.
static NSString* sanitizeUTF8String(NSString* str) {
  return sanitizeUTF8StringFull(str, NULL, NULL);
}

// Remap a cursor/selection index from the original (pre-sanitization) string
// to the sanitized string using the dropBefore table built by sanitizeUTF8StringFull.
// Indices < 0 (e.g. -1 = "no composition") are passed through unchanged.
static NSInteger remapTextIndex(NSInteger idx,
                                NSUInteger originalLen,
                                const NSUInteger* dropBefore,
                                NSUInteger sanitizedLen) {
  if (idx < 0) return idx;              // -1 means "not set"; leave it alone
  NSUInteger u = (NSUInteger)idx;
  if (u > originalLen) u = originalLen; // clamp to valid range before lookup
  NSUInteger mapped = u - dropBefore[u];
  if (mapped > sanitizedLen) mapped = sanitizedLen;
  return (NSInteger)mapped;
 }

// Keys in a Flutter text-editing-state dict that hold UTF-16 code-unit offsets
// into the "text" field. When surrogates are removed from "text" these offsets
// must be remapped so they still point to valid positions.
static NSArray<NSString*>* textEditingIndexKeys(void) {
  static NSArray<NSString*>* keys = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    keys = @[@"selectionBase", @"selectionExtent", @"composingBase", @"composingExtent"];
  });
  return keys;
}

// Recursively sanitize all strings (including dictionary keys) in a
// JSON-compatible object tree so NSJSONSerialization never encounters an
// unpaired surrogate.
//
// Special case: if a NSDictionary contains a "text" key together with any of
// the text-editing index keys, the cursor/composing indices are also remapped
// to account for any removed surrogates.  Without this remapping the Dart
// layer would receive an index that points past the end of the sanitized text
// and throw a range assertion ("Range start N is out of text of length M").
static id sanitizeJSONObject(id obj) {
  if ([obj isKindOfClass:[NSString class]]) {
    return sanitizeUTF8String(obj);
  }
  if ([obj isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:[obj count]];

    // Detect text-editing-state dict: has both "text" and at least one index key.
    NSString* rawText = obj[@"text"];
    BOOL isEditingState = NO;
    if (rawText != nil) {
      for (NSString* k in textEditingIndexKeys()) {
        if (obj[k] != nil) { isEditingState = YES; break; }
      }
    }

    if (isEditingState) {
      // Sanitize the text field with position mapping so we can fix the indices.
      NSUInteger origLen = 0;
      NSUInteger* dropBefore = NULL;
      NSString* sanitizedText = sanitizeUTF8StringFull(rawText, &dropBefore, &origLen);
      NSUInteger sanitizedLen = sanitizedText.length;

      [obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        if ([key isEqualToString:@"text"]) {
          result[key] = sanitizedText;
        } else if (dropBefore
                   && [value isKindOfClass:[NSNumber class]]
                   && [textEditingIndexKeys() containsObject:key]) {
          NSInteger raw = [value integerValue];
          NSInteger mapped = remapTextIndex(raw, origLen, dropBefore, sanitizedLen);
          result[key] = @(mapped);
        } else {
          id sKey = [key isKindOfClass:[NSString class]] ? sanitizeUTF8String(key) : key;
          result[sKey] = sanitizeJSONObject(value);
        }
      }];
      if (dropBefore) free(dropBefore);
    } else {
      [obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        id sKey = [key isKindOfClass:[NSString class]] ? sanitizeUTF8String(key) : key;
        result[sKey] = sanitizeJSONObject(value);
      }];
    }
    return result;
   }
  if ([obj isKindOfClass:[NSArray class]]) {
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[obj count]];
    for (id item in obj) {
      [result addObject:sanitizeJSONObject(item)];
    }
    return result;
  }
  return obj;
 }

@implementation FlutterJSONMessageCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [[FlutterJSONMessageCodec alloc] init];
  }
  return _sharedInstance;
}

- (NSData*)encode:(id)message {
  if (message == nil) {
    return nil;
  }
  NSData* encoding;
  NSError* error;
  if ([message isKindOfClass:[NSArray class]] || [message isKindOfClass:[NSDictionary class]]) {
    encoding = [NSJSONSerialization dataWithJSONObject:sanitizeJSONObject(message) options:0 error:&error];
  } else {
    // NSJSONSerialization does not support top-level simple values.
    // We encode as singleton array, then extract the relevant bytes.
    encoding = [NSJSONSerialization dataWithJSONObject:@[ message ] options:0 error:&error];
    if (encoding) {
      encoding = [encoding subdataWithRange:NSMakeRange(1, encoding.length - 2)];
    }
  }

  NSAssert(encoding, @"Invalid JSON message, encoding failed: %@", error);
  return encoding;
}

- (id)decode:(NSData*)message {
  if ([message length] == 0) {
    return nil;
  }
  BOOL isSimpleValue = NO;
  id decoded = nil;
  NSError* error;
  if (0 < message.length) {
    UInt8 first;
    [message getBytes:&first length:1];
    isSimpleValue = first != '{' && first != '[';
    if (isSimpleValue) {
      // NSJSONSerialization does not support top-level simple values.
      // We expand encoding to singleton array, then decode that and extract
      // the single entry.
      UInt8 begin = '[';
      UInt8 end = ']';
      NSMutableData* expandedMessage = [NSMutableData dataWithLength:message.length + 2];
      [expandedMessage replaceBytesInRange:NSMakeRange(0, 1) withBytes:&begin];
      [expandedMessage replaceBytesInRange:NSMakeRange(1, message.length) withBytes:message.bytes];
      [expandedMessage replaceBytesInRange:NSMakeRange(message.length + 1, 1) withBytes:&end];
      message = expandedMessage;
    }
    decoded = [NSJSONSerialization JSONObjectWithData:message options:0 error:&error];
  }
  NSAssert(decoded, @"Invalid JSON message, decoding failed: %@", error);
  return isSimpleValue ? ((NSArray*)decoded)[0] : decoded;
}
@end

@implementation FlutterJSONMethodCodec
+ (instancetype)sharedInstance {
  static id _sharedInstance = nil;
  if (!_sharedInstance) {
    _sharedInstance = [[FlutterJSONMethodCodec alloc] init];
  }
  return _sharedInstance;
}

- (NSData*)encodeMethodCall:(FlutterMethodCall*)call {
  return [[FlutterJSONMessageCodec sharedInstance] encode:@{
    @"method" : call.method,
    @"args" : [self wrapNil:call.arguments],
  }];
}

- (NSData*)encodeSuccessEnvelope:(id)result {
  return [[FlutterJSONMessageCodec sharedInstance] encode:@[ [self wrapNil:result] ]];
}

- (NSData*)encodeErrorEnvelope:(FlutterError*)error {
  return [[FlutterJSONMessageCodec sharedInstance] encode:@[
    error.code,
    [self wrapNil:error.message],
    [self wrapNil:error.details],
  ]];
}

- (FlutterMethodCall*)decodeMethodCall:(NSData*)message {
  NSDictionary* dictionary = [[FlutterJSONMessageCodec sharedInstance] decode:message];
  id method = dictionary[@"method"];
  id arguments = [self unwrapNil:dictionary[@"args"]];
  NSAssert([method isKindOfClass:[NSString class]], @"Invalid JSON method call");
  return [FlutterMethodCall methodCallWithMethodName:method arguments:arguments];
}

- (id)decodeEnvelope:(NSData*)envelope {
  NSArray* array = [[FlutterJSONMessageCodec sharedInstance] decode:envelope];
  if (array.count == 1) {
    return [self unwrapNil:array[0]];
  }
  NSAssert(array.count == 3, @"Invalid JSON envelope");
  id code = array[0];
  id message = [self unwrapNil:array[1]];
  id details = [self unwrapNil:array[2]];
  NSAssert([code isKindOfClass:[NSString class]], @"Invalid JSON envelope");
  NSAssert(message == nil || [message isKindOfClass:[NSString class]], @"Invalid JSON envelope");
  return [FlutterError errorWithCode:code message:message details:details];
}

- (id)wrapNil:(id)value {
  return value == nil ? [NSNull null] : value;
}
- (id)unwrapNil:(id)value {
  return value == [NSNull null] ? nil : value;
}
@end
