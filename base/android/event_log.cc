// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/event_log.h"
#include "jni/EventLog_jni.h"

namespace base {
namespace android {

void EventLogWriteInt(int tag, int value) {
  Java_EventLog_writeEvent(AttachCurrentThread(), tag, value);
}

bool RegisterEventLog(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
