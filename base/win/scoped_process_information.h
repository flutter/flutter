// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_SCOPED_PROCESS_INFORMATION_H_
#define BASE_WIN_SCOPED_PROCESS_INFORMATION_H_

#include <windows.h>

#include "base/basictypes.h"
#include "base/base_export.h"
#include "base/win/scoped_handle.h"

namespace base {
namespace win {

// Manages the closing of process and thread handles from PROCESS_INFORMATION
// structures. Allows clients to take ownership of either handle independently.
class BASE_EXPORT ScopedProcessInformation {
 public:
  ScopedProcessInformation();
  explicit ScopedProcessInformation(const PROCESS_INFORMATION& process_info);
  ~ScopedProcessInformation();

  // Returns true iff this instance is holding a thread and/or process handle.
  bool IsValid() const;

  // Closes the held thread and process handles, if any.
  void Close();

  // Populates this instance with the provided |process_info|.
  void Set(const PROCESS_INFORMATION& process_info);

  // Populates this instance with duplicate handles and the thread/process IDs
  // from |other|. Returns false in case of failure, in which case this instance
  // will be completely unpopulated.
  bool DuplicateFrom(const ScopedProcessInformation& other);

  // Transfers ownership of the held PROCESS_INFORMATION, if any, away from this
  // instance.
  PROCESS_INFORMATION Take();

  // Transfers ownership of the held process handle, if any, away from this
  // instance. Note that the related process_id will also be cleared.
  HANDLE TakeProcessHandle();

  // Transfers ownership of the held thread handle, if any, away from this
  // instance. Note that the related thread_id will also be cleared.
  HANDLE TakeThreadHandle();

  // Returns the held process handle, if any, while retaining ownership.
  HANDLE process_handle() const {
    return process_handle_.Get();
  }

  // Returns the held thread handle, if any, while retaining ownership.
  HANDLE thread_handle() const {
    return thread_handle_.Get();
  }

  // Returns the held process id, if any.
  DWORD process_id() const {
    return process_id_;
  }

  // Returns the held thread id, if any.
  DWORD thread_id() const {
    return thread_id_;
  }

 private:
  ScopedHandle process_handle_;
  ScopedHandle thread_handle_;
  DWORD process_id_;
  DWORD thread_id_;

  DISALLOW_COPY_AND_ASSIGN(ScopedProcessInformation);
};

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_SCOPED_PROCESS_INFORMATION_H_
