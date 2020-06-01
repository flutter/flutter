// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_TONIC_DART_WRAPPABLE_H_
#define LIB_TONIC_DART_WRAPPABLE_H_

#include "third_party/dart/runtime/include/dart_api.h"
#include "tonic/common/macros.h"
#include "tonic/converter/dart_converter.h"
#include "tonic/dart_state.h"
#include "tonic/dart_wrapper_info.h"
#include "tonic/logging/dart_error.h"

#include <type_traits>

namespace tonic {

// DartWrappable is a base class that you can inherit from in order to be
// exposed to Dart code as an interface.
class DartWrappable {
 public:
  enum DartNativeFields {
    kPeerIndex,  // Must be first to work with Dart_GetNativeReceiver.
    kWrapperInfoIndex,
    kNumberOfNativeFields,
  };

  DartWrappable() : dart_wrapper_(nullptr) {}

  // Subclasses that wish to expose a new interface must override this function
  // and provide information about their wrapper. There is no need to call your
  // base class's implementation of this function.
  // Implement using IMPLEMENT_WRAPPERTYPEINFO macro
  virtual const DartWrapperInfo& GetDartWrapperInfo() const = 0;

  // Override this to customize the object size reported to the Dart garbage
  // collector.
  // Implement using IMPLEMENT_WRAPPERTYPEINFO macro
  virtual size_t GetAllocationSize() const;

  virtual void RetainDartWrappableReference() const = 0;

  virtual void ReleaseDartWrappableReference() const = 0;

  // Use this method sparingly. It follows a slower path using Dart_New.
  // Prefer constructing the object in Dart code and using
  // AssociateWithDartWrapper.
  Dart_Handle CreateDartWrapper(DartState* dart_state);
  void AssociateWithDartWrapper(Dart_Handle wrappable);
  void ClearDartWrapper();  // Warning: Might delete this.
  Dart_WeakPersistentHandle dart_wrapper() const { return dart_wrapper_; }

 protected:
  virtual ~DartWrappable();

  static Dart_PersistentHandle GetTypeForWrapper(
      tonic::DartState* dart_state,
      const tonic::DartWrapperInfo& wrapper_info);

 private:
  static void FinalizeDartWrapper(void* isolate_callback_data,
                                  Dart_WeakPersistentHandle wrapper,
                                  void* peer);

  Dart_WeakPersistentHandle dart_wrapper_;

  TONIC_DISALLOW_COPY_AND_ASSIGN(DartWrappable);
};

#define DEFINE_WRAPPERTYPEINFO()                                           \
 public:                                                                   \
  const tonic::DartWrapperInfo& GetDartWrapperInfo() const override {      \
    return dart_wrapper_info_;                                             \
  }                                                                        \
  static Dart_PersistentHandle GetDartType(tonic::DartState* dart_state) { \
    return GetTypeForWrapper(dart_state, dart_wrapper_info_);              \
  }                                                                        \
                                                                           \
 private:                                                                  \
  static const tonic::DartWrapperInfo& dart_wrapper_info_

#define IMPLEMENT_WRAPPERTYPEINFO(LibraryName, ClassName)       \
  static const tonic::DartWrapperInfo                           \
      kDartWrapperInfo_##LibraryName_##ClassName = {            \
          #LibraryName,                                         \
          #ClassName,                                           \
          sizeof(ClassName),                                    \
  };                                                            \
  const tonic::DartWrapperInfo& ClassName::dart_wrapper_info_ = \
      kDartWrapperInfo_##LibraryName_##ClassName;

struct DartConverterWrappable {
  static DartWrappable* FromDart(Dart_Handle handle);
  static DartWrappable* FromArguments(Dart_NativeArguments args,
                                      int index,
                                      Dart_Handle& exception);
};

template <typename T>
struct DartConverter<
    T*,
    typename std::enable_if<
        std::is_convertible<T*, const DartWrappable*>::value>::type> {
  static Dart_Handle ToDart(DartWrappable* val) {
    if (!val)
      return Dart_Null();
    if (Dart_WeakPersistentHandle wrapper = val->dart_wrapper())
      return Dart_HandleFromWeakPersistent(wrapper);
    return val->CreateDartWrapper(DartState::Current());
  }

  static void SetReturnValue(Dart_NativeArguments args,
                             DartWrappable* val,
                             bool auto_scope = true) {
    if (!val)
      Dart_SetReturnValue(args, Dart_Null());
    else if (Dart_WeakPersistentHandle wrapper = val->dart_wrapper())
      Dart_SetWeakHandleReturnValue(args, wrapper);
    else
      Dart_SetReturnValue(args, val->CreateDartWrapper(DartState::Current()));
  }

  static T* FromDart(Dart_Handle handle) {
    // TODO(abarth): We're missing a type check.
    return static_cast<T*>(DartConverterWrappable::FromDart(handle));
  }

  static T* FromArguments(Dart_NativeArguments args,
                          int index,
                          Dart_Handle& exception,
                          bool auto_scope = true) {
    // TODO(abarth): We're missing a type check.
    return static_cast<T*>(
        DartConverterWrappable::FromArguments(args, index, exception));
  }
};

////////////////////////////////////////////////////////////////////////////////
// Support for generic smart pointers that have a "get" method that returns a
// pointer to a type that is Dart convertible as well as a constructor that
// adopts a raw pointer to that type.

template <template <typename T> class PTR, typename T>
struct DartConverter<PTR<T>> {
  static Dart_Handle ToDart(const PTR<T>& val) {
    return DartConverter<T*>::ToDart(val.get());
  }

  static PTR<T> FromDart(Dart_Handle handle) {
    return DartConverter<T*>::FromDart(handle);
  }

  static PTR<T> FromArguments(Dart_NativeArguments args,
                              int index,
                              Dart_Handle& exception,
                              bool auto_scope = true) {
    return PTR<T>(
        DartConverter<T*>::FromArguments(args, index, exception, auto_scope));
  }

  static void SetReturnValue(Dart_NativeArguments args,
                             const PTR<T>& val,
                             bool auto_scope = true) {
    DartConverter<T*>::SetReturnValue(args, val.get());
  }
};

template <template <typename T> class PTR, typename T>
struct DartListFactory<
    PTR<T>,
    typename std::enable_if<
        std::is_convertible<T*, const DartWrappable*>::value>::type> {
  static Dart_Handle NewList(intptr_t length) {
    Dart_PersistentHandle type = T::GetDartType(DartState::Current());
    TONIC_DCHECK(!LogIfError(type));
    return Dart_NewListOfType(Dart_HandleFromPersistent(type), length);
  }
};

template <typename T>
inline T* GetReceiver(Dart_NativeArguments args) {
  intptr_t receiver;
  Dart_Handle result = Dart_GetNativeReceiver(args, &receiver);
  TONIC_DCHECK(!Dart_IsError(result));
  if (!receiver)
    Dart_ThrowException(ToDart("Object has been disposed."));
  return static_cast<T*>(reinterpret_cast<DartWrappable*>(receiver));
}

}  // namespace tonic

#endif  // LIB_TONIC_DART_WRAPPABLE_H_
