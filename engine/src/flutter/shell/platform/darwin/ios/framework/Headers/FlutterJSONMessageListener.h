// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERJSONMESSAGELISTENER_H_
#define FLUTTER_FLUTTERJSONMESSAGELISTENER_H_

#include "FlutterMessageListener.h"

FLUTTER_EXPORT
@interface FlutterJSONMessageListener : NSObject<FlutterMessageListener>

- (NSDictionary*)didReceiveJSON:(NSDictionary*)message;

@end

#endif  // FLUTTER_FLUTTERJSONMESSAGELISTENER_H_
