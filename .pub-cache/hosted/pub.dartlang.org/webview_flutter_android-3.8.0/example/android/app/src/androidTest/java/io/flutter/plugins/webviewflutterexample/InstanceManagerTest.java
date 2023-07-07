// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutterexample;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.plugins.webviewflutter.InstanceManager;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class InstanceManagerTest {
  @Test
  public void managerDoesNotTriggerFinalizationListenerWhenStopped() throws InterruptedException {
    final boolean[] callbackTriggered = {false};
    final InstanceManager instanceManager =
        InstanceManager.create(identifier -> callbackTriggered[0] = true);
    instanceManager.stopFinalizationListener();

    Object object = new Object();
    instanceManager.addDartCreatedInstance(object, 0);

    assertEquals(object, instanceManager.remove(0));

    // To allow for object to be garbage collected.
    //noinspection UnusedAssignment
    object = null;

    Runtime.getRuntime().gc();

    // Wait for the interval after finalized callbacks are made for garbage collected objects.
    // See InstanceManager.CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL.
    Thread.sleep(30000);

    assertNull(instanceManager.getInstance(0));
    assertFalse(callbackTriggered[0]);
  }
}
