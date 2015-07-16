// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_APPLICATION_APPLICATION_TEST_BASE_H_
#define MOJO_PUBLIC_CPP_APPLICATION_APPLICATION_TEST_BASE_H_

#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/string.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {

class ApplicationImpl;

namespace test {

// Access the command line arguments passed to the application test.
const Array<String>& Args();

// Run all application tests. This must be called after the environment is
// initialized, to support construction of a default run loop.
MojoResult RunAllTests(MojoHandle application_request_handle);

// A GTEST base class for application testing executed in mojo_shell.
class ApplicationTestBase : public testing::Test {
 public:
  ApplicationTestBase();
  ~ApplicationTestBase() override;

 protected:
  ApplicationImpl* application_impl() { return application_impl_; }

  // Get the ApplicationDelegate for the application to be tested.
  virtual ApplicationDelegate* GetApplicationDelegate();

  // testing::Test:
  void SetUp() override;
  void TearDown() override;

  // True by default, which indicates a MessageLoop will automatically be
  // created for the application.  Tests may override this function to prevent
  // a default loop from being created.
  virtual bool ShouldCreateDefaultRunLoop();

 private:
  // The application implementation instance, reconstructed for each test.
  ApplicationImpl* application_impl_;
  // The application delegate used if GetApplicationDelegate is not overridden.
  ApplicationDelegate default_application_delegate_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ApplicationTestBase);
};

}  // namespace test

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_APPLICATION_APPLICATION_TEST_BASE_H_
