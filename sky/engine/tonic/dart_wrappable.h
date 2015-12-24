// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_WRAPPABLE_H_
#define SKY_ENGINE_TONIC_DART_WRAPPABLE_H_

#include "base/logging.h"
#include "base/template_util.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_wrapper_info.h"

namespace blink {
class DartGCVisitor;
struct DartWrapperInfo;

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
  virtual const DartWrapperInfo& GetDartWrapperInfo() const = 0;

  // Subclasses that wish to integrate with the Dart garbage collector should
  // override this function. Please call your base class's AcceptDartGCVisitor
  // at the end of your override.
  virtual void AcceptDartGCVisitor(DartGCVisitor& visitor) const;

  Dart_Handle CreateDartWrapper(DartState* dart_state);
  void AssociateWithDartWrapper(Dart_NativeArguments args);
  void ClearDartWrapper(); // Warning: Might delete this.
  Dart_WeakPersistentHandle dart_wrapper() const { return dart_wrapper_; }

 protected:
  virtual ~DartWrappable();

 private:
  static void FinalizeDartWrapper(void* isolate_callback_data,
                                  Dart_WeakPersistentHandle wrapper,
                                  void* peer);

  Dart_WeakPersistentHandle dart_wrapper_;

  DISALLOW_COPY_AND_ASSIGN(DartWrappable);
};

#define DEFINE_WRAPPERTYPEINFO()                                               \
 public:                                                                       \
  const DartWrapperInfo& GetDartWrapperInfo() const override {                 \
    return dart_wrapper_info_;                                                 \
  }                                                                            \
 private:                                                                      \
  static const DartWrapperInfo& dart_wrapper_info_

#define IMPLEMENT_WRAPPERTYPEINFO(ClassName)                                   \
static void RefObject(DartWrappable* impl) {                                   \
  static_cast<ClassName*>(impl)->ref();                                        \
}                                                                              \
static void DerefObject(DartWrappable* impl) {                                 \
  static_cast<ClassName*>(impl)->deref();                                      \
}                                                                              \
static const DartWrapperInfo kDartWrapperInfo = {                              \
  #ClassName,                                                                  \
  sizeof(ClassName),                                                           \
  &RefObject,                                                                  \
  &DerefObject,                                                                \
};                                                                             \
const DartWrapperInfo& ClassName::dart_wrapper_info_ = kDartWrapperInfo;                                   \

struct DartConverterWrappable {
  static DartWrappable* FromDart(Dart_Handle handle);
  static DartWrappable* FromArguments(Dart_NativeArguments args,
                                      int index,
                                      Dart_Handle& exception);
  static DartWrappable* FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                                   int index,
                                                   Dart_Handle& exception);
};

template<typename T>
struct DartConverter<
    T*,
    typename base::enable_if<
        base::is_convertible<T*, const DartWrappable*>::value>::type> {
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
    return static_cast<T*>(DartConverterWrappable::FromArguments(
        args, index, exception));
  }

  static T* FromArgumentsWithNullCheck(Dart_NativeArguments args,
                                       int index,
                                       Dart_Handle& exception,
                                       bool auto_scope = true) {
    // TODO(abarth): We're missing a type check.
    return static_cast<T*>(DartConverterWrappable::FromArgumentsWithNullCheck(
        args, index, exception));
  }
};

template<typename T>
struct DartConverter<RefPtr<T>> {
  static Dart_Handle ToDart(RefPtr<T> val) {
    return DartConverter<T*>::ToDart(val.get());
  }

  static RefPtr<T> FromDart(Dart_Handle handle) {
    return DartConverter<T*>::FromDart(handle);
  }
};

template<typename T>
struct DartConverter<PassRefPtr<T>> {
  static void SetReturnValue(Dart_NativeArguments args,
                             PassRefPtr<T> val,
                             bool auto_scope = true) {
    DartConverter<T*>::SetReturnValue(args, val.get());
  }
};

template<typename T>
inline T* GetReceiver(Dart_NativeArguments args) {
  intptr_t receiver;
  Dart_Handle result = Dart_GetNativeReceiver(args, &receiver);
  DCHECK(!Dart_IsError(result));
  return static_cast<T*>(reinterpret_cast<DartWrappable*>(receiver));
}

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_WRAPPABLE_H_
