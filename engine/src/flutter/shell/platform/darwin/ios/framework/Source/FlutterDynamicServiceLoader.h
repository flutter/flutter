// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_DYNAMIC_SERVICE_LOADER_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_DYNAMIC_SERVICE_LOADER_H_

#import <Foundation/Foundation.h>
#include "flutter/shell/platform/darwin/common/platform_service_provider.h"

@interface FlutterDynamicServiceLoader : NSObject

- (void)resolveService:(NSString*)name
                handle:(mojo::ScopedMessagePipeHandle)handle;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_DYNAMIC_SERVICE_LOADER_H_
