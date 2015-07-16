// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/fd_table.h"

#include <errno.h>

#include <limits>
#include <utility>

#include "files/public/c/lib/errno_impl.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojio {

FDTable::FDTable(ErrnoImpl* errno_impl, size_t max_num_fds)
    : errno_impl_(errno_impl), table_(max_num_fds) {
  MOJO_DCHECK(max_num_fds > 0);
  // The index of the last FD has to fit into an |int|.
  MOJO_DCHECK(max_num_fds - 1 <=
              static_cast<size_t>(std::numeric_limits<int>::max()));
}

FDTable::~FDTable() {
  // TODO(vtl): Warn if there are still non-null entries?
}

int FDTable::Add(std::unique_ptr<FDImpl> fd_impl) {
  ErrnoImpl::Setter errno_setter(errno_impl_);
  MOJO_DCHECK(fd_impl);

  for (size_t i = 0; i < table_.size(); i++) {
    if (!table_[i]) {
      table_[i] = std::move(fd_impl);
      return static_cast<int>(i);
    }
  }
  errno_setter.Set(EMFILE);
  return -1;
}

FDImpl* FDTable::Get(int fd) const {
  ErrnoImpl::Setter errno_setter(errno_impl_);
  if (fd < 0 || static_cast<size_t>(fd) >= table_.size() || !table_[fd]) {
    errno_setter.Set(EBADF);
    return nullptr;
  }
  return table_[fd].get();
}

std::unique_ptr<FDImpl> FDTable::Remove(int fd) {
  ErrnoImpl::Setter errno_setter(errno_impl_);
  if (fd < 0 || static_cast<size_t>(fd) >= table_.size() || !table_[fd]) {
    errno_setter.Set(EBADF);
    return nullptr;
  }
  return std::move(table_[fd]);
}

}  // namespace mojio
