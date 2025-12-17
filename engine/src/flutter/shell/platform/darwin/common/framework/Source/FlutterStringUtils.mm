// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterStringUtils.h"

NSString* FlutterSanitizeUTF8ForJSON(NSData* data) {
  if (!data) {
    return nil;
  }

  // Pass 1: Decode as UTF-8, potentially lossy.
  // This handles invalid UTF-8 bytes (e.g. truncated sequences).
  NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (!string) {
    NSMutableString* result = [NSMutableString stringWithCapacity:data.length];
    const uint8_t* bytes = (const uint8_t*)data.bytes;
    NSUInteger length = data.length;
    NSUInteger i = 0;

    while (i < length) {
      uint8_t c = bytes[i];
      if (c < 0x80) {
        [result appendFormat:@"%c", c];
        i++;
      } else {
        NSUInteger seqLen = 0;
        if ((c & 0xE0) == 0xC0) {
          seqLen = 2;
        } else if ((c & 0xF0) == 0xE0) {
          seqLen = 3;
        } else if ((c & 0xF8) == 0xF0) {
          seqLen = 4;
        }

        BOOL valid = seqLen > 0 && i + seqLen <= length;
        for (NSUInteger j = 1; valid && j < seqLen; j++) {
          if ((bytes[i + j] & 0xC0) != 0x80) {
            valid = NO;
          }
        }

        if (valid) {
          NSString* part = [[NSString alloc] initWithBytes:bytes + i
                                                    length:seqLen
                                                  encoding:NSUTF8StringEncoding];
          if (part) {
            [result appendString:part];
            i += seqLen;
            continue;
          }
        }

        [result appendString:@"\uFFFD"];
        i++;
      }
    }
    string = result;
  }

  // Pass 2: Sanitize unpaired surrogate escape sequences (\uXXXX).
  // NSJSONSerialization fails if it encounters unpaired surrogates in escape sequences.
  // We scan for \uXXXX and replace unpaired ones with \uFFFD.
  NSUInteger length = string.length;
  NSMutableString* result = [NSMutableString stringWithCapacity:length];
  BOOL modified = NO;

  for (NSUInteger i = 0; i < length;) {
    unichar c = [string characterAtIndex:i];
    if (c == '\\' && i + 1 < length) {
      unichar next = [string characterAtIndex:i + 1];
      if (next == 'u' && i + 5 < length) {
        NSString* hexStr = [string substringWithRange:NSMakeRange(i + 2, 4)];
        unsigned int codePoint;
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        if ([scanner scanHexInt:&codePoint]) {
          BOOL isHigh = (codePoint >= 0xD800 && codePoint <= 0xDBFF);
          BOOL isLow = (codePoint >= 0xDC00 && codePoint <= 0xDFFF);

          if (isHigh) {
            // Check if followed by low surrogate
            BOOL hasPair = NO;
            if (i + 11 < length && [string characterAtIndex:i + 6] == '\\' &&
                [string characterAtIndex:i + 7] == 'u') {
              NSString* lowHex = [string substringWithRange:NSMakeRange(i + 8, 4)];
              unsigned int lowCode;
              NSScanner* lowScanner = [NSScanner scannerWithString:lowHex];
              if ([lowScanner scanHexInt:&lowCode]) {
                if (lowCode >= 0xDC00 && lowCode <= 0xDFFF) {
                  hasPair = YES;
                }
              }
            }

            if (hasPair) {
              // Valid pair. Append strictly.
              [result appendString:[string substringWithRange:NSMakeRange(i, 12)]];
              i += 12;
              continue;
            } else {
              // Unpaired high. Replace.
              [result appendString:@"\\uFFFD"];
              modified = YES;
              i += 6;
              continue;
            }
          } else if (isLow) {
            // Unpaired low (if it was paired, it would be consumed by High check).
            [result appendString:@"\\uFFFD"];
            modified = YES;
            i += 6;
            continue;
          }
        }
      } else {
        // escaped char other than u (or incomplete u), consume backslash and next char
        [result appendString:[string substringWithRange:NSMakeRange(i, 2)]];
        i += 2;
        continue;
      }
    }

    // normal char
    [result appendFormat:@"%C", c];
    i++;
  }

  return modified ? result : string;
}
