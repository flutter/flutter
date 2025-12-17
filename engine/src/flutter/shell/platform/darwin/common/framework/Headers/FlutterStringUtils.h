// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERSTRINGUTILS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERSTRINGUTILS_H_

#import <Foundation/Foundation.h>

/**
 * Sanitizes a UTF-8 string to ensure it is valid and contains no unpaired surrogate escape
 * sequences (e.g. \uXXXX) typical in JSON.
 *
 * This function performs two passes:
 * 1. Lossy UTF-8 decoding to replace invalid bytes with \uFFFD.
 * 2. Scans for JSON-style escape sequences \uXXXX and replaces unpaired surrogates with \uFFFD.
 */
NSString* FlutterSanitizeUTF8ForJSON(NSData* data);

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERSTRINGUTILS_H_
