// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MACROS_H_
#define FLUTTER_FML_MACROS_H_

#include "lib/fxl/macros.h"

#ifndef FML_USED_ON_EMBEDDER

#define FML_EMBEDDER_ONLY [[deprecated]]

#else  // FML_USED_ON_EMBEDDER

#define FML_EMBEDDER_ONLY

#endif  // FML_USED_ON_EMBEDDER

#endif  // FLUTTER_FML_MACROS_H_
