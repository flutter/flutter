// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_GL_CONTEXT_H_
#define MOJO_GPU_GL_CONTEXT_H_

#include "base/basictypes.h"
#include "base/memory/weak_ptr.h"
#include "base/observer_list.h"
#include "mojo/public/c/gles2/gles2.h"

namespace gpu {
namespace gles2 {
class GLES2Interface;
}
}

namespace mojo {
class Shell;

class GLContext {
 public:
  class Observer {
   public:
    virtual void OnContextLost() = 0;

   protected:
    virtual ~Observer();
  };

  static base::WeakPtr<GLContext> Create(Shell* shell);

  void MakeCurrent();
  void Destroy();

  gpu::gles2::GLES2Interface* gl() const { return gl_; }

  void AddObserver(Observer* observer);
  void RemoveObserver(Observer* observer);

 private:
  explicit GLContext(Shell* shell);
  ~GLContext();

  static void ContextLostThunk(void* self);
  void OnContextLost();

  MojoGLES2Context context_;
  gpu::gles2::GLES2Interface* gl_;

  base::ObserverList<Observer> observers_;
  base::WeakPtrFactory<GLContext> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(GLContext);
};

}  // namespace mojo

#endif  // MOJO_GPU_GL_CONTEXT_H_
