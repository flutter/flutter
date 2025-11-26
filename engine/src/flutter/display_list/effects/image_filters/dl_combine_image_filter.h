// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_COMBINE_IMAGE_FILTER_H_
#define FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_COMBINE_IMAGE_FILTER_H_

#include "flutter/display_list/effects/dl_image_filter.h"

namespace flutter {

class DlCombineImageFilter final : public DlImageFilter {
 public:
  DlCombineImageFilter(const std::shared_ptr<DlImageFilter>& first,
                       const std::shared_ptr<DlImageFilter>& second,
                       const std::shared_ptr<DlImageFilter>& combiner)
      : first_(first), second_(second), combiner_(combiner) {}

  static std::shared_ptr<DlImageFilter> Make(
      const std::shared_ptr<DlImageFilter>& first,
      const std::shared_ptr<DlImageFilter>& second,
      const std::shared_ptr<DlImageFilter>& combiner);

  std::shared_ptr<DlImageFilter> shared() const override {
    return std::make_shared<DlCombineImageFilter>(this);
  }

  DlImageFilterType type() const override { return DlImageFilterType::kCombine; }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlImageFilter> first() const { return first_; }
  std::shared_ptr<DlImageFilter> second() const { return second_; }
  std::shared_ptr<DlImageFilter> combiner() const { return combiner_; }

  const DlCombineImageFilter* asCombine() const override { return this; }

  bool modifies_transparent_black() const override;

  DlRect* map_local_bounds(const DlRect& input_bounds,
                           DlRect& output_bounds) const override;

  DlIRect* map_device_bounds(const DlIRect& input_bounds,
                             const DlMatrix& ctm,
                             DlIRect& output_bounds) const override;

  DlIRect* get_input_device_bounds(const DlIRect& output_bounds,
                                   const DlMatrix& ctm,
                                   DlIRect& input_bounds) const override;

  MatrixCapability matrix_capability() const override;

  explicit DlCombineImageFilter(const DlCombineImageFilter* filter)
      : DlCombineImageFilter(filter->first_, filter->second_, filter->combiner_) {}
  DlCombineImageFilter(const DlCombineImageFilter& filter)
      : DlCombineImageFilter(&filter) {}

 protected:
  bool equals_(const DlImageFilter& other) const override;

 private:
  const std::shared_ptr<DlImageFilter> first_;
  const std::shared_ptr<DlImageFilter> second_;
  const std::shared_ptr<DlImageFilter> combiner_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_EFFECTS_IMAGE_FILTERS_DL_COMBINE_IMAGE_FILTER_H_
