// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTEROBSERVATORYPUBLISHER_H_
#define FLUTTER_FLUTTEROBSERVATORYPUBLISHER_H_

#import <Foundation/Foundation.h>

@interface FlutterObservatoryPublisher : NSObject

- (instancetype)initWithEnableObservatoryPublication:(BOOL)enableObservatoryPublication
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property(nonatomic, readonly) NSURL* url;

@end

#endif  // FLUTTER_FLUTTEROBSERVATORYPUBLISHER_H_
