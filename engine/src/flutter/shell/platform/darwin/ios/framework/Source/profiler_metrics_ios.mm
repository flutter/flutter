// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/profiler_metrics_ios.h"

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/IOKit.h"

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
namespace {

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE

template <typename T>
T ClearValue() {
  return nullptr;
}

template <>
io_object_t ClearValue<io_object_t>() {
  return 0;
}

template <typename T>
/// Generic RAII wrapper like unique_ptr but gives access to its handle.
class Scoped {
 public:
  typedef void (*Deleter)(T);
  explicit Scoped(Deleter deleter) : object_(ClearValue<T>()), deleter_(deleter) {}
  Scoped(T object, Deleter deleter) : object_(object), deleter_(deleter) {}
  ~Scoped() {
    if (object_) {
      deleter_(object_);
    }
  }
  T* handle() {
    if (object_) {
      deleter_(object_);
      object_ = ClearValue<T>();
    }
    return &object_;
  }
  T get() { return object_; }
  void reset(T new_value) {
    if (object_) {
      deleter_(object_);
    }
    object_ = new_value;
  }

 private:
  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(Scoped);
  T object_;
  Deleter deleter_;
};

void DeleteCF(CFMutableDictionaryRef value) {
  CFRelease(value);
}

void DeleteIO(io_object_t value) {
  IOObjectRelease(value);
}

std::optional<GpuUsageInfo> FindGpuUsageInfo(io_iterator_t iterator) {
  for (Scoped<io_registry_entry_t> regEntry(IOIteratorNext(iterator), DeleteIO); regEntry.get();
       regEntry.reset(IOIteratorNext(iterator))) {
    Scoped<CFMutableDictionaryRef> serviceDictionary(DeleteCF);
    if (IORegistryEntryCreateCFProperties(regEntry.get(), serviceDictionary.handle(),
                                          kCFAllocatorDefault, kNilOptions) != kIOReturnSuccess) {
      continue;
    }

    NSDictionary* dictionary =
        ((__bridge NSDictionary*)serviceDictionary.get())[@"PerformanceStatistics"];
    NSNumber* utilization = dictionary[@"Device Utilization %"];
    if (utilization) {
      return (GpuUsageInfo){.percent_usage = [utilization doubleValue]};
    }
  }
  return std::nullopt;
}

[[maybe_unused]] std::optional<GpuUsageInfo> FindSimulatorGpuUsageInfo() {
  Scoped<io_iterator_t> iterator(DeleteIO);
  if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("IntelAccelerator"),
                                   iterator.handle()) == kIOReturnSuccess) {
    return FindGpuUsageInfo(iterator.get());
  }
  return std::nullopt;
}

[[maybe_unused]] std::optional<GpuUsageInfo> FindDeviceGpuUsageInfo() {
  Scoped<io_iterator_t> iterator(DeleteIO);
  if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceNameMatching("sgx"),
                                   iterator.handle()) == kIOReturnSuccess) {
    for (Scoped<io_registry_entry_t> regEntry(IOIteratorNext(iterator.get()), DeleteIO);
         regEntry.get(); regEntry.reset(IOIteratorNext(iterator.get()))) {
      Scoped<io_iterator_t> innerIterator(DeleteIO);
      if (IORegistryEntryGetChildIterator(regEntry.get(), kIOServicePlane,
                                          innerIterator.handle()) == kIOReturnSuccess) {
        std::optional<GpuUsageInfo> result = FindGpuUsageInfo(innerIterator.get());
        if (result.has_value()) {
          return result;
        }
      }
    }
  }
  return std::nullopt;
}

#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG ||
        // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE

std::optional<GpuUsageInfo> PollGpuUsage() {
#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE || \
     FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_JIT_RELEASE)
  return std::nullopt;
#elif TARGET_IPHONE_SIMULATOR
  return FindSimulatorGpuUsageInfo();
#elif TARGET_OS_IOS
  return FindDeviceGpuUsageInfo();
#endif  // TARGET_IPHONE_SIMULATOR
}
}  // namespace

ProfileSample ProfilerMetricsIOS::GenerateSample() {
  return {.cpu_usage = CpuUsage(), .memory_usage = MemoryUsage(), .gpu_usage = PollGpuUsage()};
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
  uint32_t num_threads = mach_threads.thread_count;

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
    switch (kernel_return_code) {
      case KERN_SUCCESS: {
        const double current_thread_cpu_usage =
            basic_thread_info.cpu_usage / static_cast<float>(TH_USAGE_SCALE);
        total_cpu_usage += current_thread_cpu_usage;
        break;
      }
      case MACH_SEND_TIMEOUT:
      case MACH_SEND_TIMED_OUT:
      case MACH_SEND_INVALID_DEST:
        // Ignore as this thread been destroyed. The possible return codes are not really well
        // documented. This handling is inspired from the following sources:
        // - https://opensource.apple.com/source/xnu/xnu-4903.221.2/tests/task_inspect.c.auto.html
        // - https://github.com/apple/swift-corelibs-libdispatch/blob/main/src/queue.c#L6617
        num_threads--;
        break;
      default:
        FML_LOG(ERROR) << "Error retrieving thread information: "
                       << mach_error_string(kernel_return_code);
        return std::nullopt;
    }
  }

  flutter::CpuUsageInfo cpu_usage_info = {.num_threads = num_threads,
                                          .total_cpu_usage = total_cpu_usage * 100.0};
  return cpu_usage_info;
}

std::optional<MemoryUsageInfo> ProfilerMetricsIOS::MemoryUsage() {
  kern_return_t kernel_return_code;
  task_vm_info_data_t task_memory_info;
  mach_msg_type_number_t task_memory_info_count = TASK_VM_INFO_COUNT;

  kernel_return_code =
      task_info(mach_task_self(), TASK_VM_INFO, reinterpret_cast<task_info_t>(&task_memory_info),
                &task_memory_info_count);
  if (kernel_return_code != KERN_SUCCESS) {
    FML_LOG(ERROR) << " Error retrieving task memory information: "
                   << mach_error_string(kernel_return_code);
    return std::nullopt;
  }

  // `phys_footprint` is Apple's recommended way to measure app's memory usage. It provides the
  // best approximate to xcode memory gauge. According to its source code explanation, the physical
  // footprint mainly consists of app's internal memory data and IOKit mappings. `resident_size`
  // is the total physical memory used by the app, so we simply do `resident_size - phys_footprint`
  // to obtain the shared memory usage.
  const double dirty_memory_usage =
      static_cast<double>(task_memory_info.phys_footprint) / 1024.0 / 1024.0;
  const double owned_shared_memory_usage =
      static_cast<double>(task_memory_info.resident_size) / 1024.0 / 1024.0 - dirty_memory_usage;
  flutter::MemoryUsageInfo memory_usage_info = {
      .dirty_memory_usage = dirty_memory_usage,
      .owned_shared_memory_usage = owned_shared_memory_usage};
  return memory_usage_info;
}

}  // namespace flutter
