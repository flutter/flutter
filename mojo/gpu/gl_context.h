// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_GL_CONTEXT_H_
#define MOJO_GPU_GL_CONTEXT_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/observer_list.h"
#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/public/cpp/bindings/interface_ptr.h"

namespace mojo {
class ApplicationConnector;
class CommandBuffer;
using CommandBufferPtr = InterfacePtr<CommandBuffer>;

// Provides an easy interface to create and use a GL context.
//
// Instances of this object are not thread-safe and must be used on the same
// thread as they were created on.
class GLContext : public base::RefCounted<GLContext> {
 public:
  // RAII style helper for executing code within a GL context.
  //
  // The scope reactivates the prior GL context when exited (destroyed).
  // Scopes can be nested.
  class Scope {
   public:
    // Upon entry to the scope, makes the GL context active.
    //
    // This operation is not allowed if |GLContext::is_lost()| is true.
    explicit Scope(const scoped_refptr<GLContext>& gl_context);

    // Upon exit from the scope, reactivates the prior GL context.
    ~Scope();

    // Gets the underlying GL context, never null.
    const scoped_refptr<GLContext>& gl_context() const { return gl_context_; }

    // Gets the underlying MGL context handle, never |MGL_NO_CONTEXT|.
    MGLContext mgl_context() const { return gl_context_->mgl_context_; }

   private:
    scoped_refptr<GLContext> gl_context_;
    MGLContext prior_mgl_context_;

    DISALLOW_COPY_AND_ASSIGN(Scope);
  };

  // Observes GL context state changes.
  class Observer {
   public:
    // Invoked when the GL context is lost remotely.  This method is not
    // called if the GL context is destroyed normally.
    //
    // Take care handling this callback.  It may be invoked during any
    // blocking GL request.
    virtual void OnContextLost() = 0;

   protected:
    virtual ~Observer();
  };

  // Creates an offscreen GL context by binding to the GPU service.
  static scoped_refptr<GLContext> CreateOffscreen(
      ApplicationConnector* connector);

  // Creates a GL context from a command buffer.
  static scoped_refptr<GLContext> CreateFromCommandBuffer(
      InterfaceHandle<CommandBuffer> command_buffer);

  // Gets the underlying MGL context handle.
  // Use a |Scope| to make the MGL context current.
  // This remains valid even when the GL context is lost although it will
  // not be possible to enter the GL context scope after loss.
  MGLContext mgl_context() const { return mgl_context_; }

  // Returns true if the GL context was lost.
  bool is_lost() const { return lost_; }

  // Returns true if the GL context is currently active on this thread.
  // This may be true even if the GL context was lost.
  bool IsCurrent() const;

  // Adds or removes observers for state changes.
  // Does not take ownership of the observer object.
  void AddObserver(Observer* observer);
  void RemoveObserver(Observer* observer);

 private:
  friend class base::RefCounted<GLContext>;

  explicit GLContext(InterfaceHandle<CommandBuffer> command_buffer);
  ~GLContext();

  static void ContextLostThunk(void* self);
  void OnContextLost();

  const MGLContext mgl_context_;
  bool lost_ = false;
  base::ObserverList<Observer> observers_;

  DISALLOW_COPY_AND_ASSIGN(GLContext);
};

}  // namespace mojo

#endif  // MOJO_GPU_GL_CONTEXT_H_
