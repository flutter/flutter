// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_GL_CONTEXT_H_
#define MOJO_GPU_GL_CONTEXT_H_

#include "base/basictypes.h"
#include "base/memory/weak_ptr.h"
#include "base/observer_list.h"
#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/public/cpp/bindings/interface_ptr.h"

namespace mojo {
class ApplicationConnector;
class CommandBuffer;
using CommandBufferPtr = InterfacePtr<CommandBuffer>;
class Shell;

class GLContext {
 public:
  class Observer {
   public:
    virtual void OnContextLost() = 0;

   protected:
    virtual ~Observer();
  };

  // Creates an offscreen GL context.
  static base::WeakPtr<GLContext> CreateOffscreen(
      ApplicationConnector* connector);

  // Creates a GL context from a command buffer.
  static base::WeakPtr<GLContext> CreateFromCommandBuffer(
      InterfaceHandle<CommandBuffer> command_buffer);

  void MakeCurrent();
  bool IsCurrent();
  void Destroy();

  void AddObserver(Observer* observer);
  void RemoveObserver(Observer* observer);

 private:
  explicit GLContext(InterfaceHandle<CommandBuffer> command_buffer);
  ~GLContext();

  static void ContextLostThunk(void* self);
  void OnContextLost();

  MGLContext context_;

  base::ObserverList<Observer> observers_;
  base::WeakPtrFactory<GLContext> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(GLContext);
};

}  // namespace mojo

#endif  // MOJO_GPU_GL_CONTEXT_H_
