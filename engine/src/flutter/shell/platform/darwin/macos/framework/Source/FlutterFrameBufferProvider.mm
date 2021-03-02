// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"

#import <OpenGL/gl.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

@interface FlutterFrameBufferProvider () {
  const NSOpenGLContext* _openGLContext;
  uint32_t _frameBufferId;
  uint32_t _backingTexture;
}
@end

@implementation FlutterFrameBufferProvider
- (instancetype)initWithOpenGLContext:(const NSOpenGLContext*)openGLContext {
  if (self = [super init]) {
    _openGLContext = openGLContext;
    MacOSGLContextSwitch context_switch(_openGLContext);

    glGenFramebuffers(1, &_frameBufferId);
    glGenTextures(1, &_backingTexture);

    [self createFramebuffer];
  }
  return self;
}

- (void)createFramebuffer {
  glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferId);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _backingTexture);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
}

- (uint32_t)glFrameBufferId {
  return _frameBufferId;
}

- (uint32_t)glTextureId {
  return _backingTexture;
}

- (void)dealloc {
  MacOSGLContextSwitch context_switch(_openGLContext);

  glDeleteFramebuffers(1, &_frameBufferId);
  glDeleteTextures(1, &_backingTexture);
}

@end
