// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_FILE_FD_IMPL_H_
#define SERVICES_FILES_C_LIB_FILE_FD_IMPL_H_

#include "files/c/lib/fd_impl.h"
#include "files/c/mojio_sys_types.h"
#include "files/interfaces/file.mojom-sync.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/public/cpp/bindings/interface_handle.h"
#include "mojo/public/cpp/bindings/synchronous_interface_ptr.h"

namespace mojio {

class FileFDImpl : public FDImpl {
 public:
  FileFDImpl(ErrnoImpl* errno_impl,
             mojo::InterfaceHandle<mojo::files::File> file);
  ~FileFDImpl() override;

  // |FDImpl| implementation:
  bool Close() override;
  std::unique_ptr<FDImpl> Dup() override;
  bool Ftruncate(mojio_off_t length) override;
  mojio_off_t Lseek(mojio_off_t offset, int whence) override;
  mojio_ssize_t Read(void* buf, size_t count) override;
  mojio_ssize_t Write(const void* buf, size_t count) override;
  bool Fstat(struct mojio_stat* buf) override;

 private:
  mojo::SynchronousInterfacePtr<mojo::files::File> file_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(FileFDImpl);
};

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_FILE_FD_IMPL_H_
