// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_JNI_WEAK_REF_H_
#define BASE_ANDROID_JNI_WEAK_REF_H_

#include <jni.h>

#include "base/android/scoped_java_ref.h"
#include "base/base_export.h"

// Manages WeakGlobalRef lifecycle.
// This class is not thread-safe w.r.t. get() and reset(). Multiple threads may
// safely use get() concurrently, but if the user calls reset() (or of course,
// calls the destructor) they'll need to provide their own synchronization.
class BASE_EXPORT JavaObjectWeakGlobalRef {
 public:
  JavaObjectWeakGlobalRef();
  JavaObjectWeakGlobalRef(const JavaObjectWeakGlobalRef& orig);
  JavaObjectWeakGlobalRef(JNIEnv* env, jobject obj);
  virtual ~JavaObjectWeakGlobalRef();

  void operator=(const JavaObjectWeakGlobalRef& rhs);

  base::android::ScopedJavaLocalRef<jobject> get(JNIEnv* env) const;

  bool is_empty() const { return obj_ == NULL; }

  void reset();

 private:
  void Assign(const JavaObjectWeakGlobalRef& rhs);

  jweak obj_;
};

// Get the real object stored in the weak reference returned as a
// ScopedJavaLocalRef.
BASE_EXPORT base::android::ScopedJavaLocalRef<jobject> GetRealObject(
    JNIEnv* env, jweak obj);

#endif  // BASE_ANDROID_JNI_WEAK_REF_H_
