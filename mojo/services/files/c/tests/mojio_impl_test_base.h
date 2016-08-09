// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_TESTS_MOJIO_IMPL_TEST_BASE_H_
#define SERVICES_FILES_C_TESTS_MOJIO_IMPL_TEST_BASE_H_

#include "files/interfaces/directory.mojom.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/bindings/interface_handle.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojio {
namespace test {

// This is a base class for tests that test the underlying implementation (i.e.,
// doesn't use the singletons).
class MojioImplTestBase : public mojo::test::ApplicationTestBase {
 public:
  MojioImplTestBase();
  ~MojioImplTestBase() override;

  void SetUp() override;

 protected:
  mojo::InterfaceHandle<mojo::files::Directory>& directory() {
    return directory_;
  }

 private:
  mojo::InterfaceHandle<mojo::files::Directory> directory_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MojioImplTestBase);
};

}  // namespace test
}  // namespace mojio

#endif  // SERVICES_FILES_C_TESTS_MOJIO_IMPL_TEST_BASE_H_
