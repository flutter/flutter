// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/application/application_runner_chromium.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/public/cpp/bindings/interface_impl.h"
#include "net/server/http_server.h"
#include "net/socket/tcp_server_socket.h"
#include "sky/services/inspector/inspector.mojom.h"


namespace sky {
namespace inspector {

// TODO(eseidel): None of this Impl nonsense is necessary: crbug.com/431963
class InspectorServerImpl : public mojo::InterfaceImpl<InspectorServer> {
public:
  class Delegate {
  public:
    virtual void Register(InspectorServerImpl* impl) = 0;
    virtual void Unregister(InspectorServerImpl* impl) = 0;
    virtual void Listen(int32_t port) = 0;
  };
  InspectorServerImpl(Delegate* delegate) : delegate_(delegate) {
    delegate_->Register(this);
  }
  virtual ~InspectorServerImpl() {
    delegate_->Unregister(this);
  }

  // InspectorServer:
  void Listen(int32_t port, const mojo::Callback<void()>& callback) override {
    delegate_->Listen(port);
    callback.Run();
  }

  void OnShutdown() {
    delete this;
  }

private:
  // InterfaceImpl:
  void OnConnectionError() override {
    delete this; // crbug.com/431911
  }

  Delegate* delegate_;
};

class InspectorFrontendImpl : public mojo::InterfaceImpl<InspectorFrontend> {
 public:
  class Delegate {
  public:
    virtual void Register(InspectorFrontendImpl*) = 0;
    virtual void Unregister(InspectorFrontendImpl*) = 0;
    virtual void SendMessage(const mojo::String&) = 0;
  };

  InspectorFrontendImpl(Delegate* delegate);
  virtual ~InspectorFrontendImpl();

  void OnShutdown();

 private:
  // InspectorFrontend:
  void SendMessage(const mojo::String& message) override;

  // InterfaceImpl:
  void OnConnectionError() override;

  Delegate* delegate_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(InspectorFrontendImpl);
};

InspectorFrontendImpl::InspectorFrontendImpl(Delegate* delegate)
    : delegate_(delegate) {
  delegate_->Register(this);
}

InspectorFrontendImpl::~InspectorFrontendImpl() {
  delegate_->Unregister(this);
}

void InspectorFrontendImpl::OnShutdown() {
  client()->OnDisconnect();
  delete this;
}

void InspectorFrontendImpl::OnConnectionError() {
  delete this; // crbug.com/431911
}

void InspectorFrontendImpl::SendMessage(const mojo::String& message) {
  delegate_->SendMessage(message);
}


namespace {
const int kNotConnected = -1;
}

class Server : public mojo::ApplicationDelegate,
    public InspectorFrontendImpl::Delegate,
    public InspectorServerImpl::Delegate,
    public mojo::InterfaceFactory<InspectorFrontend>,
    public mojo::InterfaceFactory<InspectorServer>,
    public net::HttpServer::Delegate {
 public:
  Server() : connection_id_(kNotConnected) {}
  virtual ~Server();

 private:
  // mojo::ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override {
  }
  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->AddService<InspectorFrontend>(this);
    connection->AddService<InspectorServer>(this);
    return true;
  }

  // InterfaceFactory<InspectorFrontend>:
  void Create(mojo::ApplicationConnection* connection,
        mojo::InterfaceRequest<InspectorFrontend> request) override {
    // Weak instead of strong, per crbug.com/431911
    WeakBindToRequest(new InspectorFrontendImpl(this), &request);
  }

  // InterfaceFactory<InspectorServer>:
  void Create(mojo::ApplicationConnection* connection,
        mojo::InterfaceRequest<InspectorServer> request) override {
    // Weak instead of strong, per crbug.com/431911
    WeakBindToRequest(new InspectorServerImpl(this), &request);
  }

