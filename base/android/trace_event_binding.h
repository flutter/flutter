// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_TRACE_EVENT_BINDING_H_
#define BASE_ANDROID_TRACE_EVENT_BINDING_H_

#include <jni.h>

namespace base {
namespace android {

extern bool RegisterTraceEvent(JNIEnv* env);

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_TRACE_EVENT_BINDING_H_
