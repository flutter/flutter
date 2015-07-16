// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/authorization_util.h"

#import <Foundation/Foundation.h>
#include <sys/wait.h>

#include <string>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/mac/bundle_locations.h"
#include "base/mac/foundation_util.h"
#include "base/mac/mac_logging.h"
#include "base/mac/scoped_authorizationref.h"
#include "base/posix/eintr_wrapper.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"

namespace base {
namespace mac {

AuthorizationRef GetAuthorizationRightsWithPrompt(
    AuthorizationRights* rights,
    CFStringRef prompt,
    AuthorizationFlags extraFlags) {
  // Create an empty AuthorizationRef.
  ScopedAuthorizationRef authorization;
  OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
                                        kAuthorizationFlagDefaults,
                                        authorization.get_pointer());
  if (status != errAuthorizationSuccess) {
    OSSTATUS_LOG(ERROR, status) << "AuthorizationCreate";
    return NULL;
  }

  AuthorizationFlags flags = kAuthorizationFlagDefaults |
                             kAuthorizationFlagInteractionAllowed |
                             kAuthorizationFlagExtendRights |
                             kAuthorizationFlagPreAuthorize |
                             extraFlags;

  // product_logo_32.png is used instead of app.icns because Authorization
  // Services can't deal with .icns files.
  NSString* icon_path =
      [base::mac::FrameworkBundle() pathForResource:@"product_logo_32"
                                             ofType:@"png"];
  const char* icon_path_c = [icon_path fileSystemRepresentation];
  size_t icon_path_length = icon_path_c ? strlen(icon_path_c) : 0;

  // The OS will append " Type an administrator's name and password to allow
  // <CFBundleDisplayName> to make changes."
  NSString* prompt_ns = base::mac::CFToNSCast(prompt);
  const char* prompt_c = [prompt_ns UTF8String];
  size_t prompt_length = prompt_c ? strlen(prompt_c) : 0;

  AuthorizationItem environment_items[] = {
    {kAuthorizationEnvironmentIcon, icon_path_length, (void*)icon_path_c, 0},
    {kAuthorizationEnvironmentPrompt, prompt_length, (void*)prompt_c, 0}
  };

  AuthorizationEnvironment environment = {arraysize(environment_items),
                                          environment_items};

  status = AuthorizationCopyRights(authorization,
                                   rights,
                                   &environment,
                                   flags,
                                   NULL);

  if (status != errAuthorizationSuccess) {
    if (status != errAuthorizationCanceled) {
      OSSTATUS_LOG(ERROR, status) << "AuthorizationCopyRights";
    }
    return NULL;
  }

  return authorization.release();
}

AuthorizationRef AuthorizationCreateToRunAsRoot(CFStringRef prompt) {
  // Specify the "system.privilege.admin" right, which allows
  // AuthorizationExecuteWithPrivileges to run commands as root.
  AuthorizationItem right_items[] = {
    {kAuthorizationRightExecute, 0, NULL, 0}
  };
  AuthorizationRights rights = {arraysize(right_items), right_items};

  return GetAuthorizationRightsWithPrompt(&rights, prompt, 0);
}

OSStatus ExecuteWithPrivilegesAndGetPID(AuthorizationRef authorization,
                                        const char* tool_path,
                                        AuthorizationFlags options,
                                        const char** arguments,
                                        FILE** pipe,
                                        pid_t* pid) {
  // pipe may be NULL, but this function needs one.  In that case, use a local
  // pipe.
  FILE* local_pipe;
  FILE** pipe_pointer;
  if (pipe) {
    pipe_pointer = pipe;
  } else {
    pipe_pointer = &local_pipe;
  }

  // AuthorizationExecuteWithPrivileges wants |char* const*| for |arguments|,
  // but it doesn't actually modify the arguments, and that type is kind of
  // silly and callers probably aren't dealing with that.  Put the cast here
  // to make things a little easier on callers.
  OSStatus status = AuthorizationExecuteWithPrivileges(authorization,
                                                       tool_path,
                                                       options,
                                                       (char* const*)arguments,
                                                       pipe_pointer);
  if (status != errAuthorizationSuccess) {
    return status;
  }

  int line_pid = -1;
  size_t line_length = 0;
  char* line_c = fgetln(*pipe_pointer, &line_length);
  if (line_c) {
    if (line_length > 0 && line_c[line_length - 1] == '\n') {
      // line_c + line_length is the start of the next line if there is one.
      // Back up one character.
      --line_length;
    }
    std::string line(line_c, line_length);
    if (!base::StringToInt(line, &line_pid)) {
      // StringToInt may have set line_pid to something, but if the conversion
      // was imperfect, use -1.
      LOG(ERROR) << "ExecuteWithPrivilegesAndGetPid: funny line: " << line;
      line_pid = -1;
    }
  } else {
    LOG(ERROR) << "ExecuteWithPrivilegesAndGetPid: no line";
  }

  if (!pipe) {
    fclose(*pipe_pointer);
  }

  if (pid) {
    *pid = line_pid;
  }

  return status;
}

OSStatus ExecuteWithPrivilegesAndWait(AuthorizationRef authorization,
                                      const char* tool_path,
                                      AuthorizationFlags options,
                                      const char** arguments,
                                      FILE** pipe,
                                      int* exit_status) {
  pid_t pid;
  OSStatus status = ExecuteWithPrivilegesAndGetPID(authorization,
                                                   tool_path,
                                                   options,
                                                   arguments,
                                                   pipe,
                                                   &pid);
  if (status != errAuthorizationSuccess) {
    return status;
  }

  // exit_status may be NULL, but this function needs it.  In that case, use a
  // local version.
  int local_exit_status;
  int* exit_status_pointer;
  if (exit_status) {
    exit_status_pointer = exit_status;
  } else {
    exit_status_pointer = &local_exit_status;
  }

  if (pid != -1) {
    pid_t wait_result = HANDLE_EINTR(waitpid(pid, exit_status_pointer, 0));
    if (wait_result != pid) {
      PLOG(ERROR) << "waitpid";
      *exit_status_pointer = -1;
    }
  } else {
    *exit_status_pointer = -1;
  }

  return status;
}

}  // namespace mac
}  // namespace base
