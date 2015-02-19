// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.oknet;

import com.squareup.okhttp.OkHttpClient;

import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.mojo.CookieStore;
import org.chromium.mojom.mojo.NetAddress;
import org.chromium.mojom.mojo.NetworkService;
import org.chromium.mojom.mojo.TcpBoundSocket;
import org.chromium.mojom.mojo.TcpConnectedSocket;
import org.chromium.mojom.mojo.UdpSocket;
import org.chromium.mojom.mojo.UrlLoader;
import org.chromium.mojom.mojo.WebSocket;

/**
 * OkHttp implementation of NetworkService.
 */
public class NetworkServiceImpl implements NetworkService {
    private OkHttpClient mClient;
    private Core mCore;

    public NetworkServiceImpl(Core core) {
        assert core != null;
        mCore = core;
        mClient = new OkHttpClient();
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void createUrlLoader(InterfaceRequest<UrlLoader> loader) {
        UrlLoader.MANAGER.bind(new UrlLoaderImpl(mCore, mClient), loader);
    }

    @Override
    public void getCookieStore(InterfaceRequest<CookieStore> cookieStore) {
        cookieStore.close();
    }

    @Override
    public void createWebSocket(InterfaceRequest<WebSocket> socket) {
        socket.close();
    }

    @Override
    public void createTcpBoundSocket(NetAddress localAddress,
            InterfaceRequest<TcpBoundSocket> boundSocket, CreateTcpBoundSocketResponse callback) {
        boundSocket.close();
    }

    @Override
    public void createTcpConnectedSocket(NetAddress remoteAddress,
            DataPipe.ConsumerHandle sendStream, DataPipe.ProducerHandle receiveStream,
            InterfaceRequest<TcpConnectedSocket> clientSocket,
            CreateTcpConnectedSocketResponse callback) {
        sendStream.close();
        receiveStream.close();
        clientSocket.close();
    }

    @Override
    public void createUdpSocket(InterfaceRequest<UdpSocket> socket) {
        socket.close();
    }
}
