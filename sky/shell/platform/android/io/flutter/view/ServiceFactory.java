// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.content.Context;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;

/**
 * An interface for creating services. Instances of this interface can be
 * registered with ServiceRegistry and thereby made available to non-Java
 * clients.
 **/
interface ServiceFactory {
    void connectToService(Context context, Core core, MessagePipeHandle pipe);
}
