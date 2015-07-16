// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_AUTHORIZATION_UTIL_H_
#define BASE_MAC_AUTHORIZATION_UTIL_H_

// AuthorizationExecuteWithPrivileges fork()s and exec()s the tool, but it
// does not wait() for it.  It also doesn't provide the caller with access to
// the forked pid.  If used irresponsibly, zombie processes will accumulate.
//
// Apple's really gotten us between a rock and a hard place, here.
//
// Fortunately, AuthorizationExecuteWithPrivileges does give access to the
// tool's stdout (and stdin) via a FILE* pipe.  The tool can output its pid
// to this pipe, and the main program can read it, and then have something
// that it can wait() for.
//
// The contract is that any tool executed by the wrappers declared in this
// file must print its pid to stdout on a line by itself before doing anything
// else.
//
// http://developer.apple.com/library/mac/#samplecode/BetterAuthorizationSample/Listings/BetterAuthorizationSampleLib_c.html
// (Look for "What's This About Zombies?")

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Authorization.h>
#include <stdio.h>
#include <sys/types.h>

#include "base/base_export.h"

namespace base {
namespace mac {

// Obtains an AuthorizationRef for the rights indicated by |rights|.  If
// necessary, prompts the user for authentication. If the user is prompted,
// |prompt| will be used as the prompt string and an icon appropriate for the
// application will be displayed in a prompt dialog. Note that the system
// appends its own text to the prompt string. |extraFlags| will be ORed
// together with the default flags. Returns NULL on failure.
BASE_EXPORT
AuthorizationRef GetAuthorizationRightsWithPrompt(
    AuthorizationRights* rights,
    CFStringRef prompt,
    AuthorizationFlags extraFlags);

// Obtains an AuthorizationRef (using |GetAuthorizationRightsWithPrompt|) that
// can be used to run commands as root.
BASE_EXPORT
AuthorizationRef AuthorizationCreateToRunAsRoot(CFStringRef prompt);

// Calls straight through to AuthorizationExecuteWithPrivileges.  If that
// call succeeds, |pid| will be set to the pid of the executed tool.  If the
// pid can't be determined, |pid| will be set to -1.  |pid| must not be NULL.
// |pipe| may be NULL, but the tool will always be executed with a pipe in
// order to read the pid from its stdout.
BASE_EXPORT
OSStatus ExecuteWithPrivilegesAndGetPID(AuthorizationRef authorization,
                                        const char* tool_path,
                                        AuthorizationFlags options,
                                        const char** arguments,
                                        FILE** pipe,
                                        pid_t* pid);

// Calls ExecuteWithPrivilegesAndGetPID, and if that call succeeds, calls
// waitpid() to wait for the process to exit.  If waitpid() succeeds, the
// exit status is placed in |exit_status|, otherwise, -1 is stored.
// |exit_status| may be NULL and this function will still wait for the process
// to exit.
BASE_EXPORT
OSStatus ExecuteWithPrivilegesAndWait(AuthorizationRef authorization,
                                      const char* tool_path,
                                      AuthorizationFlags options,
                                      const char** arguments,
                                      FILE** pipe,
                                      int* exit_status);

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_AUTHORIZATION_UTIL_H_
