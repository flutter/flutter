// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.MojoException;

import java.util.Collections;
import java.util.Set;
import java.util.WeakHashMap;

/**
 * A {@link ConnectionErrorHandler} that delegate the errors to a list of registered handlers. This
 * class will use weak pointers to prevent keeping references to any handlers it delegates to.
 */
public class DelegatingConnectionErrorHandler implements ConnectionErrorHandler {

    /**
     * The registered handlers. This uses a {@link WeakHashMap} so that it doesn't prevent the
     * handler from being garbage collected.
     */
    private final Set<ConnectionErrorHandler> mHandlers =
            Collections.newSetFromMap(new WeakHashMap<ConnectionErrorHandler, Boolean>());

    /**
     * @see ConnectionErrorHandler#onConnectionError(MojoException)
     */
    @Override
    public void onConnectionError(MojoException e) {
        for (ConnectionErrorHandler handler : mHandlers) {
            handler.onConnectionError(e);
        }
    }

    /**
     * Add a handler that will be notified of any error this object receives.
     */
    public void addConnectionErrorHandler(ConnectionErrorHandler handler) {
        mHandlers.add(handler);
    }

    /**
     * Remove a previously registered handler.
     */
    public void removeConnectionErrorHandler(ConnectionErrorHandler handler) {
        mHandlers.remove(handler);
    }
}
