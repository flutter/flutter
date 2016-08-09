// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings.test.mojom.mojo;

import org.chromium.mojo.bindings.MessageReceiver;
import org.chromium.mojo.bindings.test.mojom.mojo.IntegrationTestInterface.Method0Response;
import org.chromium.mojo.bindings.test.mojom.mojo.IntegrationTestInterface_Internal.IntegrationTestInterfaceMethod0ResponseParamsForwardToCallback;

/**
 * Helper class to access {@link IntegrationTestInterface_Internal} package protected method for
 * tests.
 */
public class IntegrationTestInterfaceTestHelper {

    private static final class SinkMethod0Response implements Method0Response {
        @Override
        public void call(byte[] arg1) {
        }
    }

    /**
     * Creates a new {@link MessageReceiver} to use for the callback of
     * |IntegrationTestInterface#method0(Method0Response)|.
     */
    public static MessageReceiver newIntegrationTestInterfaceMethodCallback() {
        return new IntegrationTestInterfaceMethod0ResponseParamsForwardToCallback(
                new SinkMethod0Response());
    }
}
