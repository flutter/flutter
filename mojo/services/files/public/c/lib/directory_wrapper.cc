// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/directory_wrapper.h"

#include <errno.h>

#include "files/public/c/lib/errno_impl.h"
#include "files/public/c/lib/file_fd_impl.h"
#include "files/public/c/lib/template_util.h"
#include "files/public/c/lib/util.h"
#include "files/public/c/mojio_fcntl.h"
#include "files/public/interfaces/file.mojom.h"
#include "files/public/interfaces/types.mojom.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojio {

DirectoryWrapper::DirectoryWrapper(ErrnoImpl* errno_impl,
                                   mojo::files::DirectoryPtr directory)
    : errno_impl_(errno_impl), directory_(directory.Pass()) {
  MOJO_DCHECK(directory_);
}

DirectoryWrapper::~DirectoryWrapper() {
}

// TODO(vtl): This doesn't currently support opening non-files (in particular,
// directories), but it should.
std::unique_ptr<FDImpl> DirectoryWrapper::Open(const char* path,
                                               int oflag,
                                               mojio_mode_t mode) {
  ErrnoImpl::Setter errno_setter(errno_impl_);

  if (!path) {
    errno_setter.Set(EFAULT);
    return nullptr;
  }

  uint32_t mojo_open_flags = 0;
  switch (oflag & MOJIO_O_ACCMODE) {
    case MOJIO_O_RDONLY:
      mojo_open_flags = mojo::files::kOpenFlagRead;
      break;
    case MOJIO_O_RDWR:
      mojo_open_flags =
          mojo::files::kOpenFlagRead | mojo::files::kOpenFlagWrite;
      break;
    case MOJIO_O_WRONLY:
      mojo_open_flags = mojo::files::kOpenFlagWrite;
      break;
    default:
      errno_setter.Set(EINVAL);
      return nullptr;
  }

  if ((oflag & MOJIO_O_CREAT))
    mojo_open_flags |= mojo::files::kOpenFlagCreate;
  if ((oflag & MOJIO_O_EXCL))
    mojo_open_flags |= mojo::files::kOpenFlagExclusive;
  if ((oflag & MOJIO_O_TRUNC))
    mojo_open_flags |= mojo::files::kOpenFlagTruncate;
  if ((oflag & MOJIO_O_APPEND))
    mojo_open_flags |= mojo::files::kOpenFlagAppend;
  // TODO(vtl): What should we do we open flags we don't support? And invalid
  // flags?

  // TODO(vtl): We currently totally ignore |mode|; maybe we should do something
  // with it?

  mojo::files::FilePtr file;
  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  directory_->OpenFile(path, mojo::GetProxy(&file), mojo_open_flags,
                       Capture(&error));
  if (!directory_.WaitForIncomingResponse()) {
    // This may be somewhat surprising. The implication is that the CWD is
    // stale, which may be a little strange.
    errno_setter.Set(ESTALE);
    return nullptr;
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return nullptr;
  // C++11, why don't you have make_unique?
  return std::unique_ptr<FDImpl>(new FileFDImpl(errno_impl_, file.Pass()));
}

bool DirectoryWrapper::Chdir(const char* path) {
  ErrnoImpl::Setter errno_setter(errno_impl_);

  if (!path)
    return errno_setter.Set(EFAULT);

  mojo::files::DirectoryPtr new_directory;
  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  directory_->OpenDirectory(
      path, mojo::GetProxy(&new_directory),
      mojo::files::kOpenFlagRead | mojo::files::kOpenFlagWrite,
      Capture(&error));
  if (!directory_.WaitForIncomingResponse()) {
    // This may be somewhat surprising. The implication is that the CWD is
    // stale, which may be a little strange.
    return errno_setter.Set(ESTALE);
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return false;
  directory_ = new_directory.Pass();
  return true;
}

}  // namespace mojio
