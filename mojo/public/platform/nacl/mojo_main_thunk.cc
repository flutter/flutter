// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/c/system/main.h"
#include "mojo/public/platform/nacl/mojo_initial_handle.h"

int main() {
  MojoHandle handle;
  _MojoGetInitialHandle(&handle);
  return MojoMain(handle);
}
