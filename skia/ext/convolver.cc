// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>

#include "base/logging.h"
#include "skia/ext/convolver.h"
#include "skia/ext/convolver_SSE2.h"
#include "skia/ext/convolver_mips_dspr2.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkTypes.h"

namespace skia {

namespace {

// Converts the argument to an 8-bit unsigned value by clamping to the range
// 0-255.
inline unsigned char ClampTo8(int a) {
  if (static_cast<unsigned>(a) < 256)
    return a;  // Avoid the extra check in the common case.
  if (a < 0)
    return 0;
  return 255;
}

// Takes the value produced by accumulating element-wise product of image with
// a kernel and brings it back into range.
// All of the filter scaling factors are in fixed point with kShiftBits bits of
// fractional part.
inline unsigned char BringBackTo8(int a, bool take_absolute) {
  a >>= ConvolutionFilter1D::kShiftBits;
  if (take_absolute)
    a = std::abs(a);
  return ClampTo8(a);
}

// Stores a list of rows in a circular buffer. The usage is you write into it
// by calling AdvanceRow. It will keep track of which row in the buffer it
// should use next, and the total number of rows added.
class CircularRowBuffer {
 public:
  // The number of pixels in each row is given in |source_row_pixel_width|.
  // The maximum number of rows needed in the buffer is |max_y_filter_size|
  // (we only need to store enough rows for the biggest filter).
  //
  // We use the |first_input_row| to compute the coordinates of all of the
  // following rows returned by Advance().
  CircularRowBuffer(int dest_row_pixel_width, int max_y_filter_size,
                    int first_input_row)
      : row_byte_width_(dest_row_pixel_width * 4),
        num_rows_(max_y_filter_size),
        next_row_(0),
        next_row_coordinate_(first_input_row) {
    buffer_.resize(row_byte_width_ * max_y_filter_size);
    row_addresses_.resize(num_rows_);
  }

  // Moves to the next row in the buffer, returning a pointer to the beginning
  // of it.
  unsigned char* AdvanceRow() {
    unsigned char* row = &buffer_[next_row_ * row_byte_width_];
    next_row_coordinate_++;

    // Set the pointer to the next row to use, wrapping around if necessary.
    next_row_++;
    if (next_row_ == num_rows_)
      next_row_ = 0;
    return row;
  }

  // Returns a pointer to an "unrolled" array of rows. These rows will start
  // at the y coordinate placed into |*first_row_index| and will continue in
  // order for the maximum number of rows in this circular buffer.
  //
  // The |first_row_index_| may be negative. This means the circular buffer
  // starts before the top of the image (it hasn't been filled yet).
  unsigned char* const* GetRowAddresses(int* first_row_index) {
    // Example for a 4-element circular buffer holding coords 6-9.
    //   Row 0   Coord 8
    //   Row 1   Coord 9
    //   Row 2   Coord 6  <- next_row_ = 2, next_row_coordinate_ = 10.
    //   Row 3   Coord 7
    //
    // The "next" row is also the first (lowest) coordinate. This computation
    // may yield a negative value, but that's OK, the math will work out
    // since the user of this buffer will compute the offset relative
    // to the first_row_index and the negative rows will never be used.
    *first_row_index = next_row_coordinate_ - num_rows_;

    int cur_row = next_row_;
    for (int i = 0; i < num_rows_; i++) {
      row_addresses_[i] = &buffer_[cur_row * row_byte_width_];

      // Advance to the next row, wrapping if necessary.
      cur_row++;
      if (cur_row == num_rows_)
        cur_row = 0;
    }
    return &row_addresses_[0];
  }

 private:
  // The buffer storing the rows. They are packed, each one row_byte_width_.
  std::vector<unsigned char> buffer_;

  // Number of bytes per row in the |buffer_|.
  int row_byte_width_;

  // The number of rows available in the buffer.
  int num_rows_;

  // The next row index we should write into. This wraps around as the
  // circular buffer is used.
  int next_row_;

