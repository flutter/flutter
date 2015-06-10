// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "network_service_impl.h"
#include "url_loader_impl.h"
#include "base/logging.h"
#include <Foundation/Foundation.h>

namespace mojo {

void NetworkServiceImpl::CreateURLLoader(
    InterfaceRequest<URLLoader> loader) {
  new URLLoaderImpl(loader.Pass());
}

void NetworkServiceImpl::GetCookieStore(
    InterfaceRequest<CookieStore> cookie_store) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateWebSocket(
    InterfaceRequest<WebSocket> socket) {
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

void NetworkServiceImpl::CreateUDPSocket(
    InterfaceRequest<UDPSocket> socket) {
  DCHECK(false);
}

void NetworkServiceImpl::CreateHttpServer(
    NetAddressPtr local_address,
    HttpServerDelegatePtr delegate,
    const CreateHttpServerCallback& callback) {
  DCHECK(false);
}

void NetworkServiceImpl::RegisterURLLoaderInterceptor(
                        URLLoaderInterceptorFactoryPtr factory) {
  DCHECK(false);
}

void NetworkServiceFactory::Create(ApplicationConnection* connection,
                                   InterfaceRequest<NetworkService> request) {
  new NetworkServiceImpl(request.Pass());
}

}  // namespace mojo
