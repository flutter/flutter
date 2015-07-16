// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.application;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.RunLoop;

/**
 * A utility for running an Application.
 *
 */
public class ApplicationRunner {
    /**
     * Runs the delegate in a RunLoop.
     *
     * @param delegate Application specific functionality.
     * @param core Core mojo interface.
     * @param applicationRequest Handle for the application request.
     */
    public static void run(
            ApplicationDelegate delegate, Core core, MessagePipeHandle applicationRequest) {
        try (RunLoop runLoop = core.createDefaultRunLoop()) {
            try (ApplicationImpl application =
                            new ApplicationImpl(delegate, core, applicationRequest)) {
                runLoop.run();
            }
        }
    }
}
