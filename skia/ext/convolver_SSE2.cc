// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "skia/ext/convolver.h"
#include "skia/ext/convolver_SSE2.h"
#include "third_party/skia/include/core/SkTypes.h"

#include <emmintrin.h>  // ARCH_CPU_X86_FAMILY was defined in build/config.h

namespace skia {

// Convolves horizontally along a single row. The row data is given in
// |src_data| and continues for the num_values() of the filter.
void ConvolveHorizontally_SSE2(const unsigned char* src_data,
                               const ConvolutionFilter1D& filter,
                               unsigned char* out_row,
                               bool /*has_alpha*/) {
  int num_values = filter.num_values();

  int filter_offset, filter_length;
  __m128i zero = _mm_setzero_si128();
  __m128i mask[4];
  // |mask| will be used to decimate all extra filter coefficients that are
  // loaded by SIMD when |filter_length| is not divisible by 4.
  // mask[0] is not used in following algorithm.
  mask[1] = _mm_set_epi16(0, 0, 0, 0, 0, 0, 0, -1);
  mask[2] = _mm_set_epi16(0, 0, 0, 0, 0, 0, -1, -1);
  mask[3] = _mm_set_epi16(0, 0, 0, 0, 0, -1, -1, -1);

  // Output one pixel each iteration, calculating all channels (RGBA) together.
  for (int out_x = 0; out_x < num_values; out_x++) {
    const ConvolutionFilter1D::Fixed* filter_values =
        filter.FilterForValue(out_x, &filter_offset, &filter_length);

    __m128i accum = _mm_setzero_si128();

    // Compute the first pixel in this row that the filter affects. It will
    // touch |filter_length| pixels (4 bytes each) after this.
    const __m128i* row_to_filter =
        reinterpret_cast<const __m128i*>(&src_data[filter_offset << 2]);

    // We will load and accumulate with four coefficients per iteration.
    for (int filter_x = 0; filter_x < filter_length >> 2; filter_x++) {

      // Load 4 coefficients => duplicate 1st and 2nd of them for all channels.
      __m128i coeff, coeff16;
      // [16] xx xx xx xx c3 c2 c1 c0
      coeff = _mm_loadl_epi64(reinterpret_cast<const __m128i*>(filter_values));
      // [16] xx xx xx xx c1 c1 c0 c0
      coeff16 = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(1, 1, 0, 0));
      // [16] c1 c1 c1 c1 c0 c0 c0 c0
      coeff16 = _mm_unpacklo_epi16(coeff16, coeff16);

      // Load four pixels => unpack the first two pixels to 16 bits =>
      // multiply with coefficients => accumulate the convolution result.
      // [8] a3 b3 g3 r3 a2 b2 g2 r2 a1 b1 g1 r1 a0 b0 g0 r0
      __m128i src8 = _mm_loadu_si128(row_to_filter);
      // [16] a1 b1 g1 r1 a0 b0 g0 r0
      __m128i src16 = _mm_unpacklo_epi8(src8, zero);
      __m128i mul_hi = _mm_mulhi_epi16(src16, coeff16);
      __m128i mul_lo = _mm_mullo_epi16(src16, coeff16);
      // [32]  a0*c0 b0*c0 g0*c0 r0*c0
      __m128i t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);
      // [32]  a1*c1 b1*c1 g1*c1 r1*c1
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);

