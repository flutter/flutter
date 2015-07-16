// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/go/c_embedder/c_embedder.h"

#include "mojo/edk/embedder/test_embedder.h"

#ifdef __cplusplus
extern "C" {
#endif

void InitializeMojoEmbedder() {
  mojo::embedder::test::InitWithSimplePlatformSupport();
}

#ifdef __cplusplus
}  // extern "C"
#endif
