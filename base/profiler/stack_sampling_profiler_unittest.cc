// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/compiler_specific.h"
#include "base/path_service.h"
#include "base/profiler/stack_sampling_profiler.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/platform_thread.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

using SamplingParams = StackSamplingProfiler::SamplingParams;
using Frame = StackSamplingProfiler::Frame;
using Module = StackSamplingProfiler::Module;
using Sample = StackSamplingProfiler::Sample;
using CallStackProfile = StackSamplingProfiler::CallStackProfile;
using CallStackProfiles = StackSamplingProfiler::CallStackProfiles;

namespace {

// A thread to target for profiling, whose stack is guaranteed to contain
// SignalAndWaitUntilSignaled() when coordinated with the main thread.
class TargetThread : public PlatformThread::Delegate {
 public:
  TargetThread();

  // PlatformThread::Delegate:
  void ThreadMain() override;

  // Waits for the thread to have started and be executing in
  // SignalAndWaitUntilSignaled().
  void WaitForThreadStart();

  // Allows the thread to return from SignalAndWaitUntilSignaled() and finish
  // execution.
  void SignalThreadToFinish();

  // This function is guaranteed to be executing between calls to
  // WaitForThreadStart() and SignalThreadToFinish(). This function is static so
  // that we can get a straightforward address for it in one of the tests below,
  // rather than dealing with the complexity of a member function pointer
  // representation.
  static void SignalAndWaitUntilSignaled(WaitableEvent* thread_started_event,
                                         WaitableEvent* finish_event);

  PlatformThreadId id() const { return id_; }

 private:
  WaitableEvent thread_started_event_;
  WaitableEvent finish_event_;
  PlatformThreadId id_;

