// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
#define SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_

#include "base/callback_forward.h"
#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {
class AbstractModule;
class BuiltinSky;
class DOMDartState;
class DartValue;
class Document;
class HTMLScriptElement;

class DartController {
 public:
  DartController();
  ~DartController();

  static void InitVM();

  typedef base::Callback<void(RefPtr<AbstractModule>, RefPtr<DartValue>)>
      LoadFinishedCallback;

  void LoadScriptInModule(AbstractModule* module,
                          const String& source,
                          const TextPosition& textPosition,
                          const LoadFinishedCallback& load_finished_callback);
  void ExecuteLibraryInModule(AbstractModule* module,
                              Dart_Handle library,
                              HTMLScriptElement* script);

  void ClearForClose();
  void CreateIsolateFor(Document* document);

  DOMDartState* dart_state() const { return dom_dart_state_.get(); }

 private:
  bool ImportChildLibraries(AbstractModule* module, Dart_Handle library);
  Dart_Handle CreateLibrary(AbstractModule* module,
                            const String& source,
                            const TextPosition& position);

  OwnPtr<DOMDartState> dom_dart_state_;
  OwnPtr<BuiltinSky> builtin_sky_;

  DISALLOW_COPY_AND_ASSIGN(DartController);
};

}

#endif // SKY_ENGINE_CORE_SCRIPT_DART_CONTROLLER_H_
