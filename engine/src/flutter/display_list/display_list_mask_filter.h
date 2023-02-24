// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MASK_FILTER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MASK_FILTER_H_

#include "flutter/display_list/display_list_attributes.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"

namespace flutter {

class DlBlurMaskFilter;

// The DisplayList MaskFilter class. This class implements all of the
// facilities and adheres to the design goals of the |DlAttribute| base
// class.

// An enumerated type for the recognized MaskFilter operations.
// If a custom MaskFilter outside of the recognized types is needed
// then a |kUnknown| type that simply defers to an SkMaskFilter is
// provided as a fallback.
enum class DlMaskFilterType { kBlur, kUnknown };

class DlMaskFilter
    : public DlAttribute<DlMaskFilter, SkMaskFilter, DlMaskFilterType> {
 public:
  // Return a shared_ptr holding a DlMaskFilter representing the indicated
  // Skia SkMaskFilter pointer.
  //
  // Since there is no public SkBlurMaskFilter and since the SkMaskFilter
  // class provides no |asABlur| style type inference method, we cannot
  // infer any specific data from the SkMaskFilter. As a result, the return
  // value in this case will always be nullptr or DlUnknownMaskFilter.
  static std::shared_ptr<DlMaskFilter> From(SkMaskFilter* sk_filter);

  // Return a shared_ptr holding a DlMaskFilter representing the indicated
  // Skia SkMaskFilter pointer.
  //
  // Since there is no public SkBlurMaskFilter and since the SkMaskFilter
  // class provides no |asABlur| style type inference methods, we cannot
  // infer any specific data from the SkMaskFilter. As a result, the return
  // value in this case will always be nullptr or DlUnknownMaskFilter.
  static std::shared_ptr<DlMaskFilter> From(sk_sp<SkMaskFilter> sk_filter) {
    return From(sk_filter.get());
  }

  // Return a DlBlurMaskFilter pointer to this object iff it is a Blur
  // type of MaskFilter, otherwise return nullptr.
  virtual const DlBlurMaskFilter* asBlur() const { return nullptr; }
};

// The Blur type of MaskFilter which specifies modifying the
// colors as if the color specified in the Blur filter is the
// source color and the color drawn by the rendering operation
// is the destination color. The mode parameter of the Blur
// filter is then used to combine those colors.
class DlBlurMaskFilter final : public DlMaskFilter {
 public:
  DlBlurMaskFilter(SkBlurStyle style, SkScalar sigma, bool respect_ctm = true)
      : style_(style), sigma_(sigma), respect_ctm_(respect_ctm) {}
  DlBlurMaskFilter(const DlBlurMaskFilter& filter)
      : DlBlurMaskFilter(filter.style_, filter.sigma_, filter.respect_ctm_) {}
  DlBlurMaskFilter(const DlBlurMaskFilter* filter)
      : DlBlurMaskFilter(filter->style_, filter->sigma_, filter->respect_ctm_) {
  }

  DlMaskFilterType type() const override { return DlMaskFilterType::kBlur; }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlMaskFilter> shared() const override {
    return std::make_shared<DlBlurMaskFilter>(this);
  }

  sk_sp<SkMaskFilter> skia_object() const override {
    return SkMaskFilter::MakeBlur(style_, sigma_, respect_ctm_);
  }

  const DlBlurMaskFilter* asBlur() const override { return this; }

  SkBlurStyle style() const { return style_; }
  SkScalar sigma() const { return sigma_; }
  bool respectCTM() const { return respect_ctm_; }

 protected:
  bool equals_(DlMaskFilter const& other) const override {
    FML_DCHECK(other.type() == DlMaskFilterType::kBlur);
    auto that = static_cast<DlBlurMaskFilter const*>(&other);
    return style_ == that->style_ && sigma_ == that->sigma_ &&
           respect_ctm_ == that->respect_ctm_;
  }

 private:
  SkBlurStyle style_;
  SkScalar sigma_;
  // Added for backward compatibility with Flutter text shadow rendering which
  // uses Skia blur filters with this flag set to false.
  bool respect_ctm_;
};

// A wrapper class for a Skia MaskFilter of unknown type. The above 4 types
// are the only types that can be constructed by Flutter using the
// ui.MaskFilter class so this class should be rarely used.
// In fact, now that the DisplayListCanvasRecorder is deleted and the
// Paragraph code talks directly to a DisplayListBuilder, there may be
// no more reasons to maintain this sub-class.
// See: https://github.com/flutter/flutter/issues/121389
class DlUnknownMaskFilter final : public DlMaskFilter {
 public:
  DlUnknownMaskFilter(sk_sp<SkMaskFilter> sk_filter)
      : sk_filter_(std::move(sk_filter)) {}
  DlUnknownMaskFilter(const DlUnknownMaskFilter& filter)
      : DlUnknownMaskFilter(filter.sk_filter_) {}
  DlUnknownMaskFilter(const DlUnknownMaskFilter* filter)
      : DlUnknownMaskFilter(filter->sk_filter_) {}

  DlMaskFilterType type() const override { return DlMaskFilterType::kUnknown; }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlMaskFilter> shared() const override {
    return std::make_shared<DlUnknownMaskFilter>(this);
  }

  sk_sp<SkMaskFilter> skia_object() const override { return sk_filter_; }

  virtual ~DlUnknownMaskFilter() = default;

 protected:
  bool equals_(const DlMaskFilter& other) const override {
    FML_DCHECK(other.type() == DlMaskFilterType::kUnknown);
    auto that = static_cast<DlUnknownMaskFilter const&>(other);
    return sk_filter_ == that.sk_filter_;
  }

 private:
  sk_sp<SkMaskFilter> sk_filter_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MASK_FILTER_H_
