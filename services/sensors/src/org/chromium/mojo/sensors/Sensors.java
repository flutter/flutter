// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.sensors;

import android.content.Context;

import org.chromium.mojo.application.ApplicationConnection;
import org.chromium.mojo.application.ApplicationDelegate;
import org.chromium.mojo.application.ApplicationRunner;
import org.chromium.mojo.application.ServiceFactoryBinder;
import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojom.mojo.Shell;
import org.chromium.mojom.sensors.SensorService;

/**
 * Android service application implementing the SensorService interface.
 */
public class Sensors implements ApplicationDelegate {
    private Context mContext;

    public Sensors(Context context) {
        mContext = context;
    }

    /**
      * @see ApplicationDelegate#initialize(Shell, String[], String)
      */
    @Override
    public void initialize(Shell shell, String[] args, String url) {}

    /**
     * @see ApplicationDelegate#configureIncomingConnection(ApplicationConnection)
     */
    @Override
    public boolean configureIncomingConnection(ApplicationConnection connection) {
        connection.addService(new ServiceFactoryBinder<SensorService>() {
            @Override
            public void bind(InterfaceRequest<SensorService> request) {
                SensorService.MANAGER.bind(new SensorServiceImpl(mContext), request);
            }

            @Override
            public String getInterfaceName() {
                return SensorService.MANAGER.getName();
            }
        });
        return true;
    }

    /**
     * @see ApplicationDelegate#quit()
     */
    @Override
    public void quit() {}

    public static void mojoMain(
            Context context, Core core, MessagePipeHandle applicationRequestHandle) {
        ApplicationRunner.run(new Sensors(context), core, applicationRequestHandle);
    }
}
