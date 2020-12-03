// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/**
 * RAII wrapper that sets provided NSOpenGLContext as current and restores
 * original context on scope exit.
 */
class MacOSGLContextSwitch {
 public:
  explicit MacOSGLContextSwitch(const NSOpenGLContext* context);
  ~MacOSGLContextSwitch();

  MacOSGLContextSwitch(const MacOSGLContextSwitch&) = delete;
  MacOSGLContextSwitch(MacOSGLContextSwitch&&) = delete;

 private:
  NSOpenGLContext* previous_;
};
