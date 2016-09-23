// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;
import android.util.Log;
import java.util.HashSet;

import org.chromium.mojo.bindings.ConnectionErrorHandler;
import org.chromium.mojo.bindings.Interface.Binding;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.mojo.ServiceProvider;

/**
 * A collection of services.
 **/
class ServiceProviderImpl implements ServiceProvider {
    private static final String TAG = "ServiceProviderImpl";

    private Core mCore;
    private FlutterView mView;
    private ServiceRegistry mRegistry;
    private HashSet<Binding> mBindings = new HashSet<Binding>();

    ServiceProviderImpl(Core core, FlutterView view, ServiceRegistry registry) {
        assert core != null;
        assert view != null;
        mCore = core;
        mView = view;
        mRegistry = registry;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void connectToService(String interfaceName, MessagePipeHandle pipe) {
        ServiceFactory factory = mRegistry.get(interfaceName);
        if (factory == null) {
            pipe.close();
            return;
        }
        final Binding binding = factory.connectToService(mView, mCore, pipe);
        mBindings.add(binding);
        binding.registerErrorHandler(new ConnectionErrorHandler() {
            @Override
            public void onConnectionError(MojoException e) {
                Log.w(TAG, "Flutter service provider connection error", e);
                mBindings.remove(binding);
            }
        });
    }

    public void unbindServices() {
        for (Binding binding : mBindings) {
            binding.unbind().close();
        }
        mBindings.clear();
    }
}
