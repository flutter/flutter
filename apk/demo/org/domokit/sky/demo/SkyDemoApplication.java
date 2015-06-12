// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.demo;

import android.content.Context;

import org.chromium.mojo.keyboard.KeyboardServiceImpl;
import org.chromium.mojo.sensors.SensorServiceImpl;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.intents.ActivityManager;
import org.chromium.mojom.keyboard.KeyboardService;
import org.chromium.mojom.sensors.SensorService;
import org.domokit.intents.ActivityManagerImpl;
import org.domokit.sky.shell.ServiceFactory;
import org.domokit.sky.shell.ServiceRegistry;
import org.domokit.sky.shell.SkyApplication;

/**
 * SkyDemo implementation of {@link android.app.Application}
 */
public class SkyDemoApplication extends SkyApplication {
    @Override
    public void onCreate() {
        super.onCreate();

        ServiceRegistry.SHARED.register(SensorService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                SensorService.MANAGER.bind(new SensorServiceImpl(context), pipe);
            }
        });

        ServiceRegistry.SHARED.register(KeyboardService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                KeyboardService.MANAGER.bind(new KeyboardServiceImpl(context), pipe);
            }
        });

        ServiceRegistry.SHARED.register(ActivityManager.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                ActivityManager.MANAGER.bind(new ActivityManagerImpl(context), pipe);
            }
        });
    }
}
