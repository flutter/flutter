// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_INSPECTOR_INSPECTOR_FRONTEND_IMPL_H_
#define SKY_SERVICES_INSPECTOR_INSPECTOR_FRONTEND_IMPL_H_

#include "mojo/public/cpp/application/interface_factory_impl.h"
#include "mojo/public/cpp/bindings/interface_impl.h"
#include "net/server/http_server.h"
#include "net/socket/tcp_server_socket.h"
#include "sky/services/inspector/inspector.mojom.h"

namespace sky {
namespace inspector {

class InspectorFronendImpl : public mojo::InterfaceImpl<InspectorFrontend>,
                             public net::HttpServer::Delegate {
 public:
  InspectorFronendImpl();
  virtual ~InspectorFronendImpl();

 private:
  // From net::HttpServer::Delegate
  virtual void OnConnect(int connection_id) override;
  virtual void OnHttpRequest(
      int connection_id, const net::HttpServerRequestInfo& info) override;
  virtual void OnWebSocketRequest(
      int connection_id, const net::HttpServerRequestInfo& info) override;
  virtual void OnWebSocketMessage(
      int connection_id, const std::string& data) override;
  virtual void OnClose(int connection_id) override;

  // From InspectorFronend
  virtual void Listen(int32_t port) override;
  virtual void SendMessage(const mojo::String&) override;

  void StopListening();

  void Register(int port);
  void Unregister();

  int port_;
  int connection_id_;
  scoped_ptr<net::HttpServer> web_server_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(InspectorFronendImpl);
};

typedef mojo::InterfaceFactoryImpl<
    InspectorFronendImpl> InspectorFronendFactory;

}  // namespace tester
}  // namespace sky

#endif  // SKY_SERVICES_INSPECTOR_INSPECTOR_FRONTEND_IMPL_H_
