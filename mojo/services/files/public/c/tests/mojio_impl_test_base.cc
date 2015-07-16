// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/tests/mojio_impl_test_base.h"

#include "files/public/c/lib/template_util.h"
#include "files/public/interfaces/files.mojom.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/bindings/interface_request.h"
#include "mojo/public/cpp/environment/logging.h"

namespace mojio {
namespace test {

MojioImplTestBase::MojioImplTestBase() {
}

MojioImplTestBase::~MojioImplTestBase() {
}

void MojioImplTestBase::SetUp() {
  mojo::test::ApplicationTestBase::SetUp();

  mojo::files::FilesPtr files;
  application_impl()->ConnectToService("mojo:files", &files);

  mojo::files::Error error = mojo::files::ERROR_INTERNAL;
  files->OpenFileSystem(nullptr, mojo::GetProxy(&directory_), Capture(&error));
  MOJO_CHECK(files.WaitForIncomingResponse());
  MOJO_CHECK(error == mojo::files::ERROR_OK);
}

}  // namespace test
}  // namespace mojio
