// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/environment/environment.h"

MojoResult MojoMain(MojoHandle handle) {
  // An Environment instance is needed to construct run loops.
  mojo::Environment environment;

  return mojo::test::RunAllTests(handle);
}
