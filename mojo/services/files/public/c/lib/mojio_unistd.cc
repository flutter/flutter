// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/mojio_unistd.h"

#include <memory>
#include <utility>

#include "files/public/c/lib/directory_wrapper.h"
#include "files/public/c/lib/fd_impl.h"
#include "files/public/c/lib/fd_table.h"
#include "files/public/c/lib/singletons.h"

namespace mojio {
namespace {

int ChdirImpl(const char* path) {
  DirectoryWrapper* cwd = singletons::GetCurrentWorkingDirectory();
  if (!cwd)
    return -1;

  return cwd->Chdir(path) ? 0 : -1;
}

int CloseImpl(int fd) {
  std::unique_ptr<FDImpl> fd_impl(singletons::GetFDTable()->Remove(fd));
  if (!fd_impl)
    return -1;

  return fd_impl->Close() ? 0 : -1;
}

int DupImpl(int fd) {
  FDImpl* fd_impl = singletons::GetFDTable()->Get(fd);
  if (!fd_impl)
    return -1;

  std::unique_ptr<FDImpl> new_fd_impl(fd_impl->Dup());
  if (!new_fd_impl)
    return -1;

  return singletons::GetFDTable()->Add(std::move(new_fd_impl));
}

int FtruncateImpl(int fd, mojio_off_t length) {
  FDImpl* fd_impl = singletons::GetFDTable()->Get(fd);
  if (!fd_impl)
    return -1;

  return fd_impl->Ftruncate(length) ? 0 : -1;
}

mojio_off_t LseekImpl(int fd, mojio_off_t offset, int whence) {
  FDImpl* fd_impl = singletons::GetFDTable()->Get(fd);
  if (!fd_impl)
    return -1;

  return fd_impl->Lseek(offset, whence);
}

mojio_ssize_t ReadImpl(int fd, void* buf, size_t count) {
  FDImpl* fd_impl = singletons::GetFDTable()->Get(fd);
  if (!fd_impl)
    return -1;

  return fd_impl->Read(buf, count);
}

mojio_ssize_t WriteImpl(int fd, const void* buf, size_t count) {
  FDImpl* fd_impl = singletons::GetFDTable()->Get(fd);
  if (!fd_impl)
    return -1;

  return fd_impl->Write(buf, count);
}

}  // namespace
}  // namespace mojio

extern "C" {

int mojio_chdir(const char* path) {
  return mojio::ChdirImpl(path);
}

int mojio_close(int fd) {
  return mojio::CloseImpl(fd);
}

int mojio_dup(int fd) {
  return mojio::DupImpl(fd);
}

int mojio_ftruncate(int fd, mojio_off_t length) {
  return mojio::FtruncateImpl(fd, length);
}

mojio_off_t mojio_lseek(int fd, mojio_off_t offset, int whence) {
  return mojio::LseekImpl(fd, offset, whence);
}

mojio_ssize_t mojio_read(int fd, void* buf, size_t count) {
  return mojio::ReadImpl(fd, buf, count);
}

mojio_ssize_t mojio_write(int fd, const void* buf, size_t count) {
  return mojio::WriteImpl(fd, buf, count);
}

}  // extern "C"
