// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterShell_Internal.h"

#include <pthread.h>
#include <memory>

#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/thread.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/profiler_metrics_ios.h"
#include "flutter/shell/profiling/sampling_profiler.h"

FLUTTER_ASSERT_ARC

namespace {

constexpr int kNumProfilerSamplesPerSec = 5;

/// Inheriting ThreadConfigurer and use iOS platform thread API to configure the thread priorities
/// Using iOS platform thread API to configure thread priority
void IOSPlatformThreadConfigSetter(const fml::Thread::ThreadConfig& config) {
  // set thread name
  fml::Thread::SetCurrentThreadName(config);

  // set thread priority
  switch (config.priority) {
    case fml::Thread::ThreadPriority::kBackground: {
      pthread_set_qos_class_self_np(QOS_CLASS_BACKGROUND, 0);
      [[NSThread currentThread] setThreadPriority:0];
      break;
    }
    case fml::Thread::ThreadPriority::kNormal: {
      pthread_set_qos_class_self_np(QOS_CLASS_DEFAULT, 0);
      [[NSThread currentThread] setThreadPriority:0.5];
      break;
    }
    case fml::Thread::ThreadPriority::kRaster:
    case fml::Thread::ThreadPriority::kDisplay: {
      pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
      [[NSThread currentThread] setThreadPriority:1.0];
      sched_param param{};
      int policy;
      pthread_t thread = pthread_self();
      if (!pthread_getschedparam(thread, &policy, &param)) {
        param.sched_priority = 50;
        pthread_setschedparam(thread, policy, &param);
      }
      break;
    }
  }
}

bool IsProfilerEnabled() {
  bool profilerEnabled = false;
#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG) || \
    (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE)
  profilerEnabled = true;
#endif
  return profilerEnabled;
}

NSString* GenerateThreadLabel(NSString* labelPrefix) {
  static size_t s_shellCount = 0;
  return [NSString stringWithFormat:@"%@.%zu", labelPrefix, ++s_shellCount];
}

flutter::ThreadHost MakeThreadHost(NSString* thread_label) {
  // The current thread will be used as the platform thread. Ensure that the message loop is
  // initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();

  // No dedicated UI thread is created: on iOS the UI thread is always merged onto the platform
  // thread. FlutterDartProject rejects any other threading configuration at startup.
  uint32_t threadHostType = flutter::ThreadHost::Type::kRaster | flutter::ThreadHost::Type::kIo;

  if (IsProfilerEnabled()) {
    threadHostType = threadHostType | flutter::ThreadHost::Type::kProfiler;
  }

  flutter::ThreadHost::ThreadHostConfig host_config(thread_label.UTF8String, threadHostType,
                                                    IOSPlatformThreadConfigSetter);

  host_config.raster_config =
      fml::Thread::ThreadConfig(flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
                                    flutter::ThreadHost::Type::kRaster, thread_label.UTF8String),
                                fml::Thread::ThreadPriority::kRaster);

  host_config.io_config =
      fml::Thread::ThreadConfig(flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
                                    flutter::ThreadHost::Type::kIo, thread_label.UTF8String),
                                fml::Thread::ThreadPriority::kNormal);

  return (flutter::ThreadHost){host_config};
}

}  // namespace

@implementation FlutterShell {
  std::shared_ptr<flutter::ThreadHost> _threadHost;
  std::shared_ptr<flutter::SamplingProfiler> _profiler;
}

- (instancetype)init {
  return [super init];
}

- (void)createThreadHostWithLabelPrefix:(NSString*)labelPrefix {
  FML_DCHECK(NSThread.isMainThread);
  _threadLabel = GenerateThreadLabel(labelPrefix);
  _threadHost = std::make_shared<flutter::ThreadHost>(MakeThreadHost(_threadLabel));
}

- (void)inheritThreadHostFromShell:(FlutterShell*)shell {
  FML_DCHECK(!_threadHost);
  _threadLabel = shell->_threadLabel;
  _threadHost = shell->_threadHost;
  _profiler = shell->_profiler;
}

- (void)startProfilerIfEnabled {
  if (!IsProfilerEnabled()) {
    return;
  }
  FML_DCHECK(_threadHost && !_threadHost->name_prefix.empty());
  _profiler = std::make_shared<flutter::SamplingProfiler>(
      _threadHost->name_prefix.c_str(), _threadHost->profiler_thread->GetTaskRunner(),
      []() {
        flutter::ProfilerMetricsIOS profiler_metrics;
        return profiler_metrics.GenerateSample();
      },
      kNumProfilerSamplesPerSec);
  _profiler->Start();
}

- (void)destroyThreadHost {
  _profiler.reset();
  _threadHost.reset();
  _threadLabel = nil;
}

- (const flutter::ThreadHost*)threadHost {
  return _threadHost.get();
}

@end
