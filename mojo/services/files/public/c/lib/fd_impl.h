// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_FD_IMPL_H_
#define SERVICES_FILES_C_LIB_FD_IMPL_H_

#include <memory>

#include "files/public/c/mojio_sys_stat.h"
#include "files/public/c/mojio_sys_types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojio {

class ErrnoImpl;

// |FDImpl| is an interface for file-descriptor-like objects, on top of which
// <unistd.h>-style (and also <stdio.h>-style) functions may be implemented.
// (For <unistd.h>-style functions, one needs a file descriptor table, since FDs
// are integers with a prescribed allocation scheme.)
//
// <unistd.h> functions with a "boolean" return value (0 on success, -1 on
// failure) here return a |bool| instead (true on success, false on failure). On
// failure, all methods set "errno" using the |ErrnoImpl| passed to the
// constructor.
class FDImpl {
 public:
  virtual ~FDImpl() {}

  // <unistd.h>:
  virtual bool Close() = 0;  // May be called only at most once.
  virtual std::unique_ptr<FDImpl> Dup() = 0;
  virtual bool Ftruncate(mojio_off_t length) = 0;
  virtual mojio_off_t Lseek(mojio_off_t offset, int whence) = 0;
  virtual mojio_ssize_t Read(void* buf, size_t count) = 0;
  virtual mojio_ssize_t Write(const void* buf, size_t count) = 0;

  // <sys/stat.h>:
  virtual bool Fstat(struct mojio_stat* buf) = 0;

 protected:
  // The |ErrnoImpl| must outlive this object and all objects transitively
  // |Dup()|ed from it.
  explicit FDImpl(ErrnoImpl* errno_impl) : errno_impl_(errno_impl) {}

  ErrnoImpl* errno_impl() const { return errno_impl_; }

 private:
  ErrnoImpl* const errno_impl_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(FDImpl);
};

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_FD_IMPL_H_
