// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/mojio_fcntl.h"

#include <stdarg.h>

#include <memory>
#include <utility>

#include "files/public/c/lib/directory_wrapper.h"
#include "files/public/c/lib/fd_impl.h"
#include "files/public/c/lib/fd_table.h"
#include "files/public/c/lib/singletons.h"

namespace mojio {
namespace {

int OpenImpl(const char* path, int oflag, mojio_mode_t mode) {
  DirectoryWrapper* cwd = singletons::GetCurrentWorkingDirectory();
  if (!cwd)
    return -1;

  std::unique_ptr<FDImpl> fd_impl(cwd->Open(path, oflag, mode));
  if (!fd_impl)
    return -1;

  return singletons::GetFDTable()->Add(std::move(fd_impl));
}

}  // namespace
}  // namespace mojio

extern "C" {

int mojio_creat(const char* path, mojio_mode_t mode) {
  // This is defined by POSIX.
  return mojio::OpenImpl(path, MOJIO_O_WRONLY | MOJIO_O_CREAT | MOJIO_O_TRUNC,
                         mode);
}

int mojio_open(const char* path, int oflag, ...) {
  va_list ap;
  mojio_mode_t mode = 0;
  if ((oflag & MOJIO_O_CREAT)) {
    va_start(ap, oflag);
    mode = va_arg(ap, mojio_mode_t);
    va_end(ap);
  }
  return mojio::OpenImpl(path, oflag, mode);
}

}  // extern "C"