  // The y coordinate of the |next_row_|. This is incremented each time a
  // new row is appended and does not wrap.
  int next_row_coordinate_;

  // Buffer used by GetRowAddresses().
  std::vector<unsigned char*> row_addresses_;
};

// Convolves horizontally along a single row. The row data is given in
// |src_data| and continues for the num_values() of the filter.
template<bool has_alpha>
void ConvolveHorizontally(const unsigned char* src_data,
                          const ConvolutionFilter1D& filter,
                          unsigned char* out_row) {
  // Loop over each pixel on this row in the output image.
  int num_values = filter.num_values();
  for (int out_x = 0; out_x < num_values; out_x++) {
    // Get the filter that determines the current output pixel.
    int filter_offset, filter_length;
    const ConvolutionFilter1D::Fixed* filter_values =
        filter.FilterForValue(out_x, &filter_offset, &filter_length);

    // Compute the first pixel in this row that the filter affects. It will
    // touch |filter_length| pixels (4 bytes each) after this.
    const unsigned char* row_to_filter = &src_data[filter_offset * 4];

    // Apply the filter to the row to get the destination pixel in |accum|.
    int accum[4] = {0};
    for (int filter_x = 0; filter_x < filter_length; filter_x++) {
      ConvolutionFilter1D::Fixed cur_filter = filter_values[filter_x];
      accum[0] += cur_filter * row_to_filter[filter_x * 4 + 0];
      accum[1] += cur_filter * row_to_filter[filter_x * 4 + 1];
      accum[2] += cur_filter * row_to_filter[filter_x * 4 + 2];
      if (has_alpha)
        accum[3] += cur_filter * row_to_filter[filter_x * 4 + 3];
    }

    // Bring this value back in range. All of the filter scaling factors
    // are in fixed point with kShiftBits bits of fractional part.
    accum[0] >>= ConvolutionFilter1D::kShiftBits;
    accum[1] >>= ConvolutionFilter1D::kShiftBits;
    accum[2] >>= ConvolutionFilter1D::kShiftBits;
    if (has_alpha)
      accum[3] >>= ConvolutionFilter1D::kShiftBits;

    // Store the new pixel.
    out_row[out_x * 4 + 0] = ClampTo8(accum[0]);
    out_row[out_x * 4 + 1] = ClampTo8(accum[1]);
    out_row[out_x * 4 + 2] = ClampTo8(accum[2]);
    if (has_alpha)
      out_row[out_x * 4 + 3] = ClampTo8(accum[3]);
  }
}

// Does vertical convolution to produce one output row. The filter values and
// length are given in the first two parameters. These are applied to each
// of the rows pointed to in the |source_data_rows| array, with each row
// being |pixel_width| wide.
//
// The output must have room for |pixel_width * 4| bytes.
template<bool has_alpha>
void ConvolveVertically(const ConvolutionFilter1D::Fixed* filter_values,
                        int filter_length,
                        unsigned char* const* source_data_rows,
                        int pixel_width,
                        unsigned char* out_row) {
  // We go through each column in the output and do a vertical convolution,
  // generating one output pixel each time.
  for (int out_x = 0; out_x < pixel_width; out_x++) {
    // Compute the number of bytes over in each row that the current column
    // we're convolving starts at. The pixel will cover the next 4 bytes.
    int byte_offset = out_x * 4;

    // Apply the filter to one column of pixels.
    int accum[4] = {0};
    for (int filter_y = 0; filter_y < filter_length; filter_y++) {
      ConvolutionFilter1D::Fixed cur_filter = filter_values[filter_y];
      accum[0] += cur_filter * source_data_rows[filter_y][byte_offset + 0];
      accum[1] += cur_filter * source_data_rows[filter_y][byte_offset + 1];
      accum[2] += cur_filter * source_data_rows[filter_y][byte_offset + 2];
      if (has_alpha)
        accum[3] += cur_filter * source_data_rows[filter_y][byte_offset + 3];
    }

    // Bring this value back in range. All of the filter scaling factors
    // are in fixed point with kShiftBits bits of precision.
    accum[0] >>= ConvolutionFilter1D::kShiftBits;
    accum[1] >>= ConvolutionFilter1D::kShiftBits;
    accum[2] >>= ConvolutionFilter1D::kShiftBits;
    if (has_alpha)
      accum[3] >>= ConvolutionFilter1D::kShiftBits;

    // Store the new pixel.
    out_row[byte_offset + 0] = ClampTo8(accum[0]);
    out_row[byte_offset + 1] = ClampTo8(accum[1]);
    out_row[byte_offset + 2] = ClampTo8(accum[2]);
    if (has_alpha) {
      unsigned char alpha = ClampTo8(accum[3]);

      // Make sure the alpha channel doesn't come out smaller than any of the
      // color channels. We use premultipled alpha channels, so this should
      // never happen, but rounding errors will cause this from time to time.
      // These "impossible" colors will cause overflows (and hence random pixel
      // values) when the resulting bitmap is drawn to the screen.
      //
      // We only need to do this when generating the final output row (here).
      int max_color_channel = std::max(out_row[byte_offset + 0],
          std::max(out_row[byte_offset + 1], out_row[byte_offset + 2]));
      if (alpha < max_color_channel)
        out_row[byte_offset + 3] = max_color_channel;
      else
        out_row[byte_offset + 3] = alpha;
    } else {
      // No alpha channel, the image is opaque.
      out_row[byte_offset + 3] = 0xff;
    }
  }
}

void ConvolveVertically(const ConvolutionFilter1D::Fixed* filter_values,
                        int filter_length,
                        unsigned char* const* source_data_rows,
                        int pixel_width,
                        unsigned char* out_row,
                        bool source_has_alpha) {
  if (source_has_alpha) {
    ConvolveVertically<true>(filter_values, filter_length,
                             source_data_rows,
                             pixel_width,
                             out_row);
  } else {
    ConvolveVertically<false>(filter_values, filter_length,
                              source_data_rows,
                              pixel_width,
                              out_row);
  }
}

}  // namespace

// ConvolutionFilter1D ---------------------------------------------------------

ConvolutionFilter1D::ConvolutionFilter1D()
    : max_filter_(0) {
}

ConvolutionFilter1D::~ConvolutionFilter1D() {
}

void ConvolutionFilter1D::AddFilter(int filter_offset,
                                    const float* filter_values,
                                    int filter_length) {
  SkASSERT(filter_length > 0);

  std::vector<Fixed> fixed_values;
  fixed_values.reserve(filter_length);

  for (int i = 0; i < filter_length; ++i)
    fixed_values.push_back(FloatToFixed(filter_values[i]));

  AddFilter(filter_offset, &fixed_values[0], filter_length);
}

void ConvolutionFilter1D::AddFilter(int filter_offset,
                                    const Fixed* filter_values,
                                    int filter_length) {
  // It is common for leading/trailing filter values to be zeros. In such
  // cases it is beneficial to only store the central factors.
  // For a scaling to 1/4th in each dimension using a Lanczos-2 filter on
  // a 1080p image this optimization gives a ~10% speed improvement.
  int filter_size = filter_length;
  int first_non_zero = 0;
  while (first_non_zero < filter_length && filter_values[first_non_zero] == 0)
    first_non_zero++;

  if (first_non_zero < filter_length) {
    // Here we have at least one non-zero factor.
    int last_non_zero = filter_length - 1;
    while (last_non_zero >= 0 && filter_values[last_non_zero] == 0)
      last_non_zero--;

    filter_offset += first_non_zero;
    filter_length = last_non_zero + 1 - first_non_zero;
    SkASSERT(filter_length > 0);

    for (int i = first_non_zero; i <= last_non_zero; i++)
      filter_values_.push_back(filter_values[i]);
  } else {
    // Here all the factors were zeroes.
    filter_length = 0;
  }

  FilterInstance instance;

  // We pushed filter_length elements onto filter_values_
  instance.data_location = (static_cast<int>(filter_values_.size()) -
                            filter_length);
  instance.offset = filter_offset;
  instance.trimmed_length = filter_length;
  instance.length = filter_size;
  filters_.push_back(instance);

  max_filter_ = std::max(max_filter_, filter_length);
}

const ConvolutionFilter1D::Fixed* ConvolutionFilter1D::GetSingleFilter(
    int* specified_filter_length,
    int* filter_offset,
    int* filter_length) const {
  const FilterInstance& filter = filters_[0];
  *filter_offset = filter.offset;
  *filter_length = filter.trimmed_length;
  *specified_filter_length = filter.length;
  if (filter.trimmed_length == 0)
    return NULL;

  return &filter_values_[filter.data_location];
}

typedef void (*ConvolveVertically_pointer)(
    const ConvolutionFilter1D::Fixed* filter_values,
    int filter_length,
    unsigned char* const* source_data_rows,
    int pixel_width,
    unsigned char* out_row,
    bool has_alpha);
typedef void (*Convolve4RowsHorizontally_pointer)(
    const unsigned char* src_data[4],
    const ConvolutionFilter1D& filter,
    unsigned char* out_row[4]);
typedef void (*ConvolveHorizontally_pointer)(
    const unsigned char* src_data,
    const ConvolutionFilter1D& filter,
    unsigned char* out_row,
    bool has_alpha);

struct ConvolveProcs {
  // This is how many extra pixels may be read by the
  // conolve*horizontally functions.
  int extra_horizontal_reads;
  ConvolveVertically_pointer convolve_vertically;
  Convolve4RowsHorizontally_pointer convolve_4rows_horizontally;
  ConvolveHorizontally_pointer convolve_horizontally;
};

void SetupSIMD(ConvolveProcs *procs) {
#ifdef SIMD_SSE2
  procs->extra_horizontal_reads = 3;
  procs->convolve_vertically = &ConvolveVertically_SSE2;
  procs->convolve_4rows_horizontally = &Convolve4RowsHorizontally_SSE2;
  procs->convolve_horizontally = &ConvolveHorizontally_SSE2;
#elif defined SIMD_MIPS_DSPR2
  procs->extra_horizontal_reads = 3;
  procs->convolve_vertically = &ConvolveVertically_mips_dspr2;
  procs->convolve_horizontally = &ConvolveHorizontally_mips_dspr2;
#endif
}

void BGRAConvolve2D(const unsigned char* source_data,
                    int source_byte_row_stride,
                    bool source_has_alpha,
                    const ConvolutionFilter1D& filter_x,
                    const ConvolutionFilter1D& filter_y,
                    int output_byte_row_stride,
                    unsigned char* output,
                    bool use_simd_if_possible) {
  ConvolveProcs simd;
  simd.extra_horizontal_reads = 0;
  simd.convolve_vertically = NULL;
  simd.convolve_4rows_horizontally = NULL;
  simd.convolve_horizontally = NULL;
  if (use_simd_if_possible) {
    SetupSIMD(&simd);
  }

  int max_y_filter_size = filter_y.max_filter();

  // The next row in the input that we will generate a horizontally
  // convolved row for. If the filter doesn't start at the beginning of the
  // image (this is the case when we are only resizing a subset), then we
  // don't want to generate any output rows before that. Compute the starting
  // row for convolution as the first pixel for the first vertical filter.
  int filter_offset, filter_length;
  const ConvolutionFilter1D::Fixed* filter_values =
      filter_y.FilterForValue(0, &filter_offset, &filter_length);
  int next_x_row = filter_offset;

  // We loop over each row in the input doing a horizontal convolution. This
  // will result in a horizontally convolved image. We write the results into
  // a circular buffer of convolved rows and do vertical convolution as rows
  // are available. This prevents us from having to store the entire
  // intermediate image and helps cache coherency.
  // We will need four extra rows to allow horizontal convolution could be done
  // simultaneously. We also padding each row in row buffer to be aligned-up to
  // 16 bytes.
  // TODO(jiesun): We do not use aligned load from row buffer in vertical
  // convolution pass yet. Somehow Windows does not like it.
  int row_buffer_width = (filter_x.num_values() + 15) & ~0xF;
  int row_buffer_height = max_y_filter_size +
      (simd.convolve_4rows_horizontally ? 4 : 0);
  CircularRowBuffer row_buffer(row_buffer_width,
                               row_buffer_height,
                               filter_offset);

  // Loop over every possible output row, processing just enough horizontal
  // convolutions to run each subsequent vertical convolution.
  SkASSERT(output_byte_row_stride >= filter_x.num_values() * 4);
  int num_output_rows = filter_y.num_values();

  // We need to check which is the last line to convolve before we advance 4
  // lines in one iteration.
  int last_filter_offset, last_filter_length;

  // SSE2 can access up to 3 extra pixels past the end of the
  // buffer. At the bottom of the image, we have to be careful
  // not to access data past the end of the buffer. Normally
  // we fall back to the C++ implementation for the last row.
  // If the last row is less than 3 pixels wide, we may have to fall
  // back to the C++ version for more rows. Compute how many
  // rows we need to avoid the SSE implementation for here.
  filter_x.FilterForValue(filter_x.num_values() - 1, &last_filter_offset,
                          &last_filter_length);
  int avoid_simd_rows = 1 + simd.extra_horizontal_reads /
      (last_filter_offset + last_filter_length);

  filter_y.FilterForValue(num_output_rows - 1, &last_filter_offset,
                          &last_filter_length);

  for (int out_y = 0; out_y < num_output_rows; out_y++) {
    filter_values = filter_y.FilterForValue(out_y,
                                            &filter_offset, &filter_length);

    // Generate output rows until we have enough to run the current filter.
    while (next_x_row < filter_offset + filter_length) {
      if (simd.convolve_4rows_horizontally &&
          next_x_row + 3 < last_filter_offset + last_filter_length -
          avoid_simd_rows) {
        const unsigned char* src[4];
        unsigned char* out_row[4];
        for (int i = 0; i < 4; ++i) {
          src[i] = &source_data[(next_x_row + i) * source_byte_row_stride];
          out_row[i] = row_buffer.AdvanceRow();
        }
        simd.convolve_4rows_horizontally(src, filter_x, out_row);
        next_x_row += 4;
      } else {
        // Check if we need to avoid SSE2 for this row.
        if (simd.convolve_horizontally &&
            next_x_row < last_filter_offset + last_filter_length -
            avoid_simd_rows) {
          simd.convolve_horizontally(
              &source_data[next_x_row * source_byte_row_stride],
              filter_x, row_buffer.AdvanceRow(), source_has_alpha);
        } else {
          if (source_has_alpha) {
            ConvolveHorizontally<true>(
                &source_data[next_x_row * source_byte_row_stride],
                filter_x, row_buffer.AdvanceRow());
          } else {
            ConvolveHorizontally<false>(
                &source_data[next_x_row * source_byte_row_stride],
                filter_x, row_buffer.AdvanceRow());
          }
        }
        next_x_row++;
      }
    }

    // Compute where in the output image this row of final data will go.
    unsigned char* cur_output_row = &output[out_y * output_byte_row_stride];

    // Get the list of rows that the circular buffer has, in order.
    int first_row_in_circular_buffer;
    unsigned char* const* rows_to_convolve =
        row_buffer.GetRowAddresses(&first_row_in_circular_buffer);

    // Now compute the start of the subset of those rows that the filter
    // needs.
    unsigned char* const* first_row_for_filter =
        &rows_to_convolve[filter_offset - first_row_in_circular_buffer];

    if (simd.convolve_vertically) {
      simd.convolve_vertically(filter_values, filter_length,
                               first_row_for_filter,
                               filter_x.num_values(), cur_output_row,
                               source_has_alpha);
    } else {
      ConvolveVertically(filter_values, filter_length,
                         first_row_for_filter,
                         filter_x.num_values(), cur_output_row,
                         source_has_alpha);
    }
  }
}

void SingleChannelConvolveX1D(const unsigned char* source_data,
                              int source_byte_row_stride,
                              int input_channel_index,
                              int input_channel_count,
                              const ConvolutionFilter1D& filter,
                              const SkISize& image_size,
                              unsigned char* output,
                              int output_byte_row_stride,
                              int output_channel_index,
                              int output_channel_count,
                              bool absolute_values) {
  int filter_offset, filter_length, filter_size;
  // Very much unlike BGRAConvolve2D, here we expect to have the same filter
  // for all pixels.
  const ConvolutionFilter1D::Fixed* filter_values =
      filter.GetSingleFilter(&filter_size, &filter_offset, &filter_length);

  if (filter_values == NULL || image_size.width() < filter_size) {
    NOTREACHED();
    return;
  }

  int centrepoint = filter_length / 2;
  if (filter_size - filter_offset != 2 * filter_offset) {
    // This means the original filter was not symmetrical AND
    // got clipped from one side more than from the other.
    centrepoint = filter_size / 2 - filter_offset;
  }

  const unsigned char* source_data_row = source_data;
  unsigned char* output_row = output;

  for (int r = 0; r < image_size.height(); ++r) {
    unsigned char* target_byte = output_row + output_channel_index;
    // Process the lead part, padding image to the left with the first pixel.
    int c = 0;
    for (; c < centrepoint; ++c, target_byte += output_channel_count) {
      int accval = 0;
      int i = 0;
      int pixel_byte_index = input_channel_index;
      for (; i < centrepoint - c; ++i)  // Padding part.
        accval += filter_values[i] * source_data_row[pixel_byte_index];

      for (; i < filter_length; ++i, pixel_byte_index += input_channel_count)
        accval += filter_values[i] * source_data_row[pixel_byte_index];

      *target_byte = BringBackTo8(accval, absolute_values);
    }

    // Now for the main event.
    for (; c < image_size.width() - centrepoint;
         ++c, target_byte += output_channel_count) {
      int accval = 0;
      int pixel_byte_index = (c - centrepoint) * input_channel_count +
          input_channel_index;

      for (int i = 0; i < filter_length;
           ++i, pixel_byte_index += input_channel_count) {
        accval += filter_values[i] * source_data_row[pixel_byte_index];
      }

      *target_byte = BringBackTo8(accval, absolute_values);
    }

    for (; c < image_size.width(); ++c, target_byte += output_channel_count) {
      int accval = 0;
      int overlap_taps = image_size.width() - c + centrepoint;
      int pixel_byte_index = (c - centrepoint) * input_channel_count +
          input_channel_index;
      int i = 0;
      for (; i < overlap_taps - 1; ++i, pixel_byte_index += input_channel_count)
        accval += filter_values[i] * source_data_row[pixel_byte_index];

      for (; i < filter_length; ++i)
        accval += filter_values[i] * source_data_row[pixel_byte_index];

      *target_byte = BringBackTo8(accval, absolute_values);
    }

    source_data_row += source_byte_row_stride;
    output_row += output_byte_row_stride;
  }
}

void SingleChannelConvolveY1D(const unsigned char* source_data,
                              int source_byte_row_stride,
                              int input_channel_index,
                              int input_channel_count,
                              const ConvolutionFilter1D& filter,
                              const SkISize& image_size,
                              unsigned char* output,
                              int output_byte_row_stride,
                              int output_channel_index,
                              int output_channel_count,
                              bool absolute_values) {
  int filter_offset, filter_length, filter_size;
  // Very much unlike BGRAConvolve2D, here we expect to have the same filter
  // for all pixels.
  const ConvolutionFilter1D::Fixed* filter_values =
      filter.GetSingleFilter(&filter_size, &filter_offset, &filter_length);

  if (filter_values == NULL || image_size.height() < filter_size) {
    NOTREACHED();
    return;
  }

  int centrepoint = filter_length / 2;
  if (filter_size - filter_offset != 2 * filter_offset) {
    // This means the original filter was not symmetrical AND
    // got clipped from one side more than from the other.
    centrepoint = filter_size / 2 - filter_offset;
  }

  for (int c = 0; c < image_size.width(); ++c) {
    unsigned char* target_byte = output + c * output_channel_count +
        output_channel_index;
    int r = 0;

    for (; r < centrepoint; ++r, target_byte += output_byte_row_stride) {
      int accval = 0;
      int i = 0;
      int pixel_byte_index = c * input_channel_count + input_channel_index;

      for (; i < centrepoint - r; ++i)  // Padding part.
        accval += filter_values[i] * source_data[pixel_byte_index];

      for (; i < filter_length; ++i, pixel_byte_index += source_byte_row_stride)
        accval += filter_values[i] * source_data[pixel_byte_index];

      *target_byte = BringBackTo8(accval, absolute_values);
    }

    for (; r < image_size.height() - centrepoint;
         ++r, target_byte += output_byte_row_stride) {
      int accval = 0;
      int pixel_byte_index = (r - centrepoint) * source_byte_row_stride +
          c * input_channel_count + input_channel_index;
      for (int i = 0; i < filter_length;
           ++i, pixel_byte_index += source_byte_row_stride) {
        accval += filter_values[i] * source_data[pixel_byte_index];
      }

      *target_byte = BringBackTo8(accval, absolute_values);
    }

    for (; r < image_size.height();
         ++r, target_byte += output_byte_row_stride) {
      int accval = 0;
      int overlap_taps = image_size.height() - r + centrepoint;
      int pixel_byte_index = (r - centrepoint) * source_byte_row_stride +
          c * input_channel_count + input_channel_index;
      int i = 0;
      for (; i < overlap_taps - 1;
           ++i, pixel_byte_index += source_byte_row_stride) {
        accval += filter_values[i] * source_data[pixel_byte_index];
      }

      for (; i < filter_length; ++i)
        accval += filter_values[i] * source_data[pixel_byte_index];

      *target_byte = BringBackTo8(accval, absolute_values);
    }
  }
}

void SetUpGaussianConvolutionKernel(ConvolutionFilter1D* filter,
                                    float kernel_sigma,
                                    bool derivative) {
  DCHECK(filter != NULL);
  DCHECK_GT(kernel_sigma, 0.0);
  const int tail_length = static_cast<int>(4.0f * kernel_sigma + 0.5f);
  const int kernel_size = tail_length * 2 + 1;
  const float sigmasq = kernel_sigma * kernel_sigma;
  std::vector<float> kernel_weights(kernel_size, 0.0);
  float kernel_sum = 1.0f;

  kernel_weights[tail_length] = 1.0f;

  for (int ii = 1; ii <= tail_length; ++ii) {
    float v = std::exp(-0.5f * ii * ii / sigmasq);
    kernel_weights[tail_length + ii] = v;
    kernel_weights[tail_length - ii] = v;
    kernel_sum += 2.0f * v;
  }

  for (int i = 0; i < kernel_size; ++i)
    kernel_weights[i] /= kernel_sum;

  if (derivative) {
    kernel_weights[tail_length] = 0.0;
    for (int ii = 1; ii <= tail_length; ++ii) {
      float v = sigmasq * kernel_weights[tail_length + ii] / ii;
      kernel_weights[tail_length + ii] = v;
      kernel_weights[tail_length - ii] = -v;
    }
  }

  filter->AddFilter(0, &kernel_weights[0], kernel_weights.size());
}

}  // namespace skia
