// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/android/message_loop_android.h"

#include <fcntl.h>
#include <unistd.h>

#include "flutter/fml/platform/linux/timerfd.h"

namespace fml {

static constexpr int kClockType = CLOCK_MONOTONIC;

static fml::jni::ScopedJavaGlobalRef<jclass>* g_looper_class = nullptr;
static jmethodID g_looper_prepare_method_ = nullptr;
static jmethodID g_looper_loop_method_ = nullptr;
static jmethodID g_looper_my_looper_method_ = nullptr;
static jmethodID g_looper_quit_method_ = nullptr;

static void LooperPrepare() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  env->CallStaticVoidMethod(g_looper_class->obj(), g_looper_prepare_method_);
}

static void LooperLoop() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  env->CallStaticVoidMethod(g_looper_class->obj(), g_looper_loop_method_);
}

static void LooperQuit() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  auto my_looper = env->CallStaticObjectMethod(g_looper_class->obj(),
                                               g_looper_my_looper_method_);
  if (my_looper != nullptr) {
    env->CallVoidMethod(my_looper, g_looper_quit_method_);
  }
}

static ALooper* AcquireLooperForThread() {
  ALooper* looper = ALooper_forThread();

  if (looper == nullptr) {
    // No looper has been configured for the current thread. Create one and
    // return the same.
    looper = ALooper_prepare(0);
  }

  // The thread already has a looper. Acquire a reference to the same and return
  // it.
  ALooper_acquire(looper);
  return looper;
}

MessageLoopAndroid::MessageLoopAndroid()
    : looper_(AcquireLooperForThread()),
      timer_fd_(::timerfd_create(kClockType, TFD_NONBLOCK | TFD_CLOEXEC)),
      running_(false) {
  FML_CHECK(looper_.is_valid());
  FML_CHECK(timer_fd_.is_valid());

  static const int kWakeEvents = ALOOPER_EVENT_INPUT;

  ALooper_callbackFunc read_event_fd = [](int, int events, void* data) -> int {
    if (events & kWakeEvents) {
      reinterpret_cast<MessageLoopAndroid*>(data)->OnEventFired();
    }
    return 1;  // continue receiving callbacks
  };

  int add_result = ::ALooper_addFd(looper_.get(),          // looper
                                   timer_fd_.get(),        // fd
                                   ALOOPER_POLL_CALLBACK,  // ident
                                   kWakeEvents,            // events
                                   read_event_fd,          // callback
                                   this                    // baton
  );
  FML_CHECK(add_result == 1);
}

MessageLoopAndroid::~MessageLoopAndroid() {
  int remove_result = ::ALooper_removeFd(looper_.get(), timer_fd_.get());
  FML_CHECK(remove_result == 1);
}

void MessageLoopAndroid::Run() {
  FML_DCHECK(looper_.get() == ALooper_forThread());

  running_ = true;
  // Initialize the current thread as a looper.
  LooperPrepare();
  // Run the message queue in this thread.
  LooperLoop();
}

void MessageLoopAndroid::Terminate() {
  running_ = false;
  LooperQuit();
}

void MessageLoopAndroid::WakeUp(fml::TimePoint time_point) {
  [[maybe_unused]] bool result = TimerRearm(timer_fd_.get(), time_point);
  FML_DCHECK(result);
}

void MessageLoopAndroid::OnEventFired() {
  if (TimerDrain(timer_fd_.get())) {
    RunExpiredTasksNow();
  }
}

bool MessageLoopAndroid::Register(JNIEnv* env) {
  jclass clazz = env->FindClass("android/os/Looper");
  FML_CHECK(clazz != nullptr);

  g_looper_class = new fml::jni::ScopedJavaGlobalRef<jclass>(env, clazz);
  FML_CHECK(!g_looper_class->is_null());

  g_looper_prepare_method_ =
      env->GetStaticMethodID(g_looper_class->obj(), "prepare", "()V");
  FML_CHECK(g_looper_prepare_method_ != nullptr);

  g_looper_loop_method_ =
      env->GetStaticMethodID(g_looper_class->obj(), "loop", "()V");
  FML_CHECK(g_looper_loop_method_ != nullptr);

  g_looper_my_looper_method_ = env->GetStaticMethodID(
      g_looper_class->obj(), "myLooper", "()Landroid/os/Looper;");
  FML_CHECK(g_looper_my_looper_method_ != nullptr);

  g_looper_quit_method_ =
      env->GetMethodID(g_looper_class->obj(), "quit", "()V");
  FML_CHECK(g_looper_quit_method_ != nullptr);

  return true;
}

}  // namespace fml
