// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SERVICE_PROVIDER_IMPL_H_
#define SKY_SHELL_SERVICE_PROVIDER_IMPL_H_

#include <jni.h>
#include "mojo/public/cpp/system/core.h"

namespace sky {
namespace shell {

bool RegisterJavaServiceProvider(JNIEnv* env);
mojo::ScopedMessagePipeHandle CreateJavaServiceProvider();

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SERVICE_PROVIDER_IMPL_H_
