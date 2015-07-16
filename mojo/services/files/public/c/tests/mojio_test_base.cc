// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/tests/mojio_test_base.h"

#include "files/public/c/lib/singletons.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojio {
namespace test {

void MojioTestBase::SetUp() {
  MojioImplTestBase::SetUp();

  // Explicitly set up the singletons.
  MOJO_CHECK(singletons::GetErrnoImpl());
  MOJO_CHECK(singletons::GetFDTable());
  singletons::SetCurrentWorkingDirectory(directory().Pass());
  MOJO_CHECK(singletons::GetCurrentWorkingDirectory());
}

void MojioTestBase::TearDown() {
  // Explicitly tear down the singletons.
  singletons::ResetCurrentWorkingDirectory();
  singletons::ResetFDTable();
  singletons::ResetErrnoImpl();

  MojioImplTestBase::TearDown();
}

}  // namespace test
}  // namespace mojio
