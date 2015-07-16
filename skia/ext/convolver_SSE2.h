// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_CONVOLVER_SSE2_H_
#define SKIA_EXT_CONVOLVER_SSE2_H_

#include "skia/ext/convolver.h"

namespace skia {

void ConvolveVertically_SSE2(const ConvolutionFilter1D::Fixed* filter_values,
                             int filter_length,
                             unsigned char* const* source_data_rows,
                             int pixel_width,
                             unsigned char* out_row,
                             bool has_alpha);
void Convolve4RowsHorizontally_SSE2(const unsigned char* src_data[4],
                                    const ConvolutionFilter1D& filter,
                                    unsigned char* out_row[4]);
void ConvolveHorizontally_SSE2(const unsigned char* src_data,
                               const ConvolutionFilter1D& filter,
                               unsigned char* out_row,
                               bool has_alpha);
}  // namespace skia

#endif  // SKIA_EXT_CONVOLVER_SSE2_H_
