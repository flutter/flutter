// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DART_DART_SNAPSHOTTER_VM_H_
#define MOJO_DART_DART_SNAPSHOTTER_VM_H_

#include "dart/runtime/include/dart_api.h"
#include "tonic/dart_library_provider.h"
#include "tonic/dart_state.h"

class SnapshotterDartState : public tonic::DartState {
 public:
  SnapshotterDartState() : library_provider_(nullptr) {
  };

  tonic::DartLibraryProvider* library_provider() const {
    return library_provider_.get();
  }

  void set_library_provider(tonic::DartLibraryProvider* library_provider) {
    library_provider_.reset(library_provider);
    DCHECK(library_provider_.get() == library_provider);
  }

  static SnapshotterDartState* From(Dart_Isolate isolate) {
    return reinterpret_cast<SnapshotterDartState*>(DartState::From(isolate));
  }

  static SnapshotterDartState* Current() {
    return reinterpret_cast<SnapshotterDartState*>(DartState::Current());
  }

  static SnapshotterDartState* Cast(void* data) {
    return reinterpret_cast<SnapshotterDartState*>(data);
  }

 private:
  std::unique_ptr<tonic::DartLibraryProvider> library_provider_;
};

void InitDartVM();
Dart_Isolate CreateDartIsolate();

#endif  // MOJO_DART_DART_SNAPSHOTTER_VM_H_
