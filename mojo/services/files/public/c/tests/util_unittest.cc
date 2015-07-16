// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/util.h"

#include "files/public/interfaces/types.mojom.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojio {
namespace {

// TODO(vtl): This test is pretty lame until |mojo::files::Error| can also
// encapsulate "real" errno values.
TEST(UtilTest, ErrorToErrno) {
  const struct ExpectedMapping {
    mojo::files::Error from;
    int to;
  } kExpectedMappings[] = {
      {mojo::files::ERROR_OK, 0},
      {mojo::files::ERROR_UNKNOWN, EIO},
      {mojo::files::ERROR_INVALID_ARGUMENT, EINVAL},
      {mojo::files::ERROR_PERMISSION_DENIED, EACCES},
      {mojo::files::ERROR_OUT_OF_RANGE, EINVAL},
      {mojo::files::ERROR_UNIMPLEMENTED, ENOSYS},
      {mojo::files::ERROR_CLOSED, EBADF},
      {mojo::files::ERROR_UNAVAILABLE, EACCES},
      {mojo::files::ERROR_INTERNAL, EIO},
  };

  for (size_t i = 0; i < MOJO_ARRAYSIZE(kExpectedMappings); i++) {
    const ExpectedMapping& m = kExpectedMappings[i];
    EXPECT_EQ(m.to, ErrorToErrno(m.from)) << "i=" << i << ", m.from=" << m.from;
  }
}

}  // namespace
}  // namespace mojio
