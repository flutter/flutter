// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.content.Context;
import android.util.Log;

import org.chromium.base.BaseChromiumApplication;
import org.chromium.base.PathUtils;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;
import org.chromium.base.library_loader.ProcessInitException;
import org.chromium.mojo.keyboard.KeyboardServiceImpl;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.activity.Activity;
import org.chromium.mojom.keyboard.KeyboardService;
import org.chromium.mojom.mojo.NetworkService;
import org.domokit.activity.ActivityImpl;
import org.domokit.oknet.NetworkServiceImpl;

/**
 * Sky implementation of {@link android.app.Application}, managing application-level global
 * state and initializations.
 */
public class SkyApplication extends BaseChromiumApplication {
    static final String SNAPSHOT = "snapshot_blob.bin";
    static final String APP_BUNDLE = "app.skyx";

    private static final String TAG = "SkyApplication";
    private static final String PRIVATE_DATA_DIRECTORY_SUFFIX = "sky_shell";
    private static final String[] SKY_RESOURCES = {"icudtl.dat", SNAPSHOT, APP_BUNDLE};

    private ResourceExtractor mResourceExtractor;

    public ResourceExtractor getResourceExtractor() {
        return mResourceExtractor;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        initJavaUtils();
        initResources();
        initNative();
        onServiceRegistryAvailable(ServiceRegistry.SHARED);
    }

    /**
      * Override this function to add more resources for extraction.
      */
    protected void onBeforeResourceExtraction(ResourceExtractor extractor) {
        extractor.addResources(SKY_RESOURCES);
    }

    /**
      * Override this function to register more services.
      */
    protected void onServiceRegistryAvailable(ServiceRegistry registry) {
        registry.register(NetworkService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                // TODO(eseidel): Refactor ownership to match other services.
                new NetworkServiceImpl(context, core, pipe);
            }
        });

        registry.register(KeyboardService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                KeyboardService.MANAGER.bind(new KeyboardServiceImpl(context), pipe);
            }
        });

        registry.register(Activity.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                Activity.MANAGER.bind(new ActivityImpl(), pipe);
            }
        });
    }

    private void initJavaUtils() {
        PathUtils.setPrivateDataDirectorySuffix(PRIVATE_DATA_DIRECTORY_SUFFIX,
                                                getApplicationContext());
    }

    private void initResources() {
        Context context = getApplicationContext();
        new ResourceCleaner(context).start();
        mResourceExtractor = new ResourceExtractor(context);
        onBeforeResourceExtraction(mResourceExtractor);
        mResourceExtractor.start();
    }

    private void initNative() {
        try {
            LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER).ensureInitialized();
        } catch (ProcessInitException e) {
            Log.e(TAG, "Unable to load Sky Engine binary.", e);
            throw new RuntimeException(e);
        }
    }
}
