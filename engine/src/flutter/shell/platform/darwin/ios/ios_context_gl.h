// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "flutter/shell/platform/darwin/ios/ios_render_target_gl.h"

@class CAEAGLLayer;

namespace flutter {

class IOSContextGL final : public IOSContext {
 public:
  IOSContextGL();

  // |IOSContext|
  ~IOSContextGL() override;

  std::unique_ptr<IOSRenderTargetGL> CreateRenderTarget(fml::scoped_nsobject<CAEAGLLayer> layer);

 private:
  fml::scoped_nsobject<EAGLContext> context_;
  fml::scoped_nsobject<EAGLContext> resource_context_;

  // |IOSContext|
  sk_sp<GrContext> CreateResourceContext() override;

  // |IOSContext|
  bool MakeCurrent() override;

  // |IOSContext|
  bool ClearCurrent() override;

  // |IOSContext|
  bool ResourceMakeCurrent() override;

  // |IOSContext|
  std::unique_ptr<Texture> CreateExternalTexture(
      int64_t texture_id,
      fml::scoped_nsobject<NSObject<FlutterTexture>> texture) override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSContextGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_
