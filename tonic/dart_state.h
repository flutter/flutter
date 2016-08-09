// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_STATE_H_
#define FLUTTER_TONIC_DART_STATE_H_

#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_isolate_reloader.h"
#include "lib/tonic/dart_persistent_value.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/scopes/dart_api_scope.h"
#include "lib/tonic/scopes/dart_isolate_scope.h"

namespace blink {
class DartExceptionFactory;
class DartLibraryLoader;

// DartState represents the state associated with a given Dart isolate. The
// lifetime of this object is controlled by the DartVM. If you want to hold a
// reference to a DartState instance, please hold a base::WeakPtr<DartState>.
//
// DartState is analogous to gin::PerIsolateData and JSC::ExecState.
class DartState : public tonic::DartState {
 public:
  DartState();
  virtual ~DartState();

  static DartState* From(Dart_Isolate isolate);
  static DartState* Current();

  DartLibraryLoader& library_loader() { return *library_loader_; }

  // Takes ownership of |isolate_reloader|.
  void set_isolate_reloader(
      std::unique_ptr<DartIsolateReloader> isolate_reloader) {
    isolate_reloader_ = std::move(isolate_reloader);
  }
  DartIsolateReloader* isolate_reloader() { return isolate_reloader_.get(); }

 private:
  std::unique_ptr<DartLibraryLoader> library_loader_;
  std::unique_ptr<DartIsolateReloader> isolate_reloader_;

 protected:
  FTL_DISALLOW_COPY_AND_ASSIGN(DartState);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_STATE_H_
