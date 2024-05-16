// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_CAPTURE_H_
#define FLUTTER_IMPELLER_CORE_CAPTURE_H_

#include <functional>
#include <initializer_list>
#include <memory>
#include <string>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/vector.h"

namespace impeller {

struct CaptureProcTable;

#define _FOR_EACH_CAPTURE_PROPERTY(PROPERTY_V) \
  PROPERTY_V(bool, Boolean, boolean)           \
  PROPERTY_V(int, Integer, integer)            \
  PROPERTY_V(Scalar, Scalar, scalar)           \
  PROPERTY_V(Point, Point, point)              \
  PROPERTY_V(Vector3, Vector3, vector3)        \
  PROPERTY_V(Rect, Rect, rect)                 \
  PROPERTY_V(Color, Color, color)              \
  PROPERTY_V(Matrix, Matrix, matrix)           \
  PROPERTY_V(std::string, String, string)

template <typename Type>
struct CaptureCursorListElement {
  std::string label;

  explicit CaptureCursorListElement(const std::string& label) : label(label){};

  virtual ~CaptureCursorListElement() = default;

  //----------------------------------------------------------------------------
  /// @brief  Determines if previously captured data matches closely enough with
  ///         newly recorded data to safely emitted in its place. If this
  ///         returns `false`, then the remaining elements in the capture list
  ///         are discarded and re-recorded.
  ///
  ///         This mechanism ensures that the UI of an interactive inspector can
  ///         never deviate from reality, even if the schema of the captured
  ///         data were to significantly deviate.
  ///
  virtual bool MatchesCloselyEnough(const Type& other) const = 0;
};

#define _CAPTURE_TYPE(type_name, pascal_name, lower_name) k##pascal_name,

#define _CAPTURE_PROPERTY_CAST_DECLARATION(type_name, pascal_name, lower_name) \
  std::optional<type_name> As##pascal_name() const;

/// A capturable property type
struct CaptureProperty : public CaptureCursorListElement<CaptureProperty> {
  enum class Type { _FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_TYPE) };

  struct Options {
    struct Range {
      Scalar min;
      Scalar max;
    };

    /// Readonly properties are always re-recorded during capture. Any edits
    /// made to readonly values in-between captures are overwritten during the
    /// next capture.
    bool readonly = false;

    /// An inspector hint that can be used for displaying sliders. Only used for
    /// numeric types. Rounded down for integer types.
    std::optional<Range> range;
  };

  Options options;

  CaptureProperty(const std::string& label, Options options);

  virtual ~CaptureProperty();

  virtual Type GetType() const = 0;

  virtual void Invoke(const CaptureProcTable& proc_table) = 0;

  bool MatchesCloselyEnough(const CaptureProperty& other) const override;

  _FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROPERTY_CAST_DECLARATION)
};

#define _CAPTURE_PROPERTY_DECLARATION(type_name, pascal_name, lower_name) \
  struct Capture##pascal_name##Property final : public CaptureProperty {  \
    type_name value;                                                      \
                                                                          \
    static std::shared_ptr<Capture##pascal_name##Property>                \
    Make(const std::string& label, type_name value, Options options);     \
                                                                          \
    /* |CaptureProperty| */                                               \
    Type GetType() const override;                                        \
                                                                          \
    /* |CaptureProperty| */                                               \
    void Invoke(const CaptureProcTable& proc_table) override;             \
                                                                          \
   private:                                                               \
    Capture##pascal_name##Property(const std::string& label,              \
                                   type_name value,                       \
                                   Options options);                      \
                                                                          \
    FML_DISALLOW_COPY_AND_ASSIGN(Capture##pascal_name##Property);         \
  };

_FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROPERTY_DECLARATION);

