// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MASK_FILTER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MASK_FILTER_H_

#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"

namespace flutter {

class DlBlurMaskFilter;

// The DisplayList MaskFilter class. This class was designed to be:
//
// - Typed:
//     Even though most references and pointers are passed around as the
//     base class, a DlMaskFilter::Type can be queried using the |type|
//     method to determine which type of MaskFilter is being used.
//
// - Inspectable:
//     Any parameters required to full specify the filtering operations are
//     provided on the specific base classes.
//
// - Safely Downcast:
//     For the subclasses that have specific data to query, methods |asBlur|
//     are provided to safely downcast the reference for inspection.
//
// - Skiafiable:
//     The classes override an |sk_filter| method to easily obtain a Skia
//     version of the filter on demand.
//
// - Immutable:
//     Neither the base class or any of the subclasses specify any mutation
//     methods. Instances are often passed around as const as a reminder,
//     but the classes have no mutation methods anyway.
//
// - Flat and Embeddable:
//     Bulk freed + bulk compared + zero memory fragmentation.
//
//     All of these classes are designed to be stored in the DisplayList
//     buffer allocated in-line with the rest of the data to avoid dangling
//     pointers that require explicit freeing when the DisplayList goes
//     away, or that fragment the memory needed to read the operations in
//     the DisplayList. Furthermore, the data in the classes can be bulk
//     compared using a |memcmp| when performing a |DisplayList::Equals|.
//
// - Passed by Pointer:
//     The data shared via the |Dispatcher::setMaskFilter| call is stored
//     in the buffer itself and so its lifetime is controlled by the
//     DisplayList. That memory cannot be shared as by a |shared_ptr|
//     because the memory may be freed outside the control of the shared
//     pointer. Creating a shared version of the object would require a
//     new instantiation which we'd like to avoid on every dispatch call,
//     so a raw (const) pointer is shared instead with all of the
//     responsibilities of non-ownership in the called method.
//
//     But, for methods that need to keep a copy of the data...
//
// - Shared_Ptr-able:
//     The classes support a method to return a |std::shared_ptr| version of
//     themselves, safely instantiating a new copy of the object into a
//     shared_ptr using |std::make_shared|. For those dispatcher objects
//     that may want to hold on to the contents of the object (typically
//     in a |current_mask_filter_| field), they can obtain a shared_ptr
//     copy safely and easily using the |shared| method.

class DlMaskFilter {
 public:
  // An enumerated type for the recognized MaskFilter operations.
  // If a custom MaskFilter outside of the recognized types is needed
  // then a |kUnknown| type that simply defers to an SkMaskFilter is
  // provided as a fallback.
  enum Type { kBlur, kUnknown };

  // Return a shared_ptr holding a DlMaskFilter representing the indicated
  // Skia SkMaskFilter pointer.
  //
  // Since there is no public SkBlurMaskFilter and since the SkMaskFilter
  // class provides no |asABlur| style type inference methods, we cannot
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

  // Return the recognized type of the MaskFilter operation.
  virtual Type type() const = 0;

  // Return the size of the instantiated data (typically used to allocate)
  // storage in the DisplayList buffer.
  virtual size_t size() const = 0;

  // Return a shared version of |this| MaskFilter. The |shared_ptr| returned
  // will reference a copy of this object so that the lifetime of the shared
  // version is not tied to the storage of this particular instance.
  virtual std::shared_ptr<DlMaskFilter> shared() const = 0;

  // Return an equivalent |SkMaskFilter| version of this object.
  virtual sk_sp<SkMaskFilter> sk_filter() const = 0;

  // Return a DlBlurMaskFilter pointer to this object iff it is a Blur
  // type of MaskFilter, otherwise return nullptr.
  virtual const DlBlurMaskFilter* asBlur() const { return nullptr; }

  // Perform a content aware |==| comparison of the MaskFilter.
  bool operator==(DlMaskFilter const& other) const {
    return type() == other.type() && equals_(other);
  }
  // Perform a content aware |!=| comparison of the ColorFilter.
  bool operator!=(DlMaskFilter const& other) const { return !(*this == other); }

  virtual ~DlMaskFilter() = default;

 protected:
  // Virtual comparison method to support |==| and |!=|.
  virtual bool equals_(DlMaskFilter const& other) const = 0;
};

// The Blur type of MaskFilter which specifies modifying the
// colors as if the color specified in the Blur filter is the
// source color and the color drawn by the rendering operation
// is the destination color. The mode parameter of the Blur
// filter is then used to combine those colors.
class DlBlurMaskFilter final : public DlMaskFilter {
 public:
  DlBlurMaskFilter(SkBlurStyle style, SkScalar sigma)
      : style_(style), sigma_(sigma) {}
  DlBlurMaskFilter(const DlBlurMaskFilter& filter)
      : DlBlurMaskFilter(filter.style_, filter.sigma_) {}
  DlBlurMaskFilter(const DlBlurMaskFilter* filter)
      : DlBlurMaskFilter(filter->style_, filter->sigma_) {}

  Type type() const override { return kBlur; }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlMaskFilter> shared() const override {
    return std::make_shared<DlBlurMaskFilter>(this);
  }

  sk_sp<SkMaskFilter> sk_filter() const override {
    return SkMaskFilter::MakeBlur(style_, sigma_);
  }

  const DlBlurMaskFilter* asBlur() const override { return this; }

  SkBlurStyle style() const { return style_; }
  SkScalar sigma() const { return sigma_; }

 protected:
  bool equals_(DlMaskFilter const& other) const override {
    FML_DCHECK(other.type() == kBlur);
    auto that = static_cast<DlBlurMaskFilter const&>(other);
    return style_ == that.style_ && sigma_ == that.sigma_;
  }

 private:
  SkBlurStyle style_;
  SkScalar sigma_;
};

// A wrapper class for a Skia MaskFilter of unknown type. The above 4 types
// are the only types that can be constructed by Flutter using the
// ui.MaskFilter class so this class should be rarely used. The main use
// would come from the |DisplayListCanvasRecorder| recording Skia rendering
// calls that originated outside of the Flutter dart code. This would
// primarily happen in the Paragraph code that renders the text using the
// SkCanvas interface which we capture into DisplayList data structures.
class DlUnknownMaskFilter final : public DlMaskFilter {
 public:
  DlUnknownMaskFilter(sk_sp<SkMaskFilter> sk_filter)
      : sk_filter_(std::move(sk_filter)) {}
  DlUnknownMaskFilter(const DlUnknownMaskFilter& filter)
      : DlUnknownMaskFilter(filter.sk_filter_) {}
  DlUnknownMaskFilter(const DlUnknownMaskFilter* filter)
      : DlUnknownMaskFilter(filter->sk_filter_) {}

  Type type() const override { return kUnknown; }
  size_t size() const override { return sizeof(*this); }

  std::shared_ptr<DlMaskFilter> shared() const override {
    return std::make_shared<DlUnknownMaskFilter>(this);
  }

  sk_sp<SkMaskFilter> sk_filter() const override { return sk_filter_; }

  virtual ~DlUnknownMaskFilter() = default;

 protected:
  bool equals_(const DlMaskFilter& other) const override {
    FML_DCHECK(other.type() == kUnknown);
    auto that = static_cast<DlUnknownMaskFilter const&>(other);
    return sk_filter_ == that.sk_filter_;
  }

 private:
  sk_sp<SkMaskFilter> sk_filter_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MASK_FILTER_H_
