// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string.h>
#include <time.h>
#include <algorithm>
#include <numeric>
#include <vector>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/time/time.h"
#include "skia/ext/convolver.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkColorPriv.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTypes.h"

namespace skia {

namespace {

// Fills the given filter with impulse functions for the range 0->num_entries.
void FillImpulseFilter(int num_entries, ConvolutionFilter1D* filter) {
  float one = 1.0f;
  for (int i = 0; i < num_entries; i++)
    filter->AddFilter(i, &one, 1);
}

// Filters the given input with the impulse function, and verifies that it
// does not change.
void TestImpulseConvolution(const unsigned char* data, int width, int height) {
  int byte_count = width * height * 4;

  ConvolutionFilter1D filter_x;
  FillImpulseFilter(width, &filter_x);

  ConvolutionFilter1D filter_y;
  FillImpulseFilter(height, &filter_y);

  std::vector<unsigned char> output;
  output.resize(byte_count);
  BGRAConvolve2D(data, width * 4, true, filter_x, filter_y,
                 filter_x.num_values() * 4, &output[0], false);

  // Output should exactly match input.
  EXPECT_EQ(0, memcmp(data, &output[0], byte_count));
}

// Fills the destination filter with a box filter averaging every two pixels
// to produce the output.
void FillBoxFilter(int size, ConvolutionFilter1D* filter) {
  const float box[2] = { 0.5, 0.5 };
  for (int i = 0; i < size; i++)
    filter->AddFilter(i * 2, box, 2);
}

}  // namespace

// Tests that each pixel, when set and run through the impulse filter, does
// not change.
TEST(Convolver, Impulse) {
  // We pick an "odd" size that is not likely to fit on any boundaries so that
  // we can see if all the widths and paddings are handled properly.
  int width = 15;
  int height = 31;
  int byte_count = width * height * 4;
  std::vector<unsigned char> input;
  input.resize(byte_count);

  unsigned char* input_ptr = &input[0];
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      for (int channel = 0; channel < 3; channel++) {
        memset(input_ptr, 0, byte_count);
        input_ptr[(y * width + x) * 4 + channel] = 0xff;
        // Always set the alpha channel or it will attempt to "fix" it for us.
        input_ptr[(y * width + x) * 4 + 3] = 0xff;
        TestImpulseConvolution(input_ptr, width, height);
      }
    }
  }
}

// Tests that using a box filter to halve an image results in every square of 4
// pixels in the original get averaged to a pixel in the output.
TEST(Convolver, Halve) {
  static const int kSize = 16;

  int src_width = kSize;
  int src_height = kSize;
  int src_row_stride = src_width * 4;
  int src_byte_count = src_row_stride * src_height;
  std::vector<unsigned char> input;
  input.resize(src_byte_count);

  int dest_width = src_width / 2;
  int dest_height = src_height / 2;
  int dest_byte_count = dest_width * dest_height * 4;
  std::vector<unsigned char> output;
  output.resize(dest_byte_count);

  // First fill the array with a bunch of random data.
  srand(static_cast<unsigned>(time(NULL)));
  for (int i = 0; i < src_byte_count; i++)
    input[i] = rand() * 255 / RAND_MAX;

  // Compute the filters.
  ConvolutionFilter1D filter_x, filter_y;
  FillBoxFilter(dest_width, &filter_x);
  FillBoxFilter(dest_height, &filter_y);

  // Do the convolution.
  BGRAConvolve2D(&input[0], src_width, true, filter_x, filter_y,
                 filter_x.num_values() * 4, &output[0], false);

  // Compute the expected results and check, allowing for a small difference
  // to account for rounding errors.
  for (int y = 0; y < dest_height; y++) {
    for (int x = 0; x < dest_width; x++) {
      for (int channel = 0; channel < 4; channel++) {
        int src_offset = (y * 2 * src_row_stride + x * 2 * 4) + channel;
        int value = input[src_offset] +  // Top left source pixel.
                    input[src_offset + 4] +  // Top right source pixel.
                    input[src_offset + src_row_stride] +  // Lower left.
                    input[src_offset + src_row_stride + 4];  // Lower right.
        value /= 4;  // Average.
        int difference = value - output[(y * dest_width + x) * 4 + channel];
        EXPECT_TRUE(difference >= -1 || difference <= 1);
      }
    }
  }
}

