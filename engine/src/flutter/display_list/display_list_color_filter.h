// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_FILTER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_FILTER_H_

#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"

namespace flutter {

class DlBlendColorFilter;
class DlMatrixColorFilter;

// The DisplayList ColorFilter class. This class was designed to be:
//
// - Typed:
//     Even though most references and pointers are passed around as the
//     base class, a DlColorFilter::Type can be queried using the |type|
//     method to determine which type of ColorFilter is being used.
//
// - Inspectable:
//     Any parameters required to full specify the filtering operations are
//     provided on the specific base classes.
//
// - Safely Downcast:
//     For the subclasses that have specific data to query, methods |asBlend|
//     and |asMatrix| are provided to safely downcast the reference for
//     inspection.
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
//     The data shared via the |Dispatcher::setColorFilter| call is stored
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
//     in a |current_color_filter_| field), they can obtain a shared_ptr
//     copy safely and easily using the |shared| method.

class DlColorFilter {
 public:
  // An enumerated type for the recognized ColorFilter operations.
  // If a custom ColorFilter outside of the recognized types is needed
  // then a |kUnknown| type that simply defers to an SkColorFilter is
  // provided as a fallback.
  enum Type {
    kBlend,
    kMatrix,
    kSrgbToLinearGamma,
    kLinearToSrgbGamma,
    kUnknown
  };

  // Return a shared_ptr holding a DlColorFilter representing the indicated
  // Skia SkColorFilter pointer.
  //
  // This method can detect each of the 4 recognized types from an analogous
  // SkColorFilter.
  static std::shared_ptr<DlColorFilter> From(SkColorFilter* sk_filter);

  // Return a shared_ptr holding a DlColorFilter representing the indicated
  // Skia SkColorFilter pointer.
  //
  // This method can detect each of the 4 recognized types from an analogous
  // SkColorFilter.
  static std::shared_ptr<DlColorFilter> From(sk_sp<SkColorFilter> sk_filter) {
    return From(sk_filter.get());
  }

  // Return the recognized type of the ColorFilter operation.
  virtual Type type() const = 0;

  // Return the size of the instantiated data (typically used to allocate)
  // storage in the DisplayList buffer.
  virtual size_t size() const = 0;

  // Return a boolean indicating whether the color filtering operation will
  // modify transparent black. This is typically used to determine if applying
  // the ColorFilter to a temporary saveLayer buffer will turn the surrounding
  // pixels non-transparent and therefore expand the bounds.
  virtual bool modifies_transparent_black() const = 0;

  // Return a shared version of a DlColorFilter pointer, or nullptr if the
  // pointer is null.
  static std::shared_ptr<DlColorFilter> Shared(const DlColorFilter* filter) {
    return filter == nullptr ? nullptr : filter->shared();
  }

  // Return a shared version of |this| ColorFilter. The |shared_ptr| returned
  // will reference a copy of this object so that the lifetime of the shared
  // version is not tied to the storage of this particular instance.
  virtual std::shared_ptr<DlColorFilter> shared() const = 0;

  // Return an equivalent |SkColorFilter| version of this object.
  virtual sk_sp<SkColorFilter> sk_filter() const = 0;

  // Return a DlBlendColorFilter pointer to this object iff it is a Blend
  // type of ColorFilter, otherwise return nullptr.
  virtual const DlBlendColorFilter* asBlend() const { return nullptr; }

  // Return a DlMatrixColorFilter pointer to this object iff it is a Matrix
  // type of ColorFilter, otherwise return nullptr.
  virtual const DlMatrixColorFilter* asMatrix() const { return nullptr; }

  // asSrgb<->Linear and asUnknown are not needed because they
  // have no properties to query. Their type fully specifies their
  // operation or can be accessed via the common sk_filter() method.

  // Perform a content aware |==| comparison of the ColorFilter.
  bool operator==(DlColorFilter const& other) const {
    return type() == other.type() && equals_(other);
  }
  // Perform a content aware |!=| comparison of the ColorFilter.
  bool operator!=(DlColorFilter const& other) const {
    return !(*this == other);
  }

