// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MATH_GLSL_
#define MATH_GLSL_

// pow(x, y) crashes the shader compiler on the Nexus 5.
// See also: https://skia-review.googlesource.com/c/skia/+/148480
#ifdef IMPELLER_TARGET_OPENGLES
#define POW(x, y) exp2(y* log2(x))
#else
#define POW(x, y) pow(x, y)
#endif

#endif  // MATH_GLSL_
