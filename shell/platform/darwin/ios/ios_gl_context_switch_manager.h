// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_SWITCH_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_SWITCH_MANAGER_H_

#define GLES_SILENCE_DEPRECATION

#import <OpenGLES/EAGL.h>
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/renderer_context_switch_manager.h"

namespace flutter {

//------------------------------------------------------------------------------
/// The iOS implementation of `RendererContextSwitchManager`.
///
/// On `IOSGLContextSwitch`'s construction, it pushes the current EAGLContext to a stack and
/// sets the flutter's gl context as current.
/// On `IOSGLContextSwitch`'s desstruction, it pops a EAGLContext from the stack and set it to
/// current.
///
class IOSGLContextSwitchManager final : public RendererContextSwitchManager {
 public:
  class IOSGLContextSwitch final : public RendererContextSwitch {
   public:
    IOSGLContextSwitch(IOSGLContextSwitchManager& manager,
                       fml::scoped_nsobject<EAGLContext> context);

    ~IOSGLContextSwitch();

    bool GetSwitchResult() override;

   private:
    IOSGLContextSwitchManager& manager_;
    bool switch_result_;
    bool has_pushed_context_;

    FML_DISALLOW_COPY_AND_ASSIGN(IOSGLContextSwitch);
  };

  IOSGLContextSwitchManager();

  ~IOSGLContextSwitchManager();

  std::unique_ptr<RendererContextSwitch> MakeCurrent() override;
  std::unique_ptr<RendererContextSwitch> ResourceMakeCurrent() override;

  fml::scoped_nsobject<EAGLContext> GetContext();

 private:
  fml::scoped_nsobject<EAGLContext> context_;
  fml::scoped_nsobject<EAGLContext> resource_context_;
  fml::scoped_nsobject<NSMutableArray> stored_;

  bool PushContext(fml::scoped_nsobject<EAGLContext> context);
  void PopContext();

  FML_DISALLOW_COPY_AND_ASSIGN(IOSGLContextSwitchManager);
};

}

#endif
