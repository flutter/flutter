// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package embedder

/*
#include "mojo/go/c_embedder/c_embedder.h"
*/
import "C"

func InitializeMojoEmbedder() {
	C.InitializeMojoEmbedder()
}