  DISALLOW_COPY_AND_ASSIGN(TargetThread);
};

TargetThread::TargetThread()
    : thread_started_event_(false, false), finish_event_(false, false),
      id_(0) {}

void TargetThread::ThreadMain() {
  id_ = PlatformThread::CurrentId();
  SignalAndWaitUntilSignaled(&thread_started_event_, &finish_event_);
}

void TargetThread::WaitForThreadStart() {
  thread_started_event_.Wait();
}

void TargetThread::SignalThreadToFinish() {
  finish_event_.Signal();
}

// static
// Disable inlining for this function so that it gets its own stack frame.
NOINLINE void TargetThread::SignalAndWaitUntilSignaled(
    WaitableEvent* thread_started_event,
    WaitableEvent* finish_event) {
  thread_started_event->Signal();
  volatile int x = 1;
  finish_event->Wait();
  x = 0;  // Prevent tail call to WaitableEvent::Wait().
  ALLOW_UNUSED_LOCAL(x);
}

// Called on the profiler thread when complete, to collect profiles.
void SaveProfiles(CallStackProfiles* profiles,
                  const CallStackProfiles& pending_profiles) {
  *profiles = pending_profiles;
}

// Called on the profiler thread when complete. Collects profiles produced by
// the profiler, and signals an event to allow the main thread to know that that
// the profiler is done.
void SaveProfilesAndSignalEvent(CallStackProfiles* profiles,
                                WaitableEvent* event,
                                const CallStackProfiles& pending_profiles) {
  *profiles = pending_profiles;
  event->Signal();
}

// Executes the function with the target thread running and executing within
// SignalAndWaitUntilSignaled(). Performs all necessary target thread startup
// and shutdown work before and afterward.
template <class Function>
void WithTargetThread(Function function) {
  TargetThread target_thread;
  PlatformThreadHandle target_thread_handle;
  EXPECT_TRUE(PlatformThread::Create(0, &target_thread, &target_thread_handle));

  target_thread.WaitForThreadStart();

  function(target_thread.id());

  target_thread.SignalThreadToFinish();

  PlatformThread::Join(target_thread_handle);
}

// Captures profiles as specified by |params| on the TargetThread, and returns
// them in |profiles|. Waits up to |profiler_wait_time| for the profiler to
// complete.
void CaptureProfilesWithObjectCallback(const SamplingParams& params,
                                       CallStackProfiles* profiles,
                                       TimeDelta profiler_wait_time) {
  profiles->clear();

  WithTargetThread([&params, profiles, profiler_wait_time](
      PlatformThreadId target_thread_id) {
    WaitableEvent sampling_thread_completed(true, false);
    const StackSamplingProfiler::CompletedCallback callback =
        Bind(&SaveProfilesAndSignalEvent, Unretained(profiles),
             Unretained(&sampling_thread_completed));
    StackSamplingProfiler profiler(target_thread_id, params, callback);
    profiler.Start();
    sampling_thread_completed.TimedWait(profiler_wait_time);
    profiler.Stop();
    sampling_thread_completed.Wait();
  });
}

// Captures profiles as specified by |params| on the TargetThread, and returns
// them in |profiles|. Uses the default callback rather than a per-object
// callback.
void CaptureProfilesWithDefaultCallback(const SamplingParams& params,
                                        CallStackProfiles* profiles) {
  profiles->clear();

  WithTargetThread([&params, profiles](PlatformThreadId target_thread_id) {
    WaitableEvent sampling_thread_completed(false, false);
    StackSamplingProfiler::SetDefaultCompletedCallback(
        Bind(&SaveProfilesAndSignalEvent, Unretained(profiles),
             Unretained(&sampling_thread_completed)));

    StackSamplingProfiler profiler(target_thread_id, params);
    profiler.Start();
    sampling_thread_completed.Wait();

    StackSamplingProfiler::SetDefaultCompletedCallback(
        StackSamplingProfiler::CompletedCallback());
  });
}

// Runs the profiler with |params| on the TargetThread, with no default or
// per-object callback.
void RunProfilerWithNoCallback(const SamplingParams& params,
                               TimeDelta profiler_wait_time) {
  WithTargetThread([&params, profiler_wait_time](
      PlatformThreadId target_thread_id) {
    StackSamplingProfiler profiler(target_thread_id, params);
    profiler.Start();
    // Since we don't specify a callback, we don't have a synchronization
    // mechanism with the sampling thread. Just sleep instead.
    PlatformThread::Sleep(profiler_wait_time);
    profiler.Stop();
  });
}

// If this executable was linked with /INCREMENTAL (the default for non-official
// debug and release builds on Windows), function addresses do not correspond to
// function code itself, but instead to instructions in the Incremental Link
// Table that jump to the functions. Checks for a jump instruction and if
// present does a little decompilation to find the function's actual starting
// address.
const void* MaybeFixupFunctionAddressForILT(const void* function_address) {
#if defined(_WIN64)
  const unsigned char* opcode =
      reinterpret_cast<const unsigned char*>(function_address);
  if (*opcode == 0xe9) {
    // This is a relative jump instruction. Assume we're in the ILT and compute
    // the function start address from the instruction offset.
    const int32* offset = reinterpret_cast<const int32*>(opcode + 1);
    const unsigned char* next_instruction =
        reinterpret_cast<const unsigned char*>(offset + 1);
    return next_instruction + *offset;
  }
#endif
  return function_address;
}

// Searches through the frames in |sample|, returning an iterator to the first
// frame that has an instruction pointer between |function_address| and
// |function_address| + |size|. Returns sample.end() if no such frames are
// found.
Sample::const_iterator FindFirstFrameWithinFunction(
    const Sample& sample,
    const void* function_address,
    int function_size) {
  function_address = MaybeFixupFunctionAddressForILT(function_address);
  for (auto it = sample.begin(); it != sample.end(); ++it) {
    if ((it->instruction_pointer >= function_address) &&
        (it->instruction_pointer <
         (static_cast<const unsigned char*>(function_address) + function_size)))
      return it;
  }
  return sample.end();
}

// Formats a sample into a string that can be output for test diagnostics.
std::string FormatSampleForDiagnosticOutput(
    const Sample& sample,
    const std::vector<Module>& modules) {
  std::string output;
  for (const Frame& frame: sample) {
    output += StringPrintf(
        "0x%p %s\n", frame.instruction_pointer,
        modules[frame.module_index].filename.AsUTF8Unsafe().c_str());
  }
  return output;
}

// Returns a duration that is longer than the test timeout. We would use
// TimeDelta::Max() but https://crbug.com/465948.
TimeDelta AVeryLongTimeDelta() { return TimeDelta::FromDays(1); }

}  // namespace


