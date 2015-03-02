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
import org.chromium.mojo.system.impl.CoreImpl;
import org.chromium.mojom.mojo.ServiceProvider;

/**
 * A collection of services implemented in Java.
 **/
@JNINamespace("sky::shell")
public class JavaServiceProvider implements ServiceProvider {
    private Core mCore;
    private Context mContext;

    @SuppressWarnings("unused")
    @CalledByNative
    public static void create(Context context, int nativeHandle) {
        Core core = CoreImpl.getInstance();
        MessagePipeHandle pipe = core.acquireNativeHandle(nativeHandle).toMessagePipeHandle();
        ServiceProvider.MANAGER.bind(new JavaServiceProvider(core, context), pipe);
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
        ServiceFactory factory = ServiceRegistry.SHARED.get(interfaceName);
        if (factory == null) {
            pipe.close();
            return;
        }
        factory.connectToService(mContext, mCore, pipe);
    }
}
