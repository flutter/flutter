// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_DIRECTORY_WRAPPER_H_
#define SERVICES_FILES_C_LIB_DIRECTORY_WRAPPER_H_

#include <memory>

#include "files/c/mojio_sys_types.h"
#include "files/interfaces/directory.mojom-sync.h"
#include "files/interfaces/directory.mojom.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/public/cpp/bindings/interface_handle.h"
#include "mojo/public/cpp/bindings/synchronous_interface_ptr.h"

namespace mojio {

class ErrnoImpl;
class FDImpl;

// TODO(vtl): Probably this should be made into an implementation of |FDImpl|
// (with additional methods) and renamed |DirectoryFDImpl|, to support opening
// directories, |openat()|, etc.
class DirectoryWrapper {
 public:
  DirectoryWrapper(ErrnoImpl* errno_impl,
                   mojo::InterfaceHandle<mojo::files::Directory> directory);
  ~DirectoryWrapper();

  std::unique_ptr<FDImpl> Open(const char* path, int oflag, mojio_mode_t mode);
  bool Chdir(const char* path);

  // TODO(vtl): MkDir(), etc.

  // Mostly for tests:
  mojo::SynchronousInterfacePtr<mojo::files::Directory>& directory() {
    return directory_;
  }

 private:
  ErrnoImpl* const errno_impl_;
  mojo::SynchronousInterfacePtr<mojo::files::Directory> directory_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(DirectoryWrapper);
};

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_DIRECTORY_WRAPPER_H_