  // InspectorServerImpl::Delegate:
  void Register(InspectorServerImpl*) override;
  void Unregister(InspectorServerImpl*) override;
  void Listen(int32_t port) override;

  // InspectorFrontendImpl::Delegate:
  void Register(InspectorFrontendImpl*) override;
  void Unregister(InspectorFrontendImpl*) override;
  void SendMessage(const mojo::String& message) override;

  // net::HttpServer::Delegate:
  void OnConnect(int connection_id) override;
  void OnHttpRequest(
      int connection_id, const net::HttpServerRequestInfo& info) override;
  void OnWebSocketRequest(
      int connection_id, const net::HttpServerRequestInfo& info) override;
  void OnWebSocketMessage(
      int connection_id, const std::string& data) override;
  void OnClose(int connection_id) override;

  void CloseAllAgentConnections();

  int connection_id_;
  scoped_ptr<net::HttpServer> web_server_;
  ObserverList<InspectorFrontendImpl> agents_;
  ObserverList<InspectorServerImpl> clients_;

  DISALLOW_COPY_AND_ASSIGN(Server);
};

Server::~Server()
{
  FOR_EACH_OBSERVER(InspectorServerImpl, clients_, OnShutdown());
  CloseAllAgentConnections();
}

void Server::CloseAllAgentConnections() {
  FOR_EACH_OBSERVER(InspectorFrontendImpl, agents_, OnShutdown());
}

void Server::OnConnect(int connection_id) {
}

void Server::OnHttpRequest(
    int connection_id, const net::HttpServerRequestInfo& info) {
  web_server_->Send500(connection_id, "websockets protocol only");
}

void Server::OnWebSocketRequest(
    int connection_id, const net::HttpServerRequestInfo& info) {
  if (connection_id_ != kNotConnected) {
    web_server_->Close(connection_id);
    return;
  }
  web_server_->AcceptWebSocket(connection_id, info);
  connection_id_ = connection_id;
  FOR_EACH_OBSERVER(InspectorFrontendImpl, agents_, client()->OnConnect());
}

void Server::OnWebSocketMessage(
    int connection_id, const std::string& data) {
  DCHECK_EQ(connection_id, connection_id_);
  FOR_EACH_OBSERVER(InspectorFrontendImpl, agents_, client()->OnMessage(data));
}

void Server::OnClose(int connection_id) {
  if (connection_id != connection_id_)
    return;
  connection_id_ = kNotConnected;
  FOR_EACH_OBSERVER(InspectorFrontendImpl, agents_, client()->OnDisconnect());
}

void Server::Register(InspectorServerImpl* client) {
  clients_.AddObserver(client);
}

void Server::Unregister(InspectorServerImpl* client) {
  clients_.RemoveObserver(client);
}

void Server::Register(InspectorFrontendImpl* agent) {
  agents_.AddObserver(agent);
}

void Server::Unregister(InspectorFrontendImpl* agent) {
  agents_.RemoveObserver(agent);
}

void Server::Listen(int32_t port) {
  CloseAllAgentConnections(); // Assume caller represents a new app.

  // TODO(eseidel): Early-out here if we're already bound to the right port.
  web_server_.reset();
  scoped_ptr<net::ServerSocket> server_socket(
      new net::TCPServerSocket(NULL, net::NetLog::Source()));
  server_socket->ListenWithAddressAndPort("0.0.0.0", port, 1);
  web_server_.reset(new net::HttpServer(server_socket.Pass(), this));
}

void Server::SendMessage(const mojo::String& message) {
  if (connection_id_ == kNotConnected)
    return;
  web_server_->SendOverWebSocket(connection_id_, message);
}

}  // namespace inspector
}  // namespace sky

MojoResult MojoMain(MojoHandle shell_handle) {
  mojo::ApplicationRunnerChromium runner(new sky::inspector::Server);
  runner.set_message_loop_type(base::MessageLoop::TYPE_IO);
  return runner.Run(shell_handle);
}
