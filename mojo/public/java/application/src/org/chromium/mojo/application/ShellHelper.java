// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.application;

import org.chromium.mojo.bindings.Interface;
import org.chromium.mojo.bindings.Interface.Proxy;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.Pair;
import org.chromium.mojom.mojo.ServiceProvider;
import org.chromium.mojom.mojo.Shell;

/**
 * Helper class to help connecting to other application through the shell.
 */
public class ShellHelper {
    /**
     * Connects to a service in another application.
     *
     * @param core Implementation of the {@link Core} api.
     * @param shell Instance of the shell.
     * @param application URL to the application to use.
     * @param manager {@link org.chromium.mojo.bindings.Interface.Manager} for the service to
     *            connect to.
     * @return a proxy to the service.
     */
    public static <I extends Interface, P extends Proxy> P connectToService(
            Core core, Shell shell, String application, Interface.Manager<I, P> manager) {
        Pair<ServiceProvider.Proxy, InterfaceRequest<ServiceProvider>> providerRequest =
                ServiceProvider.MANAGER.getInterfaceRequest(core);
        try (ServiceProvider.Proxy provider = providerRequest.first) {
            shell.connectToApplication(application, providerRequest.second, null);
            Pair<P, InterfaceRequest<I>> serviceRequest = manager.getInterfaceRequest(core);
            provider.connectToService(manager.getName(), serviceRequest.second.passHandle());
            return serviceRequest.first;
        }
    }
}
