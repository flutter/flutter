// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SKIA_GANESH_CONTEXT_H_
#define MOJO_SKIA_GANESH_CONTEXT_H_

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "mojo/gpu/gl_context.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace mojo {
namespace skia {

// Binds a Ganesh rendering context to a GL context.
//
// Instances of this object is not thread-safe and must be used on the
// same thread as the GL context was created on.
class GaneshContext : public base::RefCounted<GaneshContext>,
                      private GLContext::Observer {
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
    //
    // This operation is not allowed if |GaneshContext::is_lost()| is true.
    explicit Scope(const scoped_refptr<GaneshContext>& ganesh_context);

    // Upon exit from the scope, flushes the Ganesh context state and
    // reactivates the prior GL context.
    ~Scope();

    // Gets the underlying Ganesh context, never null.
    const scoped_refptr<GaneshContext>& ganesh_context() const {
      return ganesh_context_;
    }

    // Gets the underlying Ganesh rendering context, never null.
    const sk_sp<GrContext>& gr_context() const {
      return ganesh_context_->gr_context_;
    }

    // Gets the underlying GL context scope.
    //
    // Be careful when manipulating the GL context from within a Ganesh
    // scope since the Ganesh renderer caches GL state.  Queries are safe
    // but operations which modify the state of the GL context, such as binding
    // textures, should be followed by a call to |GrContext::resetContext|
    // before performing other Ganesh related actions within the scope.
    const GLContext::Scope& gl_scope() const { return gl_scope_; }

   private:
    scoped_refptr<GaneshContext> ganesh_context_;
    GLContext::Scope gl_scope_;

    DISALLOW_COPY_AND_ASSIGN(Scope);
  };

  // Creates a Ganesh context bound to the specified GL context.
  explicit GaneshContext(const scoped_refptr<GLContext>& gl_context);

  // Gets the underlying GL context, never null.
  const scoped_refptr<GLContext>& gl_context() const { return gl_context_; }

  // Returns true if the GL context was lost.
  bool is_lost() const { return gl_context_->is_lost(); }

 private:
  friend class base::RefCounted<GaneshContext>;

  ~GaneshContext() override;
  void OnContextLost() override;

  const scoped_refptr<GLContext> gl_context_;
  sk_sp<GrContext> gr_context_;
  bool scope_entered_ = false;

  DISALLOW_COPY_AND_ASSIGN(GaneshContext);
};

}  // namespace skia
}  // namespace mojo

#endif  // MOJO_SKIA_GANESH_CONTEXT_H_
