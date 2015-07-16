// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/android/surface_texture_listener.h"

#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "base/thread_task_runner_handle.h"
#include "jni/SurfaceTextureListener_jni.h"

namespace gfx {

SurfaceTextureListener::SurfaceTextureListener(const base::Closure& callback)
    : callback_(callback),
      browser_loop_(base::ThreadTaskRunnerHandle::Get()) {
}

SurfaceTextureListener::~SurfaceTextureListener() {
}

void SurfaceTextureListener::Destroy(JNIEnv* env, jobject obj) {
  delete this;
}

void SurfaceTextureListener::FrameAvailable(JNIEnv* env, jobject obj) {
  if (!browser_loop_->BelongsToCurrentThread()) {
    browser_loop_->PostTask(FROM_HERE, callback_);
  } else {
    callback_.Run();
  }
}

// static
bool SurfaceTextureListener::RegisterSurfaceTextureListener(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace gfx