// The tests below are enabled for Win x64 only, pending implementation of the
// tested functionality on other platforms/architectures.

// Checks that the basic expected information is present in a sampled call stack
// profile.
#if defined(_WIN64)
#define MAYBE_Basic Basic
#else
#define MAYBE_Basic DISABLED_Basic
#endif
TEST(StackSamplingProfilerTest, MAYBE_Basic) {
  SamplingParams params;
  params.sampling_interval = TimeDelta::FromMilliseconds(0);
  params.samples_per_burst = 1;
  params.user_data = 100;
  params.preserve_sample_ordering = true;

  std::vector<CallStackProfile> profiles;
  CaptureProfilesWithObjectCallback(params, &profiles, AVeryLongTimeDelta());

  // Check that the profile and samples sizes are correct, and the module
  // indices are in range.
  ASSERT_EQ(1u, profiles.size());
  const CallStackProfile& profile = profiles[0];
  ASSERT_EQ(1u, profile.samples.size());
  EXPECT_EQ(params.sampling_interval, profile.sampling_period);
  const Sample& sample = profile.samples[0];
  for (const auto& frame : sample) {
    ASSERT_GE(frame.module_index, 0u);
    ASSERT_LT(frame.module_index, profile.modules.size());
  }
  EXPECT_EQ(100u, profile.user_data);
  EXPECT_EQ(true, profile.preserve_sample_ordering);

  // Check that the stack contains a frame for
  // TargetThread::SignalAndWaitUntilSignaled() and that the frame has this
  // executable's module.
  //
  // Since we don't have a good way to know the function size, use 100 bytes as
  // a reasonable window to locate the instruction pointer.
  Sample::const_iterator loc = FindFirstFrameWithinFunction(
      sample,
      reinterpret_cast<const void*>(&TargetThread::SignalAndWaitUntilSignaled),
      100);
  ASSERT_TRUE(loc != sample.end())
      << "Function at "
      << MaybeFixupFunctionAddressForILT(
          reinterpret_cast<const void*>(
              &TargetThread::SignalAndWaitUntilSignaled))
      << " was not found in stack:\n"
      << FormatSampleForDiagnosticOutput(sample, profile.modules);
  FilePath executable_path;
  EXPECT_TRUE(PathService::Get(FILE_EXE, &executable_path));
  EXPECT_EQ(executable_path, profile.modules[loc->module_index].filename);
}

// Checks that the expected number of profiles and samples are present in the
// call stack profiles produced.
#if defined(_WIN64)
#define MAYBE_MultipleProfilesAndSamples MultipleProfilesAndSamples
#else
#define MAYBE_MultipleProfilesAndSamples DISABLED_MultipleProfilesAndSamples
#endif
TEST(StackSamplingProfilerTest, MAYBE_MultipleProfilesAndSamples) {
  SamplingParams params;
  params.burst_interval = params.sampling_interval =
      TimeDelta::FromMilliseconds(0);
  params.bursts = 2;
  params.samples_per_burst = 3;

  std::vector<CallStackProfile> profiles;
  CaptureProfilesWithObjectCallback(params, &profiles, AVeryLongTimeDelta());

  ASSERT_EQ(2u, profiles.size());
  EXPECT_EQ(3u, profiles[0].samples.size());
  EXPECT_EQ(3u, profiles[1].samples.size());
}

// Checks that no call stack profiles are captured if the profiling is stopped
// during the initial delay.
#if defined(_WIN64)
#define MAYBE_StopDuringInitialDelay StopDuringInitialDelay
#else
#define MAYBE_StopDuringInitialDelay DISABLED_StopDuringInitialDelay
#endif
TEST(StackSamplingProfilerTest, MAYBE_StopDuringInitialDelay) {
  SamplingParams params;
  params.initial_delay = TimeDelta::FromSeconds(60);

  std::vector<CallStackProfile> profiles;
  CaptureProfilesWithObjectCallback(params, &profiles,
                                    TimeDelta::FromMilliseconds(0));

  EXPECT_TRUE(profiles.empty());
}

