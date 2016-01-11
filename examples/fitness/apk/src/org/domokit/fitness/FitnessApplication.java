// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.fitness;

import android.content.Context;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.gcm.GcmService;
import org.domokit.gcm.RegistrationIntentService;
import org.domokit.sky.shell.ServiceFactory;
import org.domokit.sky.shell.ServiceRegistry;
import org.domokit.sky.shell.SkyApplication;

/**
 * Sky implementation of {@link android.app.Application}, managing application-level global
 * state and initializations.
 */
public class FitnessApplication extends SkyApplication {
    /**
      * Override this function to register more services.
      */
    protected void onServiceRegistryAvailable(ServiceRegistry registry) {
        super.onServiceRegistryAvailable(registry);

        registry.register(GcmService.MANAGER.getName(), new ServiceFactory() {
            @Override
            public void connectToService(Context context, Core core, MessagePipeHandle pipe) {
                GcmService.MANAGER.bind(
                    new RegistrationIntentService.MojoService(context), pipe);
            }
        });
    }
}
