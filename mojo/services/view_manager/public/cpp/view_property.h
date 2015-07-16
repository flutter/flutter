// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_PROPERTY_H_
#define MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_PROPERTY_H_

#include <stdint.h>

// This header should be included by code that defines ViewProperties. It
// should not be included by code that only gets and sets ViewProperties.
//
// To define a new ViewProperty:
//
//  #include "view_manager/public/cpp/view_property.h"
//
//  DECLARE_EXPORTED_VIEW_PROPERTY_TYPE(FOO_EXPORT, MyType);
//  namespace foo {
//    // Use this to define an exported property that is premitive,
//    // or a pointer you don't want automatically deleted.
//    DEFINE_VIEW_PROPERTY_KEY(MyType, kMyKey, MyDefault);
//
//    // Use this to define an exported property whose value is a heap
//    // allocated object, and has to be owned and freed by the view.
//    DEFINE_OWNED_VIEW_PROPERTY_KEY(gfx::Rect, kRestoreBoundsKey, nullptr);
//
//    // Use this to define a non exported property that is primitive,
//    // or a pointer you don't want to automatically deleted, and is used
//    // only in a specific file. This will define the property in an unnamed
//    // namespace which cannot be accessed from another file.
//    DEFINE_LOCAL_VIEW_PROPERTY_KEY(MyType, kMyKey, MyDefault);
//
//  }  // foo namespace
//
// To define a new type used for ViewProperty.
//
//  // outside all namespaces:
//  DECLARE_EXPORTED_VIEW_PROPERTY_TYPE(FOO_EXPORT, MyType)
//
// If a property type is not exported, use DECLARE_VIEW_PROPERTY_TYPE(MyType)
// which is a shorthand for DECLARE_EXPORTED_VIEW_PROPERTY_TYPE(, MyType).

namespace mojo {
namespace {

// No single new-style cast works for every conversion to/from int64_t, so we
// need this helper class. A third specialization is needed for bool because
// MSVC warning C4800 (forcing value to bool) is not suppressed by an explicit
// cast (!).
template <typename T>
class ViewPropertyCaster {
 public:
  static int64_t ToInt64(T x) { return static_cast<int64_t>(x); }
  static T FromInt64(int64_t x) { return static_cast<T>(x); }
};
template <typename T>
class ViewPropertyCaster<T*> {
 public:
  static int64_t ToInt64(T* x) { return reinterpret_cast<int64_t>(x); }
  static T* FromInt64(int64_t x) { return reinterpret_cast<T*>(x); }
};
template <>
class ViewPropertyCaster<bool> {
 public:
  static int64_t ToInt64(bool x) { return static_cast<int64_t>(x); }
  static bool FromInt64(int64_t x) { return x != 0; }
};

}  // namespace

template <typename T>
struct ViewProperty {
  T default_value;
  const char* name;
  View::PropertyDeallocator deallocator;
};

template <typename T>
void View::SetLocalProperty(const ViewProperty<T>* property, T value) {
  int64_t old = SetLocalPropertyInternal(
      property, property->name,
      value == property->default_value ? nullptr : property->deallocator,
      ViewPropertyCaster<T>::ToInt64(value),
      ViewPropertyCaster<T>::ToInt64(property->default_value));
  if (property->deallocator &&
      old != ViewPropertyCaster<T>::ToInt64(property->default_value)) {
    (*property->deallocator)(old);
  }
}

template <typename T>
T View::GetLocalProperty(const ViewProperty<T>* property) const {
  return ViewPropertyCaster<T>::FromInt64(GetLocalPropertyInternal(
      property, ViewPropertyCaster<T>::ToInt64(property->default_value)));
}

template <typename T>
void View::ClearLocalProperty(const ViewProperty<T>* property) {
  SetLocalProperty(property, property->default_value);
}

}  // namespace mojo

// Macros to instantiate the property getter/setter template functions.
#define DECLARE_EXPORTED_VIEW_PROPERTY_TYPE(EXPORT, T)                         \
  template EXPORT void mojo::View::SetLocalProperty(                           \
      const mojo::ViewProperty<T>*, T);                                        \
  template EXPORT T mojo::View::GetLocalProperty(const mojo::ViewProperty<T>*) \
      const;                                                                   \
  template EXPORT void mojo::View::ClearLocalProperty(                         \
      const mojo::ViewProperty<T>*);
#define DECLARE_VIEW_PROPERTY_TYPE(T) DECLARE_EXPORTED_VIEW_PROPERTY_TYPE(, T)

#define DEFINE_VIEW_PROPERTY_KEY(TYPE, NAME, DEFAULT)                       \
  COMPILE_ASSERT(sizeof(TYPE) <= sizeof(int64_t), property_type_too_large); \
  namespace {                                                               \
  const mojo::ViewProperty<TYPE> NAME##_Value = {DEFAULT, #NAME, nullptr};  \
  }                                                                         \
  const mojo::ViewProperty<TYPE>* const NAME = &NAME##_Value;

#define DEFINE_LOCAL_VIEW_PROPERTY_KEY(TYPE, NAME, DEFAULT)                 \
  COMPILE_ASSERT(sizeof(TYPE) <= sizeof(int64_t), property_type_too_large); \
  namespace {                                                               \
  const mojo::ViewProperty<TYPE> NAME##_Value = {DEFAULT, #NAME, nullptr};  \
  const mojo::ViewProperty<TYPE>* const NAME = &NAME##_Value;               \
  }

#define DEFINE_OWNED_VIEW_PROPERTY_KEY(TYPE, NAME, DEFAULT)            \
  namespace {                                                          \
  void Deallocator##NAME(int64_t p) {                                  \
    enum { type_must_be_complete = sizeof(TYPE) };                     \
    delete mojo::ViewPropertyCaster<TYPE*>::FromInt64(p);              \
  }                                                                    \
  const mojo::ViewProperty<TYPE*> NAME##_Value = {DEFAULT,             \
                                                  #NAME,               \
                                                  &Deallocator##NAME}; \
  }                                                                    \
  const mojo::ViewProperty<TYPE*>* const NAME = &NAME##_Value;

#endif  // MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_PROPERTY_H_
