// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_PARSER_HTMLSCRIPTRUNNER_H_
#define SKY_ENGINE_CORE_HTML_PARSER_HTMLSCRIPTRUNNER_H_

#include "base/memory/weak_ptr.h"
#include "sky/engine/core/app/AbstractModule.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class HTMLScriptRunnerHost {
 public:
  virtual void scriptExecutionCompleted() = 0;
};

// Dart script blocks can include 'import' statements which can introduce
// additional dependencies which need to be resolved before the script can
// be executed.  The job of this class is to insulate the rest of the system
// from this complexity and take in a script and always produce a callback
// to continue parsing when that script completes/errors out, etc.

class HTMLScriptRunner {
public:
 static PassOwnPtr<HTMLScriptRunner> createForScript(
     PassRefPtr<HTMLScriptElement>,
     TextPosition,
     HTMLScriptRunnerHost*);
    ~HTMLScriptRunner();

    void start();

    bool isExecutingScript() const;

private:
 HTMLScriptRunner(PassRefPtr<HTMLScriptElement>,
                  TextPosition,
                  HTMLScriptRunnerHost*);

 enum State {
   StateInitial,    // No script.
   StateLoading,    // Waiting on imports to load.
   StateExecuting,  // Actually running the script.
   StateCompleted,  // Done, always hit this state regardless of success.
 };

 enum AdvanceType {
   ExecutionNormal,
   ExecutionFailure,
 };

 // Advancing to StateCompleted may cause the host to delete us.
 void advanceTo(State, AdvanceType = ExecutionNormal);

 void executeLibrary(RefPtr<AbstractModule> module, RefPtr<DartValue> library);
 void scriptFailed();

 HTMLScriptRunnerHost* m_host;
 RefPtr<HTMLScriptElement> m_element;
 TextPosition m_position;
 State m_state;
 base::WeakPtrFactory<HTMLScriptRunner> m_weakFactory;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_PARSER_HTMLSCRIPTRUNNER_H_
