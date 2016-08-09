// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TEST_SCOPED_TEST_DIR_H_
#define MOJO_EDK_SYSTEM_TEST_SCOPED_TEST_DIR_H_

#include "base/files/scoped_temp_dir.h"
#include "mojo/edk/util/scoped_file.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace test {

// Creates/destroyes a temporary directory for test purposes. (Unlike
// |base::ScopedTempDir|, this automatically creates the temporary directory.)
class ScopedTestDir final {
 public:
  ScopedTestDir();
  ~ScopedTestDir();

  util::ScopedFILE CreateFile();

 private:
  base::ScopedTempDir temp_dir_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedTestDir);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_SCOPED_TEST_DIR_H_
