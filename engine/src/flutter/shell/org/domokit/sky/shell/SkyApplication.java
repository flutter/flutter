// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.util.Log;

import org.chromium.base.BaseChromiumApplication;
import org.chromium.base.PathUtils;
import org.chromium.base.ResourceExtractor;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.library_loader.ProcessInitException;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.mojo.NetworkService;
import org.domokit.oknet.NetworkServiceImpl;

/**
 * Sky implementation of {@link android.app.Application}, managing application-level global
 * state and initializations.
 */
public class SkyApplication extends BaseChromiumApplication {
    private static final String TAG = "SkyApplication";
    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";
    private static final String[] SKY_MANDATORY_PAKS = {
        "icudtl.dat",
    };

    @Override
    public void onCreate() {
        super.onCreate();
        initializeJavaUtils();
        initializeNative();
        initializeServiceRegistry();
        ResourceExtractor.setMandatoryPaksToExtract(SKY_MANDATORY_PAKS);
    }

    private void initializeJavaUtils() {
        PathUtils.setPrivateDataDirectorySuffix(PRIVATE_DATA_DIRECTORY_SUFFIX, getApplicationContext());
    }

    private void initializeNative() {
        try {
            LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER).ensureInitialized();
        } catch (ProcessInitException e) {
            Log.e(TAG, "sky_shell initialization failed.", e);
            throw new RuntimeException(e);
        }
    }

    private void initializeServiceRegistry() {
        ServiceRegistry.SHARED.register(NetworkService.MANAGER.getName(), new ServiceFactory() {
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                new NetworkServiceImpl(context, core, pipe);
            }
        });
    }
}
