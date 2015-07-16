// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/java_handler_thread.h"

#include <jni.h>

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread_restrictions.h"
#include "jni/JavaHandlerThread_jni.h"

namespace base {

namespace android {

JavaHandlerThread::JavaHandlerThread(const char* name) {
  JNIEnv* env = base::android::AttachCurrentThread();

  java_thread_.Reset(Java_JavaHandlerThread_create(
      env, ConvertUTF8ToJavaString(env, name).Release()));
}

JavaHandlerThread::~JavaHandlerThread() {
}

void JavaHandlerThread::Start() {
  // Check the thread has not already been started.
  DCHECK(!message_loop_);

  JNIEnv* env = base::android::AttachCurrentThread();
  base::WaitableEvent initialize_event(false, false);
  Java_JavaHandlerThread_start(env,
                               java_thread_.obj(),
                               reinterpret_cast<intptr_t>(this),
                               reinterpret_cast<intptr_t>(&initialize_event));
  // Wait for thread to be initialized so it is ready to be used when Start
  // returns.
  base::ThreadRestrictions::ScopedAllowWait wait_allowed;
  initialize_event.Wait();
}

void JavaHandlerThread::Stop() {
  JNIEnv* env = base::android::AttachCurrentThread();
  base::WaitableEvent shutdown_event(false, false);
  Java_JavaHandlerThread_stop(env,
                              java_thread_.obj(),
                              reinterpret_cast<intptr_t>(this),
                              reinterpret_cast<intptr_t>(&shutdown_event));
  // Wait for thread to shut down before returning.
  base::ThreadRestrictions::ScopedAllowWait wait_allowed;
  shutdown_event.Wait();
}

void JavaHandlerThread::InitializeThread(JNIEnv* env, jobject obj,
                                         jlong event) {
  // TYPE_JAVA to get the Android java style message loop.
  message_loop_.reset(new base::MessageLoop(base::MessageLoop::TYPE_JAVA));
  static_cast<MessageLoopForUI*>(message_loop_.get())->Start();
  reinterpret_cast<base::WaitableEvent*>(event)->Signal();
}

void JavaHandlerThread::StopThread(JNIEnv* env, jobject obj, jlong event) {
  static_cast<MessageLoopForUI*>(message_loop_.get())->Quit();
  reinterpret_cast<base::WaitableEvent*>(event)->Signal();
}

// static
bool JavaHandlerThread::RegisterBindings(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

} // namespace android
} // namespace base
