// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/scoped_process_information.h"

#include "base/logging.h"
#include "base/win/scoped_handle.h"
#include "base/win/windows_version.h"

namespace base {
namespace win {

namespace {

// Duplicates source into target, returning true upon success. |target| is
// guaranteed to be untouched in case of failure. Succeeds with no side-effects
// if source is NULL.
bool CheckAndDuplicateHandle(HANDLE source, ScopedHandle* target) {
  if (!source)
    return true;

  HANDLE temp = NULL;

  // TODO(shrikant): Remove following code as soon as we gather some
  // information regarding AppContainer related DuplicateHandle failures that
  // only seem to happen on certain machine and only random launches (normally
  // renderer launches seem to succeed even on those machines.)
  if (base::win::GetVersion() == base::win::VERSION_WIN8 ||
      base::win::GetVersion() == base::win::VERSION_WIN8_1) {
    typedef LONG (WINAPI *NtDuplicateObject)(
        IN HANDLE SourceProcess,
        IN HANDLE SourceHandle,
        IN HANDLE TargetProcess,
        OUT PHANDLE TargetHandle,
        IN ACCESS_MASK DesiredAccess,
        IN ULONG Attributes,
        IN ULONG Options);

    typedef ULONG (WINAPI *RtlNtStatusToDosError)(IN LONG Status);

    NtDuplicateObject nt_duplicate_object =
        reinterpret_cast<NtDuplicateObject>(::GetProcAddress(
            GetModuleHandle(L"ntdll.dll"), "NtDuplicateObject"));
    if (nt_duplicate_object != NULL) {
      LONG status = nt_duplicate_object(::GetCurrentProcess(), source,
                                        ::GetCurrentProcess(), &temp,
                                        0, FALSE, DUPLICATE_SAME_ACCESS);
      if (status < 0) {
        DPLOG(ERROR) << "Failed to duplicate a handle.";
        RtlNtStatusToDosError ntstatus_to_doserror =
            reinterpret_cast<RtlNtStatusToDosError>(::GetProcAddress(
                GetModuleHandle(L"ntdll.dll"), "RtlNtStatusToDosError"));
        if (ntstatus_to_doserror != NULL) {
          ::SetLastError(ntstatus_to_doserror(status));
        }
        return false;
      }
    }
  } else {
    if (!::DuplicateHandle(::GetCurrentProcess(), source,
                           ::GetCurrentProcess(), &temp, 0, FALSE,
                           DUPLICATE_SAME_ACCESS)) {
      DPLOG(ERROR) << "Failed to duplicate a handle.";
      return false;
    }
  }
  target->Set(temp);
  return true;
}

}  // namespace

ScopedProcessInformation::ScopedProcessInformation()
    : process_id_(0), thread_id_(0) {
}

ScopedProcessInformation::ScopedProcessInformation(
    const PROCESS_INFORMATION& process_info) : process_id_(0), thread_id_(0) {
  Set(process_info);
}

ScopedProcessInformation::~ScopedProcessInformation() {
  Close();
}

bool ScopedProcessInformation::IsValid() const {
  return process_id_ || process_handle_.Get() ||
         thread_id_ || thread_handle_.Get();
}

void ScopedProcessInformation::Close() {
  process_handle_.Close();
  thread_handle_.Close();
  process_id_ = 0;
  thread_id_ = 0;
}

void ScopedProcessInformation::Set(const PROCESS_INFORMATION& process_info) {
  if (IsValid())
    Close();

  process_handle_.Set(process_info.hProcess);
  thread_handle_.Set(process_info.hThread);
  process_id_ = process_info.dwProcessId;
  thread_id_ = process_info.dwThreadId;
}

bool ScopedProcessInformation::DuplicateFrom(
    const ScopedProcessInformation& other) {
  DCHECK(!IsValid()) << "target ScopedProcessInformation must be NULL";
  DCHECK(other.IsValid()) << "source ScopedProcessInformation must be valid";

  if (CheckAndDuplicateHandle(other.process_handle(), &process_handle_) &&
      CheckAndDuplicateHandle(other.thread_handle(), &thread_handle_)) {
    process_id_ = other.process_id();
    thread_id_ = other.thread_id();
    return true;
  }

  return false;
}

PROCESS_INFORMATION ScopedProcessInformation::Take() {
  PROCESS_INFORMATION process_information = {};
  process_information.hProcess = process_handle_.Take();
  process_information.hThread = thread_handle_.Take();
  process_information.dwProcessId = process_id();
  process_information.dwThreadId = thread_id();
  process_id_ = 0;
  thread_id_ = 0;

  return process_information;
}

HANDLE ScopedProcessInformation::TakeProcessHandle() {
  process_id_ = 0;
  return process_handle_.Take();
}

HANDLE ScopedProcessInformation::TakeThreadHandle() {
  thread_id_ = 0;
  return thread_handle_.Take();
}

}  // namespace win
}  // namespace base
