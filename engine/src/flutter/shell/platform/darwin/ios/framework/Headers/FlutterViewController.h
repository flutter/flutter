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
                         bundle:(NSBundle*)nibBundleOrNil
    NS_DESIGNATED_INITIALIZER;

- (void)handleStatusBarTouches:(UIEvent*)event;
@end

__BEGIN_DECLS

// Initializes Flutter for this process. Need only be called once per process.
FLUTTER_EXPORT void FlutterInit(int argc, const char* argv[])
    __attribute__((deprecated("This call is no longer necessary and will be "
                              "removed in an upcoming release.")));

__END_DECLS

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
