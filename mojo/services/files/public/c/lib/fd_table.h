// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_FD_TABLE_H_
#define SERVICES_FILES_C_LIB_FD_TABLE_H_

#include <stddef.h>

#include <memory>
#include <vector>

#include "files/public/c/lib/fd_impl.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojio {

class ErrnoImpl;

// A simple (thread-unsafe) implementation of an FD (file descriptor) table,
// mapping FDs (integers) to |FDImpl|s. (Note that on failure, all the methods
// set "errno" using the |ErrnoImpl| provided to the constructor.)
class FDTable {
 public:
  // The |ErrnoImpl| must outlive this object. |max_num_fds| is the maximum
  // number of FDs allowed (simultaneously). This number should be relatively
  // small (hundreds to maybe tens of thousands, certainly not millions).
  FDTable(ErrnoImpl* errno_impl, size_t max_num_fds);
  // Note: This does not |Close()| any remaining |FDImpl|s.
  ~FDTable();

  // Returns the new FD (>= 0) on success and -1 on failure. Note that the
  // lowest-valued FD available is always allocated.
  int Add(std::unique_ptr<FDImpl> fd_impl);

  // Returns the |FDImpl| associated to |fd| (null if |fd| is not valid),
  // keeping the |FDImpl| in the table (and thus |fd| valid).
  FDImpl* Get(int fd) const;

  // Removes and returns the |FDImpl| associated to |fd| (null if |fd| is not
  // valid). Note that |Close()| is not called on the |FDImpl|.
  std::unique_ptr<FDImpl> Remove(int fd);

  ErrnoImpl* errno_impl() const { return errno_impl_; }
  size_t max_num_fds() const { return table_.size(); }

 private:
  ErrnoImpl* const errno_impl_;
  std::vector<std::unique_ptr<FDImpl>> table_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(FDTable);
};

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_FD_TABLE_H_
