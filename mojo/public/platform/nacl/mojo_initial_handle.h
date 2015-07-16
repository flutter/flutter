// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NACL_MOJO_INTIIAL_HANDLE_H_
#define MOJO_PUBLIC_PLATFORM_NACL_MOJO_INTIIAL_HANDLE_H_

#include "mojo/public/c/system/types.h"

// Provides a MojoHandle that allows untrusted code to communicate with Mojo
// interfaces outside the sandbox or in other processes.
MojoResult _MojoGetInitialHandle(MojoHandle* out_handle);

#endif  // MOJO_PUBLIC_PLATFORM_NACL_MOJO_INTIIAL_HANDLE_H_
