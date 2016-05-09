// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/c/tests/mojio_impl_test_base.h"

#include "files/interfaces/files.mojom-sync.h"
#include "files/interfaces/files.mojom.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/bindings/synchronous_interface_ptr.h"
#include "mojo/public/cpp/environment/logging.h"

using mojo::SynchronousInterfacePtr;

namespace mojio {
namespace test {

MojioImplTestBase::MojioImplTestBase() {
}

MojioImplTestBase::~MojioImplTestBase() {
}

void MojioImplTestBase::SetUp() {
  mojo::test::ApplicationTestBase::SetUp();

  SynchronousInterfacePtr<mojo::files::Files> files;
  mojo::ConnectToService(application_impl()->shell(), "mojo:files",
                         GetSynchronousProxy(&files));

  mojo::files::Error error = mojo::files::Error::INTERNAL;
  MOJO_CHECK(
      files->OpenFileSystem(nullptr, mojo::GetProxy(&directory_), &error));
  MOJO_CHECK(error == mojo::files::Error::OK);
}

}  // namespace test
}  // namespace mojio
