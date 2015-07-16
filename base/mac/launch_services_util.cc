// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/launch_services_util.h"

#include "base/logging.h"
#include "base/mac/mac_logging.h"
#include "base/mac/mac_util.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/strings/sys_string_conversions.h"

namespace base {
namespace mac {

bool OpenApplicationWithPath(const base::FilePath& bundle_path,
                             const CommandLine& command_line,
                             LSLaunchFlags launch_flags,
                             ProcessSerialNumber* out_psn) {
  FSRef app_fsref;
  if (!base::mac::FSRefFromPath(bundle_path.value(), &app_fsref)) {
    LOG(ERROR) << "base::mac::FSRefFromPath failed for " << bundle_path.value();
    return false;
  }

  std::vector<std::string> argv = command_line.argv();
  int argc = argv.size();
  base::ScopedCFTypeRef<CFMutableArrayRef> launch_args(
      CFArrayCreateMutable(NULL, argc - 1, &kCFTypeArrayCallBacks));
  if (!launch_args) {
    LOG(ERROR) << "CFArrayCreateMutable failed, size was " << argc;
    return false;
  }

  for (int i = 1; i < argc; ++i) {
    const std::string& arg(argv[i]);

    base::ScopedCFTypeRef<CFStringRef> arg_cf(base::SysUTF8ToCFStringRef(arg));
    if (!arg_cf) {
      LOG(ERROR) << "base::SysUTF8ToCFStringRef failed for " << arg;
      return false;
    }
    CFArrayAppendValue(launch_args, arg_cf);
  }

  LSApplicationParameters ls_parameters = {
    0,     // version
    launch_flags,
    &app_fsref,
    NULL,  // asyncLaunchRefCon
    NULL,  // environment
    launch_args,
    NULL   // initialEvent
  };
  // TODO(jeremya): this opens a new browser window if Chrome is already
  // running without any windows open.
  OSStatus status = LSOpenApplication(&ls_parameters, out_psn);
  if (status != noErr) {
    OSSTATUS_LOG(ERROR, status) << "LSOpenApplication";
    return false;
  }
  return true;
}

}  // namespace mac
}  // namespace base
