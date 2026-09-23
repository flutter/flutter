// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_gl_fence.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>

// How long to wait for a fence before giving up on it. Reaching this means the
// driver has taken an unreasonable amount of time to render a frame; carry on
// and use the frame rather than blocking the thread indefinitely.
static constexpr EGLTimeKHR kFenceTimeoutNanoseconds = 1000000000;  // 1s

struct _FlGLFence {
  GObject parent_instance;

  // Display [sync] was created on, stored so the fence can be destroyed without
  // a context being current.
  EGLDisplay display;

  EGLSyncKHR sync;

  // TRUE if OpenGL can wait for the fence, i.e. without blocking this thread.
  gboolean can_wait_sync;
};

G_DEFINE_TYPE(FlGLFence, fl_gl_fence, G_TYPE_OBJECT)

static void fl_gl_fence_dispose(GObject* object) {
  FlGLFence* self = FL_GL_FENCE(object);

  if (self->sync != EGL_NO_SYNC_KHR) {
    eglDestroySyncKHR(self->display, self->sync);
    self->sync = EGL_NO_SYNC_KHR;
  }

  G_OBJECT_CLASS(fl_gl_fence_parent_class)->dispose(object);
}

static void fl_gl_fence_class_init(FlGLFenceClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_gl_fence_dispose;
}

static void fl_gl_fence_init(FlGLFence* self) {
  self->display = EGL_NO_DISPLAY;
  self->sync = EGL_NO_SYNC_KHR;
}

FlGLFence* fl_gl_fence_new(FlOpenGLManager* opengl_manager) {
  g_return_val_if_fail(FL_IS_OPENGL_MANAGER(opengl_manager), nullptr);

  FlGLFence* self = FL_GL_FENCE(g_object_new(fl_gl_fence_get_type(), nullptr));

  EGLDisplay display = fl_opengl_manager_get_display(opengl_manager);
  EGLSyncKHR sync = eglCreateSyncKHR(display, EGL_SYNC_FENCE_KHR, nullptr);
  // Creating a fence only adds it to the command stream; the commands have to
  // be flushed for it to be reached, otherwise waiting on it can never return.
  glFlush();
  if (sync == EGL_NO_SYNC_KHR) {
    g_warning("Failed to create fence");
    return self;
  }

  self->display = display;
  self->sync = sync;
  self->can_wait_sync = fl_opengl_manager_can_wait_sync(opengl_manager);

  return self;
}

// Blocks the calling thread until the fence is reached.
static void client_wait(FlGLFence* self) {
  // The commands were flushed when the fence was created, so they don't need to
  // be flushed again here. Flushing wouldn't work anyway, as that only applies
  // to a fence created in the context current on this thread.
  EGLint result = eglClientWaitSyncKHR(self->display, self->sync, 0,
                                       kFenceTimeoutNanoseconds);
  if (result == EGL_TIMEOUT_EXPIRED_KHR) {
    g_warning("Timed out waiting for OpenGL rendering to complete");
  }
}

void fl_gl_fence_wait(FlGLFence* self) {
  g_return_if_fail(FL_IS_GL_FENCE(self));

  // Nothing to wait for if the fence couldn't be created.
  if (self->sync == EGL_NO_SYNC_KHR) {
    return;
  }

  if (!self->can_wait_sync) {
    client_wait(self);
    return;
  }

  eglWaitSyncKHR(self->display, self->sync, 0);
}
