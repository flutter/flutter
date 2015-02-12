// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {
class AbstractModule;
class BuiltinSky;
class DOMDartState;
class Document;

class DartController {
 public:
  DartController();
  ~DartController();

  static void InitVM();

  void LoadModule(RefPtr<AbstractModule> module,
                  const String& source,
                  const TextPosition& textPosition);
  void ClearForClose();
  void CreateIsolateFor(Document*);

  DOMDartState* dart_state() const { return dom_dart_state_.get(); }

 private:
  void ExecuteModule(RefPtr<AbstractModule> module);

  OwnPtr<DOMDartState> dom_dart_state_;
  OwnPtr<BuiltinSky> builtin_sky_;

  base::WeakPtrFactory<DartController> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(DartController);
};

}

#endif // SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
