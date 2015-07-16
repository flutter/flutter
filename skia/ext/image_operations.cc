// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define _USE_MATH_DEFINES
#include <algorithm>
#include <cmath>
#include <limits>

#include "skia/ext/image_operations.h"

// TODO(pkasting): skia/ext should not depend on base/!
#include "base/containers/stack_container.h"
#include "base/logging.h"
#include "base/metrics/histogram.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event.h"
#include "build/build_config.h"
#include "skia/ext/convolver.h"
#include "third_party/skia/include/core/SkColorPriv.h"
#include "third_party/skia/include/core/SkRect.h"

namespace skia {

namespace {

// Returns the ceiling/floor as an integer.
inline int CeilInt(float val) {
  return static_cast<int>(ceil(val));
}
inline int FloorInt(float val) {
  return static_cast<int>(floor(val));
}

// Filter function computation -------------------------------------------------

// Evaluates the box filter, which goes from -0.5 to +0.5.
float EvalBox(float x) {
  return (x >= -0.5f && x < 0.5f) ? 1.0f : 0.0f;
}

// Evaluates the Lanczos filter of the given filter size window for the given
// position.
//
// |filter_size| is the width of the filter (the "window"), outside of which
// the value of the function is 0. Inside of the window, the value is the
// normalized sinc function:
//   lanczos(x) = sinc(x) * sinc(x / filter_size);
// where
//   sinc(x) = sin(pi*x) / (pi*x);
float EvalLanczos(int filter_size, float x) {
  if (x <= -filter_size || x >= filter_size)
    return 0.0f;  // Outside of the window.
  if (x > -std::numeric_limits<float>::epsilon() &&
      x < std::numeric_limits<float>::epsilon())
    return 1.0f;  // Special case the discontinuity at the origin.
  float xpi = x * static_cast<float>(M_PI);
  return (sin(xpi) / xpi) *  // sinc(x)
          sin(xpi / filter_size) / (xpi / filter_size);  // sinc(x/filter_size)
}

// Evaluates the Hamming filter of the given filter size window for the given
// position.
//
// The filter covers [-filter_size, +filter_size]. Outside of this window
// the value of the function is 0. Inside of the window, the value is sinus
// cardinal multiplied by a recentered Hamming function. The traditional
// Hamming formula for a window of size N and n ranging in [0, N-1] is:
//   hamming(n) = 0.54 - 0.46 * cos(2 * pi * n / (N-1)))
// In our case we want the function centered for x == 0 and at its minimum
// on both ends of the window (x == +/- filter_size), hence the adjusted
// formula:
//   hamming(x) = (0.54 -
//                 0.46 * cos(2 * pi * (x - filter_size)/ (2 * filter_size)))
//              = 0.54 - 0.46 * cos(pi * x / filter_size - pi)
//              = 0.54 + 0.46 * cos(pi * x / filter_size)
float EvalHamming(int filter_size, float x) {
  if (x <= -filter_size || x >= filter_size)
    return 0.0f;  // Outside of the window.
  if (x > -std::numeric_limits<float>::epsilon() &&
      x < std::numeric_limits<float>::epsilon())
    return 1.0f;  // Special case the sinc discontinuity at the origin.
  const float xpi = x * static_cast<float>(M_PI);

  return ((sin(xpi) / xpi) *  // sinc(x)
          (0.54f + 0.46f * cos(xpi / filter_size)));  // hamming(x)
}

// ResizeFilter ----------------------------------------------------------------

// Encapsulates computation and storage of the filters required for one complete
// resize operation.
class ResizeFilter {
 public:
  ResizeFilter(ImageOperations::ResizeMethod method,
               int src_full_width, int src_full_height,
               int dest_width, int dest_height,
               const SkIRect& dest_subset);

  // Returns the filled filter values.
  const ConvolutionFilter1D& x_filter() { return x_filter_; }
  const ConvolutionFilter1D& y_filter() { return y_filter_; }

