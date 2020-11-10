// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SWITCHABLE_GL_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SWITCHABLE_GL_CONTEXT_H_

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/thread_checker.h"
#include "flutter/fml/memory/weak_ptr.h"

@class EAGLContext;

namespace flutter {

//------------------------------------------------------------------------------
/// The iOS implementation of a |SwitchableGLContext|.
///
/// It wraps a pointer to an EAGLContext. When passed in the constructor of the |GLContextSwitch|,
/// this EAGLContext is set to current. When the |GLContextSwitch| destroys, the current context
/// will be restored to the context before setting this EAGLContext to current.
///
/// Note: An |IOSSwitchableGLContext| doesn't retain the EAGLContext. Someone else must retain the
/// pointer and outlive all the |IOSSwitchableGLContext|. This object is meant to be only owned by a
/// |GLContextSwitch| and should be destroyed when The |GLContectSwitch| destroys.
class IOSSwitchableGLContext final : public SwitchableGLContext {
 public:
  IOSSwitchableGLContext(EAGLContext* context);

  bool SetCurrent() override;

  bool RemoveCurrent() override;

 private:
  // These pointers are managed by IOSRendererTarget/IOSContextGL or a 3rd party
  // plugin that uses gl context. |IOSSwitchableGLContext| should never outlive
  // those objects. Never release this pointer within this object.
  EAGLContext* context_;
  EAGLContext* previous_context_;

  FML_DECLARE_THREAD_CHECKER(checker);

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSwitchableGLContext);
};

}  // namespace flutter

#endif
