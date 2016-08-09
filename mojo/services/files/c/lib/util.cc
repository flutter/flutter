// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/lib/util.h"

#include <assert.h>
#include <errno.h>

namespace mojio {

int ErrorToErrno(mojo::files::Error error) {
  switch (error) {
    // TODO(vtl): Real errno encodings....
    case mojo::files::Error::OK:
      return 0;
    case mojo::files::Error::UNKNOWN:
      // TODO(vtl): Something better?
      return EIO;
    case mojo::files::Error::INVALID_ARGUMENT:
      return EINVAL;
    case mojo::files::Error::PERMISSION_DENIED:
      return EACCES;
    case mojo::files::Error::OUT_OF_RANGE:
      // TODO(vtl): But sometimes it might be E2BIG or EDOM or ENAMETOOLONG,
      // etc.?
      return EINVAL;
    case mojo::files::Error::UNIMPLEMENTED:
      // TODO(vtl): Sometimes ENOTSUP?
      return ENOSYS;
    case mojo::files::Error::CLOSED:
      return EBADF;
    case mojo::files::Error::UNAVAILABLE:
      // TODO(vtl): May sometimes be EAGAIN?
      return EACCES;
    case mojo::files::Error::INTERNAL:
      // TODO(vtl): Something better?
      return EIO;
  }
  assert(false);
  // TODO(vtl): Something better?
  return EIO;
}

}  // namespace mojio
