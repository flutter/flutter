// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertNull;

import org.junit.Test;

public class JavaObjectHostApiTest {
  @Test
  public void dispose() {
    final InstanceManager instanceManager = InstanceManager.create(identifier -> {});

    final JavaObjectHostApiImpl hostApi = new JavaObjectHostApiImpl(instanceManager);

    Object object = new Object();
    instanceManager.addDartCreatedInstance(object, 0);

    // To free object for garbage collection.
    //noinspection UnusedAssignment
    object = null;

    hostApi.dispose(0L);
    Runtime.getRuntime().gc();

    assertNull(instanceManager.getInstance(0));

    instanceManager.stopFinalizationListener();
  }
}
