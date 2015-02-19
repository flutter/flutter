// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.Pair;
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.mojo.NetworkService;
import org.chromium.mojom.mojo.ServiceProvider;
import org.domokit.oknet.NetworkServiceImpl;

/**
 * A class to intialize the network.
 **/
@JNINamespace("sky::shell")
public class JavaServiceProvider implements ServiceProvider {
    private Core mCore;

    @SuppressWarnings("unused")
    @CalledByNative
    public static int create() {
        Core core = CoreImpl.getInstance();
        Pair<MessagePipeHandle, MessagePipeHandle> messagePipe = core.createMessagePipe(null);
        ServiceProvider.MANAGER.bind(new JavaServiceProvider(core), messagePipe.first);
        return messagePipe.second.releaseNativeHandle();
    }

    public JavaServiceProvider(Core core) {
        assert core != null;
        mCore = core;
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void connectToService(String interfaceName, MessagePipeHandle pipe) {
        if (interfaceName.equals(NetworkService.MANAGER.getName())) {
            NetworkService.MANAGER.bind(new NetworkServiceImpl(mCore), pipe);
            return;
        }
        pipe.close();
    }
}
