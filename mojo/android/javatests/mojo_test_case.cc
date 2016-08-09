// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/android/javatests/mojo_test_case.h"

#include "base/android/jni_android.h"
#include "base/android/scoped_java_ref.h"
#include "base/at_exit.h"
#include "base/bind.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/test/test_support_android.h"
#include "jni/MojoTestCase_jni.h"
#include "mojo/message_pump/message_pump_mojo.h"

#include "mojo/public/cpp/environment/environment.h"

namespace {

struct TestEnvironment {
  TestEnvironment() : message_loop(mojo::common::MessagePumpMojo::Create()) {}

  base::ShadowingAtExitManager at_exit;
  base::MessageLoop message_loop;
};

}  // namespace

namespace mojo {
namespace android {

static void InitApplicationContext(JNIEnv* env,
                                   const JavaParamRef<jobject>& jcaller,
                                   const JavaParamRef<jobject>& context) {
  base::android::InitApplicationContext(env, context);
  base::InitAndroidTestMessageLoop();
}

static jlong SetupTestEnvironment(JNIEnv* env,
                                  const JavaParamRef<jobject>& jcaller) {
  return reinterpret_cast<intptr_t>(new TestEnvironment());
}

static void TearDownTestEnvironment(JNIEnv* env,
                                    const JavaParamRef<jobject>& jcaller,
                                    jlong test_environment) {
  delete reinterpret_cast<TestEnvironment*>(test_environment);
}

static void RunLoop(JNIEnv* env,
                    const JavaParamRef<jobject>& jcaller,
                    jlong timeout_ms) {
  base::RunLoop run_loop;
  if (timeout_ms) {
    base::MessageLoop::current()->PostDelayedTask(
        FROM_HERE,
        base::MessageLoop::QuitClosure(),
        base::TimeDelta::FromMilliseconds(timeout_ms));
    run_loop.Run();
  } else {
    run_loop.RunUntilIdle();
  }
}

bool RegisterMojoTestCase(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace mojo
