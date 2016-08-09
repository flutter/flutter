// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.oknet;

import android.content.Context;
import android.util.Log;

import com.squareup.okhttp.Cache;
import com.squareup.okhttp.OkHttpClient;

import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.mojo.CookieStore;
import org.chromium.mojom.mojo.HostResolver;
import org.chromium.mojom.mojo.HttpServerDelegate;
import org.chromium.mojom.mojo.NetAddress;
import org.chromium.mojom.mojo.NetworkService;
import org.chromium.mojom.mojo.TcpBoundSocket;
import org.chromium.mojom.mojo.TcpConnectedSocket;
import org.chromium.mojom.mojo.UdpSocket;
import org.chromium.mojom.mojo.UrlLoader;
import org.chromium.mojom.mojo.UrlLoaderInterceptorFactory;
import org.chromium.mojom.mojo.WebSocket;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * OkHttp implementation of NetworkService.
 */
public class NetworkServiceImpl implements NetworkService {
    private static final String TAG = "NetworkServiceImpl";
    private static ExecutorService sThreadPool;
    private static OkHttpClient sClient;
    private Core mCore;

    public NetworkServiceImpl(Context context, Core core) {
        assert core != null;
        mCore = core;

        if (sThreadPool == null) {
            sThreadPool = Executors.newCachedThreadPool();
        }

        if (sClient == null) {
            sClient = new OkHttpClient();

            try {
                int cacheSize = 10 * 1024 * 1024; // 10 MiB
                File cacheDirectory = new File(context.getCacheDir(), "ok_http_cache");
                Cache cache = new Cache(cacheDirectory, cacheSize);
                sClient.setCache(cache);
            } catch (IOException e) {
                Log.e(TAG, "Unable to create HTTP cache", e);
            }
        }
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void createUrlLoader(InterfaceRequest<UrlLoader> loader) {
        UrlLoader.MANAGER.bind(new UrlLoaderImpl(mCore, sClient, sThreadPool), loader);
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

    @Override
    public void createHttpServer(NetAddress localAddress, HttpServerDelegate delegate,
            CreateHttpServerResponse callback) {
        delegate.close();
    }

    @Override
    public void registerUrlLoaderInterceptor(UrlLoaderInterceptorFactory factory) {
        factory.close();
    }

    @Override
    public void createHostResolver(InterfaceRequest<HostResolver> resolver) {
        resolver.close();
    }
}