// Tests the optimization in Convolver1D::AddFilter that avoids storing
// leading/trailing zeroes.
TEST(Convolver, AddFilter) {
  skia::ConvolutionFilter1D filter;

  const skia::ConvolutionFilter1D::Fixed* values = NULL;
  int filter_offset = 0;
  int filter_length = 0;

  // An all-zero filter is handled correctly, all factors ignored
  static const float factors1[] = { 0.0f, 0.0f, 0.0f };
  filter.AddFilter(11, factors1, arraysize(factors1));
  ASSERT_EQ(0, filter.max_filter());
  ASSERT_EQ(1, filter.num_values());

  values = filter.FilterForValue(0, &filter_offset, &filter_length);
  ASSERT_TRUE(values == NULL);   // No values => NULL.
  ASSERT_EQ(11, filter_offset);  // Same as input offset.
  ASSERT_EQ(0, filter_length);   // But no factors since all are zeroes.

  // Zeroes on the left are ignored
  static const float factors2[] = { 0.0f, 1.0f, 1.0f, 1.0f, 1.0f };
  filter.AddFilter(22, factors2, arraysize(factors2));
  ASSERT_EQ(4, filter.max_filter());
  ASSERT_EQ(2, filter.num_values());

  values = filter.FilterForValue(1, &filter_offset, &filter_length);
  ASSERT_TRUE(values != NULL);
  ASSERT_EQ(23, filter_offset);  // 22 plus 1 leading zero
  ASSERT_EQ(4, filter_length);   // 5 - 1 leading zero

  // Zeroes on the right are ignored
  static const float factors3[] = { 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f };
  filter.AddFilter(33, factors3, arraysize(factors3));
  ASSERT_EQ(5, filter.max_filter());
  ASSERT_EQ(3, filter.num_values());

  values = filter.FilterForValue(2, &filter_offset, &filter_length);
  ASSERT_TRUE(values != NULL);
  ASSERT_EQ(33, filter_offset);  // 33, same as input due to no leading zero
  ASSERT_EQ(5, filter_length);   // 7 - 2 trailing zeroes

  // Zeroes in leading & trailing positions
  static const float factors4[] = { 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f };
  filter.AddFilter(44, factors4, arraysize(factors4));
  ASSERT_EQ(5, filter.max_filter());  // No change from existing value.
  ASSERT_EQ(4, filter.num_values());

  values = filter.FilterForValue(3, &filter_offset, &filter_length);
  ASSERT_TRUE(values != NULL);
  ASSERT_EQ(46, filter_offset);  // 44 plus 2 leading zeroes
  ASSERT_EQ(3, filter_length);   // 7 - (2 leading + 2 trailing) zeroes

  // Zeroes surrounded by non-zero values are ignored
  static const float factors5[] = { 0.0f, 0.0f,
                                    1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f,
                                    0.0f };
  filter.AddFilter(55, factors5, arraysize(factors5));
  ASSERT_EQ(6, filter.max_filter());
  ASSERT_EQ(5, filter.num_values());

  values = filter.FilterForValue(4, &filter_offset, &filter_length);
  ASSERT_TRUE(values != NULL);
  ASSERT_EQ(57, filter_offset);  // 55 plus 2 leading zeroes
  ASSERT_EQ(6, filter_length);   // 9 - (2 leading + 1 trailing) zeroes

  // All-zero filters after the first one also work
  static const float factors6[] = { 0.0f };
  filter.AddFilter(66, factors6, arraysize(factors6));
  ASSERT_EQ(6, filter.max_filter());
  ASSERT_EQ(6, filter.num_values());

  values = filter.FilterForValue(5, &filter_offset, &filter_length);
  ASSERT_TRUE(values == NULL);   // filter_length == 0 => values is NULL
  ASSERT_EQ(66, filter_offset);  // value passed in
  ASSERT_EQ(0, filter_length);
}

