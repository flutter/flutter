// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/lib/util.h"

#include "files/interfaces/types.mojom.h"
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
      {mojo::files::Error::OK, 0},
      {mojo::files::Error::UNKNOWN, EIO},
      {mojo::files::Error::INVALID_ARGUMENT, EINVAL},
      {mojo::files::Error::PERMISSION_DENIED, EACCES},
      {mojo::files::Error::OUT_OF_RANGE, EINVAL},
      {mojo::files::Error::UNIMPLEMENTED, ENOSYS},
      {mojo::files::Error::CLOSED, EBADF},
      {mojo::files::Error::UNAVAILABLE, EACCES},
      {mojo::files::Error::INTERNAL, EIO},
  };

  for (size_t i = 0; i < MOJO_ARRAYSIZE(kExpectedMappings); i++) {
    const ExpectedMapping& m = kExpectedMappings[i];
    EXPECT_EQ(m.to, ErrorToErrno(m.from)) << "i=" << i << ", m.from=" << m.from;
  }
}

}  // namespace
}  // namespace mojio
