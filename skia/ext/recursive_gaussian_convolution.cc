// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <cmath>
#include <vector>

#include "base/logging.h"
#include "skia/ext/recursive_gaussian_convolution.h"

namespace skia {

namespace {

// Takes the value produced by accumulating element-wise product of image with
// a kernel and brings it back into range.
// All of the filter scaling factors are in fixed point with kShiftBits bits of
// fractional part.
template<bool take_absolute>
inline unsigned char FloatTo8(float f) {
  int a = static_cast<int>(f + 0.5f);
  if (take_absolute)
    a = std::abs(a);
  else if (a < 0)
    return 0;
  if (a < 256)
    return a;
  return 255;
}

template<RecursiveFilter::Order order>
inline float ForwardFilter(float in_n_1,
                           float in_n,
                           float in_n1,
                           const std::vector<float>& w,
                           int n,
                           const float* b) {
  switch (order) {
    case RecursiveFilter::FUNCTION:
      return b[0] * in_n + b[1] * w[n-1] + b[2] * w[n-2] + b[3] * w[n-3];
    case RecursiveFilter::FIRST_DERIVATIVE:
      return b[0] * 0.5f * (in_n1 - in_n_1) +
          b[1] * w[n-1] + b[2] * w[n-2] + b[3] * w[n-3];
    case RecursiveFilter::SECOND_DERIVATIVE:
      return b[0] * (in_n - in_n_1)  +
          b[1] * w[n-1] + b[2] * w[n-2] + b[3] * w[n-3];
  }

  NOTREACHED();
  return 0.0f;
}

template<RecursiveFilter::Order order>
inline float BackwardFilter(const std::vector<float>& out,
                            int n,
                            float w_n,
                            float w_n1,
                            const float* b) {
  switch (order) {
    case RecursiveFilter::FUNCTION:
    case RecursiveFilter::FIRST_DERIVATIVE:
      return b[0] * w_n +
          b[1] * out[n + 1] + b[2] * out[n + 2] + b[3] * out[n + 3];
    case RecursiveFilter::SECOND_DERIVATIVE:
      return b[0] * (w_n1 - w_n)  +
          b[1] * out[n + 1] + b[2] * out[n + 2] + b[3] * out[n + 3];
  }
  NOTREACHED();
  return 0.0f;
}

template<RecursiveFilter::Order order, bool absolute_values>
unsigned char SingleChannelRecursiveFilter(
    const unsigned char* const source_data,
    int source_pixel_stride,
    int source_row_stride,
    int row_width,
    int row_count,
    unsigned char* const output,
    int output_pixel_stride,
    int output_row_stride,
    const float* b) {
  const int intermediate_buffer_size = row_width + 6;
  std::vector<float> w(intermediate_buffer_size);
  const unsigned char* in = source_data;
  unsigned char* out = output;
  unsigned char max_output = 0;
  for (int r = 0; r < row_count;
       ++r, in += source_row_stride, out += output_row_stride) {
    // Compute forward filter.
    // First initialize start of the w (temporary) vector.
    if (order == RecursiveFilter::FUNCTION)
      w[0] = w[1] = w[2] = in[0];
    else
      w[0] = w[1] = w[2] = 0.0f;
    // Note that special-casing of w[3] is needed because of derivatives.
    w[3] = ForwardFilter<order>(
        in[0], in[0], in[source_pixel_stride], w, 3, b);
    int n = 4;
    int c = 1;
    int byte_index = source_pixel_stride;
    for (; c < row_width - 1; ++c, ++n, byte_index += source_pixel_stride) {
      w[n] = ForwardFilter<order>(in[byte_index - source_pixel_stride],
                                  in[byte_index],
                                  in[byte_index + source_pixel_stride],
                                  w, n, b);
    }

    // The value of w corresponding to the last image pixel needs to be computed
    // separately, again because of derivatives.
    w[n] = ForwardFilter<order>(in[byte_index - source_pixel_stride],
                                in[byte_index],
                                in[byte_index],
                                w, n, b);
    // Now three trailing bytes set to the same value as current w[n].
    w[n + 1] = w[n];
    w[n + 2] = w[n];
    w[n + 3] = w[n];

    // Now apply the back filter.
    float w_n1 = w[n + 1];
    int output_index = (row_width - 1) * output_pixel_stride;
    for (; c >= 0; output_index -= output_pixel_stride, --c, --n) {
      float w_n = BackwardFilter<order>(w, n, w[n], w_n1, b);
      w_n1 = w[n];
      w[n] = w_n;
      out[output_index] = FloatTo8<absolute_values>(w_n);
      max_output = std::max(max_output, out[output_index]);
    }
  }
  return max_output;
}

unsigned char SingleChannelRecursiveFilter(
    const unsigned char* const source_data,
    int source_pixel_stride,
    int source_row_stride,
    int row_width,
    int row_count,
    unsigned char* const output,
    int output_pixel_stride,
    int output_row_stride,
    const float* b,
    RecursiveFilter::Order order,
    bool absolute_values) {
  if (absolute_values) {
   switch (order) {
     case RecursiveFilter::FUNCTION:
       return SingleChannelRecursiveFilter<RecursiveFilter::FUNCTION, true>(
           source_data, source_pixel_stride, source_row_stride,
           row_width, row_count,
           output, output_pixel_stride, output_row_stride, b);
     case RecursiveFilter::FIRST_DERIVATIVE:
       return SingleChannelRecursiveFilter<
         RecursiveFilter::FIRST_DERIVATIVE, true>(
             source_data, source_pixel_stride, source_row_stride,
             row_width, row_count,
             output, output_pixel_stride, output_row_stride, b);
     case RecursiveFilter::SECOND_DERIVATIVE:
       return SingleChannelRecursiveFilter<
         RecursiveFilter::SECOND_DERIVATIVE, true>(
             source_data, source_pixel_stride, source_row_stride,
             row_width, row_count,
             output, output_pixel_stride, output_row_stride, b);
   }
  } else {
    switch (order) {
     case RecursiveFilter::FUNCTION:
       return SingleChannelRecursiveFilter<RecursiveFilter::FUNCTION, false>(
           source_data, source_pixel_stride, source_row_stride,
           row_width, row_count,
           output, output_pixel_stride, output_row_stride, b);
     case RecursiveFilter::FIRST_DERIVATIVE:
       return SingleChannelRecursiveFilter<
         RecursiveFilter::FIRST_DERIVATIVE, false>(
             source_data, source_pixel_stride, source_row_stride,
             row_width, row_count,
             output, output_pixel_stride, output_row_stride, b);
     case RecursiveFilter::SECOND_DERIVATIVE:
       return SingleChannelRecursiveFilter<
         RecursiveFilter::SECOND_DERIVATIVE, false>(
             source_data, source_pixel_stride, source_row_stride,
             row_width, row_count,
             output, output_pixel_stride, output_row_stride, b);
   }
  }

  NOTREACHED();
  return 0;
}

}

float RecursiveFilter::qFromSigma(float sigma) {
  DCHECK_GE(sigma, 0.5f);
  if (sigma <= 2.5f)
    return 3.97156f - 4.14554f * std::sqrt(1.0f - 0.26891f * sigma);
  return 0.98711f * sigma - 0.96330f;
}

void RecursiveFilter::computeCoefficients(float q, float b[4]) {
  b[0] = 1.57825f + 2.44413f * q + 1.4281f * q * q + 0.422205f * q * q * q;
  b[1] = 2.4413f * q + 2.85619f * q * q + 1.26661f * q * q * q;
  b[2] = - 1.4281f * q * q - 1.26661f * q * q * q;
  b[3] = 0.422205f * q * q * q;

  // The above is exactly like in the paper. To cut down on computations,
  // we can fix up these numbers a bit now.
  float b_norm = 1.0f - (b[1] + b[2] + b[3]) / b[0];
  b[1] /= b[0];
  b[2] /= b[0];
  b[3] /= b[0];
  b[0] = b_norm;
}

RecursiveFilter::RecursiveFilter(float sigma, Order order)
    : order_(order), q_(qFromSigma(sigma)) {
  computeCoefficients(q_, b_);
}

unsigned char SingleChannelRecursiveGaussianX(const unsigned char* source_data,
                                              int source_byte_row_stride,
                                              int input_channel_index,
                                              int input_channel_count,
                                              const RecursiveFilter& filter,
                                              const SkISize& image_size,
                                              unsigned char* output,
                                              int output_byte_row_stride,
                                              int output_channel_index,
                                              int output_channel_count,
                                              bool absolute_values) {
  return SingleChannelRecursiveFilter(source_data + input_channel_index,
                                      input_channel_count,
                                      source_byte_row_stride,
                                      image_size.width(),
                                      image_size.height(),
                                      output + output_channel_index,
                                      output_channel_count,
                                      output_byte_row_stride,
                                      filter.b(),
                                      filter.order(),
                                      absolute_values);
}

unsigned char  SingleChannelRecursiveGaussianY(const unsigned char* source_data,
                                               int source_byte_row_stride,
                                               int input_channel_index,
                                               int input_channel_count,
                                               const RecursiveFilter& filter,
                                               const SkISize& image_size,
                                               unsigned char* output,
                                               int output_byte_row_stride,
                                               int output_channel_index,
                                               int output_channel_count,
                                               bool absolute_values) {
  return SingleChannelRecursiveFilter(source_data + input_channel_index,
                                      source_byte_row_stride,
                                      input_channel_count,
                                      image_size.height(),
                                      image_size.width(),
                                      output + output_channel_index,
                                      output_byte_row_stride,
                                      output_channel_count,
                                      filter.b(),
                                      filter.order(),
                                      absolute_values);
}

}  // namespace skia
