// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/profiler_metrics_ios.h"

namespace {

// RAII holder for `thread_array_t` this is so any early returns in
// `ProfilerMetricsIOS::CpuUsage` don't leak them.
class MachThreads {
 public:
  thread_array_t threads = NULL;
  mach_msg_type_number_t thread_count = 0;

  MachThreads() = default;

  ~MachThreads() {
    kern_return_t kernel_return_code = vm_deallocate(
        mach_task_self(), reinterpret_cast<vm_offset_t>(threads), thread_count * sizeof(thread_t));
    FML_CHECK(kernel_return_code == KERN_SUCCESS) << "Failed to deallocate thread infos.";
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MachThreads);
};

}

namespace flutter {

ProfileSample ProfilerMetricsIOS::GenerateSample() {
  return {.cpu_usage = CpuUsage()};
}

std::optional<CpuUsageInfo> ProfilerMetricsIOS::CpuUsage() {
  kern_return_t kernel_return_code;
  MachThreads mach_threads = MachThreads();

  // Get threads in the task
  kernel_return_code =
      task_threads(mach_task_self(), &mach_threads.threads, &mach_threads.thread_count);
  if (kernel_return_code != KERN_SUCCESS) {
    FML_LOG(ERROR) << "Error retrieving task information: "
                   << mach_error_string(kernel_return_code);
    return std::nullopt;
  }

  double total_cpu_usage = 0.0;

  // Add the CPU usage for each thread. It should be noted that there may be some CPU usage missing
  // from this calculation. If a thread ends between calls to this routine, then its info will be
  // lost. We could solve this by installing a callback using pthread_key_create. The callback would
  // report the thread is ending and allow the code to get the CPU usage. But we need to call
  // pthread_setspecific in each thread to set the key's value to a non-null value for the callback
  // to work. If we really need this information and if we have a good mechanism for calling
  // pthread_setspecific in every thread, then we can include that value in the CPU usage.
  for (mach_msg_type_number_t i = 0; i < mach_threads.thread_count; i++) {
    thread_basic_info_data_t basic_thread_info;
    mach_msg_type_number_t thread_info_count = THREAD_BASIC_INFO_COUNT;
    kernel_return_code =
        thread_info(mach_threads.threads[i], THREAD_BASIC_INFO,
                    reinterpret_cast<thread_info_t>(&basic_thread_info), &thread_info_count);
    if (kernel_return_code != KERN_SUCCESS) {
      FML_LOG(ERROR) << "Error retrieving thread information: "
                     << mach_error_string(kernel_return_code);
      return std::nullopt;
    }
    const double current_thread_cpu_usage =
        basic_thread_info.cpu_usage / static_cast<float>(TH_USAGE_SCALE);
    total_cpu_usage += current_thread_cpu_usage;
  }

  flutter::CpuUsageInfo cpu_usage_info = {.num_threads = mach_threads.thread_count,
                                          .total_cpu_usage = total_cpu_usage * 100.0};
  return cpu_usage_info;
}

}  // namespace flutter
