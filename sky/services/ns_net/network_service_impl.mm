// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/ns_net/network_service_impl.h"
#include "sky/services/ns_net/url_loader_impl.h"
#include "base/logging.h"

namespace mojo {

NetworkServiceImpl::NetworkServiceImpl(InterfaceRequest<NetworkService> request)
    : binding_(this, request.Pass()) {}

NetworkServiceImpl::~NetworkServiceImpl() {}

void NetworkServiceImpl::CreateURLLoader(InterfaceRequest<URLLoader> loader) {
  new URLLoaderImpl(loader.Pass());
}

void NetworkServiceImpl::GetCookieStore(
    InterfaceRequest<CookieStore> cookie_store) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateWebSocket(InterfaceRequest<WebSocket> socket) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateTCPBoundSocket(
    NetAddressPtr local_address,
    InterfaceRequest<TCPBoundSocket> bound_socket,
    const CreateTCPBoundSocketCallback& callback) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateTCPConnectedSocket(
    NetAddressPtr remote_address,
    ScopedDataPipeConsumerHandle send_stream,
    ScopedDataPipeProducerHandle receive_stream,
    InterfaceRequest<TCPConnectedSocket> client_socket,
    const CreateTCPConnectedSocketCallback& callback) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateUDPSocket(InterfaceRequest<UDPSocket> socket) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateHttpServer(
    NetAddressPtr local_address,
    InterfaceHandle<HttpServerDelegate> delegate,
    const CreateHttpServerCallback& callback) {
  DCHECK(false);
}

void NetworkServiceImpl::RegisterURLLoaderInterceptor(
    InterfaceHandle<URLLoaderInterceptorFactory> factory) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateHostResolver(
    InterfaceRequest<HostResolver> host_resolver) {
  DCHECK(false);
}

}  // namespace mojo
