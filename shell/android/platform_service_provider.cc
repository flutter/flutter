// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/android/platform_service_provider.h"

#include "base/android/jni_android.h"
#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "jni/PlatformServiceProvider_jni.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "sky/shell/service_provider.h"

namespace sky {
namespace shell {
namespace {

void CreatePlatformServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request) {
  Java_PlatformServiceProvider_create(
      base::android::AttachCurrentThread(),
      base::android::GetApplicationContext(),
      request.PassMessagePipe().release().value());
}

} // namespace

bool RegisterPlatformServiceProvider(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

mojo::ServiceProviderPtr CreateServiceProvider(
        ServiceProviderContext* context) {
  mojo::MessagePipe pipe;
  context->java_task_runner->PostTask(
      FROM_HERE,
      base::Bind(CreatePlatformServiceProvider,
                 base::Passed(mojo::MakeRequest<mojo::ServiceProvider>(
                     pipe.handle1.Pass()))));
  return mojo::MakeProxy(
      mojo::InterfacePtrInfo<mojo::ServiceProvider>(pipe.handle0.Pass(), 0u));
}

}  // namespace shell
}  // namespace sky
