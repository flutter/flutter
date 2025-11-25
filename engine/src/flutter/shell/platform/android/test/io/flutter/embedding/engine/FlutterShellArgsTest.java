// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import org.junit.Test;

public class FlutterShellArgsTest {

  @Test
  public void allFlags_containsAllFlags() {
    // Count the number of declared flags in FlutterShellArgs.
    int declaredFlagsCount = 0;
    for (Field field : FlutterShellArgs.class.getDeclaredFields()) {
      if (FlutterShellArgs.Flag.class.isAssignableFrom(field.getType())
          && Modifier.isStatic(field.getModifiers())
          && Modifier.isFinal(field.getModifiers())) {
        declaredFlagsCount++;
      }
    }

    // Check that the number of declared flags matches the size of ALL_FLAGS.
    assertEquals(
        "If you are adding a new Flag to FlutterShellArgs, please make sure it is added to ALL_FLAGS as well. Otherwise, the flag will be silently ignored when specified.",
        declaredFlagsCount,
        FlutterShellArgs.ALL_FLAGS.size());
  }

  @Test
  public void getFlagByMetadataKey_returnsExpectedFlagWhenValidKeySpecified() {
    FlutterShellArgs.Flag flag =
        FlutterShellArgs.getFlagByMetadataKey(
            "io.flutter.embedding.android.EnableSoftwareRendering");
    assertNotNull(flag);
    assertEquals("--enable-software-rendering", flag.commandLineArgument);
  }

  @Test
  public void getFlagFromIntentKey_returnsExpectedFlagWhenValidKeySpecified() {
    // Test flag without value.
    FlutterShellArgs.Flag flag = FlutterShellArgs.getFlagFromIntentKey("enable-software-rendering");
    assertNotNull(flag);
    assertEquals("--enable-software-rendering", flag.commandLineArgument);

    // Test with flag.
    flag = FlutterShellArgs.getFlagFromIntentKey("vm-service-port");
    assertNotNull(flag);
    assertEquals("--vm-service-port=", flag.commandLineArgument);
  }

  @Test
  public void getFlagFromIntentKey_returnsNullWhenInvalidKeySpecified() {
    assertNull(FlutterShellArgs.getFlagFromIntentKey("non-existent-flag"));
  }

  @Test
  public void getFlagByMetadataKey_returnsNullWhenInvalidKeySpecified() {
    FlutterShellArgs.Flag flag =
        FlutterShellArgs.getFlagByMetadataKey("io.flutter.embedding.android.InvalidMetaDataKey");
    assertNull("Should return null for an invalid meta-data key", flag);
  }

  @Test
  public void isDeprecated_returnsTrueWhenFlagIsDeprecated() {
    assertTrue(FlutterShellArgs.isDeprecated(FlutterShellArgs.DISABLE_MERGED_PLATFORM_UI_THREAD));
  }

  @Test
  public void isDeprecated_returnsFalseWhenFlagIsNotDeprecated() {
    assertFalse(FlutterShellArgs.isDeprecated(FlutterShellArgs.VM_SNAPSHOT_DATA));
  }
}
