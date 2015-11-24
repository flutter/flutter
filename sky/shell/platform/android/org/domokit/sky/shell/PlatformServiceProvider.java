// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.mojo.ServiceProvider;

/**
 * A collection of services implemented in Java.
 **/
public class PlatformServiceProvider implements ServiceProvider {
    private Core mCore;
    private Context mContext;
    private ServiceRegistry mLocalRegistry;

    public PlatformServiceProvider(Core core, Context context, ServiceRegistry localRegistry) {
        assert core != null;
        assert context != null;
        mCore = core;
        mContext = context;
        mLocalRegistry = localRegistry;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void connectToService(String interfaceName, MessagePipeHandle pipe) {
        ServiceFactory factory = mLocalRegistry.get(interfaceName);
        if (factory == null) {
            factory = ServiceRegistry.SHARED.get(interfaceName);
        }
        if (factory == null) {
            pipe.close();
            return;
        }
        factory.connectToService(mContext, mCore, pipe);
    }
}