      // Duplicate 3rd and 4th coefficients for all channels =>
      // unpack the 3rd and 4th pixels to 16 bits => multiply with coefficients
      // => accumulate the convolution results.
      // [16] xx xx xx xx c3 c3 c2 c2
      coeff16 = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(3, 3, 2, 2));
      // [16] c3 c3 c3 c3 c2 c2 c2 c2
      coeff16 = _mm_unpacklo_epi16(coeff16, coeff16);
      // [16] a3 g3 b3 r3 a2 g2 b2 r2
      src16 = _mm_unpackhi_epi8(src8, zero);
      mul_hi = _mm_mulhi_epi16(src16, coeff16);
      mul_lo = _mm_mullo_epi16(src16, coeff16);
      // [32]  a2*c2 b2*c2 g2*c2 r2*c2
      t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);
      // [32]  a3*c3 b3*c3 g3*c3 r3*c3
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);

      // Advance the pixel and coefficients pointers.
      row_to_filter += 1;
      filter_values += 4;
    }

    // When |filter_length| is not divisible by 4, we need to decimate some of
    // the filter coefficient that was loaded incorrectly to zero; Other than
    // that the algorithm is same with above, exceot that the 4th pixel will be
    // always absent.
    int r = filter_length&3;
    if (r) {
      // Note: filter_values must be padded to align_up(filter_offset, 8).
      __m128i coeff, coeff16;
      coeff = _mm_loadl_epi64(reinterpret_cast<const __m128i*>(filter_values));
      // Mask out extra filter taps.
      coeff = _mm_and_si128(coeff, mask[r]);
      coeff16 = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(1, 1, 0, 0));
      coeff16 = _mm_unpacklo_epi16(coeff16, coeff16);

      // Note: line buffer must be padded to align_up(filter_offset, 16).
      // We resolve this by use C-version for the last horizontal line.
      __m128i src8 = _mm_loadu_si128(row_to_filter);
      __m128i src16 = _mm_unpacklo_epi8(src8, zero);
      __m128i mul_hi = _mm_mulhi_epi16(src16, coeff16);
      __m128i mul_lo = _mm_mullo_epi16(src16, coeff16);
      __m128i t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);

      src16 = _mm_unpackhi_epi8(src8, zero);
      coeff16 = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(3, 3, 2, 2));
      coeff16 = _mm_unpacklo_epi16(coeff16, coeff16);
      mul_hi = _mm_mulhi_epi16(src16, coeff16);
      mul_lo = _mm_mullo_epi16(src16, coeff16);
      t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum = _mm_add_epi32(accum, t);
    }

    // Shift right for fixed point implementation.
    accum = _mm_srai_epi32(accum, ConvolutionFilter1D::kShiftBits);

    // Packing 32 bits |accum| to 16 bits per channel (signed saturation).
    accum = _mm_packs_epi32(accum, zero);
    // Packing 16 bits |accum| to 8 bits per channel (unsigned saturation).
    accum = _mm_packus_epi16(accum, zero);

    // Store the pixel value of 32 bits.
    *(reinterpret_cast<int*>(out_row)) = _mm_cvtsi128_si32(accum);
    out_row += 4;
  }
}

