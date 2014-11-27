// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/v8_inspector/inspector_backend_mojo.h"

#include "base/memory/scoped_ptr.h"
#include "base/run_loop.h"
#include "gen/sky/core/InspectorBackendDispatcher.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/application/service_provider_impl.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "sky/engine/core/inspector/InjectedScriptHost.h"
#include "sky/engine/core/inspector/InspectorFrontendChannel.h"
#include "sky/engine/core/inspector/InspectorState.h"
#include "sky/engine/core/inspector/InstrumentingAgents.h"
#include "sky/engine/platform/JSONValues.h"
#include "sky/engine/v8_inspector/inspector_host.h"
#include "sky/engine/v8_inspector/PageDebuggerAgent.h"
#include "sky/engine/v8_inspector/PageScriptDebugServer.h"

namespace blink {

class InspectorBackendMojoImpl
    : public InspectorFrontendChannel,
      public mojo::InterfaceImpl<sky::InspectorBackend> {
 public:
  explicit InspectorBackendMojoImpl(inspector::InspectorHost*);
  ~InspectorBackendMojoImpl();

  void Connect();

  // InspectorBackend:
  void OnConnect();
  void OnMessage(const mojo::String& message) override;
  void OnDisconnect();

  // InspectorFrontendChannel:
  void sendMessageToFrontend(PassRefPtr<JSONObject> message) override;
  // TODO(eseidel): Unclear if flush is needed.
  void flush() override {}

  inspector::InspectorHost* host_;
  sky::InspectorFrontendPtr frontend_;

  OwnPtr<InspectorFrontend> old_frontend_;
  RefPtr<InspectorBackendDispatcher> dispatcher_;
  OwnPtr<PageDebuggerAgent> debugger_agent_;
  OwnPtr<InjectedScriptManager> script_manager_;
  OwnPtr<InspectorState> inspector_state_;
  OwnPtr<InstrumentingAgents> agents_;

  DISALLOW_COPY_AND_ASSIGN(InspectorBackendMojoImpl);
};

// FIXME: Probably this should be provided by the InspectorHost?
class MessageLoopAdaptor : public PageScriptDebugServer::ClientMessageLoop {
 public:
  MessageLoopAdaptor() {}

 private:
  virtual void run(inspector::InspectorHost* host) {
    run_loop_.reset(new base::RunLoop());
    run_loop_->Run();
  }

  virtual void quitNow() {
    if (run_loop_)
      run_loop_->Quit();
  }

  scoped_ptr<base::RunLoop> run_loop_;
};

class InspectorHostResolverImpl : public PageScriptDebugServer::InspectorHostResolver {
 public:
  explicit InspectorHostResolverImpl(inspector::InspectorHost* host) : host_(host) { }
  ~InspectorHostResolverImpl() override { }
  inspector::InspectorHost* inspectorHostFor(v8::Handle<v8::Context> context) override {
    if (context == host_->GetContext())
      return host_;
    return nullptr;
  }
 private:
  inspector::InspectorHost* host_;
};

InspectorBackendMojoImpl::InspectorBackendMojoImpl(
    inspector::InspectorHost* host)
    : host_(host) {
}

InspectorBackendMojoImpl::~InspectorBackendMojoImpl() {
}

void InspectorBackendMojoImpl::Connect() {
  mojo::Shell* shell = host_->GetShell();
  mojo::ServiceProviderPtr inspector_service_provider;
  shell->ConnectToApplication("mojo:sky_inspector_server",
                              GetProxy(&inspector_service_provider));
  mojo::ConnectToService(inspector_service_provider.get(), &frontend_);
  frontend_.set_client(this);

  // Theoretically we should load our state from the inspector cookie.
  inspector_state_ =
      adoptPtr(new InspectorState(nullptr, JSONObject::create()));
  old_frontend_ = adoptPtr(new InspectorFrontend(this));

  PageScriptDebugServer::setMainThreadIsolate(host_->GetIsolate());
  OwnPtr<MessageLoopAdaptor> message_loop = adoptPtr(new MessageLoopAdaptor);
  PageScriptDebugServer::shared().setClientMessageLoop(message_loop.release());
  OwnPtr<InspectorHostResolverImpl> host_resolver =
      adoptPtr(new InspectorHostResolverImpl(host_));
  PageScriptDebugServer::shared().setInspectorHostResolver(host_resolver.release());

  // AgentRegistry used to do this, but we don't need it for one agent.
  script_manager_ = InjectedScriptManager::createForPage();
  debugger_agent_ = PageDebuggerAgent::create(&PageScriptDebugServer::shared(),
                                              host_, script_manager_.get());
  agents_ = adoptPtr(new InstrumentingAgents(debugger_agent_.get()));
  script_manager_->injectedScriptHost()->init(agents_.get(), &PageScriptDebugServer::shared());
  debugger_agent_->init(agents_.get(), inspector_state_.get());
  debugger_agent_->setFrontend(old_frontend_.get());

  dispatcher_ = InspectorBackendDispatcher::create(this);
  dispatcher_->registerAgent(debugger_agent_.get());
}

void InspectorBackendMojoImpl::OnConnect() {
}

void InspectorBackendMojoImpl::OnDisconnect() {
}

void InspectorBackendMojoImpl::sendMessageToFrontend(
    PassRefPtr<JSONObject> message) {
  frontend_->SendMessage(message->toJSONString().toUTF8());
}

void InspectorBackendMojoImpl::OnMessage(const mojo::String& message) {
  String wtf_message = String::fromUTF8(message.To<std::string>());
  String command_name;
  InspectorBackendDispatcher::getCommandName(wtf_message, &command_name);
  // InspectorBackendDispatcher will automatically reply with errors
  // if agents are missing, since we only want this backend to care about
  // the Debugger agent, we manually filter here.
  if (command_name.startsWith("Debugger"))
    dispatcher_->dispatch(wtf_message);
}

}  // namespace blink

namespace inspector {

InspectorBackendMojo::InspectorBackendMojo(InspectorHost* host)
    : impl_(new blink::InspectorBackendMojoImpl(host)) {
}

InspectorBackendMojo::~InspectorBackendMojo() {
}

void InspectorBackendMojo::Connect() {
  impl_->Connect();
}

}  // namespace inspector
