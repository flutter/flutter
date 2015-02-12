// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS2_DART_EVENT_LISTENER_H_
#define SKY_ENGINE_BINDINGS2_DART_EVENT_LISTENER_H_

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/core/events/EventListener.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {

class DartEventListener : public EventListener {
 public:
  static PassRefPtr<DartEventListener> FromDart(Dart_Handle handle);

  ~DartEventListener() override;

  bool operator==(const EventListener& other) override {
    return this == &other;
  }
  void handleEvent(ExecutionContext*, Event*) override;

  void AcceptDartGCVisitor(DartGCVisitor& visitor) const override;

 private:
  explicit DartEventListener(Dart_Handle handle);

  static void Finalize(void* isolate_callback_data,
                       Dart_WeakPersistentHandle handle,
                       void* peer);

  base::WeakPtr<DartState> data_state_;
  Dart_WeakPersistentHandle closure_;
};

template <>
struct DartConverter<EventListener*> {
  static PassRefPtr<EventListener> FromDart(Dart_Handle handle) {
    return DartEventListener::FromDart(handle);
  }

  static PassRefPtr<EventListener> FromArguments(Dart_NativeArguments args,
                                                 int index,
                                                 Dart_Handle& exception) {
    return FromDart(Dart_GetNativeArgument(args, index));
  }

  static PassRefPtr<EventListener> FromArgumentsWithNullCheck(
      Dart_NativeArguments args,
      int index,
      Dart_Handle& exception) {
    Dart_Handle handle = Dart_GetNativeArgument(args, index);
    if (Dart_IsNull(handle))
      return nullptr;
    return FromDart(handle);
  }
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS2_DART_EVENT_LISTENER_H_
