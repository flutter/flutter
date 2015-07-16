// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process.h"

#include <errno.h>
#include <sys/resource.h>

#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/strings/string_split.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/lock.h"

namespace base {

namespace {

const int kForegroundPriority = 0;

#if defined(OS_CHROMEOS)
// We are more aggressive in our lowering of background process priority
// for chromeos as we have much more control over other processes running
// on the machine.
//
// TODO(davemoore) Refactor this by adding support for higher levels to set
// the foregrounding / backgrounding process so we don't have to keep
// chrome / chromeos specific logic here.
const int kBackgroundPriority = 19;
const char kControlPath[] = "/sys/fs/cgroup/cpu%s/cgroup.procs";
const char kForeground[] = "/chrome_renderers/foreground";
const char kBackground[] = "/chrome_renderers/background";
const char kProcPath[] = "/proc/%d/cgroup";

struct CGroups {
  // Check for cgroups files. ChromeOS supports these by default. It creates
  // a cgroup mount in /sys/fs/cgroup and then configures two cpu task groups,
  // one contains at most a single foreground renderer and the other contains
  // all background renderers. This allows us to limit the impact of background
  // renderers on foreground ones to a greater level than simple renicing.
  bool enabled;
  base::FilePath foreground_file;
  base::FilePath background_file;

  CGroups() {
    foreground_file =
        base::FilePath(base::StringPrintf(kControlPath, kForeground));
    background_file =
        base::FilePath(base::StringPrintf(kControlPath, kBackground));
    base::FileSystemType foreground_type;
    base::FileSystemType background_type;
    enabled =
        base::GetFileSystemType(foreground_file, &foreground_type) &&
        base::GetFileSystemType(background_file, &background_type) &&
        foreground_type == FILE_SYSTEM_CGROUP &&
        background_type == FILE_SYSTEM_CGROUP;
  }
};

base::LazyInstance<CGroups> cgroups = LAZY_INSTANCE_INITIALIZER;
#else
const int kBackgroundPriority = 5;
#endif

struct CheckForNicePermission {
  CheckForNicePermission() : can_reraise_priority(false) {
    // We won't be able to raise the priority if we don't have the right rlimit.
    // The limit may be adjusted in /etc/security/limits.conf for PAM systems.
    struct rlimit rlim;
    if ((getrlimit(RLIMIT_NICE, &rlim) == 0) &&
        (20 - kForegroundPriority) <= static_cast<int>(rlim.rlim_cur)) {
        can_reraise_priority = true;
    }
  };

  bool can_reraise_priority;
};

}  // namespace

// static
bool Process::CanBackgroundProcesses() {
#if defined(OS_CHROMEOS)
  if (cgroups.Get().enabled)
    return true;
#endif

  static LazyInstance<CheckForNicePermission> check_for_nice_permission =
      LAZY_INSTANCE_INITIALIZER;
  return check_for_nice_permission.Get().can_reraise_priority;
}

bool Process::IsProcessBackgrounded() const {
  DCHECK(IsValid());

#if defined(OS_CHROMEOS)
  if (cgroups.Get().enabled) {
    std::string proc;
    if (base::ReadFileToString(
            base::FilePath(StringPrintf(kProcPath, process_)),
            &proc)) {
      std::vector<std::string> proc_parts;
      base::SplitString(proc, ':', &proc_parts);
      DCHECK_EQ(proc_parts.size(), 3u);
      bool ret = proc_parts[2] == std::string(kBackground);
      return ret;
    } else {
      return false;
    }
  }
#endif
  return GetPriority() == kBackgroundPriority;
}

bool Process::SetProcessBackgrounded(bool background) {
  DCHECK(IsValid());

#if defined(OS_CHROMEOS)
  if (cgroups.Get().enabled) {
    std::string pid = StringPrintf("%d", process_);
    const base::FilePath file =
        background ?
            cgroups.Get().background_file : cgroups.Get().foreground_file;
    return base::WriteFile(file, pid.c_str(), pid.size()) > 0;
  }
#endif // OS_CHROMEOS

  if (!CanBackgroundProcesses())
    return false;

  int priority = background ? kBackgroundPriority : kForegroundPriority;
  int result = setpriority(PRIO_PROCESS, process_, priority);
  DPCHECK(result == 0);
  return result == 0;
}

}  // namespace base
