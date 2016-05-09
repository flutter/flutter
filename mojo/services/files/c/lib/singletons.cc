// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/lib/singletons.h"

#include <errno.h>

#include "files/c/lib/directory_wrapper.h"
#include "files/c/lib/fd_table.h"
#include "files/c/lib/real_errno_impl.h"
#include "files/c/mojio_config.h"
#include "mojo/public/cpp/environment/logging.h"

using mojo::InterfaceHandle;

namespace mojio {
namespace singletons {

namespace {

RealErrnoImpl* g_errno_impl = nullptr;
FDTable* g_fd_table = nullptr;
DirectoryWrapper* g_current_working_directory = nullptr;

}  // namespace

ErrnoImpl* GetErrnoImpl() {
  if (!g_errno_impl)
    g_errno_impl = new RealErrnoImpl();  // Does NOT modify errno.
  return g_errno_impl;
}

void ResetErrnoImpl() {
  delete g_errno_impl;  // Does NOT modify errno.
  g_errno_impl = nullptr;
}

FDTable* GetFDTable() {
  ErrnoImpl::Setter errno_setter(GetErrnoImpl());  // Protect errno.
  if (!g_fd_table)
    g_fd_table = new FDTable(GetErrnoImpl(), MOJIO_CONFIG_MAX_NUM_FDS);
  return g_fd_table;
}

void ResetFDTable() {
  ErrnoImpl::Setter errno_setter(GetErrnoImpl());  // Protect errno.
  delete g_fd_table;
  g_fd_table = nullptr;
}

void SetCurrentWorkingDirectory(
    InterfaceHandle<mojo::files::Directory> directory) {
  delete g_current_working_directory;
  g_current_working_directory = new DirectoryWrapper(
      GetErrnoImpl(), mojo::files::DirectoryPtr::Create(directory.Pass()));
}

DirectoryWrapper* GetCurrentWorkingDirectory() {
  ErrnoImpl::Setter errno_setter(GetErrnoImpl());
  if (!g_current_working_directory) {
    // TODO(vtl): Ponder this error code. (This is, e.g.,  what openat() would
    // return if its dirfd were not valid.)
    errno_setter.Set(EBADF);
    MOJO_LOG(ERROR) << "No current working directory";
    return nullptr;
  }

  return g_current_working_directory;
}

void ResetCurrentWorkingDirectory() {
  ErrnoImpl::Setter errno_setter(GetErrnoImpl());  // Protect errno.
  delete g_current_working_directory;
  g_current_working_directory = nullptr;
}

}  // namespace singletons
}  // namespace mojio
