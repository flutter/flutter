// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/vsync_waiter_android.h"

#include <utility>

#include "jni/VsyncWaiter_jni.h"
#include "lib/ftl/logging.h"
#include "flutter/common/threads.h"

namespace shell {

VsyncWaiterAndroid::VsyncWaiterAndroid() : weak_factory_(this) {}

VsyncWaiterAndroid::~VsyncWaiterAndroid() = default;

void VsyncWaiterAndroid::AsyncWaitForVsync(Callback callback) {
  FTL_DCHECK(!callback_);
  callback_ = std::move(callback);
  ftl::WeakPtr<VsyncWaiterAndroid>* weak =
      new ftl::WeakPtr<VsyncWaiterAndroid>();
  *weak = weak_factory_.GetWeakPtr();

  blink::Threads::Platform()->PostTask([weak] {
    JNIEnv* env = base::android::AttachCurrentThread();
    Java_VsyncWaiter_asyncWaitForVsync(env, reinterpret_cast<intptr_t>(weak));
  });
}

void VsyncWaiterAndroid::OnVsync(long frameTimeNanos) {
  Callback callback = std::move(callback_);
  callback_ = Callback();

  blink::Threads::UI()->PostTask([callback, frameTimeNanos] {
    callback(ftl::TimePoint::FromEpochDelta(
        ftl::TimeDelta::FromNanoseconds(frameTimeNanos)));
  });
}

static void OnVsync(JNIEnv* env,
                    jclass jcaller,
                    jlong frameTimeNanos,
                    jlong cookie) {
  ftl::WeakPtr<VsyncWaiterAndroid>* weak =
      reinterpret_cast<ftl::WeakPtr<VsyncWaiterAndroid>*>(cookie);
  VsyncWaiterAndroid* waiter = weak->get();
  delete weak;
  if (waiter)
    waiter->OnVsync(frameTimeNanos);
}

bool VsyncWaiterAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace shell
