// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/application/application_runner_chromium.h"
#include "mojo/common/weak_binding_set.h"
#include "mojo/common/weak_interface_ptr_set.h"
#include "mojo/public/c/system/main.h"
#include "mojo/public/cpp/application/application_delegate.h"
#include "mojo/public/cpp/application/application_impl.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "net/server/http_server.h"
#include "net/socket/tcp_server_socket.h"
#include "sky/services/inspector/inspector.mojom.h"


namespace sky {
namespace inspector {

namespace {
const int kNotConnected = -1;
}

class Server : public mojo::ApplicationDelegate,
               public InspectorFrontend,
               public InspectorServer,
               public mojo::InterfaceFactory<InspectorFrontend>,
               public mojo::InterfaceFactory<InspectorServer>,
               public net::HttpServer::Delegate {
 public:
  Server() : connection_id_(kNotConnected), server_binding_(this) {}
  virtual ~Server();

 private:
  // mojo::ApplicationDelegate:
  void Initialize(mojo::ApplicationImpl* app) override {
  }
  bool ConfigureIncomingConnection(
      mojo::ApplicationConnection* connection) override {
    connection->AddService<InspectorFrontend>(this);
    connection->AddService<InspectorServer>(this);
    if (connection->GetServiceProvider()) {
      // The application connecting to us may implement InspectorBackend,
      // attempt to establish a connection to find out. If it doesn't then this
      // pipe will close.
      InspectorBackendPtr backend;
      connection->ConnectToService(&backend);
      backends_.AddInterfacePtr(backend.Pass());
    }
    return true;
  }

  // InterfaceFactory<InspectorFrontend>:
  void Create(mojo::ApplicationConnection* connection,
        mojo::InterfaceRequest<InspectorFrontend> request) override {
    frontend_bindings_.AddBinding(this, request.Pass());
  }

  // InterfaceFactory<InspectorServer>:
  void Create(mojo::ApplicationConnection* connection,
        mojo::InterfaceRequest<InspectorServer> request) override {
    server_binding_.Bind(request.PassMessagePipe());
  }

  // InspectorServer:
  void Listen(int32_t port, const mojo::Closure& callback) override;

  // InspectorFrontend:
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

  int connection_id_;
  scoped_ptr<net::HttpServer> web_server_;

  mojo::WeakInterfacePtrSet<InspectorBackend> backends_;
  mojo::WeakBindingSet<InspectorFrontend> frontend_bindings_;
  mojo::Binding<InspectorServer> server_binding_;

  DISALLOW_COPY_AND_ASSIGN(Server);
};

Server::~Server()
{
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
  backends_.ForAllPtrs([](InspectorBackend* backend) { backend->OnConnect(); });
}

void Server::OnWebSocketMessage(
    int connection_id, const std::string& data) {
  DCHECK_EQ(connection_id, connection_id_);
  backends_.ForAllPtrs(
      [data](InspectorBackend* backend) { backend->OnMessage(data); });
}

void Server::OnClose(int connection_id) {
  if (connection_id != connection_id_)
    return;
  connection_id_ = kNotConnected;
  backends_.ForAllPtrs(
      [](InspectorBackend* backend) { backend->OnDisconnect(); });
}

void Server::Listen(int32_t port, const mojo::Closure& callback) {
  backends_.CloseAll();  // Assume caller represents a new app.

  // TODO(eseidel): Early-out here if we're already bound to the right port.
  web_server_.reset();
  scoped_ptr<net::ServerSocket> server_socket(
      new net::TCPServerSocket(NULL, net::NetLog::Source()));
  server_socket->ListenWithAddressAndPort("0.0.0.0", port, 1);
  web_server_.reset(new net::HttpServer(server_socket.Pass(), this));
  callback.Run();
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
