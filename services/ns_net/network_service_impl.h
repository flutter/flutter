// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_NSNET_NETWORK_SERVICE_IMPL_H_
#define FLUTTER_SERVICES_NSNET_NETWORK_SERVICE_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/network/interfaces/network_service.mojom.h"

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
                        InterfaceHandle<HttpServerDelegate> delegate,
                        const CreateHttpServerCallback& callback) override;
  void RegisterURLLoaderInterceptor(
      InterfaceHandle<URLLoaderInterceptorFactory> factory) override;
  void CreateHostResolver(
      InterfaceRequest<HostResolver> host_resolver) override;

 private:
  StrongBinding<NetworkService> binding_;

  DISALLOW_COPY_AND_ASSIGN(NetworkServiceImpl);
};

}  // namespace mojo

#endif  // FLUTTER_SERVICES_NSNET_NETWORK_SERVICE_IMPL_H_