// Checks that the single completed call stack profile is captured if the
// profiling is stopped between bursts.
#if defined(_WIN64)
#define MAYBE_StopDuringInterBurstInterval StopDuringInterBurstInterval
#else
#define MAYBE_StopDuringInterBurstInterval DISABLED_StopDuringInterBurstInterval
#endif
TEST(StackSamplingProfilerTest, MAYBE_StopDuringInterBurstInterval) {
  SamplingParams params;
  params.sampling_interval = TimeDelta::FromMilliseconds(0);
  params.burst_interval = TimeDelta::FromSeconds(60);
  params.bursts = 2;
  params.samples_per_burst = 1;

  std::vector<CallStackProfile> profiles;
  CaptureProfilesWithObjectCallback(params, &profiles,
                                    TimeDelta::FromMilliseconds(50));

  ASSERT_EQ(1u, profiles.size());
  EXPECT_EQ(1u, profiles[0].samples.size());
}

// Checks that only completed call stack profiles are captured.
#if defined(_WIN64)
#define MAYBE_StopDuringInterSampleInterval StopDuringInterSampleInterval
#else
#define MAYBE_StopDuringInterSampleInterval \
  DISABLED_StopDuringInterSampleInterval
#endif
TEST(StackSamplingProfilerTest, MAYBE_StopDuringInterSampleInterval) {
  SamplingParams params;
  params.sampling_interval = TimeDelta::FromSeconds(60);
  params.samples_per_burst = 2;

  std::vector<CallStackProfile> profiles;
  CaptureProfilesWithObjectCallback(params, &profiles,
                                    TimeDelta::FromMilliseconds(50));

  EXPECT_TRUE(profiles.empty());
}

// Checks that profiles are captured via the default completed callback.
#if defined(_WIN64)
#define MAYBE_DefaultCallback DefaultCallback
#else
#define MAYBE_DefaultCallback DISABLED_DefaultCallback
#endif
TEST(StackSamplingProfilerTest, MAYBE_DefaultCallback) {
  SamplingParams params;
  params.samples_per_burst = 1;

  CallStackProfiles profiles;
  CaptureProfilesWithDefaultCallback(params, &profiles);

  EXPECT_EQ(1u, profiles.size());
  EXPECT_EQ(1u, profiles[0].samples.size());
}

// Checks that profiles are queued until a default callback is set, then
// delivered.
#if defined(_WIN64)
#define MAYBE_ProfilesQueuedWithNoCallback ProfilesQueuedWithNoCallback
#else
#define MAYBE_ProfilesQueuedWithNoCallback DISABLED_ProfilesQueuedWithNoCallback
#endif
TEST(StackSamplingProfilerTest, MAYBE_ProfilesQueuedWithNoCallback) {
  SamplingParams params;
  params.samples_per_burst = 1;

  RunProfilerWithNoCallback(params, TimeDelta::FromMilliseconds(50));

  CallStackProfiles profiles;
  // This should immediately call SaveProfiles on this thread.
  StackSamplingProfiler::SetDefaultCompletedCallback(
      Bind(&SaveProfiles, Unretained(&profiles)));
  EXPECT_EQ(1u, profiles.size());
  EXPECT_EQ(1u, profiles[0].samples.size());
  StackSamplingProfiler::SetDefaultCompletedCallback(
      StackSamplingProfiler::CompletedCallback());
}

// Checks that we can destroy the profiler while profiling.
#if defined(_WIN64)
#define MAYBE_DestroyProfilerWhileProfiling DestroyProfilerWhileProfiling
#else
#define MAYBE_DestroyProfilerWhileProfiling \
  DISABLED_DestroyProfilerWhileProfiling
#endif
TEST(StackSamplingProfilerTest, MAYBE_DestroyProfilerWhileProfiling) {
  SamplingParams params;
  params.sampling_interval = TimeDelta::FromMilliseconds(10);

  CallStackProfiles profiles;
  WithTargetThread([&params, &profiles](PlatformThreadId target_thread_id) {
    scoped_ptr<StackSamplingProfiler> profiler;
    profiler.reset(new StackSamplingProfiler(
        target_thread_id, params, Bind(&SaveProfiles, Unretained(&profiles))));
    profiler->Start();
    profiler.reset();

    // Wait longer than a sample interval to catch any use-after-free actions by
    // the profiler thread.
    PlatformThread::Sleep(TimeDelta::FromMilliseconds(50));
  });
}

}  // namespace base
