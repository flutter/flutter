// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERVIEWCONTROLLER_H_
#define FLUTTER_FLUTTERVIEWCONTROLLER_H_

#import <UIKit/UIKit.h>

#include "FlutterAsyncMessageListener.h"
#include "FlutterDartProject.h"
#include "FlutterMacros.h"
#include "FlutterMessageListener.h"

FLUTTER_EXPORT
@interface FlutterViewController : UIViewController

- (instancetype)initWithProject:(FlutterDartProject*)project
                        nibName:(NSString*)nibNameOrNil
                         bundle:(NSBundle*)nibBundleOrNil
    NS_DESIGNATED_INITIALIZER;

- (void)sendString:(NSString*)message
   withMessageName:(NSString*)messageName;

- (void)sendString:(NSString*)message
   withMessageName:(NSString*)messageName
          callback:(void(^)(NSString*))callback;

- (void)setMessageListener:(NSObject<FlutterMessageListener>*)listener
       forMessagesWithName:(NSString*)messageName;

- (void)setAsyncMessageListener:(NSObject<FlutterAsyncMessageListener>*)listener
            forMessagesWithName:(NSString*)messageName;

@end

// Initializes Flutter for this process. Need only be called once per process.
FLUTTER_EXPORT void FlutterInit(int argc, const char* argv[]);

#endif  // FLUTTER_FLUTTERVIEWCONTROLLER_H_