// Convolves horizontally along four rows. The row data is given in
// |src_data| and continues for the num_values() of the filter.
// The algorithm is almost same as |ConvolveHorizontally_SSE2|. Please
// refer to that function for detailed comments.
void Convolve4RowsHorizontally_SSE2(const unsigned char* src_data[4],
                                    const ConvolutionFilter1D& filter,
                                    unsigned char* out_row[4]) {
  int num_values = filter.num_values();

  int filter_offset, filter_length;
  __m128i zero = _mm_setzero_si128();
  __m128i mask[4];
  // |mask| will be used to decimate all extra filter coefficients that are
  // loaded by SIMD when |filter_length| is not divisible by 4.
  // mask[0] is not used in following algorithm.
  mask[1] = _mm_set_epi16(0, 0, 0, 0, 0, 0, 0, -1);
  mask[2] = _mm_set_epi16(0, 0, 0, 0, 0, 0, -1, -1);
  mask[3] = _mm_set_epi16(0, 0, 0, 0, 0, -1, -1, -1);

  // Output one pixel each iteration, calculating all channels (RGBA) together.
  for (int out_x = 0; out_x < num_values; out_x++) {
    const ConvolutionFilter1D::Fixed* filter_values =
        filter.FilterForValue(out_x, &filter_offset, &filter_length);

    // four pixels in a column per iteration.
    __m128i accum0 = _mm_setzero_si128();
    __m128i accum1 = _mm_setzero_si128();
    __m128i accum2 = _mm_setzero_si128();
    __m128i accum3 = _mm_setzero_si128();
    int start = (filter_offset<<2);
    // We will load and accumulate with four coefficients per iteration.
    for (int filter_x = 0; filter_x < (filter_length >> 2); filter_x++) {
      __m128i coeff, coeff16lo, coeff16hi;
      // [16] xx xx xx xx c3 c2 c1 c0
      coeff = _mm_loadl_epi64(reinterpret_cast<const __m128i*>(filter_values));
      // [16] xx xx xx xx c1 c1 c0 c0
      coeff16lo = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(1, 1, 0, 0));
      // [16] c1 c1 c1 c1 c0 c0 c0 c0
      coeff16lo = _mm_unpacklo_epi16(coeff16lo, coeff16lo);
      // [16] xx xx xx xx c3 c3 c2 c2
      coeff16hi = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(3, 3, 2, 2));
      // [16] c3 c3 c3 c3 c2 c2 c2 c2
      coeff16hi = _mm_unpacklo_epi16(coeff16hi, coeff16hi);

      __m128i src8, src16, mul_hi, mul_lo, t;

#define ITERATION(src, accum)                                          \
      src8 = _mm_loadu_si128(reinterpret_cast<const __m128i*>(src));   \
      src16 = _mm_unpacklo_epi8(src8, zero);                           \
      mul_hi = _mm_mulhi_epi16(src16, coeff16lo);                      \
      mul_lo = _mm_mullo_epi16(src16, coeff16lo);                      \
      t = _mm_unpacklo_epi16(mul_lo, mul_hi);                          \
      accum = _mm_add_epi32(accum, t);                                 \
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);                          \
      accum = _mm_add_epi32(accum, t);                                 \
      src16 = _mm_unpackhi_epi8(src8, zero);                           \
      mul_hi = _mm_mulhi_epi16(src16, coeff16hi);                      \
      mul_lo = _mm_mullo_epi16(src16, coeff16hi);                      \
      t = _mm_unpacklo_epi16(mul_lo, mul_hi);                          \
      accum = _mm_add_epi32(accum, t);                                 \
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);                          \
      accum = _mm_add_epi32(accum, t)

      ITERATION(src_data[0] + start, accum0);
      ITERATION(src_data[1] + start, accum1);
      ITERATION(src_data[2] + start, accum2);
      ITERATION(src_data[3] + start, accum3);

      start += 16;
      filter_values += 4;
    }

    int r = filter_length & 3;
    if (r) {
      // Note: filter_values must be padded to align_up(filter_offset, 8);
      __m128i coeff;
      coeff = _mm_loadl_epi64(reinterpret_cast<const __m128i*>(filter_values));
      // Mask out extra filter taps.
      coeff = _mm_and_si128(coeff, mask[r]);

      __m128i coeff16lo = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(1, 1, 0, 0));
      /* c1 c1 c1 c1 c0 c0 c0 c0 */
      coeff16lo = _mm_unpacklo_epi16(coeff16lo, coeff16lo);
      __m128i coeff16hi = _mm_shufflelo_epi16(coeff, _MM_SHUFFLE(3, 3, 2, 2));
      coeff16hi = _mm_unpacklo_epi16(coeff16hi, coeff16hi);

      __m128i src8, src16, mul_hi, mul_lo, t;

      ITERATION(src_data[0] + start, accum0);
      ITERATION(src_data[1] + start, accum1);
      ITERATION(src_data[2] + start, accum2);
      ITERATION(src_data[3] + start, accum3);
    }

    accum0 = _mm_srai_epi32(accum0, ConvolutionFilter1D::kShiftBits);
    accum0 = _mm_packs_epi32(accum0, zero);
    accum0 = _mm_packus_epi16(accum0, zero);
    accum1 = _mm_srai_epi32(accum1, ConvolutionFilter1D::kShiftBits);
    accum1 = _mm_packs_epi32(accum1, zero);
    accum1 = _mm_packus_epi16(accum1, zero);
    accum2 = _mm_srai_epi32(accum2, ConvolutionFilter1D::kShiftBits);
    accum2 = _mm_packs_epi32(accum2, zero);
    accum2 = _mm_packus_epi16(accum2, zero);
    accum3 = _mm_srai_epi32(accum3, ConvolutionFilter1D::kShiftBits);
    accum3 = _mm_packs_epi32(accum3, zero);
    accum3 = _mm_packus_epi16(accum3, zero);

    *(reinterpret_cast<int*>(out_row[0])) = _mm_cvtsi128_si32(accum0);
    *(reinterpret_cast<int*>(out_row[1])) = _mm_cvtsi128_si32(accum1);
    *(reinterpret_cast<int*>(out_row[2])) = _mm_cvtsi128_si32(accum2);
    *(reinterpret_cast<int*>(out_row[3])) = _mm_cvtsi128_si32(accum3);

    out_row[0] += 4;
    out_row[1] += 4;
    out_row[2] += 4;
    out_row[3] += 4;
  }
}

