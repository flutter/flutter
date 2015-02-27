// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.mojo.NetworkService;
import org.chromium.mojom.mojo.ServiceProvider;
import org.chromium.mojom.sensors.SensorService;
import org.domokit.oknet.NetworkServiceImpl;
import org.domokit.sensors.SensorServiceImpl;

/**
 * A class to intialize the network.
 **/
@JNINamespace("sky::shell")
public class JavaServiceProvider implements ServiceProvider {
    private Core mCore;
    private Context mContext;

    @SuppressWarnings("unused")
    @CalledByNative
    public static int create(Context context) {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> messagePipe = core.createMessagePipe(null);
        ServiceProvider.MANAGER.bind(new JavaServiceProvider(core, context), messagePipe.first);
        return messagePipe.second.releaseNativeHandle();
    }

    public JavaServiceProvider(Core core, Context context) {
        assert core != null;
        assert context != null;
        mCore = core;
        mContext = context;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void connectToService(String interfaceName, MessagePipeHandle pipe) {
        if (interfaceName.equals(NetworkService.MANAGER.getName())) {
            new NetworkServiceImpl(mContext, mCore, pipe);
            return;
        } else if (interfaceName.equals(SensorService.MANAGER.getName())) {
            new SensorServiceImpl(mContext, mCore, pipe);
            return;
        }
        pipe.close();
    }
}