#define _CAPTURE_PROC(type_name, pascal_name, lower_name)           \
  std::function<void(Capture##pascal_name##Property&)> lower_name = \
      [](Capture##pascal_name##Property& value) {};

struct CaptureProcTable {
  _FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROC)
};

template <typename Type>
class CapturePlaybackList {
 public:
  CapturePlaybackList() = default;

  ~CapturePlaybackList() {
    // Force the list element type to inherit the CRTP type. We can't enforce
    // this as a template requirement directly because `CaptureElement` has a
    // recursive `CaptureCursorList<CaptureElement>` property, and so the
    // compiler fails the check due to the type being incomplete.
    static_assert(std::is_base_of_v<CaptureCursorListElement<Type>, Type>);
  }

  void Rewind() { cursor_ = 0; }

  size_t Count() { return values_.size(); }

  std::shared_ptr<Type> GetNext(std::shared_ptr<Type> captured,
                                bool force_overwrite) {
    if (cursor_ < values_.size()) {
      std::shared_ptr<Type>& result = values_[cursor_];

      if (result->MatchesCloselyEnough(*captured)) {
        if (force_overwrite) {
          values_[cursor_] = captured;
        }
        // Safe playback is possible.
        ++cursor_;
        return result;
      }
      // The data has changed too much from the last capture to safely continue
      // playback. Discard this and all subsequent elements to re-record.
      values_.resize(cursor_);
    }

    ++cursor_;
    values_.push_back(captured);
    return captured;
  }

  std::shared_ptr<Type> FindFirstByLabel(const std::string& label) {
    for (std::shared_ptr<Type>& value : values_) {
      if (value->label == label) {
        return value;
      }
    }
    return nullptr;
  }

  void Iterate(std::function<void(Type&)> iterator) const {
    for (auto& value : values_) {
      iterator(*value);
    }
  }

 private:
  size_t cursor_ = 0;
  std::vector<std::shared_ptr<Type>> values_;

  CapturePlaybackList(const CapturePlaybackList&) = delete;

  CapturePlaybackList& operator=(const CapturePlaybackList&) = delete;
};

/// A document of capture data, containing a list of properties and a list
/// of subdocuments.
struct CaptureElement final : public CaptureCursorListElement<CaptureElement> {
  CapturePlaybackList<CaptureProperty> properties;
  CapturePlaybackList<CaptureElement> children;

  static std::shared_ptr<CaptureElement> Make(const std::string& label);

  void Rewind();

  bool MatchesCloselyEnough(const CaptureElement& other) const override;

 private:
  explicit CaptureElement(const std::string& label);

  CaptureElement(const CaptureElement&) = delete;

  CaptureElement& operator=(const CaptureElement&) = delete;
};

#ifdef IMPELLER_ENABLE_CAPTURE
#define _CAPTURE_PROPERTY_RECORDER_DECLARATION(type_name, pascal_name, \
                                               lower_name)             \
  type_name Add##pascal_name(std::string_view label, type_name value,  \
                             CaptureProperty::Options options = {});
#else
#define _CAPTURE_PROPERTY_RECORDER_DECLARATION(type_name, pascal_name,       \
                                               lower_name)                   \
  inline type_name Add##pascal_name(std::string_view label, type_name value, \
                                    CaptureProperty::Options options = {}) { \
    return value;                                                            \
  }
#endif

class Capture {
 public:
  explicit Capture(const std::string& label);

  Capture();

  static Capture MakeInactive();

  inline Capture CreateChild(std::string_view label) {
#ifdef IMPELLER_ENABLE_CAPTURE
    if (!active_) {
      return Capture();
    }

    std::string label_copy = std::string(label);
    auto new_capture = Capture(label_copy);
    new_capture.element_ =
        element_->children.GetNext(new_capture.element_, false);
    new_capture.element_->Rewind();
    return new_capture;
#else
    return Capture();
#endif
  }

  std::shared_ptr<CaptureElement> GetElement() const;

  void Rewind();

  _FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROPERTY_RECORDER_DECLARATION)

 private:
#ifdef IMPELLER_ENABLE_CAPTURE
  std::shared_ptr<CaptureElement> element_;
  bool active_ = false;
#endif
};

class CaptureContext {
 public:
  CaptureContext();

  static CaptureContext MakeInactive();

  static CaptureContext MakeAllowlist(
      std::initializer_list<std::string> allowlist);

  bool IsActive() const;

  void Rewind();

  Capture GetDocument(const std::string& label);

  bool DoesDocumentExist(const std::string& label) const;

 private:
  struct InactiveFlag {};
  explicit CaptureContext(InactiveFlag);
  CaptureContext(std::initializer_list<std::string> allowlist);

#ifdef IMPELLER_ENABLE_CAPTURE
  bool active_ = false;
  std::optional<std::unordered_set<std::string>> allowlist_;
  std::unordered_map<std::string, Capture> documents_;
#endif
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_CAPTURE_H_
