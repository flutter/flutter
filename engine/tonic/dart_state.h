// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_STATE_H_
#define SKY_ENGINE_TONIC_DART_STATE_H_

#include "base/logging.h"
#include "base/memory/weak_ptr.h"
#include "base/supports_user_data.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {
class DartClassLibrary;
class DartExceptionFactory;
class DartStringCache;
class DartTimerHeap;

// DartState represents the state associated with a given Dart isolate. The
// lifetime of this object is controlled by the DartVM. If you want to hold a
// reference to a DartState instance, please hold a base::WeakPtr<DartState>.
//
// DartState is analogous to gin::PerIsolateData and JSC::ExecState.
class DartState : public base::SupportsUserData {
 public:
  class Scope {
   public:
    Scope(DartState* dart_state);
    ~Scope();

   private:
    DartIsolateScope scope_;
    DartApiScope api_scope_;
  };

  DartState();
  virtual ~DartState();

  static DartState* From(Dart_Isolate isolate);
  static DartState* Current();

  base::WeakPtr<DartState> GetWeakPtr();

  Dart_Isolate isolate() { return isolate_; }
  void set_isolate(Dart_Isolate isolate) {
    CHECK(!isolate_);
    isolate_ = isolate;
    DidSetIsolate();
  }

  DartClassLibrary& class_library() { return *class_library_; }
  DartStringCache& string_cache() { return *string_cache_; }
  DartExceptionFactory& exception_factory() { return *exception_factory_; }
  DartTimerHeap& timer_heap() { return *timer_heap_; }

  virtual void DidSetIsolate() {}

 private:
  Dart_Isolate isolate_;
  OwnPtr<DartClassLibrary> class_library_;
  OwnPtr<DartStringCache> string_cache_;
  OwnPtr<DartExceptionFactory> exception_factory_;
  OwnPtr<DartTimerHeap> timer_heap_;

  base::WeakPtrFactory<DartState> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(DartState);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_STATE_H_