void VerifySIMD(unsigned int source_width,
                unsigned int source_height,
                unsigned int dest_width,
                unsigned int dest_height) {
  float filter[] = { 0.05f, -0.15f, 0.6f, 0.6f, -0.15f, 0.05f };
  // Preparing convolve coefficients.
  ConvolutionFilter1D x_filter, y_filter;
  for (unsigned int p = 0; p < dest_width; ++p) {
    unsigned int offset = source_width * p / dest_width;
    EXPECT_LT(offset, source_width);
    x_filter.AddFilter(offset, filter,
                       std::min<int>(arraysize(filter),
                                     source_width - offset));
  }
  x_filter.PaddingForSIMD();
  for (unsigned int p = 0; p < dest_height; ++p) {
    unsigned int offset = source_height * p / dest_height;
    y_filter.AddFilter(offset, filter,
                       std::min<int>(arraysize(filter),
                                     source_height - offset));
  }
  y_filter.PaddingForSIMD();

  // Allocate input and output skia bitmap.
  SkBitmap source, result_c, result_sse;
  source.allocN32Pixels(source_width, source_height);
  result_c.allocN32Pixels(dest_width, dest_height);
  result_sse.allocN32Pixels(dest_width, dest_height);

  // Randomize source bitmap for testing.
  unsigned char* src_ptr = static_cast<unsigned char*>(source.getPixels());
  for (int y = 0; y < source.height(); y++) {
    for (unsigned int x = 0; x < source.rowBytes(); x++)
      src_ptr[x] = rand() % 255;
    src_ptr += source.rowBytes();
  }

  // Test both cases with different has_alpha.
  for (int alpha = 0; alpha < 2; alpha++) {
    // Convolve using C code.
    base::TimeTicks resize_start;
    base::TimeDelta delta_c, delta_sse;
    unsigned char* r1 = static_cast<unsigned char*>(result_c.getPixels());
    unsigned char* r2 = static_cast<unsigned char*>(result_sse.getPixels());

    resize_start = base::TimeTicks::Now();
    BGRAConvolve2D(static_cast<const uint8*>(source.getPixels()),
                   static_cast<int>(source.rowBytes()),
                   (alpha != 0), x_filter, y_filter,
                   static_cast<int>(result_c.rowBytes()), r1, false);
    delta_c = base::TimeTicks::Now() - resize_start;

    resize_start = base::TimeTicks::Now();
    // Convolve using SSE2 code
    BGRAConvolve2D(static_cast<const uint8*>(source.getPixels()),
                   static_cast<int>(source.rowBytes()),
                   (alpha != 0), x_filter, y_filter,
                   static_cast<int>(result_sse.rowBytes()), r2, true);
    delta_sse = base::TimeTicks::Now() - resize_start;

    // Unfortunately I could not enable the performance check now.
    // Most bots use debug version, and there are great difference between
    // the code generation for intrinsic, etc. In release version speed
    // difference was 150%-200% depend on alpha channel presence;
    // while in debug version speed difference was 96%-120%.
    // TODO(jiesun): optimize further until we could enable this for
    // debug version too.
    // EXPECT_LE(delta_sse, delta_c);

    int64 c_us = delta_c.InMicroseconds();
    int64 sse_us = delta_sse.InMicroseconds();
    VLOG(1) << "from:" << source_width << "x" << source_height
            << " to:" << dest_width << "x" << dest_height
            << (alpha ? " with alpha" : " w/o alpha");
    VLOG(1) << "c:" << c_us << " sse:" << sse_us;
    VLOG(1) << "ratio:" << static_cast<float>(c_us) / sse_us;

    // Comparing result.
    for (unsigned int i = 0; i < dest_height; i++) {
      EXPECT_FALSE(memcmp(r1, r2, dest_width * 4)); // RGBA always
      r1 += result_c.rowBytes();
      r2 += result_sse.rowBytes();
    }
  }
}

