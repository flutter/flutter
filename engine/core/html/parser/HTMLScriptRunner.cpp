// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/html/parser/HTMLScriptRunner.h"

#include "base/bind.h"
#include "sky/engine/core/app/AbstractModule.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLScriptElement.h"
#include "sky/engine/core/script/dart_controller.h"

namespace blink {

PassOwnPtr<HTMLScriptRunner> HTMLScriptRunner::createForScript(
    PassRefPtr<HTMLScriptElement> element,
    TextPosition position,
    HTMLScriptRunnerHost* host) {
  return adoptPtr(new HTMLScriptRunner(element, position, host));
}

HTMLScriptRunner::HTMLScriptRunner(PassRefPtr<HTMLScriptElement> element,
                                   TextPosition position,
                                   HTMLScriptRunnerHost* host)
    : m_host(host),
      m_element(element),
      m_position(position),
      m_state(StateInitial),
      m_weakFactory(this) {
}

HTMLScriptRunner::~HTMLScriptRunner()
{
  // If we hit this ASSERT we failed to notify the ScriptRunnerHost!
  ASSERT(m_state == StateCompleted);
}

bool HTMLScriptRunner::isExecutingScript() const {
  return m_state == StateExecuting;
}

void HTMLScriptRunner::advanceTo(State state, AdvanceType advanceType) {
  if (advanceType == ExecutionNormal) {
    switch (m_state) {
      case StateInitial:
        ASSERT(state == StateLoading);
        break;
      case StateLoading:
        ASSERT(state == StateExecuting);
        break;
      case StateExecuting:
        ASSERT(state == StateCompleted);
        break;
      case StateCompleted:
        ASSERT_NOT_REACHED();
    }
  }
  m_state = state;

  if (m_state == StateCompleted)
    m_host->scriptExecutionCompleted();
  // We may be deleted by scriptExecutionCompleted().
}

static LocalFrame* contextFrame(Element* element) {
  Document* contextDocument = element->document().contextDocument().get();
    if (!contextDocument)
      return nullptr;

    LocalFrame* frame = contextDocument->frame();
    if (!frame)
      return nullptr;
    return frame;
}

void HTMLScriptRunner::scriptFailed() {
  advanceTo(StateCompleted, ExecutionFailure);
}

void HTMLScriptRunner::start() {
  ASSERT(m_state == StateInitial);
  ASSERT(m_element->document().haveImportsLoaded());

  Document& sourceDocument = m_element->document();
  String source = m_element->textContent();

  LocalFrame* frame = contextFrame(m_element.get());
  if (!frame)
    return scriptFailed();

  advanceTo(StateLoading);

    ASSERT(sourceDocument.module());
    DartController::LoadFinishedCallback loadFinished = base::Bind(
        &HTMLScriptRunner::executeLibrary, m_weakFactory.GetWeakPtr());
    frame->dart().LoadScriptInModule(sourceDocument.module(), source,
                                     m_position, loadFinished);
}

// Enforce that the caller holds refs using RefPtr.
// FIXME: Neither of these should need refs, the Script should hold onto the
// library the document should keep the Module alive.
void HTMLScriptRunner::executeLibrary(RefPtr<AbstractModule> module,
                                      RefPtr<DartValue> library) {
  if (!module)
    return scriptFailed();

  advanceTo(StateExecuting);

  // Ian says we'll remove microtasks, but for now execute them right before
  // we "run" the script (call 'init'), not at dependency resolution
  // or script failures, etc.
  Microtask::performCheckpoint();

  if (LocalFrame* frame = contextFrame(m_element.get())) {
    frame->dart().ExecuteLibraryInModule(module.get(),
                                         library->dart_value(),
                                         m_element.get());
  }

  advanceTo(StateCompleted);
  // We may be deleted at this point.
}

}
