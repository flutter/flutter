// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERVIEWCONTROLLER_H_
#define FLUTTER_FLUTTERVIEWCONTROLLER_H_

#import <UIKit/UIKit.h>

@interface FlutterViewController : UIViewController

/**
 *  Initialize the view controller using the specified framework bundle
 *  containing the precompiled Dart code.
 *
 *  @param dartBundle the framework bundle containing the precompiled Dart code.
 *
 *  @return the initialized view controller.
 */
- (instancetype)initWithDartBundle:(NSBundle*)dartBundle;

/**
 *  Initialze the view controller using the specified framework bundle
 *  containing the precompiled dart code.
 *
 *  @param dartBundleOrNil the framework bundle containing the precompiled Dart
 *                         code.
 *  @param nibNameOrNil    the nib name.
 *  @param nibBundleOrNil  the bundle containing the nib.
 *
 *  @return the initialized view controller.
 *
 *  @discussion this is the designated initializer for this class. Subclasses
 *              must call this method during initialzation.
 */
- (instancetype)initWithDartBundle:(NSBundle*)dartBundleOrNil
                           nibName:(NSString*)nibNameOrNil
                            bundle:(NSBundle*)nibBundleOrNil
    NS_DESIGNATED_INITIALIZER;

@end

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
