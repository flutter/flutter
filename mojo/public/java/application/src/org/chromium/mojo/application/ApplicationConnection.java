// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.application;

import org.chromium.mojo.bindings.Interface;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.mojo.ServiceProvider;

import java.io.Closeable;
import java.util.HashMap;
import java.util.Map;

/**
 * Represents a connection to another application.
 */
public class ApplicationConnection implements Closeable {
    private final String mConnectionUrl;
    private final ServiceProvider mExposedServices;
    private final String mRequestorUrl;
    private final ServiceProviderImpl mServiceProviderImpl;

    /**
     * @param requestorUrl URL of the application requesting this connection.
     * @param exposedServices ServiceProvider for services exposed by the remote application.
     */
    public ApplicationConnection(
            String requestorUrl, ServiceProvider exposedServices, String connectionUrl) {
        mRequestorUrl = requestorUrl;
        mExposedServices = exposedServices;
        mConnectionUrl = connectionUrl;
        mServiceProviderImpl = new ServiceProviderImpl();
    }

    /**
     * @return URL of the application requesting this connection.
     */
    public String getRequestorUrl() {
        return mRequestorUrl;
    }

    /**
     * @return URL that was used by the source application to establish this connection.
     */
    public String connectionUrl() {
        return mConnectionUrl;
    }

    /**
     * @return ServiceProvider for services exposed by the remote application.
     */
    public ServiceProvider getRemoteServiceProvider() {
        return mExposedServices;
    }

    /**
     * Add a new service for this application.
     *
     * @param binder Handle to a ServiceFactoryBinder which contains a service implementation.
     */
    public void addService(ServiceFactoryBinder<? extends Interface> binder) {
        mServiceProviderImpl.addService(binder);
    }

    /**
     * @return ServiceProvider for this application.
     */
    public ServiceProvider getLocalServiceProvider() {
        return mServiceProviderImpl;
    }

    @Override
    public void close() {
        mServiceProviderImpl.close();
        if (mExposedServices != null) {
            mExposedServices.close();
        }
    }
}

class ServiceProviderImpl implements ServiceProvider {
    private final Map<String, ServiceFactoryBinder<? extends Interface>> mNameToServiceMap =
            new HashMap<String, ServiceFactoryBinder<? extends Interface>>();

    ServiceProviderImpl() {}

    public void addService(ServiceFactoryBinder<? extends Interface> binder) {
        mNameToServiceMap.put(binder.getInterfaceName(), binder);
    }

    @SuppressWarnings("unchecked")
    @Override
    public void connectToService(String interfaceName, MessagePipeHandle pipe) {
        if (mNameToServiceMap.containsKey(interfaceName)) {
            mNameToServiceMap.get(interfaceName)
                    .bind(InterfaceRequest.asInterfaceRequestUnsafe(pipe));
        } else {
            pipe.close();
        }
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}
}
