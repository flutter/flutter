// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_

#include <memory>

#include "base/callback_forward.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {
class AbstractModule;
class DartUI;
class DOMDartState;
class DartLibraryProvider;
class DartSnapshotLoader;
class View;

class DartController {
 public:
  DartController();
  ~DartController();

  static void InitVM();

  void RunFromLibrary(const std::string& name,
                      DartLibraryProvider* library_provider);
  void RunFromPrecompiledSnapshot();
  void RunFromSnapshot(mojo::ScopedDataPipeConsumerHandle snapshot);
  void RunFromSnapshotBuffer(const uint8_t* buffer, size_t size);

  void CreateIsolateFor(std::unique_ptr<DOMDartState> dom_dart_state);
  void Shutdown();

  DOMDartState* dart_state() const { return dom_dart_state_.get(); }

 private:
  void DidLoadMainLibrary(std::string url);
  void DidLoadSnapshot();
  bool SendStartMessage(Dart_Handle root_library);

  std::unique_ptr<DOMDartState> dom_dart_state_;
  std::unique_ptr<DartSnapshotLoader> snapshot_loader_;

  base::WeakPtrFactory<DartController> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(DartController);
};

}

#endif // SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
