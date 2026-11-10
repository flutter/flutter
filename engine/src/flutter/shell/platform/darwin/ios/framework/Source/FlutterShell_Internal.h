// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHELL_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHELL_INTERNAL_H_

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell.h"

#include "flutter/shell/common/thread_host.h"

@interface FlutterShell ()

// The underlying C++ ThreadHost.
//
// Spawned engines return the same ThreadHost as the engine they were spawned
// from. null before creation and after destroyThreadHost.
@property(nonatomic, readonly, nullable) const flutter::ThreadHost* threadHost;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHELL_INTERNAL_H_
