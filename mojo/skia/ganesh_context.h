// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_GANESH_CONTEXT_H_
#define MOJO_SKIA_GANESH_CONTEXT_H_

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/weak_ptr.h"
#include "mojo/gpu/gl_context.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace mojo {
namespace skia {

// Binds a Ganesh rendering context to a GL context.
//
// This object is not thread-safe.
class GaneshContext : public GLContext::Observer {
 public:
  // RAII style helper for executing code within a Ganesh environment.
  //
  // Note that Ganesh assumes that it owns the state of the GL Context
  // for the duration while the scope is active.  Take care not to perform
  // any significant low-level GL operations while in the Ganesh scope
  // which might disrupt what Ganesh is doing!
  //
  // Recursively entering the scope of a particular GaneshContext is not
  // allowed.
  class Scope {
   public:
    // Upon entry to the scope, makes the GL context active and resets
    // the Ganesh context state.
    explicit Scope(GaneshContext* context) : context_(context) {
      DCHECK(context_);
      context_->EnterScope();
    }

    // Upon exit from the scope, flushes the Ganesh context state and
    // restores the prior GL context.
    ~Scope() { context_->ExitScope(); }

    // Gets the underlying GL context, may be null if the context was lost.
    //
    // Be careful when manipulating the GL context from within a Ganesh
    // scope since the Ganesh renderer caches GL state.  Queries are safe
    // but operations which modify the state of the GL context, such as binding
    // textures, should be followed by a call to |GrContext::resetContext|
    // before performing other Ganesh related actions within the scope.
    const base::WeakPtr<GLContext>& gl_context() const {
      return context_->gl_context_;
    }

    // Gets the Ganesh rendering context, may be null if the context was lost.
    GrContext* gr_context() const { return context_->gr_context_.get(); }

   private:
    GaneshContext* context_;

    DISALLOW_COPY_AND_ASSIGN(Scope);
  };

  explicit GaneshContext(base::WeakPtr<GLContext> gl_context);
  ~GaneshContext() override;

  // Gets the underlying GL context.
  const base::WeakPtr<GLContext>& gl_context() const { return gl_context_; }

 private:
  void OnContextLost() override;
  void ReleaseContext();

  void EnterScope();
  void ExitScope();

  base::WeakPtr<GLContext> gl_context_;
  ::skia::RefPtr<GrContext> gr_context_;

  bool scope_entered_ = false;
  bool context_lost_ = false;
  MGLContext previous_mgl_context_ = MGL_NO_CONTEXT;

  DISALLOW_COPY_AND_ASSIGN(GaneshContext);
};

}  // namespace skia
}  // namespace mojo

#endif  // MOJO_SKIA_GANESH_CONTEXT_H_
