// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
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

  @SuppressWarnings("deprecation")
  @Test
  public void allFlags_haveExpectedMetaDataNamePrefix() {
    String defaultPrefix = "io.flutter.embedding.android.";
    for (FlutterShellArgs.Flag flag : FlutterShellArgs.ALL_FLAGS) {
      // Test all non-deprecated flags that should have the default prefix.
      if (!flag.equals(FlutterShellArgs.DEPRECATED_AOT_SHARED_LIBRARY_NAME)
          && !flag.equals(FlutterShellArgs.DEPRECATED_FLUTTER_ASSETS_DIR)) {
        assertTrue(
            "Flag " + flag.commandLineArgument + " does not have the correct metadata key prefix.",
            flag.metadataKey.startsWith(defaultPrefix));
      }
    }
  }

  @Test
  public void getFlagByMetadataKey_returnsExpectedFlagWhenValidKeySpecified() {
    FlutterShellArgs.Flag flag =
        FlutterShellArgs.getFlagByMetadataKey("io.flutter.embedding.android.AOTSharedLibraryName");
    assertEquals(FlutterShellArgs.AOT_SHARED_LIBRARY_NAME, flag);
  }

  @Test
  public void getFlagByMetadataKey_returnsNullWhenInvalidKeySpecified() {
    FlutterShellArgs.Flag flag =
        FlutterShellArgs.getFlagByMetadataKey("io.flutter.embedding.android.InvalidMetaDataKey");
    assertNull("Should return null for an invalid meta-data key", flag);
  }

  @Test
  public void getFlagByCommandLineArgument_returnsExpectedFlagWhenValidArgumentSpecified() {
    FlutterShellArgs.Flag flag =
        FlutterShellArgs.getFlagByCommandLineArgument("--flutter-assets-dir=");
    assertEquals(FlutterShellArgs.FLUTTER_ASSETS_DIR, flag);
  }

  @Test
  public void getFlagByCommandLineArgument_returnsNullWhenInvalidArgumentSpecified() {
    assertNull(FlutterShellArgs.getFlagFromIntentKey("--non-existent-flag"));
  }

  @Test
  public void getFlagFromIntentKey_returnsExpectedFlagWhenValidKeySpecified() {
    // Test flag without value.
    FlutterShellArgs.Flag flag = FlutterShellArgs.getFlagFromIntentKey("old-gen-heap-size");
    assertEquals(FlutterShellArgs.OLD_GEN_HEAP_SIZE, flag);

    // Test with flag.
    flag = FlutterShellArgs.getFlagFromIntentKey("vm-snapshot-data");
    assertEquals(FlutterShellArgs.VM_SNAPSHOT_DATA, flag);
  }

  @Test
  public void getFlagFromIntentKey_returnsNullWhenInvalidKeySpecified() {
    assertNull(FlutterShellArgs.getFlagFromIntentKey("non-existent-flag"));
  }

  @Test
  public void isDisabled_returnsTrueWhenFlagIsDisabled() {
    assertTrue(FlutterShellArgs.isDisabled(FlutterShellArgs.DISABLE_MERGED_PLATFORM_UI_THREAD));
  }

  @Test
  public void isDisabled_returnsFalseWhenFlagIsNotDisabled() {
    assertFalse(FlutterShellArgs.isDisabled(FlutterShellArgs.VM_SNAPSHOT_DATA));
  }

  // Deprecated flags are tested in this test.
  @SuppressWarnings("deprecation")
  @Test
  public void getReplacementFlagIfDeprecated_returnsExpectedFlag() {
    assertEquals(
        FlutterShellArgs.AOT_SHARED_LIBRARY_NAME,
        FlutterShellArgs.getReplacementFlagIfDeprecated(
            FlutterShellArgs.DEPRECATED_AOT_SHARED_LIBRARY_NAME));
    assertEquals(
        FlutterShellArgs.FLUTTER_ASSETS_DIR,
        FlutterShellArgs.getReplacementFlagIfDeprecated(
            FlutterShellArgs.DEPRECATED_FLUTTER_ASSETS_DIR));
  }

  @Test
  public void getReplacementFlagIfDeprecated_returnsNullWhenFlagIsNotDeprecated() {
    assertNull(FlutterShellArgs.getReplacementFlagIfDeprecated(FlutterShellArgs.VM_SNAPSHOT_DATA));
  }
}
