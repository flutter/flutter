// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"
#import "flutter/testing/testing.h"

#import <OpenGL/gl.h>

namespace flutter::testing {

TEST(FlutterFrameBufferProviderTest, TestCreate) {
  NSOpenGLPixelFormatAttribute attributes[] = {
      NSOpenGLPFAColorSize, 24, NSOpenGLPFAAlphaSize, 8, 0,
  };
  NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
  NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];

  [context makeCurrentContext];
  FlutterFrameBufferProvider* framebufferProvider =
      [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:context];

  GLuint fbo = [framebufferProvider glFrameBufferId];
  GLuint texture = [framebufferProvider glTextureId];

  // Normally we'd back this using an IOSurface but for this test let's just create a TexImage2D
  // with no backing data.
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);
  glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB, texture,
                         0);

  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);

  EXPECT_TRUE(status == GL_FRAMEBUFFER_COMPLETE);
}

}  // namespace flutter::testing
