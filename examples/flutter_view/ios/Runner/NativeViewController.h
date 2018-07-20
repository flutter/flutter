// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>


@protocol NativeViewControllerDelegate <NSObject>

- (void)didTapIncrementButton;

@end

@interface NativeViewController: UIViewController
@property (strong, nonatomic) id<NativeViewControllerDelegate> delegate;
- (void) didReceiveIncrement;
@end