TEST(Convolver, VerifySIMDEdgeCases) {
  srand(static_cast<unsigned int>(time(0)));
  // Loop over all possible (small) image sizes
  for (unsigned int width = 1; width < 20; width++) {
    for (unsigned int height = 1; height < 20; height++) {
      VerifySIMD(width, height, 8, 8);
      VerifySIMD(8, 8, width, height);
    }
  }
}

// Verify that lage upscales/downscales produce the same result
// with and without SIMD.
TEST(Convolver, VerifySIMDPrecision) {
  int source_sizes[][2] = { {1920, 1080}, {1377, 523}, {325, 241} };
  int dest_sizes[][2] = { {1280, 1024}, {177, 123} };

  srand(static_cast<unsigned int>(time(0)));

  // Loop over some specific source and destination dimensions.
  for (unsigned int i = 0; i < arraysize(source_sizes); ++i) {
    unsigned int source_width = source_sizes[i][0];
    unsigned int source_height = source_sizes[i][1];
    for (unsigned int j = 0; j < arraysize(dest_sizes); ++j) {
      unsigned int dest_width = dest_sizes[j][0];
      unsigned int dest_height = dest_sizes[j][1];
      VerifySIMD(source_width, source_height, dest_width, dest_height);
    }
  }
}

TEST(Convolver, SeparableSingleConvolution) {
  static const int kImgWidth = 1024;
  static const int kImgHeight = 1024;
  static const int kChannelCount = 3;
  static const int kStrideSlack = 22;
  ConvolutionFilter1D filter;
  const float box[5] = { 0.2f, 0.2f, 0.2f, 0.2f, 0.2f };
  filter.AddFilter(0, box, 5);

  // Allocate a source image and set to 0.
  const int src_row_stride = kImgWidth * kChannelCount + kStrideSlack;
  int src_byte_count = src_row_stride * kImgHeight;
  std::vector<unsigned char> input;
  const int signal_x = kImgWidth / 2;
  const int signal_y = kImgHeight / 2;
  input.resize(src_byte_count, 0);
  // The image has a single impulse pixel in channel 1, smack in the middle.
  const int non_zero_pixel_index =
      signal_y * src_row_stride + signal_x * kChannelCount + 1;
  input[non_zero_pixel_index] = 255;

  // Destination will be a single channel image with stide matching width.
  const int dest_row_stride = kImgWidth;
  const int dest_byte_count = dest_row_stride * kImgHeight;
  std::vector<unsigned char> output;
  output.resize(dest_byte_count);

  // Apply convolution in X.
  SingleChannelConvolveX1D(&input[0], src_row_stride, 1, kChannelCount,
                           filter, SkISize::Make(kImgWidth, kImgHeight),
                           &output[0], dest_row_stride, 0, 1, false);
  for (int x = signal_x - 2; x <= signal_x + 2; ++x)
    EXPECT_GT(output[signal_y * dest_row_stride + x], 0);

  EXPECT_EQ(output[signal_y * dest_row_stride + signal_x - 3], 0);
  EXPECT_EQ(output[signal_y * dest_row_stride + signal_x + 3], 0);

  // Apply convolution in Y.
  SingleChannelConvolveY1D(&input[0], src_row_stride, 1, kChannelCount,
                           filter, SkISize::Make(kImgWidth, kImgHeight),
                           &output[0], dest_row_stride, 0, 1, false);
  for (int y = signal_y - 2; y <= signal_y + 2; ++y)
    EXPECT_GT(output[y * dest_row_stride + signal_x], 0);

  EXPECT_EQ(output[(signal_y - 3) * dest_row_stride + signal_x], 0);
  EXPECT_EQ(output[(signal_y + 3) * dest_row_stride + signal_x], 0);

  EXPECT_EQ(output[signal_y * dest_row_stride + signal_x - 1], 0);
  EXPECT_EQ(output[signal_y * dest_row_stride + signal_x + 1], 0);

  // The main point of calling this is to invoke the routine on input without
  // padding.
  std::vector<unsigned char> output2;
  output2.resize(dest_byte_count);
  SingleChannelConvolveX1D(&output[0], dest_row_stride, 0, 1,
                           filter, SkISize::Make(kImgWidth, kImgHeight),
                           &output2[0], dest_row_stride, 0, 1, false);
  // This should be a result of 2D convolution.
  for (int x = signal_x - 2; x <= signal_x + 2; ++x) {
    for (int y = signal_y - 2; y <= signal_y + 2; ++y)
      EXPECT_GT(output2[y * dest_row_stride + x], 0);
  }
  EXPECT_EQ(output2[0], 0);
  EXPECT_EQ(output2[dest_row_stride - 1], 0);
  EXPECT_EQ(output2[dest_byte_count - 1], 0);
}

