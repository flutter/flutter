// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_weak_ref.h"

#include "base/android/jni_android.h"
#include "base/logging.h"

using base::android::AttachCurrentThread;

JavaObjectWeakGlobalRef::JavaObjectWeakGlobalRef()
  : obj_(NULL) {
}

JavaObjectWeakGlobalRef::JavaObjectWeakGlobalRef(
    const JavaObjectWeakGlobalRef& orig)
    : obj_(NULL) {
  Assign(orig);
}

JavaObjectWeakGlobalRef::JavaObjectWeakGlobalRef(JNIEnv* env, jobject obj)
    : obj_(env->NewWeakGlobalRef(obj)) {
  DCHECK(obj_);
}

JavaObjectWeakGlobalRef::~JavaObjectWeakGlobalRef() {
  reset();
}

void JavaObjectWeakGlobalRef::operator=(const JavaObjectWeakGlobalRef& rhs) {
  Assign(rhs);
}

void JavaObjectWeakGlobalRef::reset() {
  if (obj_) {
    AttachCurrentThread()->DeleteWeakGlobalRef(obj_);
    obj_ = NULL;
  }
}

base::android::ScopedJavaLocalRef<jobject>
    JavaObjectWeakGlobalRef::get(JNIEnv* env) const {
  return GetRealObject(env, obj_);
}

base::android::ScopedJavaLocalRef<jobject> GetRealObject(
    JNIEnv* env, jweak obj) {
  jobject real = NULL;
  if (obj) {
    real = env->NewLocalRef(obj);
    if (!real)
      DLOG(ERROR) << "The real object has been deleted!";
  }
  return base::android::ScopedJavaLocalRef<jobject>(env, real);
}

void JavaObjectWeakGlobalRef::Assign(const JavaObjectWeakGlobalRef& other) {
  if (&other == this)
    return;

  JNIEnv* env = AttachCurrentThread();
  if (obj_)
    env->DeleteWeakGlobalRef(obj_);

  obj_ = other.obj_ ? env->NewWeakGlobalRef(other.obj_) : NULL;
}