 private:
  // Returns the number of pixels that the filer spans, in filter space (the
  // destination image).
  float GetFilterSupport(float scale) {
    switch (method_) {
      case ImageOperations::RESIZE_BOX:
        // The box filter just scales with the image scaling.
        return 0.5f;  // Only want one side of the filter = /2.
      case ImageOperations::RESIZE_HAMMING1:
        // The Hamming filter takes as much space in the source image in
        // each direction as the size of the window = 1 for Hamming1.
        return 1.0f;
      case ImageOperations::RESIZE_LANCZOS2:
        // The Lanczos filter takes as much space in the source image in
        // each direction as the size of the window = 2 for Lanczos2.
        return 2.0f;
      case ImageOperations::RESIZE_LANCZOS3:
        // The Lanczos filter takes as much space in the source image in
        // each direction as the size of the window = 3 for Lanczos3.
        return 3.0f;
      default:
        NOTREACHED();
        return 1.0f;
    }
  }

  // Computes one set of filters either horizontally or vertically. The caller
  // will specify the "min" and "max" rather than the bottom/top and
  // right/bottom so that the same code can be re-used in each dimension.
  //
  // |src_depend_lo| and |src_depend_size| gives the range for the source
  // depend rectangle (horizontally or vertically at the caller's discretion
  // -- see above for what this means).
  //
  // Likewise, the range of destination values to compute and the scale factor
  // for the transform is also specified.
  void ComputeFilters(int src_size,
                      int dest_subset_lo, int dest_subset_size,
                      float scale,
                      ConvolutionFilter1D* output);

  // Computes the filter value given the coordinate in filter space.
  inline float ComputeFilter(float pos) {
    switch (method_) {
      case ImageOperations::RESIZE_BOX:
        return EvalBox(pos);
      case ImageOperations::RESIZE_HAMMING1:
        return EvalHamming(1, pos);
      case ImageOperations::RESIZE_LANCZOS2:
        return EvalLanczos(2, pos);
      case ImageOperations::RESIZE_LANCZOS3:
        return EvalLanczos(3, pos);
      default:
        NOTREACHED();
        return 0;
    }
  }

  ImageOperations::ResizeMethod method_;

  // Size of the filter support on one side only in the destination space.
  // See GetFilterSupport.
  float x_filter_support_;
  float y_filter_support_;

  // Subset of scaled destination bitmap to compute.
  SkIRect out_bounds_;

  ConvolutionFilter1D x_filter_;
  ConvolutionFilter1D y_filter_;

