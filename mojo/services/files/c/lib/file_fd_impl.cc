// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/lib/file_fd_impl.h"

#include <errno.h>
#include <string.h>

#include <limits>

#include "files/c/lib/errno_impl.h"
#include "files/c/lib/util.h"
#include "files/c/mojio_unistd.h"
#include "files/interfaces/types.mojom.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/environment/logging.h"

using mojo::InterfaceHandle;
using mojo::SynchronousInterfacePtr;

namespace mojio {

FileFDImpl::FileFDImpl(ErrnoImpl* errno_impl,
                       InterfaceHandle<mojo::files::File> file)
    : FDImpl(errno_impl),
      file_(SynchronousInterfacePtr<mojo::files::File>::Create(file.Pass())) {
  MOJO_DCHECK(file_);
}

FileFDImpl::~FileFDImpl() {
}

bool FileFDImpl::Close() {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  if (!file_->Close(&error))
    return errno_setter.Set(ESTALE);
  return errno_setter.Set(ErrorToErrno(error));
}

std::unique_ptr<FDImpl> FileFDImpl::Dup() {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  InterfaceHandle<mojo::files::File> new_file;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  if (!file_->Dup(mojo::GetProxy(&new_file), &error)) {
    errno_setter.Set(ESTALE);
    return nullptr;
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return nullptr;
  // C++11, why don't you have make_unique?
  return std::unique_ptr<FDImpl>(new FileFDImpl(errno_impl(), new_file.Pass()));
}

bool FileFDImpl::Ftruncate(mojio_off_t length) {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  if (length < 0)
    return errno_setter.Set(EINVAL);

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  if (!file_->Truncate(static_cast<int64_t>(length), &error))
    return errno_setter.Set(ESTALE);
  return errno_setter.Set(ErrorToErrno(error));
}

mojio_off_t FileFDImpl::Lseek(mojio_off_t offset, int whence) {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  mojo::files::Whence mojo_whence;
  switch (whence) {
    case MOJIO_SEEK_SET:
      mojo_whence = mojo::files::Whence::FROM_START;
      break;
    case MOJIO_SEEK_CUR:
      mojo_whence = mojo::files::Whence::FROM_CURRENT;
      break;
    case MOJIO_SEEK_END:
      mojo_whence = mojo::files::Whence::FROM_END;
      break;
    default:
      errno_setter.Set(EINVAL);
      return -1;
  }

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  int64_t position = -1;
  if (!file_->Seek(static_cast<int64_t>(offset), mojo_whence, &error,
                   &position)) {
    errno_setter.Set(ESTALE);
    return -1;
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return -1;

  if (position < 0) {
    // Service misbehaved.
    MOJO_LOG(ERROR) << "Write() wrote more than requested";
    // TODO(vtl): Is there a better error code for this?
    errno_setter.Set(EIO);
    return -1;
  }

  // TODO(vtl): The comparison should actually be against MOJIO_SSIZE_MAX.
  if (position >
      static_cast<int64_t>(std::numeric_limits<mojio_off_t>::max())) {
    errno_setter.Set(EOVERFLOW);  // Wow, this is defined by POSIX.
    return -1;
  }

  return static_cast<mojio_off_t>(position);
}

mojio_ssize_t FileFDImpl::Read(void* buf, size_t count) {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  // TODO(vtl): The comparison should actually be against MOJIO_SSIZE_MAX.
  if (count > static_cast<size_t>(std::numeric_limits<mojio_ssize_t>::max()) ||
      count > std::numeric_limits<uint32_t>::max()) {
    // POSIX leaves the behavior undefined in this case. We'll return EINVAL.
    // (EDOM also seems plausible, but its description implies that it's for
    // mathematical functions. ERANGE is for return values.)
    errno_setter.Set(EINVAL);
    return -1;
  }

  if (!buf && count > 0) {
    errno_setter.Set(EFAULT);
    return -1;
  }

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  mojo::Array<uint8_t> bytes_read;
  if (!file_->Read(static_cast<uint32_t>(count), 0,
                   mojo::files::Whence::FROM_CURRENT, &error, &bytes_read)) {
    errno_setter.Set(ESTALE);
    return -1;
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return -1;
  if (bytes_read.size() > count) {
    // Service misbehaved.
    MOJO_LOG(ERROR) << "Read() read more than requested";
    // TODO(vtl): Is there a better error code for this?
    errno_setter.Set(EIO);
    return -1;
  }

  if (bytes_read.size() > 0)
    memcpy(buf, &bytes_read[0], bytes_read.size());
  return static_cast<mojio_ssize_t>(bytes_read.size());
}

mojio_ssize_t FileFDImpl::Write(const void* buf, size_t count) {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  // TODO(vtl): The comparison should actually be against MOJIO_SSIZE_MAX.
  if (count > static_cast<size_t>(std::numeric_limits<mojio_ssize_t>::max()) ||
      count > std::numeric_limits<uint32_t>::max()) {
    // POSIX leaves the behavior undefined in this case. We'll return EINVAL.
    // (EDOM also seems plausible, but its description implies that it's for
    // mathematical functions. ERANGE is for return values.)
    errno_setter.Set(EINVAL);
    return -1;
  }

  if (!buf && count > 0) {
    errno_setter.Set(EFAULT);
    return -1;
  }

  // TODO(vtl): Is there a more natural (or efficient) way to do this?
  auto bytes_to_write = mojo::Array<uint8_t>::New(count);
  if (count > 0)
    memcpy(&bytes_to_write[0], buf, count);

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  uint32_t num_bytes_written = 0;
  if (!file_->Write(bytes_to_write.Pass(), 0, mojo::files::Whence::FROM_CURRENT,
                    &error, &num_bytes_written)) {
    errno_setter.Set(ESTALE);
    return -1;
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return -1;

  if (num_bytes_written > count) {
    // Service misbehaved.
    MOJO_LOG(ERROR) << "Write() wrote than requested";
    // TODO(vtl): Is there a better error code for this?
    errno_setter.Set(EIO);
    return -1;
  }

  return static_cast<mojio_ssize_t>(num_bytes_written);
}

bool FileFDImpl::Fstat(struct mojio_stat* buf) {
  ErrnoImpl::Setter errno_setter(errno_impl());
  MOJO_DCHECK(file_);

  if (!buf) {
    errno_setter.Set(EFAULT);
    return false;
  }

  mojo::files::FileInformationPtr file_info;
  mojo::files::Error error = mojo::files::Error::INTERNAL;
  if (!file_->Stat(&error, &file_info)) {
    errno_setter.Set(ESTALE);
    return false;
  }
  if (!errno_setter.Set(ErrorToErrno(error)))
    return false;

  if (!file_info) {
    // Service misbehaved.
    MOJO_LOG(ERROR) << "Stat() didn't provide FileInformation";
    // TODO(vtl): Is there a better error code for this?
    errno_setter.Set(EIO);
    return false;
  }

  // Zero everything first.
  memset(buf, 0, sizeof(*buf));
  // Leave |st_dev| zero.
  // Leave |st_ino| zero.
  buf->st_mode = MOJIO_S_IRWXU;
  switch (file_info->type) {
    case mojo::files::FileType::UNKNOWN:
      break;
    case mojo::files::FileType::REGULAR_FILE:
      buf->st_mode |= MOJIO_S_IFREG;
      break;
    case mojo::files::FileType::DIRECTORY:
      buf->st_mode |= MOJIO_S_IFDIR;
      break;
    default:
      MOJO_LOG(WARNING) << "Unknown FileType: " << file_info->type;
      break;
  }
  // The most likely value (it'll be wrong if |file_| has been deleted).
  // TODO(vtl): Ponder this. Maybe |FileInformation| should have nlink?
  buf->st_nlink = 1;
  // Leave |st_uid| zero.
  // Leave |st_gid| zero.
  // Leave |st_rdev| zero.
  // TODO(vtl): Should we validate size?
  buf->st_size = static_cast<mojio_off_t>(file_info->size);
  if (file_info->atime) {
    buf->st_atim.tv_sec = static_cast<mojio_time_t>(file_info->atime->seconds);
    buf->st_atim.tv_nsec = static_cast<long>(file_info->atime->nanoseconds);
  }  // Else leave |st_atim| zero.
  if (file_info->mtime) {
    buf->st_mtim.tv_sec = static_cast<mojio_time_t>(file_info->mtime->seconds);
    buf->st_mtim.tv_nsec = static_cast<long>(file_info->mtime->nanoseconds);
  }  // Else leave |st_mtim| zero.
  // Don't have |ctime|, so just use the |mtime| value instead.
  buf->st_ctim = buf->st_mtim;
  // TODO(vtl): Maybe |FileInformation| should have ctime?
  buf->st_blksize = 1024;  // Made-up value.
  // Make up a value based on size. (Note: Despite the above "block size", this
  // block count is for 512-byte blocks!)
  if (file_info->size > 0)
    buf->st_blocks = (static_cast<mojio_blkcnt_t>(file_info->size) + 511) / 512;
  // Else leave |st_blocks| zero.

  return true;
}

}  // namespace mojio
