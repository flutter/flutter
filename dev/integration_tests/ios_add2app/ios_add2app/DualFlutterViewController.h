// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DualFlutterViewController : UIViewController

@property (readonly, strong, nonatomic) FlutterViewController* topFlutterViewController;
@property (readonly, strong, nonatomic) FlutterViewController* bottomFlutterViewController;

@end

NS_ASSUME_NONNULL_END
