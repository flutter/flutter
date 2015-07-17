// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/platform_thread.h"

#include <errno.h>
#include <sys/prctl.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <unistd.h>

#include "base/android/jni_android.h"
#include "base/android/thread_utils.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/threading/platform_thread_internal_posix.h"
#include "base/threading/thread_id_name_manager.h"
#include "base/tracked_objects.h"
#include "jni/ThreadUtils_jni.h"

namespace base {

namespace internal {

// - BACKGROUND is 9 due to it being the nicest value we can use that's still
// above an Android system threshold that enables heavy throttling starting at
// 10; we want to be lower-priority than Chrome's other threads without
// incurring this behavior.
// - DISPLAY is -6 due to being midway between Android's DISPLAY (-4) and
// URGENT_DISPLAY (-8).
// - REALTIME_AUDIO corresponds to Android's THREAD_PRIORITY_AUDIO = -16 value.
const ThreadPriorityToNiceValuePair kThreadPriorityToNiceValueMap[4] = {
    {ThreadPriority::BACKGROUND, 9},
    {ThreadPriority::NORMAL, 0},
    {ThreadPriority::DISPLAY, -6},
    {ThreadPriority::REALTIME_AUDIO, -16},
};

bool SetCurrentThreadPriorityForPlatform(ThreadPriority priority) {
  // On Android, we set the Audio priority through JNI as Audio priority
  // will also allow the process to run while it is backgrounded.
  if (priority == ThreadPriority::REALTIME_AUDIO) {
    JNIEnv* env = base::android::AttachCurrentThread();
    Java_ThreadUtils_setThreadPriorityAudio(env, PlatformThread::CurrentId());
    return true;
  }
  return false;
}

bool GetCurrentThreadPriorityForPlatform(ThreadPriority* priority) {
  // See http://crbug.com/505474.
  NOTIMPLEMENTED();
  return false;
}

}  // namespace internal

void PlatformThread::SetName(const std::string& name) {
  ThreadIdNameManager::GetInstance()->SetName(CurrentId(), name);
  tracked_objects::ThreadData::InitializeThreadContext(name);

  // Like linux, on android we can get the thread names to show up in the
  // debugger by setting the process name for the LWP.
  // We don't want to do this for the main thread because that would rename
  // the process, causing tools like killall to stop working.
  if (PlatformThread::CurrentId() == getpid())
    return;

  // Set the name for the LWP (which gets truncated to 15 characters).
  int err = prctl(PR_SET_NAME, name.c_str());
  if (err < 0 && errno != EPERM)
    DPLOG(ERROR) << "prctl(PR_SET_NAME)";
}


void InitThreading() {
}

void InitOnThread() {
  // Threads on linux/android may inherit their priority from the thread
  // where they were created. This sets all new threads to the default.
  PlatformThread::SetCurrentThreadPriority(ThreadPriority::NORMAL);
}

void TerminateOnThread() {
  base::android::DetachFromVM();
}

size_t GetDefaultThreadStackSize(const pthread_attr_t& attributes) {
#if !defined(ADDRESS_SANITIZER)
  return 0;
#else
  // AddressSanitizer bloats the stack approximately 2x. Default stack size of
  // 1Mb is not enough for some tests (see http://crbug.com/263749 for example).
  return 2 * (1 << 20);  // 2Mb
#endif
}

bool RegisterThreadUtils(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace base
