// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_SERVICE_PROVIDER_ANDROID_H_
#define SKY_SHELL_PLATFORM_SERVICE_PROVIDER_ANDROID_H_

#include <jni.h>

namespace sky {
namespace shell {

bool RegisterPlatformServiceProvider(JNIEnv* env);

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_SERVICE_PROVIDER_ANDROID_H_
