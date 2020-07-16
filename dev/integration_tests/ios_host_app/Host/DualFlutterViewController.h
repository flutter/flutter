// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface DualFlutterViewController : UIViewController

@property (readonly) FlutterViewController* topFlutterViewController;
@property (readonly) FlutterViewController* bottomFlutterViewController;

@end

NS_ASSUME_NONNULL_END
