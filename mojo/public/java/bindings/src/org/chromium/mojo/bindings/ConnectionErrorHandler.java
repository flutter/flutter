// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.MojoException;

/**
 * A {@link ConnectionErrorHandler} is notified of an error happening while using the bindings over
 * message pipes.
 */
public interface ConnectionErrorHandler {
    public void onConnectionError(MojoException e);
}