  DISALLOW_COPY_AND_ASSIGN(ResizeFilter);
};

ResizeFilter::ResizeFilter(ImageOperations::ResizeMethod method,
                           int src_full_width, int src_full_height,
                           int dest_width, int dest_height,
                           const SkIRect& dest_subset)
    : method_(method),
      out_bounds_(dest_subset) {
  // method_ will only ever refer to an "algorithm method".
  SkASSERT((ImageOperations::RESIZE_FIRST_ALGORITHM_METHOD <= method) &&
           (method <= ImageOperations::RESIZE_LAST_ALGORITHM_METHOD));

  float scale_x = static_cast<float>(dest_width) /
                  static_cast<float>(src_full_width);
  float scale_y = static_cast<float>(dest_height) /
                  static_cast<float>(src_full_height);

  ComputeFilters(src_full_width, dest_subset.fLeft, dest_subset.width(),
                 scale_x, &x_filter_);
  ComputeFilters(src_full_height, dest_subset.fTop, dest_subset.height(),
                 scale_y, &y_filter_);
}

// TODO(egouriou): Take advantage of periods in the convolution.
// Practical resizing filters are periodic outside of the border area.
// For Lanczos, a scaling by a (reduced) factor of p/q (q pixels in the
// source become p pixels in the destination) will have a period of p.
// A nice consequence is a period of 1 when downscaling by an integral
// factor. Downscaling from typical display resolutions is also bound
// to produce interesting periods as those are chosen to have multiple
// small factors.
// Small periods reduce computational load and improve cache usage if
// the coefficients can be shared. For periods of 1 we can consider
// loading the factors only once outside the borders.
void ResizeFilter::ComputeFilters(int src_size,
                                  int dest_subset_lo, int dest_subset_size,
                                  float scale,
                                  ConvolutionFilter1D* output) {
  int dest_subset_hi = dest_subset_lo + dest_subset_size;  // [lo, hi)

  // When we're doing a magnification, the scale will be larger than one. This
  // means the destination pixels are much smaller than the source pixels, and
  // that the range covered by the filter won't necessarily cover any source
  // pixel boundaries. Therefore, we use these clamped values (max of 1) for
  // some computations.
  float clamped_scale = std::min(1.0f, scale);

  // This is how many source pixels from the center we need to count
  // to support the filtering function.
  float src_support = GetFilterSupport(clamped_scale) / clamped_scale;

  // Speed up the divisions below by turning them into multiplies.
  float inv_scale = 1.0f / scale;

  base::StackVector<float, 64> filter_values;
  base::StackVector<int16, 64> fixed_filter_values;

  // Loop over all pixels in the output range. We will generate one set of
  // filter values for each one. Those values will tell us how to blend the
  // source pixels to compute the destination pixel.
  for (int dest_subset_i = dest_subset_lo; dest_subset_i < dest_subset_hi;
       dest_subset_i++) {
    // Reset the arrays. We don't declare them inside so they can re-use the
    // same malloc-ed buffer.
    filter_values->clear();
    fixed_filter_values->clear();

    // This is the pixel in the source directly under the pixel in the dest.
    // Note that we base computations on the "center" of the pixels. To see
    // why, observe that the destination pixel at coordinates (0, 0) in a 5.0x
    // downscale should "cover" the pixels around the pixel with *its center*
    // at coordinates (2.5, 2.5) in the source, not those around (0, 0).
    // Hence we need to scale coordinates (0.5, 0.5), not (0, 0).
    float src_pixel = (static_cast<float>(dest_subset_i) + 0.5f) * inv_scale;

    // Compute the (inclusive) range of source pixels the filter covers.
    int src_begin = std::max(0, FloorInt(src_pixel - src_support));
    int src_end = std::min(src_size - 1, CeilInt(src_pixel + src_support));

    // Compute the unnormalized filter value at each location of the source
    // it covers.
    float filter_sum = 0.0f;  // Sub of the filter values for normalizing.
    for (int cur_filter_pixel = src_begin; cur_filter_pixel <= src_end;
         cur_filter_pixel++) {
      // Distance from the center of the filter, this is the filter coordinate
      // in source space. We also need to consider the center of the pixel
      // when comparing distance against 'src_pixel'. In the 5x downscale
      // example used above the distance from the center of the filter to
      // the pixel with coordinates (2, 2) should be 0, because its center
      // is at (2.5, 2.5).
      float src_filter_dist =
          ((static_cast<float>(cur_filter_pixel) + 0.5f) - src_pixel);

      // Since the filter really exists in dest space, map it there.
      float dest_filter_dist = src_filter_dist * clamped_scale;

      // Compute the filter value at that location.
      float filter_value = ComputeFilter(dest_filter_dist);
      filter_values->push_back(filter_value);

      filter_sum += filter_value;
    }
    DCHECK(!filter_values->empty()) << "We should always get a filter!";

    // The filter must be normalized so that we don't affect the brightness of
    // the image. Convert to normalized fixed point.
    int16 fixed_sum = 0;
    for (size_t i = 0; i < filter_values->size(); i++) {
      int16 cur_fixed = output->FloatToFixed(filter_values[i] / filter_sum);
      fixed_sum += cur_fixed;
      fixed_filter_values->push_back(cur_fixed);
    }

    // The conversion to fixed point will leave some rounding errors, which
    // we add back in to avoid affecting the brightness of the image. We
    // arbitrarily add this to the center of the filter array (this won't always
    // be the center of the filter function since it could get clipped on the
    // edges, but it doesn't matter enough to worry about that case).
    int16 leftovers = output->FloatToFixed(1.0f) - fixed_sum;
    fixed_filter_values[fixed_filter_values->size() / 2] += leftovers;

    // Now it's ready to go.
    output->AddFilter(src_begin, &fixed_filter_values[0],
                      static_cast<int>(fixed_filter_values->size()));
  }

  output->PaddingForSIMD();
}

ImageOperations::ResizeMethod ResizeMethodToAlgorithmMethod(
    ImageOperations::ResizeMethod method) {
  // Convert any "Quality Method" into an "Algorithm Method"
  if (method >= ImageOperations::RESIZE_FIRST_ALGORITHM_METHOD &&
      method <= ImageOperations::RESIZE_LAST_ALGORITHM_METHOD) {
    return method;
  }
  // The call to ImageOperationsGtv::Resize() above took care of
  // GPU-acceleration in the cases where it is possible. So now we just
  // pick the appropriate software method for each resize quality.
  switch (method) {
    // Users of RESIZE_GOOD are willing to trade a lot of quality to
    // get speed, allowing the use of linear resampling to get hardware
    // acceleration (SRB). Hence any of our "good" software filters
    // will be acceptable, and we use the fastest one, Hamming-1.
    case ImageOperations::RESIZE_GOOD:
      // Users of RESIZE_BETTER are willing to trade some quality in order
      // to improve performance, but are guaranteed not to devolve to a linear
      // resampling. In visual tests we see that Hamming-1 is not as good as
      // Lanczos-2, however it is about 40% faster and Lanczos-2 itself is
      // about 30% faster than Lanczos-3. The use of Hamming-1 has been deemed
      // an acceptable trade-off between quality and speed.
    case ImageOperations::RESIZE_BETTER:
      return ImageOperations::RESIZE_HAMMING1;
    default:
      return ImageOperations::RESIZE_LANCZOS3;
  }
}

}  // namespace

// Resize ----------------------------------------------------------------------

// static
SkBitmap ImageOperations::Resize(const SkBitmap& source,
                                 ResizeMethod method,
                                 int dest_width, int dest_height,
                                 const SkIRect& dest_subset,
                                 SkBitmap::Allocator* allocator) {
  TRACE_EVENT2("disabled-by-default-skia", "ImageOperations::Resize",
               "src_pixels", source.width() * source.height(), "dst_pixels",
               dest_width * dest_height);
  // Ensure that the ResizeMethod enumeration is sound.
  SkASSERT(((RESIZE_FIRST_QUALITY_METHOD <= method) &&
            (method <= RESIZE_LAST_QUALITY_METHOD)) ||
           ((RESIZE_FIRST_ALGORITHM_METHOD <= method) &&
            (method <= RESIZE_LAST_ALGORITHM_METHOD)));

  // Time how long this takes to see if it's a problem for users.
  base::TimeTicks resize_start = base::TimeTicks::Now();

  SkIRect dest = { 0, 0, dest_width, dest_height };
  DCHECK(dest.contains(dest_subset)) <<
      "The supplied subset does not fall within the destination image.";

  // If the size of source or destination is 0, i.e. 0x0, 0xN or Nx0, just
  // return empty.
  if (source.width() < 1 || source.height() < 1 ||
      dest_width < 1 || dest_height < 1)
    return SkBitmap();

  method = ResizeMethodToAlgorithmMethod(method);
  // Check that we deal with an "algorithm methods" from this point onward.
  SkASSERT((ImageOperations::RESIZE_FIRST_ALGORITHM_METHOD <= method) &&
           (method <= ImageOperations::RESIZE_LAST_ALGORITHM_METHOD));

  SkAutoLockPixels locker(source);
  if (!source.readyToDraw() || source.colorType() != kN32_SkColorType)
    return SkBitmap();

  ResizeFilter filter(method, source.width(), source.height(),
                      dest_width, dest_height, dest_subset);

  // Get a source bitmap encompassing this touched area. We construct the
  // offsets and row strides such that it looks like a new bitmap, while
  // referring to the old data.
  const uint8* source_subset =
      reinterpret_cast<const uint8*>(source.getPixels());

  // Convolve into the result.
  SkBitmap result;
  result.setInfo(SkImageInfo::MakeN32(dest_subset.width(), dest_subset.height(), source.alphaType()));
  result.allocPixels(allocator, NULL);
  if (!result.readyToDraw())
    return SkBitmap();

  BGRAConvolve2D(source_subset, static_cast<int>(source.rowBytes()),
                 !source.isOpaque(), filter.x_filter(), filter.y_filter(),
                 static_cast<int>(result.rowBytes()),
                 static_cast<unsigned char*>(result.getPixels()),
                 true);

  base::TimeDelta delta = base::TimeTicks::Now() - resize_start;
  UMA_HISTOGRAM_TIMES("Image.ResampleMS", delta);

  return result;
}

// static
SkBitmap ImageOperations::Resize(const SkBitmap& source,
                                 ResizeMethod method,
                                 int dest_width, int dest_height,
                                 SkBitmap::Allocator* allocator) {
  SkIRect dest_subset = { 0, 0, dest_width, dest_height };
  return Resize(source, method, dest_width, dest_height, dest_subset,
                allocator);
}

}  // namespace skia
