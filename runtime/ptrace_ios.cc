// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// It is __imperative__ that the functions in this file are __not__ included in
// release or profile builds.
//
// They call into the "private" ptrace() API to ensure that the current process
// is being ptrace()-d. Only debug builds rely on ptrace(), and the ptrace() API
// is not allowed for use in the App Store, so we must exclude it from profile-
// and release-builds.
//
// When an app is launched from a host workstation (e.g. via Xcode or
// "ios-deploy"), the process is already ptrace()-d by debugserver. However,
// when an app is launched from the home screen, it is not, so for debug builds
// we initialize the ptrace() relationship via PT_TRACE_ME if necessary.
//
// Please see the following documents for more details:
//   - go/decommissioning-dbc
//   - go/decommissioning-dbc-engine
//   - go/decommissioning-dbc-tools
#include "flutter/common/settings.h"
#include "flutter/fml/build_config.h"  // For OS_IOS.

#if OS_IOS && (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG)

// These headers should only be needed in debug mode.
#include <sys/sysctl.h>
#include <sys/types.h>

#define PT_TRACE_ME 0
#define PT_SIGEXC 12
extern "C" int ptrace(int request, pid_t pid, caddr_t addr, int data);

static bool DebuggedIOS(const flutter::Settings& vm_settings) {
  // Only the Flutter CLI passes "--enable-checked-mode". Therefore, if the flag
  // is present, we have been launched by "ios-deploy" via "debugserver".
  //
  // We choose this flag because it is always passed to launch debug builds.
  if (vm_settings.enable_checked_mode) {
    return true;
  }

  // Use "sysctl()" to check if we're currently being debugged (e.g. by Xcode).
  // We could also check "getppid() != 1" (launchd), but this is more direct.
  const pid_t self = getpid();
  int mib[5] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, self, 0};

  auto proc = std::make_unique<struct kinfo_proc>();
  size_t proc_size = sizeof(struct kinfo_proc);
  if (sysctl(mib, 4, proc.get(), &proc_size, nullptr, 0) < 0) {
    FML_LOG(ERROR) << "Could not execute sysctl() to get current process info: "
                   << strerror(errno);
    return false;
  }

  return proc->kp_proc.p_flag & P_TRACED;
}

void EnsureDebuggedIOS(const flutter::Settings& vm_settings) {
  if (DebuggedIOS(vm_settings)) {
    return;
  }

  if (ptrace(PT_TRACE_ME, 0, nullptr, 0) == -1) {
    FML_LOG(ERROR) << "Could not call ptrace(PT_TRACE_ME): " << strerror(errno);
    // No use trying PT_SIGEXC -- it's only needed if PT_TRACE_ME succeeds.
    return;
  }
  if (ptrace(PT_SIGEXC, 0, nullptr, 0) == -1) {
    FML_LOG(ERROR) << "Could not call ptrace(PT_SIGEXC): " << strerror(errno);
  }

  // The previous operation causes this process to not be reaped after it
  // terminates (even if PT_SIGEXC fails). Issue a warning to the console every
  // (approximiately) maxproc/10 leaks. See the links above for an explanation
  // of this issue.
  size_t maxproc = 0;
  size_t maxproc_size = sizeof(size_t);
  const int sysctl_result =
      sysctlbyname("kern.maxproc", &maxproc, &maxproc_size, nullptr, 0);
  if (sysctl_result < 0) {
    FML_LOG(ERROR)
        << "Could not execute sysctl() to determine process count limit: "
        << strerror(errno);
  }

  const char* warning =
      "Launching a debug-mode app from the home screen may cause problems.\n"
      "Please compile a profile-/release-build, launch your app via \"flutter "
      "run\", or see https://github.com/flutter/flutter/wiki/"
      "PID-leak-in-iOS-debug-builds-launched-from-home-screen for details.";

  if (vm_settings.verbose_logging  // used for testing and also informative
      || sysctl_result < 0         // could not determine maximum process count
      || maxproc / 10 == 0         // avoid division (%) by 0
      || getpid() % (maxproc / 10) == 0)  // warning every ~maxproc/10 leaks
  {
    FML_LOG(ERROR) << warning;
  }
}

#endif  // OS_IOS && (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG)
