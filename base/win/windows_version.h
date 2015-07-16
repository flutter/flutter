// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_WINDOWS_VERSION_H_
#define BASE_WIN_WINDOWS_VERSION_H_

#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"

typedef void* HANDLE;

namespace base {
namespace win {

// The running version of Windows.  This is declared outside OSInfo for
// syntactic sugar reasons; see the declaration of GetVersion() below.
// NOTE: Keep these in order so callers can do things like
// "if (base::win::GetVersion() >= base::win::VERSION_VISTA) ...".
enum Version {
  VERSION_PRE_XP = 0,  // Not supported.
  VERSION_XP,
  VERSION_SERVER_2003, // Also includes XP Pro x64 and Server 2003 R2.
  VERSION_VISTA,       // Also includes Windows Server 2008.
  VERSION_WIN7,        // Also includes Windows Server 2008 R2.
  VERSION_WIN8,        // Also includes Windows Server 2012.
  VERSION_WIN8_1,      // Also includes Windows Server 2012 R2.
  VERSION_WIN10,       // Also includes Windows 10 Server.
  VERSION_WIN_LAST,    // Indicates error condition.
};

// A rough bucketing of the available types of versions of Windows. This is used
// to distinguish enterprise enabled versions from home versions and potentially
// server versions.
enum VersionType {
  SUITE_HOME,
  SUITE_PROFESSIONAL,
  SUITE_SERVER,
  SUITE_LAST,
};

// A singleton that can be used to query various pieces of information about the
// OS and process state. Note that this doesn't use the base Singleton class, so
// it can be used without an AtExitManager.
class BASE_EXPORT OSInfo {
 public:
  struct VersionNumber {
    int major;
    int minor;
    int build;
  };

  struct ServicePack {
    int major;
    int minor;
  };

  // The processor architecture this copy of Windows natively uses.  For
  // example, given an x64-capable processor, we have three possibilities:
  //   32-bit Chrome running on 32-bit Windows:           X86_ARCHITECTURE
  //   32-bit Chrome running on 64-bit Windows via WOW64: X64_ARCHITECTURE
  //   64-bit Chrome running on 64-bit Windows:           X64_ARCHITECTURE
  enum WindowsArchitecture {
    X86_ARCHITECTURE,
    X64_ARCHITECTURE,
    IA64_ARCHITECTURE,
    OTHER_ARCHITECTURE,
  };

  // Whether a process is running under WOW64 (the wrapper that allows 32-bit
  // processes to run on 64-bit versions of Windows).  This will return
  // WOW64_DISABLED for both "32-bit Chrome on 32-bit Windows" and "64-bit
  // Chrome on 64-bit Windows".  WOW64_UNKNOWN means "an error occurred", e.g.
  // the process does not have sufficient access rights to determine this.
  enum WOW64Status {
    WOW64_DISABLED,
    WOW64_ENABLED,
    WOW64_UNKNOWN,
  };

  static OSInfo* GetInstance();

  Version version() const { return version_; }
  // The next two functions return arrays of values, [major, minor(, build)].
  VersionNumber version_number() const { return version_number_; }
  VersionType version_type() const { return version_type_; }
  ServicePack service_pack() const { return service_pack_; }
  WindowsArchitecture architecture() const { return architecture_; }
  int processors() const { return processors_; }
  size_t allocation_granularity() const { return allocation_granularity_; }
  WOW64Status wow64_status() const { return wow64_status_; }
  std::string processor_model_name();

  // Like wow64_status(), but for the supplied handle instead of the current
  // process.  This doesn't touch member state, so you can bypass the singleton.
  static WOW64Status GetWOW64StatusForProcess(HANDLE process_handle);

 private:
  OSInfo();
  ~OSInfo();

  Version version_;
  VersionNumber version_number_;
  VersionType version_type_;
  ServicePack service_pack_;
  WindowsArchitecture architecture_;
  int processors_;
  size_t allocation_granularity_;
  WOW64Status wow64_status_;
  std::string processor_model_name_;

  DISALLOW_COPY_AND_ASSIGN(OSInfo);
};

// Because this is by far the most commonly-requested value from the above
// singleton, we add a global-scope accessor here as syntactic sugar.
BASE_EXPORT Version GetVersion();

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_WINDOWS_VERSION_H_
