// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.application;

import org.chromium.mojo.bindings.Interface;
import org.chromium.mojo.bindings.InterfaceRequest;

/**
 * ServiceFactoryBinder holds the necessary information to bind a service interface to a message
 * pipe.
 *
 * @param <T> A mojo service interface.
 */
public interface ServiceFactoryBinder<T extends Interface> {
    /**
     * Binds an instance of the interface to the given request.
     *
     * @param request The request to bind to.
     */
    public void bind(InterfaceRequest<T> request);

    /**
     * Returns the name of the service interface being implemented.
     */
    public String getInterfaceName();
}
