// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __SKY_SHELL_MAC_TRACINGCONTROLLER__
#define __SKY_SHELL_MAC_TRACINGCONTROLLER__

#import <Foundation/Foundation.h>

@interface TracingController : NSObject

+ (instancetype)sharedController;

- (void)startTracing;
- (void)stopTracing;

@end

#endif /* defined(__SKY_SHELL_MAC_TRACINGCONTROLLER__) */