// Does vertical convolution to produce one output row. The filter values and
// length are given in the first two parameters. These are applied to each
// of the rows pointed to in the |source_data_rows| array, with each row
// being |pixel_width| wide.
//
// The output must have room for |pixel_width * 4| bytes.
template<bool has_alpha>
void ConvolveVertically_SSE2(const ConvolutionFilter1D::Fixed* filter_values,
                             int filter_length,
                             unsigned char* const* source_data_rows,
                             int pixel_width,
                             unsigned char* out_row) {
  int width = pixel_width & ~3;

  __m128i zero = _mm_setzero_si128();
  __m128i accum0, accum1, accum2, accum3, coeff16;
  const __m128i* src;
  // Output four pixels per iteration (16 bytes).
  for (int out_x = 0; out_x < width; out_x += 4) {

    // Accumulated result for each pixel. 32 bits per RGBA channel.
    accum0 = _mm_setzero_si128();
    accum1 = _mm_setzero_si128();
    accum2 = _mm_setzero_si128();
    accum3 = _mm_setzero_si128();

    // Convolve with one filter coefficient per iteration.
    for (int filter_y = 0; filter_y < filter_length; filter_y++) {

      // Duplicate the filter coefficient 8 times.
      // [16] cj cj cj cj cj cj cj cj
      coeff16 = _mm_set1_epi16(filter_values[filter_y]);

      // Load four pixels (16 bytes) together.
      // [8] a3 b3 g3 r3 a2 b2 g2 r2 a1 b1 g1 r1 a0 b0 g0 r0
      src = reinterpret_cast<const __m128i*>(
          &source_data_rows[filter_y][out_x << 2]);
      __m128i src8 = _mm_loadu_si128(src);

      // Unpack 1st and 2nd pixels from 8 bits to 16 bits for each channels =>
      // multiply with current coefficient => accumulate the result.
      // [16] a1 b1 g1 r1 a0 b0 g0 r0
      __m128i src16 = _mm_unpacklo_epi8(src8, zero);
      __m128i mul_hi = _mm_mulhi_epi16(src16, coeff16);
      __m128i mul_lo = _mm_mullo_epi16(src16, coeff16);
      // [32] a0 b0 g0 r0
      __m128i t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum0 = _mm_add_epi32(accum0, t);
      // [32] a1 b1 g1 r1
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);
      accum1 = _mm_add_epi32(accum1, t);

      // Unpack 3rd and 4th pixels from 8 bits to 16 bits for each channels =>
      // multiply with current coefficient => accumulate the result.
      // [16] a3 b3 g3 r3 a2 b2 g2 r2
      src16 = _mm_unpackhi_epi8(src8, zero);
      mul_hi = _mm_mulhi_epi16(src16, coeff16);
      mul_lo = _mm_mullo_epi16(src16, coeff16);
      // [32] a2 b2 g2 r2
      t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum2 = _mm_add_epi32(accum2, t);
      // [32] a3 b3 g3 r3
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);
      accum3 = _mm_add_epi32(accum3, t);
    }

    // Shift right for fixed point implementation.
    accum0 = _mm_srai_epi32(accum0, ConvolutionFilter1D::kShiftBits);
    accum1 = _mm_srai_epi32(accum1, ConvolutionFilter1D::kShiftBits);
    accum2 = _mm_srai_epi32(accum2, ConvolutionFilter1D::kShiftBits);
    accum3 = _mm_srai_epi32(accum3, ConvolutionFilter1D::kShiftBits);

    // Packing 32 bits |accum| to 16 bits per channel (signed saturation).
    // [16] a1 b1 g1 r1 a0 b0 g0 r0
    accum0 = _mm_packs_epi32(accum0, accum1);
    // [16] a3 b3 g3 r3 a2 b2 g2 r2
    accum2 = _mm_packs_epi32(accum2, accum3);

    // Packing 16 bits |accum| to 8 bits per channel (unsigned saturation).
    // [8] a3 b3 g3 r3 a2 b2 g2 r2 a1 b1 g1 r1 a0 b0 g0 r0
    accum0 = _mm_packus_epi16(accum0, accum2);

    if (has_alpha) {
      // Compute the max(ri, gi, bi) for each pixel.
      // [8] xx a3 b3 g3 xx a2 b2 g2 xx a1 b1 g1 xx a0 b0 g0
      __m128i a = _mm_srli_epi32(accum0, 8);
      // [8] xx xx xx max3 xx xx xx max2 xx xx xx max1 xx xx xx max0
      __m128i b = _mm_max_epu8(a, accum0);  // Max of r and g.
      // [8] xx xx a3 b3 xx xx a2 b2 xx xx a1 b1 xx xx a0 b0
      a = _mm_srli_epi32(accum0, 16);
      // [8] xx xx xx max3 xx xx xx max2 xx xx xx max1 xx xx xx max0
      b = _mm_max_epu8(a, b);  // Max of r and g and b.
      // [8] max3 00 00 00 max2 00 00 00 max1 00 00 00 max0 00 00 00
      b = _mm_slli_epi32(b, 24);

      // Make sure the value of alpha channel is always larger than maximum
      // value of color channels.
      accum0 = _mm_max_epu8(b, accum0);
    } else {
      // Set value of alpha channels to 0xFF.
      __m128i mask = _mm_set1_epi32(0xff000000);
      accum0 = _mm_or_si128(accum0, mask);
    }

    // Store the convolution result (16 bytes) and advance the pixel pointers.
    _mm_storeu_si128(reinterpret_cast<__m128i*>(out_row), accum0);
    out_row += 16;
  }

  // When the width of the output is not divisible by 4, We need to save one
  // pixel (4 bytes) each time. And also the fourth pixel is always absent.
  if (pixel_width & 3) {
    accum0 = _mm_setzero_si128();
    accum1 = _mm_setzero_si128();
    accum2 = _mm_setzero_si128();
    for (int filter_y = 0; filter_y < filter_length; ++filter_y) {
      coeff16 = _mm_set1_epi16(filter_values[filter_y]);
      // [8] a3 b3 g3 r3 a2 b2 g2 r2 a1 b1 g1 r1 a0 b0 g0 r0
      src = reinterpret_cast<const __m128i*>(
          &source_data_rows[filter_y][width<<2]);
      __m128i src8 = _mm_loadu_si128(src);
      // [16] a1 b1 g1 r1 a0 b0 g0 r0
      __m128i src16 = _mm_unpacklo_epi8(src8, zero);
      __m128i mul_hi = _mm_mulhi_epi16(src16, coeff16);
      __m128i mul_lo = _mm_mullo_epi16(src16, coeff16);
      // [32] a0 b0 g0 r0
      __m128i t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum0 = _mm_add_epi32(accum0, t);
      // [32] a1 b1 g1 r1
      t = _mm_unpackhi_epi16(mul_lo, mul_hi);
      accum1 = _mm_add_epi32(accum1, t);
      // [16] a3 b3 g3 r3 a2 b2 g2 r2
      src16 = _mm_unpackhi_epi8(src8, zero);
      mul_hi = _mm_mulhi_epi16(src16, coeff16);
      mul_lo = _mm_mullo_epi16(src16, coeff16);
      // [32] a2 b2 g2 r2
      t = _mm_unpacklo_epi16(mul_lo, mul_hi);
      accum2 = _mm_add_epi32(accum2, t);
    }

    accum0 = _mm_srai_epi32(accum0, ConvolutionFilter1D::kShiftBits);
    accum1 = _mm_srai_epi32(accum1, ConvolutionFilter1D::kShiftBits);
    accum2 = _mm_srai_epi32(accum2, ConvolutionFilter1D::kShiftBits);
    // [16] a1 b1 g1 r1 a0 b0 g0 r0
    accum0 = _mm_packs_epi32(accum0, accum1);
    // [16] a3 b3 g3 r3 a2 b2 g2 r2
    accum2 = _mm_packs_epi32(accum2, zero);
    // [8] a3 b3 g3 r3 a2 b2 g2 r2 a1 b1 g1 r1 a0 b0 g0 r0
    accum0 = _mm_packus_epi16(accum0, accum2);
    if (has_alpha) {
      // [8] xx a3 b3 g3 xx a2 b2 g2 xx a1 b1 g1 xx a0 b0 g0
      __m128i a = _mm_srli_epi32(accum0, 8);
      // [8] xx xx xx max3 xx xx xx max2 xx xx xx max1 xx xx xx max0
      __m128i b = _mm_max_epu8(a, accum0);  // Max of r and g.
      // [8] xx xx a3 b3 xx xx a2 b2 xx xx a1 b1 xx xx a0 b0
      a = _mm_srli_epi32(accum0, 16);
      // [8] xx xx xx max3 xx xx xx max2 xx xx xx max1 xx xx xx max0
      b = _mm_max_epu8(a, b);  // Max of r and g and b.
      // [8] max3 00 00 00 max2 00 00 00 max1 00 00 00 max0 00 00 00
      b = _mm_slli_epi32(b, 24);
      accum0 = _mm_max_epu8(b, accum0);
    } else {
      __m128i mask = _mm_set1_epi32(0xff000000);
      accum0 = _mm_or_si128(accum0, mask);
    }

    for (int out_x = width; out_x < pixel_width; out_x++) {
      *(reinterpret_cast<int*>(out_row)) = _mm_cvtsi128_si32(accum0);
      accum0 = _mm_srli_si128(accum0, 4);
      out_row += 4;
    }
  }
}

void ConvolveVertically_SSE2(const ConvolutionFilter1D::Fixed* filter_values,
                             int filter_length,
                             unsigned char* const* source_data_rows,
                             int pixel_width,
                             unsigned char* out_row,
                             bool has_alpha) {
  if (has_alpha) {
    ConvolveVertically_SSE2<true>(filter_values,
                                  filter_length,
                                  source_data_rows,
                                  pixel_width,
                                  out_row);
  } else {
    ConvolveVertically_SSE2<false>(filter_values,
                                   filter_length,
                                   source_data_rows,
                                   pixel_width,
                                   out_row);
  }
}

}  // namespace skia
