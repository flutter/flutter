// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.application;

import org.chromium.mojom.mojo.Shell;

/**
 * Applications should implement this interface to control various behaviors of Mojo application
 * interface.
 */
public interface ApplicationDelegate {
    /**
     * Called exactly once before any other method.
     *
     * @param shell A handle to the shell interface.
     * @param args Arguments used for this application.
     * @param url URL of this application.
     */
    public void initialize(Shell shell, String[] args, String url);

    /**
     * This method is used to configure what services a connection supports when being connected to.
     * Return false to reject the connection entirely.
     *
     * @param connection A handle to the connection.
     * @return If this application accepts any incoming connection.
     */
    public boolean configureIncomingConnection(ApplicationConnection connection);

    /**
     * Called before exiting. After returning from this call, the delegate cannot expect RunLoop to
     * still be running.
     */
    public void quit();
}
