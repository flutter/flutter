// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERVIEWCONTROLLER_H_
#define FLUTTER_FLUTTERVIEWCONTROLLER_H_

#include "FlutterMacros.h"
#include "FlutterDartProject.h"

#import <UIKit/UIKit.h>

FLUTTER_EXPORT
@interface FlutterViewController : UIViewController

- (instancetype)initWithProject:(FlutterDartProject*)project
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil
    NS_DESIGNATED_INITIALIZER;

@end

// Initializes Flutter for this process. Need only be called once per process.
FLUTTER_EXPORT void FlutterInit(int argc, const char* argv[]);

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
