// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/capture.h"

#include <initializer_list>
#include <memory>

namespace impeller {

//-----------------------------------------------------------------------------
/// CaptureProperty
///

CaptureProperty::CaptureProperty(const std::string& label, Options options)
    : CaptureCursorListElement(label), options(options) {}

CaptureProperty::~CaptureProperty() = default;

bool CaptureProperty::MatchesCloselyEnough(const CaptureProperty& other) const {
  if (label != other.label) {
    return false;
  }
  if (GetType() != other.GetType()) {
    return false;
  }
  return true;
}

#define _CAPTURE_PROPERTY_CAST_DEFINITION(type_name, pascal_name, lower_name) \
  std::optional<type_name> CaptureProperty::As##pascal_name() const {         \
    if (GetType() != Type::k##pascal_name) {                                  \
      return std::nullopt;                                                    \
    }                                                                         \
    return reinterpret_cast<const Capture##pascal_name##Property*>(this)      \
        ->value;                                                              \
  }

_FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROPERTY_CAST_DEFINITION);

#define _CAPTURE_PROPERTY_DEFINITION(type_name, pascal_name, lower_name)       \
  Capture##pascal_name##Property::Capture##pascal_name##Property(              \
      const std::string& label, type_name value, Options options)              \
      : CaptureProperty(label, options), value(std::move(value)) {}            \
                                                                               \
  std::shared_ptr<Capture##pascal_name##Property>                              \
      Capture##pascal_name##Property::Make(const std::string& label,           \
                                           type_name value, Options options) { \
    auto result = std::shared_ptr<Capture##pascal_name##Property>(             \
        new Capture##pascal_name##Property(label, std::move(value), options)); \
    return result;                                                             \
  }                                                                            \
                                                                               \
  CaptureProperty::Type Capture##pascal_name##Property::GetType() const {      \
    return Type::k##pascal_name;                                               \
  }                                                                            \
                                                                               \
  void Capture##pascal_name##Property::Invoke(                                 \
      const CaptureProcTable& proc_table) {                                    \
    proc_table.lower_name(*this);                                              \
  }

_FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROPERTY_DEFINITION);

//-----------------------------------------------------------------------------
/// CaptureElement
///

CaptureElement::CaptureElement(const std::string& label)
    : CaptureCursorListElement(label) {}

std::shared_ptr<CaptureElement> CaptureElement::Make(const std::string& label) {
  return std::shared_ptr<CaptureElement>(new CaptureElement(label));
}

void CaptureElement::Rewind() {
  properties.Rewind();
  children.Rewind();
}

bool CaptureElement::MatchesCloselyEnough(const CaptureElement& other) const {
  return label == other.label;
}

//-----------------------------------------------------------------------------
/// Capture
///

Capture::Capture() = default;

#ifdef IMPELLER_ENABLE_CAPTURE
Capture::Capture(const std::string& label)
    : element_(CaptureElement::Make(label)), active_(true) {
  element_->label = label;
}
#else
Capture::Capture(const std::string& label) {}
#endif

Capture Capture::MakeInactive() {
  return Capture();
}

std::shared_ptr<CaptureElement> Capture::GetElement() const {
#ifdef IMPELLER_ENABLE_CAPTURE
  return element_;
#else
  return nullptr;
#endif
}

void Capture::Rewind() {
  return GetElement()->Rewind();
}

#ifdef IMPELLER_ENABLE_CAPTURE
#define _CAPTURE_PROPERTY_RECORDER_DEFINITION(type_name, pascal_name,          \
                                              lower_name)                      \
  type_name Capture::Add##pascal_name(const std::string& label,                \
                                      type_name value,                         \
                                      CaptureProperty::Options options) {      \
    if (!active_) {                                                            \
      return value;                                                            \
    }                                                                          \
    FML_DCHECK(element_ != nullptr);                                           \
                                                                               \
    auto new_value = Capture##pascal_name##Property::Make(                     \
        label, std::move(value), options);                                     \
                                                                               \
    auto next = std::reinterpret_pointer_cast<Capture##pascal_name##Property>( \
        element_->properties.GetNext(std::move(new_value), options.readonly)); \
                                                                               \
    return next->value;                                                        \
  }

_FOR_EACH_CAPTURE_PROPERTY(_CAPTURE_PROPERTY_RECORDER_DEFINITION);
#endif

//-----------------------------------------------------------------------------
/// CaptureContext
///

#ifdef IMPELLER_ENABLE_CAPTURE
CaptureContext::CaptureContext() : active_(true) {}
CaptureContext::CaptureContext(std::initializer_list<std::string> allowlist)
    : active_(true), allowlist_(allowlist) {}
#else
CaptureContext::CaptureContext() {}
CaptureContext::CaptureContext(std::initializer_list<std::string> allowlist) {}
#endif

CaptureContext::CaptureContext(CaptureContext::InactiveFlag) {}

CaptureContext CaptureContext::MakeInactive() {
  return CaptureContext(InactiveFlag{});
}

CaptureContext CaptureContext::MakeAllowlist(
    std::initializer_list<std::string> allowlist) {
  return CaptureContext(allowlist);
}

bool CaptureContext::IsActive() const {
#ifdef IMPELLER_ENABLE_CAPTURE
  return active_;
#else
  return false;
#endif
}

void CaptureContext::Rewind() {
#ifdef IMPELLER_ENABLE_CAPTURE
  for (auto& [name, capture] : documents_) {
    capture.GetElement()->Rewind();
  }
#else
  return;
#endif
}

Capture CaptureContext::GetDocument(const std::string& label) {
#ifdef IMPELLER_ENABLE_CAPTURE
  if (!active_) {
    return Capture::MakeInactive();
  }

  if (allowlist_.has_value()) {
    if (allowlist_->find(label) == allowlist_->end()) {
      return Capture::MakeInactive();
    }
  }

  auto found = documents_.find(label);
  if (found != documents_.end()) {
    // Always rewind when fetching an existing document.
    found->second.Rewind();
    return found->second;
  }

  auto new_document = Capture(label);
  documents_.emplace(label, new_document);
  return new_document;
#else
  return Capture::MakeInactive();
#endif
}

bool CaptureContext::DoesDocumentExist(const std::string& label) const {
#ifdef IMPELLER_ENABLE_CAPTURE
  if (!active_) {
    return false;
  }
  return documents_.find(label) != documents_.end();
#else
  return false;
#endif
}

}  // namespace impeller