  virtual ~DlColorFilter() = default;

 protected:
  // Virtual comparison method to support |==| and |!=|.
  virtual bool equals_(DlColorFilter const& other) const = 0;
};

// The Blend type of ColorFilter which specifies modifying the
// colors as if the color specified in the Blend filter is the
// source color and the color drawn by the rendering operation
// is the destination color. The mode parameter of the Blend
// filter is then used to combine those colors.
class DlBlendColorFilter final : public DlColorFilter {
 public:
  DlBlendColorFilter(SkColor color, SkBlendMode mode)
      : color_(color), mode_(mode) {}
  DlBlendColorFilter(const DlBlendColorFilter& filter)
      : DlBlendColorFilter(filter.color_, filter.mode_) {}
  DlBlendColorFilter(const DlBlendColorFilter* filter)
      : DlBlendColorFilter(filter->color_, filter->mode_) {}

  Type type() const override { return kBlend; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override {
    // Look at blend and color to make a faster determination?
    return sk_filter()->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT;
  }

  std::shared_ptr<DlColorFilter> shared() const override {
    return std::make_shared<DlBlendColorFilter>(this);
  }

  sk_sp<SkColorFilter> sk_filter() const override {
    return SkColorFilters::Blend(color_, mode_);
  }

  const DlBlendColorFilter* asBlend() const override { return this; }

  SkColor color() const { return color_; }
  SkBlendMode mode() const { return mode_; }

 protected:
  bool equals_(DlColorFilter const& other) const override {
    FML_DCHECK(other.type() == kBlend);
    auto that = static_cast<DlBlendColorFilter const&>(other);
    return color_ == that.color_ && mode_ == that.mode_;
  }

 private:
  SkColor color_;
  SkBlendMode mode_;
};

// The Matrix type of ColorFilter which runs every pixel drawn by
// the rendering operation [iR,iG,iB,iA] through a vector/matrix
// multiplication, as in:
//
//  [ oR ]   [ m[ 0] m[ 1] m[ 2] m[ 3] m[ 4] ]   [ iR ]
//  [ oG ]   [ m[ 5] m[ 6] m[ 7] m[ 8] m[ 9] ]   [ iG ]
//  [ oB ] = [ m[10] m[11] m[12] m[13] m[14] ] x [ iB ]
//  [ oA ]   [ m[15] m[16] m[17] m[18] m[19] ]   [ iA ]
//                                               [  1 ]
//
// The resulting color [oR,oG,oB,oA] is then clamped to the range of
// valid pixel components before storing in the output.
class DlMatrixColorFilter final : public DlColorFilter {
 public:
  DlMatrixColorFilter(const float matrix[20]) {
    memcpy(matrix_, matrix, sizeof(matrix_));
  }
  DlMatrixColorFilter(const DlMatrixColorFilter& filter)
      : DlMatrixColorFilter(filter.matrix_) {}
  DlMatrixColorFilter(const DlMatrixColorFilter* filter)
      : DlMatrixColorFilter(filter->matrix_) {}

  Type type() const override { return kMatrix; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override {
    // Look at the matrix to make a faster determination?
    // Basically, are the translation components all 0?
    return sk_filter()->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT;
  }

  std::shared_ptr<DlColorFilter> shared() const override {
    return std::make_shared<DlMatrixColorFilter>(this);
  }

  sk_sp<SkColorFilter> sk_filter() const override {
    return SkColorFilters::Matrix(matrix_);
  }

  const DlMatrixColorFilter* asMatrix() const override { return this; }

  const float& operator[](int index) const { return matrix_[index]; }
  void get_matrix(float matrix[20]) const {
    memcpy(matrix, matrix_, sizeof(matrix_));
  }

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == kMatrix);
    auto that = static_cast<DlMatrixColorFilter const&>(other);
    return memcmp(matrix_, that.matrix_, sizeof(matrix_)) == 0;
  }

