// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.application;

import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.mojo.Application;
import org.chromium.mojom.mojo.ServiceProvider;
import org.chromium.mojom.mojo.Shell;

import java.util.ArrayList;

/**
 * Utility class for communicating with the Shell, and provide Services to clients.
 */
class ApplicationImpl implements Application {
    private final ApplicationDelegate mApplicationDelegate;
    private final ArrayList<ApplicationConnection> mIncomingConnections =
            new ArrayList<ApplicationConnection>();
    private final Core mCore;
    private Shell mShell;

    public ApplicationImpl(
            ApplicationDelegate delegate, Core core, MessagePipeHandle applicationRequest) {
        mApplicationDelegate = delegate;
        mCore = core;
        ApplicationImpl.MANAGER.bind(this, applicationRequest);
    }

    @Override
    public void initialize(Shell shell, String[] args, String url) {
        mShell = shell;
        mApplicationDelegate.initialize(shell, args, url);
    }

    @Override
    public void acceptConnection(String requestorUrl, InterfaceRequest<ServiceProvider> services,
            ServiceProvider exposedServices, String connectionUrl) {
        ApplicationConnection connection =
                new ApplicationConnection(requestorUrl, exposedServices, connectionUrl);
        if (services != null && mApplicationDelegate.configureIncomingConnection(connection)) {
            ServiceProvider.MANAGER.bind(connection.getLocalServiceProvider(), services);
            mIncomingConnections.add(connection);
        } else {
            connection.close();
        }
    }

    @Override
    public void requestQuit() {
        mApplicationDelegate.quit();
        for (ApplicationConnection connection : mIncomingConnections) {
            connection.close();
        }
        mCore.getCurrentRunLoop().quit();
    }

    @Override
    public void close() {
        if (mShell != null) {
            mShell.close();
        }
    }

    @Override
    public void onConnectionError(MojoException e) {}
}
