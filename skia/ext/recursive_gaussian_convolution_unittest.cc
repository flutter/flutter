// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <functional>
#include <numeric>
#include <vector>

#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/time/time.h"
#include "skia/ext/convolver.h"
#include "skia/ext/recursive_gaussian_convolution.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"

namespace {

int ComputeRowStride(int width, int channel_count, int stride_slack) {
  return width * channel_count + stride_slack;
}

SkIPoint MakeImpulseImage(std::vector<unsigned char>* image,
                          int width,
                          int height,
                          int channel_index,
                          int channel_count,
                          int stride_slack) {
  const int src_row_stride = ComputeRowStride(
      width, channel_count, stride_slack);
  const int src_byte_count = src_row_stride * height;
  const int signal_x = width / 2;
  const int signal_y = height / 2;

  image->resize(src_byte_count, 0);
  const int non_zero_pixel_index =
      signal_y * src_row_stride + signal_x * channel_count + channel_index;
  (*image)[non_zero_pixel_index] = 255;
  return SkIPoint::Make(signal_x, signal_y);
}

SkIRect MakeBoxImage(std::vector<unsigned char>* image,
                     int width,
                     int height,
                     int channel_index,
                     int channel_count,
                     int stride_slack,
                     int box_width,
                     int box_height,
                     unsigned char value) {
  const int src_row_stride = ComputeRowStride(
      width, channel_count, stride_slack);
  const int src_byte_count = src_row_stride * height;
  const SkIRect box = SkIRect::MakeXYWH((width - box_width) / 2,
                                        (height - box_height) / 2,
                                        box_width, box_height);

  image->resize(src_byte_count, 0);
  for (int y = box.top(); y < box.bottom(); ++y) {
    for (int x = box.left(); x < box.right(); ++x)
      (*image)[y * src_row_stride + x * channel_count + channel_index] = value;
  }

  return box;
}

int ComputeBoxSum(const std::vector<unsigned char>& image,
                  const SkIRect& box,
                  int image_width) {
  // Compute the sum of all pixels in the box. Assume byte stride 1 and row
  // stride same as image_width.
  int sum = 0;
  for (int y = box.top(); y < box.bottom(); ++y) {
    for (int x = box.left(); x < box.right(); ++x)
      sum += image[y * image_width + x];
  }

  return sum;
}

}  // namespace

