// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_android.h"

#include "base/at_exit.h"
#include "base/logging.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace android {

namespace {

base::subtle::AtomicWord g_atomic_id = 0;
int LazyMethodIDCall(JNIEnv* env, jclass clazz, int p) {
  jmethodID id = base::android::MethodID::LazyGet<
      base::android::MethodID::TYPE_STATIC>(
      env, clazz,
      "abs",
      "(I)I",
      &g_atomic_id);

  return env->CallStaticIntMethod(clazz, id, p);
}

int MethodIDCall(JNIEnv* env, jclass clazz, jmethodID id, int p) {
  return env->CallStaticIntMethod(clazz, id, p);
}

}  // namespace

TEST(JNIAndroidMicrobenchmark, MethodId) {
  JNIEnv* env = AttachCurrentThread();
  ScopedJavaLocalRef<jclass> clazz(GetClass(env, "java/lang/Math"));
  base::Time start_lazy = base::Time::Now();
  int o = 0;
  for (int i = 0; i < 1024; ++i)
    o += LazyMethodIDCall(env, clazz.obj(), i);
  base::Time end_lazy = base::Time::Now();

  jmethodID id = reinterpret_cast<jmethodID>(g_atomic_id);
  base::Time start = base::Time::Now();
  for (int i = 0; i < 1024; ++i)
    o += MethodIDCall(env, clazz.obj(), id, i);
  base::Time end = base::Time::Now();

  // On a Galaxy Nexus, results were in the range of:
  // JNI LazyMethodIDCall (us) 1984
  // JNI MethodIDCall (us) 1861
  LOG(ERROR) << "JNI LazyMethodIDCall (us) " <<
      base::TimeDelta(end_lazy - start_lazy).InMicroseconds();
  LOG(ERROR) << "JNI MethodIDCall (us) " <<
      base::TimeDelta(end - start).InMicroseconds();
  LOG(ERROR) << "JNI " << o;
}


}  // namespace android
}  // namespace base
