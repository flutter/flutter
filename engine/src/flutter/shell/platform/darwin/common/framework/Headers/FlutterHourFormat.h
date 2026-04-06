// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERHOURFORMAT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERHOURFORMAT_H_

#import <Foundation/Foundation.h>

NS_SWIFT_NONSENDABLE
@interface FlutterHourFormat : NSObject
+ (BOOL)isAlwaysUse24HourFormat NS_SWIFT_NONISOLATED;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_COMMON_FRAMEWORK_HEADERS_FLUTTERHOURFORMAT_H_
