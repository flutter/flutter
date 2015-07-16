// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"

namespace mojo {

class NetworkServiceImpl : public NetworkService {
 public:
  explicit NetworkServiceImpl(InterfaceRequest<NetworkService> request);
  ~NetworkServiceImpl() override;

  void CreateURLLoader(InterfaceRequest<URLLoader> loader) override;
  void GetCookieStore(InterfaceRequest<CookieStore> cookie_store) override;
  void CreateWebSocket(InterfaceRequest<WebSocket> socket) override;
  void CreateTCPBoundSocket(
      NetAddressPtr local_address,
      InterfaceRequest<TCPBoundSocket> bound_socket,
      const CreateTCPBoundSocketCallback& callback) override;
  void CreateTCPConnectedSocket(
      NetAddressPtr remote_address,
      ScopedDataPipeConsumerHandle send_stream,
      ScopedDataPipeProducerHandle receive_stream,
      InterfaceRequest<TCPConnectedSocket> client_socket,
      const CreateTCPConnectedSocketCallback& callback) override;
  void CreateUDPSocket(InterfaceRequest<UDPSocket> socket) override;
  void CreateHttpServer(NetAddressPtr local_address,
                        HttpServerDelegatePtr delegate,
                        const CreateHttpServerCallback& callback) override;
  void RegisterURLLoaderInterceptor(
                        URLLoaderInterceptorFactoryPtr factory) override;
  void CreateHostResolver(InterfaceRequest<HostResolver> host_resolver) override;

 private:
  StrongBinding<NetworkService> binding_;
};

class NetworkServiceFactory : public InterfaceFactory<NetworkService> {
 public:
  void Create(ApplicationConnection* connection,
              InterfaceRequest<NetworkService> request) override;
};

}  // namespace mojo
