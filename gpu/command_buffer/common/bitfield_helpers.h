// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains a helper template class used to access bit fields in
// unsigned int_ts.

#ifndef GPU_COMMAND_BUFFER_COMMON_BITFIELD_HELPERS_H_
#define GPU_COMMAND_BUFFER_COMMON_BITFIELD_HELPERS_H_

namespace gpu {

// Bitfield template class, used to access bit fields in unsigned int_ts.
template<int shift, int length> class BitField {
 public:
  static const unsigned int kShift = shift;
  static const unsigned int kLength = length;
  // the following is really (1<<length)-1 but also work for length == 32
  // without compiler warning.
  static const unsigned int kMask = 1U + ((1U << (length-1)) - 1U) * 2U;

  // Gets the value contained in this field.
  static unsigned int Get(unsigned int container) {
    return (container >> kShift) & kMask;
  }

  // Makes a value that can be or-ed into this field.
  static unsigned int MakeValue(unsigned int value) {
    return (value & kMask) << kShift;
  }

  // Changes the value of this field.
  static void Set(unsigned int *container, unsigned int field_value) {
    *container = (*container & ~(kMask << kShift)) | MakeValue(field_value);
  }
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_BITFIELD_HELPERS_H_
