// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/inspector/inspector_backend_mojo.h"

#include "base/memory/scoped_ptr.h"
#include "base/run_loop.h"
#include "bindings/core/v8/PageScriptDebugServer.h"
#include "bindings/core/v8/ScriptController.h"
#include "core/frame/FrameHost.h"
#include "core/inspector/InspectorState.h"
#include "core/inspector/InstrumentingAgents.h"
#include "core/inspector/PageDebuggerAgent.h"
#include "core/InspectorBackendDispatcher.h"
#include "core/page/Page.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "platform/JSONValues.h"
#include "public/platform/ServiceProvider.h"

namespace blink {

class MessageLoopAdaptor : public PageScriptDebugServer::ClientMessageLoop {
public:
    MessageLoopAdaptor() { }

private:
    virtual void run(Page* page)
    {
      if (run_loop_)
        return;
      run_loop_.reset(new base::RunLoop());
      run_loop_->Run();
    }

    virtual void quitNow()
    {
      if (run_loop_)
        run_loop_->Quit();
    }

    scoped_ptr<base::RunLoop> run_loop_;
};

InspectorBackendMojo::InspectorBackendMojo(const FrameHost& frame_host)
    : frame_host_(frame_host) {
}

InspectorBackendMojo::~InspectorBackendMojo() {
}

void InspectorBackendMojo::Connect() {
  mojo::Shell* shell = frame_host_.services().Shell();
  mojo::ServiceProviderPtr inspector_service_provider;
  shell->ConnectToApplication("mojo:sky_inspector_server",
                              GetProxy(&inspector_service_provider));
  mojo::ConnectToService(inspector_service_provider.get(), &frontend_);
  frontend_.set_client(this);

  // Theoretically we should load our state from the inspector cookie.
  inspector_state_ = adoptPtr(new InspectorState(nullptr, JSONObject::create()));
  old_frontend_ = adoptPtr(new InspectorFrontend(this));

  v8::Isolate* isolate = frame_host_.page().mainFrame()->script().isolate();
  PageScriptDebugServer::setMainThreadIsolate(isolate);
  OwnPtr<MessageLoopAdaptor> message_loop = adoptPtr(new MessageLoopAdaptor);
  PageScriptDebugServer::shared().setClientMessageLoop(message_loop.release());

  // AgentRegistry used to do this, but we don't need it for one agent.
  script_manager_ = InjectedScriptManager::createForPage();
  debugger_agent_ = PageDebuggerAgent::create(&PageScriptDebugServer::shared(), &frame_host_.page(), script_manager_.get());
  agents_ = adoptPtr(new InstrumentingAgents(debugger_agent_.get()));
  debugger_agent_->init(agents_.get(), inspector_state_.get());
  debugger_agent_->setFrontend(old_frontend_.get());

  dispatcher_ = InspectorBackendDispatcher::create(this);
  dispatcher_->registerAgent(debugger_agent_.get());
}

void InspectorBackendMojo::sendMessageToFrontend(
    PassRefPtr<JSONObject> message) {
  frontend_->SendMessage(message->toJSONString().toUTF8());
}

void InspectorBackendMojo::flush() {
  // TODO(eseidel): Unclear if this is needed.
}

void InspectorBackendMojo::OnConnect() {
}

void InspectorBackendMojo::OnDisconnect() {
}

void InspectorBackendMojo::OnMessage(const mojo::String& message) {
  String wtf_message = String::fromUTF8(message.To<std::string>());
  String command_name;
  InspectorBackendDispatcher::getCommandName(wtf_message, &command_name);
  // InspectorBackendDispatcher will automatically reply with errors
  // if agents are missing, since we only want this backend to care about
  // the Debugger agent, we manually filter here.
  if (command_name.startsWith("Debugger"))
      dispatcher_->dispatch(wtf_message);
}

} // namespace blink
