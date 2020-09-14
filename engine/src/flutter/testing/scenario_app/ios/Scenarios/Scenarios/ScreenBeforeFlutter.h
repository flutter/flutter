// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

@interface ScreenBeforeFlutter : UIViewController

- (id)initWithEngineRunCompletion:(dispatch_block_t)engineRunCompletion;
- (FlutterViewController*)showFlutter:(dispatch_block_t)showCompletion;

@property(nonatomic, readonly) FlutterEngine* engine;

@end
