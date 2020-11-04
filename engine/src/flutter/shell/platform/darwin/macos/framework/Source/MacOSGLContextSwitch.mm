// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

MacOSGLContextSwitch::MacOSGLContextSwitch(NSOpenGLContext* context) {
  previous_ = [NSOpenGLContext currentContext];
  [context makeCurrentContext];
}

MacOSGLContextSwitch::~MacOSGLContextSwitch() {
  if (previous_) {
    [previous_ makeCurrentContext];
  } else {
    [NSOpenGLContext clearCurrentContext];
  }
}