 private:
  float matrix_[20];
};

// The SrgbToLinear type of ColorFilter that applies the inverse of the sRGB
// gamma curve to the rendered pixels.
class DlSrgbToLinearGammaColorFilter final : public DlColorFilter {
 public:
  static const std::shared_ptr<DlSrgbToLinearGammaColorFilter> instance;

  DlSrgbToLinearGammaColorFilter() {}
  DlSrgbToLinearGammaColorFilter(const DlSrgbToLinearGammaColorFilter& filter)
      : DlSrgbToLinearGammaColorFilter() {}
  DlSrgbToLinearGammaColorFilter(const DlSrgbToLinearGammaColorFilter* filter)
      : DlSrgbToLinearGammaColorFilter() {}

  Type type() const override { return kSrgbToLinearGamma; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override { return false; }

  std::shared_ptr<DlColorFilter> shared() const override { return instance; }
  sk_sp<SkColorFilter> sk_filter() const override { return sk_filter_; }

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == kSrgbToLinearGamma);
    return true;
  }

 private:
  static const sk_sp<SkColorFilter> sk_filter_;
  friend class DlColorFilter;
};

// The LinearToSrgb type of ColorFilter that applies the sRGB gamma curve
// to the rendered pixels.
class DlLinearToSrgbGammaColorFilter final : public DlColorFilter {
 public:
  static const std::shared_ptr<DlLinearToSrgbGammaColorFilter> instance;

  DlLinearToSrgbGammaColorFilter() {}
  DlLinearToSrgbGammaColorFilter(const DlLinearToSrgbGammaColorFilter& filter)
      : DlLinearToSrgbGammaColorFilter() {}
  DlLinearToSrgbGammaColorFilter(const DlLinearToSrgbGammaColorFilter* filter)
      : DlLinearToSrgbGammaColorFilter() {}

  Type type() const override { return kLinearToSrgbGamma; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override { return false; }

  std::shared_ptr<DlColorFilter> shared() const override { return instance; }
  sk_sp<SkColorFilter> sk_filter() const override { return sk_filter_; }

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == kLinearToSrgbGamma);
    return true;
  }

 private:
  static const sk_sp<SkColorFilter> sk_filter_;
  friend class DlColorFilter;
};

// A wrapper class for a Skia ColorFilter of unknown type. The above 4 types
// are the only types that can be constructed by Flutter using the
// ui.ColorFilter class so this class should be rarely used. The main use
// would come from the |DisplayListCanvasRecorder| recording Skia rendering
// calls that originated outside of the Flutter dart code. This would
// primarily happen in the Paragraph code that renders the text using the
// SkCanvas interface which we capture into DisplayList data structures.
class DlUnknownColorFilter final : public DlColorFilter {
 public:
  DlUnknownColorFilter(sk_sp<SkColorFilter> sk_filter)
      : sk_filter_(std::move(sk_filter)) {}
  DlUnknownColorFilter(const DlUnknownColorFilter& filter)
      : DlUnknownColorFilter(filter.sk_filter_) {}
  DlUnknownColorFilter(const DlUnknownColorFilter* filter)
      : DlUnknownColorFilter(filter->sk_filter_) {}

  Type type() const override { return kUnknown; }
  size_t size() const override { return sizeof(*this); }
  bool modifies_transparent_black() const override {
    return sk_filter()->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT;
  }

  std::shared_ptr<DlColorFilter> shared() const override {
    return std::make_shared<DlUnknownColorFilter>(this);
  }

  sk_sp<SkColorFilter> sk_filter() const override { return sk_filter_; }

  virtual ~DlUnknownColorFilter() = default;

 protected:
  bool equals_(const DlColorFilter& other) const override {
    FML_DCHECK(other.type() == kUnknown);
    auto that = static_cast<DlUnknownColorFilter const&>(other);
    return sk_filter_ == that.sk_filter_;
  }

 private:
  sk_sp<SkColorFilter> sk_filter_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_COLOR_FILTER_H_