namespace skia {

TEST(RecursiveGaussian, SmoothingMethodComparison) {
  static const int kImgWidth = 512;
  static const int kImgHeight = 220;
  static const int kChannelIndex = 3;
  static const int kChannelCount = 3;
  static const int kStrideSlack = 22;

  std::vector<unsigned char> input;
  SkISize image_size = SkISize::Make(kImgWidth, kImgHeight);
  MakeImpulseImage(
      &input, kImgWidth, kImgHeight, kChannelIndex, kChannelCount,
      kStrideSlack);

  // Destination will be a single channel image with stide matching width.
  const int dest_row_stride = kImgWidth;
  const int dest_byte_count = dest_row_stride * kImgHeight;
  std::vector<unsigned char> intermediate(dest_byte_count);
  std::vector<unsigned char> intermediate2(dest_byte_count);
  std::vector<unsigned char> control(dest_byte_count);
  std::vector<unsigned char> output(dest_byte_count);

  const int src_row_stride = ComputeRowStride(
      kImgWidth, kChannelCount, kStrideSlack);

  const float kernel_sigma = 2.5f;
  ConvolutionFilter1D filter;
  SetUpGaussianConvolutionKernel(&filter, kernel_sigma, false);
  // Process the control image.
  SingleChannelConvolveX1D(&input[0], src_row_stride,
                           kChannelIndex, kChannelCount,
                           filter, image_size,
                           &intermediate[0], dest_row_stride, 0, 1, false);
  SingleChannelConvolveY1D(&intermediate[0], dest_row_stride, 0, 1,
                           filter, image_size,
                           &control[0], dest_row_stride, 0, 1, false);

  // Now try the same using the other method.
  RecursiveFilter recursive_filter(kernel_sigma, RecursiveFilter::FUNCTION);
  SingleChannelRecursiveGaussianY(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &intermediate2[0], dest_row_stride,
                                  0, 1, false);
  SingleChannelRecursiveGaussianX(&intermediate2[0], dest_row_stride, 0, 1,
                                  recursive_filter, image_size,
                                  &output[0], dest_row_stride, 0, 1, false);

  // We cannot expect the results to be really the same. In particular,
  // the standard implementation is computed in completely fixed-point, while
  // recursive is done in floating point and squeezed back into char*. On top
  // of that, its characteristics are a bit different (consult the paper).
  EXPECT_NEAR(std::accumulate(intermediate.begin(), intermediate.end(), 0),
              std::accumulate(intermediate2.begin(), intermediate2.end(), 0),
              50);
  int difference_count = 0;
  std::vector<unsigned char>::const_iterator i1, i2;
  for (i1 = control.begin(), i2 = output.begin();
       i1 != control.end(); ++i1, ++i2) {
    if ((*i1 != 0) != (*i2 != 0))
      difference_count++;
  }

  EXPECT_LE(difference_count, 44);  // 44 is 2 * PI * r (r == 7, spot size).
}

TEST(RecursiveGaussian, SmoothingImpulse) {
  static const int kImgWidth = 200;
  static const int kImgHeight = 300;
  static const int kChannelIndex = 3;
  static const int kChannelCount = 3;
  static const int kStrideSlack = 22;

  std::vector<unsigned char> input;
  SkISize image_size = SkISize::Make(kImgWidth, kImgHeight);
  const SkIPoint centre_point = MakeImpulseImage(
      &input, kImgWidth, kImgHeight, kChannelIndex, kChannelCount,
      kStrideSlack);

  // Destination will be a single channel image with stide matching width.
  const int dest_row_stride = kImgWidth;
  const int dest_byte_count = dest_row_stride * kImgHeight;
  std::vector<unsigned char> intermediate(dest_byte_count);
  std::vector<unsigned char> output(dest_byte_count);

  const int src_row_stride = ComputeRowStride(
      kImgWidth, kChannelCount, kStrideSlack);

  const float kernel_sigma = 5.0f;
  RecursiveFilter recursive_filter(kernel_sigma, RecursiveFilter::FUNCTION);
  SingleChannelRecursiveGaussianY(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &intermediate[0], dest_row_stride,
                                  0, 1, false);
  SingleChannelRecursiveGaussianX(&intermediate[0], dest_row_stride, 0, 1,
                                  recursive_filter, image_size,
                                  &output[0], dest_row_stride, 0, 1, false);

  // Check we got the expected impulse response.
  const int cx = centre_point.x();
  const int cy = centre_point.y();
  unsigned char value_x = output[dest_row_stride * cy + cx];
  unsigned char value_y = value_x;
  EXPECT_GT(value_x, 0);
  for (int offset = 0;
       offset < std::min(kImgWidth, kImgHeight) && (value_y > 0 || value_x > 0);
       ++offset) {
    // Symmetricity and monotonicity along X.
    EXPECT_EQ(output[dest_row_stride * cy + cx - offset],
              output[dest_row_stride * cy + cx + offset]);
    EXPECT_LE(output[dest_row_stride * cy + cx - offset], value_x);
    value_x = output[dest_row_stride * cy + cx - offset];

    // Symmetricity and monotonicity along Y.
    EXPECT_EQ(output[dest_row_stride * (cy - offset) + cx],
              output[dest_row_stride * (cy + offset) + cx]);
    EXPECT_LE(output[dest_row_stride * (cy  - offset) + cx], value_y);
    value_y = output[dest_row_stride * (cy - offset) + cx];

    // Symmetricity along X/Y (not really assured, but should be close).
    EXPECT_NEAR(value_x, value_y, 1);
  }

  // Smooth the inverse now.
  std::vector<unsigned char> output2(dest_byte_count);
  std::transform(input.begin(), input.end(), input.begin(),
                 std::bind1st(std::minus<unsigned char>(), 255U));
  SingleChannelRecursiveGaussianY(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &intermediate[0], dest_row_stride,
                                  0, 1, false);
  SingleChannelRecursiveGaussianX(&intermediate[0], dest_row_stride, 0, 1,
                                  recursive_filter, image_size,
                                  &output2[0], dest_row_stride, 0, 1, false);
  // The image should be the reverse of output, but permitting for rounding
  // we will only claim that wherever output is 0, output2 should be 255.
  // There still can be differences at the edges of the object.
  std::vector<unsigned char>::const_iterator i1, i2;
  int difference_count = 0;
  for (i1 = output.begin(), i2 = output2.begin();
       i1 != output.end(); ++i1, ++i2) {
    // The line below checks (*i1 == 0 <==> *i2 == 255).
    if ((*i1 != 0 && *i2 == 255) && ! (*i1 == 0 && *i2 != 255))
      ++difference_count;
  }
  EXPECT_LE(difference_count, 8);
}

TEST(RecursiveGaussian, FirstDerivative) {
  static const int kImgWidth = 512;
  static const int kImgHeight = 1024;
  static const int kChannelIndex = 2;
  static const int kChannelCount = 4;
  static const int kStrideSlack = 22;
  static const int kBoxSize = 400;

  std::vector<unsigned char> input;
  const SkISize image_size = SkISize::Make(kImgWidth, kImgHeight);
  const SkIRect box =  MakeBoxImage(
      &input, kImgWidth, kImgHeight, kChannelIndex, kChannelCount,
      kStrideSlack, kBoxSize, kBoxSize, 200);

  // Destination will be a single channel image with stide matching width.
  const int dest_row_stride = kImgWidth;
  const int dest_byte_count = dest_row_stride * kImgHeight;
  std::vector<unsigned char> output_x(dest_byte_count);
  std::vector<unsigned char> output_y(dest_byte_count);
  std::vector<unsigned char> output(dest_byte_count);

  const int src_row_stride = ComputeRowStride(
      kImgWidth, kChannelCount, kStrideSlack);

  const float kernel_sigma = 3.0f;
  const int spread = 4 * kernel_sigma;
  RecursiveFilter recursive_filter(kernel_sigma,
                                   RecursiveFilter::FIRST_DERIVATIVE);
  SingleChannelRecursiveGaussianX(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &output_x[0], dest_row_stride,
                                  0, 1, true);
  SingleChannelRecursiveGaussianY(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &output_y[0], dest_row_stride,
                                  0, 1, true);

  // In test code we can assume adding the two up should do fine.
  std::vector<unsigned char>::const_iterator ix, iy;
  std::vector<unsigned char>::iterator target;
  for (target = output.begin(), ix = output_x.begin(), iy = output_y.begin();
       target < output.end(); ++target, ++ix, ++iy) {
    *target = *ix + *iy;
  }

  SkIRect inflated_rect(box);
  inflated_rect.outset(spread, spread);
  SkIRect deflated_rect(box);
  deflated_rect.inset(spread, spread);

  int image_total = ComputeBoxSum(output,
                                  SkIRect::MakeWH(kImgWidth, kImgHeight),
                                  kImgWidth);
  int box_inflated = ComputeBoxSum(output, inflated_rect, kImgWidth);
  int box_deflated = ComputeBoxSum(output, deflated_rect, kImgWidth);
  EXPECT_EQ(box_deflated, 0);
  EXPECT_EQ(image_total, box_inflated);

  // Try inverted image. Behaviour should be very similar (modulo rounding).
  std::transform(input.begin(), input.end(), input.begin(),
                 std::bind1st(std::minus<unsigned char>(), 255U));
  SingleChannelRecursiveGaussianX(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &output_x[0], dest_row_stride,
                                  0, 1, true);
  SingleChannelRecursiveGaussianY(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &output_y[0], dest_row_stride,
                                  0, 1, true);

  for (target = output.begin(), ix = output_x.begin(), iy = output_y.begin();
       target < output.end(); ++target, ++ix, ++iy) {
    *target = *ix + *iy;
  }

  image_total = ComputeBoxSum(output,
                              SkIRect::MakeWH(kImgWidth, kImgHeight),
                              kImgWidth);
  box_inflated = ComputeBoxSum(output, inflated_rect, kImgWidth);
  box_deflated = ComputeBoxSum(output, deflated_rect, kImgWidth);

  EXPECT_EQ(box_deflated, 0);
  EXPECT_EQ(image_total, box_inflated);
}

TEST(RecursiveGaussian, SecondDerivative) {
  static const int kImgWidth = 700;
  static const int kImgHeight = 500;
  static const int kChannelIndex = 0;
  static const int kChannelCount = 2;
  static const int kStrideSlack = 42;
  static const int kBoxSize = 200;

  std::vector<unsigned char> input;
  SkISize image_size = SkISize::Make(kImgWidth, kImgHeight);
  const SkIRect box = MakeBoxImage(
      &input, kImgWidth, kImgHeight, kChannelIndex, kChannelCount,
      kStrideSlack, kBoxSize, kBoxSize, 200);

  // Destination will be a single channel image with stide matching width.
  const int dest_row_stride = kImgWidth;
  const int dest_byte_count = dest_row_stride * kImgHeight;
  std::vector<unsigned char> output_x(dest_byte_count);
  std::vector<unsigned char> output_y(dest_byte_count);
  std::vector<unsigned char> output(dest_byte_count);

  const int src_row_stride = ComputeRowStride(
      kImgWidth, kChannelCount, kStrideSlack);

  const float kernel_sigma = 5.0f;
  const int spread = 8 * kernel_sigma;
  RecursiveFilter recursive_filter(kernel_sigma,
                                   RecursiveFilter::SECOND_DERIVATIVE);
  SingleChannelRecursiveGaussianX(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &output_x[0], dest_row_stride,
                                  0, 1, true);
  SingleChannelRecursiveGaussianY(&input[0], src_row_stride,
                                  kChannelIndex, kChannelCount,
                                  recursive_filter, image_size,
                                  &output_y[0], dest_row_stride,
                                  0, 1, true);

  // In test code we can assume adding the two up should do fine.
  std::vector<unsigned char>::const_iterator ix, iy;
  std::vector<unsigned char>::iterator target;
  for (target = output.begin(),ix = output_x.begin(), iy = output_y.begin();
       target < output.end(); ++target, ++ix, ++iy) {
    *target = *ix + *iy;
  }

  int image_total = ComputeBoxSum(output,
                                  SkIRect::MakeWH(kImgWidth, kImgHeight),
                                  kImgWidth);
  int box_inflated = ComputeBoxSum(output,
                                   SkIRect::MakeLTRB(box.left() - spread,
                                                     box.top() - spread,
                                                     box.right() + spread,
                                                     box.bottom() + spread),
                                   kImgWidth);
  int box_deflated = ComputeBoxSum(output,
                                   SkIRect::MakeLTRB(box.left() + spread,
                                                     box.top() + spread,
                                                     box.right() - spread,
                                                     box.bottom() - spread),
                                   kImgWidth);
  // Since second derivative is not really used and implemented mostly
  // for the sake of completeness, we do not verify the detail (that dip
  // in the middle). But it is there.
  EXPECT_EQ(box_deflated, 0);
  EXPECT_EQ(image_total, box_inflated);
}

}  // namespace skia
