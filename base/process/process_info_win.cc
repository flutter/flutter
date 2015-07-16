// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_info.h"

#include <windows.h>

#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "base/win/scoped_handle.h"
#include "base/win/windows_version.h"

namespace base {

// static
const Time CurrentProcessInfo::CreationTime() {
  FILETIME creation_time = {};
  FILETIME ignore = {};
  if (::GetProcessTimes(::GetCurrentProcess(), &creation_time, &ignore,
      &ignore, &ignore) == false)
    return Time();

  return Time::FromFileTime(creation_time);
}

IntegrityLevel GetCurrentProcessIntegrityLevel() {
  if (win::GetVersion() < base::win::VERSION_VISTA)
    return INTEGRITY_UNKNOWN;

  HANDLE process_token;
  if (!::OpenProcessToken(::GetCurrentProcess(),
                          TOKEN_QUERY | TOKEN_QUERY_SOURCE, &process_token)) {
    return INTEGRITY_UNKNOWN;
  }
  win::ScopedHandle scoped_process_token(process_token);

  DWORD token_info_length = 0;
  if (::GetTokenInformation(process_token, TokenIntegrityLevel, NULL, 0,
                            &token_info_length) ||
      ::GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
    return INTEGRITY_UNKNOWN;
  }

  scoped_ptr<char[]> token_label_bytes(new char[token_info_length]);
  if (!token_label_bytes.get())
    return INTEGRITY_UNKNOWN;

  TOKEN_MANDATORY_LABEL* token_label =
      reinterpret_cast<TOKEN_MANDATORY_LABEL*>(token_label_bytes.get());
  if (!token_label)
    return INTEGRITY_UNKNOWN;

  if (!::GetTokenInformation(process_token, TokenIntegrityLevel, token_label,
                             token_info_length, &token_info_length)) {
    return INTEGRITY_UNKNOWN;
  }

  DWORD integrity_level = *::GetSidSubAuthority(
      token_label->Label.Sid,
      static_cast<DWORD>(*::GetSidSubAuthorityCount(token_label->Label.Sid)-1));

  if (integrity_level < SECURITY_MANDATORY_MEDIUM_RID)
    return LOW_INTEGRITY;

  if (integrity_level >= SECURITY_MANDATORY_MEDIUM_RID &&
      integrity_level < SECURITY_MANDATORY_HIGH_RID) {
    return MEDIUM_INTEGRITY;
  }

  if (integrity_level >= SECURITY_MANDATORY_HIGH_RID)
    return HIGH_INTEGRITY;

  NOTREACHED();
  return INTEGRITY_UNKNOWN;
}

}  // namespace base
