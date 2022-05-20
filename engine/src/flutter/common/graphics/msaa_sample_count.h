// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_GRAPHICS_MSAA_SAMPLE_COUNT_H_
#define FLUTTER_COMMON_GRAPHICS_MSAA_SAMPLE_COUNT_H_

// Supported MSAA sample count values.
enum class MsaaSampleCount {
  kNone = 1,
  kTwo = 2,
  kFour = 4,
  kEight = 8,
  kSixteen = 16,
};

#endif  // FLUTTER_COMMON_GRAPHICS_MSAA_SAMPLE_COUNT_H_
