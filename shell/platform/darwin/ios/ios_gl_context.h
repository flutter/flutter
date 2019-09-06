// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAEAGLLayer.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"

namespace flutter {

class IOSGLContext {
 public:
  IOSGLContext();
  IOSGLContext(EAGLSharegroup* sharegroup);

  ~IOSGLContext();

  bool MakeCurrent();

  bool BindRenderbufferStorage(fml::scoped_nsobject<CAEAGLLayer> layer);

  sk_sp<SkColorSpace> ColorSpace() const { return color_space_; }

  std::unique_ptr<IOSGLContext> MakeSharedContext();

  fml::WeakPtr<IOSGLContext> GetWeakPtr();

 private:
  fml::scoped_nsobject<EAGLContext> context_;
  sk_sp<SkColorSpace> color_space_;

  std::unique_ptr<fml::WeakPtrFactory<IOSGLContext>> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSGLContext);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_
