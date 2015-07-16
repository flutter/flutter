// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/util.h"

#include <assert.h>
#include <errno.h>

namespace mojio {

int ErrorToErrno(mojo::files::Error error) {
  switch (error) {
    // TODO(vtl): Real errno encodings....
    case mojo::files::ERROR_OK:
      return 0;
    case mojo::files::ERROR_UNKNOWN:
      // TODO(vtl): Something better?
      return EIO;
    case mojo::files::ERROR_INVALID_ARGUMENT:
      return EINVAL;
    case mojo::files::ERROR_PERMISSION_DENIED:
      return EACCES;
    case mojo::files::ERROR_OUT_OF_RANGE:
      // TODO(vtl): But sometimes it might be E2BIG or EDOM or ENAMETOOLONG,
      // etc.?
      return EINVAL;
    case mojo::files::ERROR_UNIMPLEMENTED:
      // TODO(vtl): Sometimes ENOTSUP?
      return ENOSYS;
    case mojo::files::ERROR_CLOSED:
      return EBADF;
    case mojo::files::ERROR_UNAVAILABLE:
      // TODO(vtl): May sometimes be EAGAIN?
      return EACCES;
    case mojo::files::ERROR_INTERNAL:
      // TODO(vtl): Something better?
      return EIO;
  }
  assert(false);
  // TODO(vtl): Something better?
  return EIO;
}

}  // namespace mojio
