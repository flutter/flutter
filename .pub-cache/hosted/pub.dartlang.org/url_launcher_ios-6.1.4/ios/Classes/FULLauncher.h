// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for UIApplication methods relating to launching URLs.
///
/// This protocol exists to allow injecting an alternate implementation for testing.
@protocol FULLauncher
- (BOOL)canOpenURL:(NSURL *)url;
- (void)openURL:(NSURL *)url
              options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
    completionHandler:(void (^__nullable)(BOOL success))completion;
@end

NS_ASSUME_NONNULL_END
