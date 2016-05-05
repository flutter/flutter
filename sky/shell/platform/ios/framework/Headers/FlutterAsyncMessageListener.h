// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERASYNCMESSAGELISTENER_H_
#define FLUTTER_FLUTTERASYNCMESSAGELISTENER_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

FLUTTER_EXPORT
@protocol FlutterAsyncMessageListener<NSObject>

- (void)didReceiveString:(NSString*)message
                callback:(void(^)(NSString*))sendResponse;

@end

#endif  // FLUTTER_FLUTTERASYNCMESSAGELISTENER_H_
