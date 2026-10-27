// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/build/bazel/toolchains/tests/macos_objc_smoke.h"

#import <Foundation/Foundation.h>

namespace {

int g_lifetime_events = 0;

struct Counted {
  Counted() { ++g_lifetime_events; }
  ~Counted() { ++g_lifetime_events; }
};

}  // namespace

@interface FlutterBazelSmokeHolder : NSObject {
  Counted _counted;
}
@end

@implementation FlutterBazelSmokeHolder
@end

bool FlutterBazelSmokeObjcUsesArc() {
#if __has_feature(objc_arc)
  return true;
#else
  return false;
#endif
}

std::string FlutterBazelSmokeUppercase(const std::string& text) {
  @autoreleasepool {
    NSString* string = [NSString stringWithUTF8String:text.c_str()];
    return std::string([[string uppercaseString] UTF8String]);
  }
}

int FlutterBazelSmokeCxxMemberLifetime() {
  g_lifetime_events = 0;
  @autoreleasepool {
    FlutterBazelSmokeHolder* holder = [[FlutterBazelSmokeHolder alloc] init];
    (void)holder;
    holder = nil;
  }
  return g_lifetime_events;
}
