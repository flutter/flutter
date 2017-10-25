// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERVIEWCONTROLLER_H_
#define FLUTTER_FLUTTERVIEWCONTROLLER_H_

#import <UIKit/UIKit.h>
#include <sys/cdefs.h>

#include "FlutterBinaryMessenger.h"
#include "FlutterDartProject.h"
#include "FlutterMacros.h"

FLUTTER_EXPORT
@interface FlutterViewController : UIViewController<FlutterBinaryMessenger>

- (instancetype)initWithProject:(FlutterDartProject*)project
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (void)handleStatusBarTouches:(UIEvent*)event;

/**
 Sets the first route that the Flutter app shows. The default is "/".

 - Parameter route: The name of the first route to show.
 */
- (void)setInitialRoute:(NSString*)route;

@end

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
