// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifdef IMPELLER_DEVICE

#define Vector3 vec3
#define Vector4 vec4
#define Matrix mat4

#else  // IMPELLER_DEVICE

#include "flutter/impeller/impeller/geometry/matrix.h"
#include "flutter/impeller/impeller/geometry/vector.h"

#endif  // IMPELLER_DEVICE
