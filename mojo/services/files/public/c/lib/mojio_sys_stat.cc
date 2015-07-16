// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/mojio_sys_stat.h"

#include "files/public/c/lib/fd_impl.h"
#include "files/public/c/lib/fd_table.h"
#include "files/public/c/lib/singletons.h"

namespace mojio {
namespace {

int FstatImpl(int fd, struct mojio_stat* buf) {
  FDImpl* fd_impl = singletons::GetFDTable()->Get(fd);
  if (!fd_impl)
    return -1;

  return fd_impl->Fstat(buf) ? 0 : -1;
}

}  // namespace
}  // namespace mojio

extern "C" {

int mojio_fstat(int fd, struct mojio_stat* buf) {
  return mojio::FstatImpl(fd, buf);
}

}  // extern "C"
