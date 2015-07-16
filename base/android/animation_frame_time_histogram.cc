// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/animation_frame_time_histogram.h"

#include "base/android/jni_string.h"
#include "base/metrics/histogram_macros.h"
#include "jni/AnimationFrameTimeHistogram_jni.h"

// static
void SaveHistogram(JNIEnv* env,
                   jobject jcaller,
                   jstring j_histogram_name,
                   jlongArray j_frame_times_ms,
                   jint j_count) {
  jlong *frame_times_ms = env->GetLongArrayElements(j_frame_times_ms, NULL);
  std::string histogram_name = base::android::ConvertJavaStringToUTF8(
      env, j_histogram_name);

  for (int i = 0; i < j_count; ++i) {
    UMA_HISTOGRAM_TIMES(histogram_name.c_str(),
                        base::TimeDelta::FromMilliseconds(frame_times_ms[i]));
  }
}

namespace base {
namespace android {

// static
bool RegisterAnimationFrameTimeHistogram(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
