// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_TRACING_CONTROLLER_H_
#define SKY_SHELL_TRACING_CONTROLLER_H_

#include "base/android/jni_weak_ref.h"
#include "base/android/scoped_java_ref.h"

namespace sky {
namespace shell {

bool RegisterTracingController(JNIEnv* env);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_TRACING_CONTROLLER_H_