TEST(Convolver, SeparableSingleConvolutionEdges) {
  // The purpose of this test is to check if the implementation treats correctly
  // edges of the image.
  static const int kImgWidth = 600;
  static const int kImgHeight = 800;
  static const int kChannelCount = 3;
  static const int kStrideSlack = 22;
  static const int kChannel = 1;
  ConvolutionFilter1D filter;
  const float box[5] = { 0.2f, 0.2f, 0.2f, 0.2f, 0.2f };
  filter.AddFilter(0, box, 5);

  // Allocate a source image and set to 0.
  int src_row_stride = kImgWidth * kChannelCount + kStrideSlack;
  int src_byte_count = src_row_stride * kImgHeight;
  std::vector<unsigned char> input(src_byte_count);

  // Draw a frame around the image.
  for (int i = 0; i < src_byte_count; ++i) {
    int row = i / src_row_stride;
    int col = i % src_row_stride / kChannelCount;
    int channel = i % src_row_stride % kChannelCount;
    if (channel != kChannel || col > kImgWidth) {
      input[i] = 255;
    } else if (row == 0 || col == 0 ||
               col == kImgWidth - 1 || row == kImgHeight - 1) {
      input[i] = 100;
    } else if (row == 1 || col == 1 ||
               col == kImgWidth - 2 || row == kImgHeight - 2) {
      input[i] = 200;
    } else {
      input[i] = 0;
    }
  }

  // Destination will be a single channel image with stide matching width.
  int dest_row_stride = kImgWidth;
  int dest_byte_count = dest_row_stride * kImgHeight;
  std::vector<unsigned char> output;
  output.resize(dest_byte_count);

  // Apply convolution in X.
  SingleChannelConvolveX1D(&input[0], src_row_stride, 1, kChannelCount,
                           filter, SkISize::Make(kImgWidth, kImgHeight),
                           &output[0], dest_row_stride, 0, 1, false);

  // Sadly, comparison is not as simple as retaining all values.
  int invalid_values = 0;
  const unsigned char first_value = output[0];
  EXPECT_NEAR(first_value, 100, 1);
  for (int i = 0; i < dest_row_stride; ++i) {
    if (output[i] != first_value)
      ++invalid_values;
  }
  EXPECT_EQ(0, invalid_values);

  int test_row = 22;
  EXPECT_NEAR(output[test_row * dest_row_stride], 100, 1);
  EXPECT_NEAR(output[test_row * dest_row_stride + 1], 80, 1);
  EXPECT_NEAR(output[test_row * dest_row_stride + 2], 60, 1);
  EXPECT_NEAR(output[test_row * dest_row_stride + 3], 40, 1);
  EXPECT_NEAR(output[(test_row + 1) * dest_row_stride - 1], 100, 1);
  EXPECT_NEAR(output[(test_row + 1) * dest_row_stride - 2], 80, 1);
  EXPECT_NEAR(output[(test_row + 1) * dest_row_stride - 3], 60, 1);
  EXPECT_NEAR(output[(test_row + 1) * dest_row_stride - 4], 40, 1);

  SingleChannelConvolveY1D(&input[0], src_row_stride, 1, kChannelCount,
                           filter, SkISize::Make(kImgWidth, kImgHeight),
                           &output[0], dest_row_stride, 0, 1, false);

  int test_column = 42;
  EXPECT_NEAR(output[test_column], 100, 1);
  EXPECT_NEAR(output[test_column + dest_row_stride], 80, 1);
  EXPECT_NEAR(output[test_column + dest_row_stride * 2], 60, 1);
  EXPECT_NEAR(output[test_column + dest_row_stride * 3], 40, 1);

  EXPECT_NEAR(output[test_column + dest_row_stride * (kImgHeight - 1)], 100, 1);
  EXPECT_NEAR(output[test_column + dest_row_stride * (kImgHeight - 2)], 80, 1);
  EXPECT_NEAR(output[test_column + dest_row_stride * (kImgHeight - 3)], 60, 1);
  EXPECT_NEAR(output[test_column + dest_row_stride * (kImgHeight - 4)], 40, 1);
}

