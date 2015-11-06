// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/scoped_test_dir.h"

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"

namespace mojo {
namespace system {
namespace test {

ScopedTestDir::ScopedTestDir() {
  CHECK(temp_dir_.CreateUniqueTempDir());
}

ScopedTestDir::~ScopedTestDir() {}

util::ScopedFILE ScopedTestDir::CreateFile() {
  base::FilePath unused;
  return util::ScopedFILE(
      base::CreateAndOpenTemporaryFileInDir(temp_dir_.path(), &unused));
}

}  // namespace test
}  // namespace system
}  // namespace mojo
