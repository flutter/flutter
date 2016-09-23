// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERMESSAGELISTENER_H_
#define FLUTTER_FLUTTERMESSAGELISTENER_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

FLUTTER_EXPORT
@protocol FlutterMessageListener<NSObject>

- (NSString*)didReceiveString:(NSString*)message;

@property(readonly, strong, nonatomic) NSString* messageName;

@end

#endif  // FLUTTER_FLUTTERMESSAGELISTENER_H_
