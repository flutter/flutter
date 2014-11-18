// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_INSPECTOR_INSPECTOR_BACKEND_MOJO_H_
#define SKY_ENGINE_INSPECTOR_INSPECTOR_BACKEND_MOJO_H_

#include "base/basictypes.h"
#include "core/inspector/InspectorFrontendChannel.h"
#include "sky/services/inspector/inspector.mojom.h"

namespace blink {
class FrameHost;
class InspectorBackendDispatcher;
class JSONObject;
class PageDebuggerAgent;
class InjectedScriptManager;
class InspectorState;
class InstrumentingAgents;
class InspectorFrontend;

class InspectorBackendMojo : public mojo::InterfaceImpl<sky::InspectorBackend>,
    public InspectorFrontendChannel {
public:
  explicit InspectorBackendMojo(const FrameHost& frame_host);
  ~InspectorBackendMojo();

  void Connect();

private:
  // InspectorBackend:
  void OnConnect() override;
  void OnDisconnect() override;
  void OnMessage(const mojo::String& message) override;

  // InspectorFrontendChannel:
  void sendMessageToFrontend(PassRefPtr<JSONObject> message) override;
  void flush() override;

  const FrameHost& frame_host_;

  sky::InspectorFrontendPtr frontend_;

  OwnPtr<InspectorFrontend> old_frontend_;
  RefPtr<InspectorBackendDispatcher> dispatcher_;
  OwnPtr<PageDebuggerAgent> debugger_agent_;
  OwnPtr<InjectedScriptManager> script_manager_;
  OwnPtr<InspectorState> inspector_state_;
  OwnPtr<InstrumentingAgents> agents_;

  DISALLOW_COPY_AND_ASSIGN(InspectorBackendMojo);
};

}  // namespace blink

#endif  // SKY_ENGINE_INSPECTOR_INSPECTOR_BACKEND_MOJO_H_