TEST(Convolver, SetUpGaussianConvolutionFilter) {
  ConvolutionFilter1D smoothing_filter;
  ConvolutionFilter1D gradient_filter;
  SetUpGaussianConvolutionKernel(&smoothing_filter, 4.5f, false);
  SetUpGaussianConvolutionKernel(&gradient_filter, 3.0f, true);

  int specified_filter_length;
  int filter_offset;
  int filter_length;

  const ConvolutionFilter1D::Fixed* smoothing_kernel =
      smoothing_filter.GetSingleFilter(
          &specified_filter_length, &filter_offset, &filter_length);
  EXPECT_TRUE(smoothing_kernel);
  std::vector<float> fp_smoothing_kernel(filter_length);
  std::transform(smoothing_kernel,
                 smoothing_kernel + filter_length,
                 fp_smoothing_kernel.begin(),
                 ConvolutionFilter1D::FixedToFloat);
  // Should sum-up to 1 (nearly), and all values whould be in ]0, 1[.
  EXPECT_NEAR(std::accumulate(
      fp_smoothing_kernel.begin(), fp_smoothing_kernel.end(), 0.0f),
              1.0f, 0.01f);
  EXPECT_GT(*std::min_element(fp_smoothing_kernel.begin(),
                              fp_smoothing_kernel.end()), 0.0f);
  EXPECT_LT(*std::max_element(fp_smoothing_kernel.begin(),
                              fp_smoothing_kernel.end()), 1.0f);

  const ConvolutionFilter1D::Fixed* gradient_kernel =
      gradient_filter.GetSingleFilter(
          &specified_filter_length, &filter_offset, &filter_length);
  EXPECT_TRUE(gradient_kernel);
  std::vector<float> fp_gradient_kernel(filter_length);
  std::transform(gradient_kernel,
                 gradient_kernel + filter_length,
                 fp_gradient_kernel.begin(),
                 ConvolutionFilter1D::FixedToFloat);
  // Should sum-up to 0, and all values whould be in ]-1.5, 1.5[.
  EXPECT_NEAR(std::accumulate(
      fp_gradient_kernel.begin(), fp_gradient_kernel.end(), 0.0f),
              0.0f, 0.01f);
  EXPECT_GT(*std::min_element(fp_gradient_kernel.begin(),
                              fp_gradient_kernel.end()), -1.5f);
  EXPECT_LT(*std::min_element(fp_gradient_kernel.begin(),
                              fp_gradient_kernel.end()), 0.0f);
  EXPECT_LT(*std::max_element(fp_gradient_kernel.begin(),
                              fp_gradient_kernel.end()), 1.5f);
  EXPECT_GT(*std::max_element(fp_gradient_kernel.begin(),
                              fp_gradient_kernel.end()), 0.0f);
}

}  // namespace skia
