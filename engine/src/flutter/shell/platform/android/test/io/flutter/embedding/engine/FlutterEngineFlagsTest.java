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

public class FlutterEngineFlagsTest {

  @Test
  public void allFlags_containsAllFlags() {
    // Count the number of declared flags in FlutterEngineFlags.
    int declaredFlagsCount = 0;
    for (Field field : FlutterEngineFlags.class.getDeclaredFields()) {
      if (FlutterEngineFlags.Flag.class.isAssignableFrom(field.getType())
          && Modifier.isStatic(field.getModifiers())
          && Modifier.isFinal(field.getModifiers())) {
        declaredFlagsCount++;
      }
    }

    // Check that the number of declared flags matches the size of ALL_FLAGS.
    assertEquals(
        "If you are adding a new Flag to FlutterEngineFlags, please make sure it is added to ALL_FLAGS as well. Otherwise, the flag will be silently ignored when specified.",
        declaredFlagsCount,
        FlutterEngineFlags.ALL_FLAGS.size());
  }

  // Annotation required because support for setting engine shell arguments via Intent will be
  // removed; see https://github.com/flutter/flutter/issues/180686.
  @SuppressWarnings("deprecation")
  @Test
  public void allFlags_haveExpectedMetaDataNamePrefix() {
    String defaultPrefix = "io.flutter.embedding.android.";
    for (FlutterEngineFlags.Flag flag : FlutterEngineFlags.ALL_FLAGS) {
      // Test all non-deprecated flags that should have the default prefix.
      if (!flag.equals(FlutterEngineFlags.DEPRECATED_AOT_SHARED_LIBRARY_NAME)
          && !flag.equals(FlutterEngineFlags.DEPRECATED_FLUTTER_ASSETS_DIR)) {
        assertTrue(
            "Flag " + flag.engineArgument + " does not have the correct metadata key prefix.",
            flag.metadataKey.startsWith(defaultPrefix));
      }
    }
  }

  @Test
  public void getFlagByEngineArgument_returnsExpectedFlagWhenValidArgumentSpecified() {
    FlutterEngineFlags.Flag flag =
        FlutterEngineFlags.getFlagByEngineArgument("--flutter-assets-dir=");
    assertEquals(FlutterEngineFlags.FLUTTER_ASSETS_DIR, flag);
  }

  @Test
  public void getFlagByEngineArgument_returnsNullWhenInvalidArgumentSpecified() {
    assertNull(FlutterEngineFlags.getFlagFromIntentKey("--non-existent-flag"));
  }

  @Test
  public void getFlagFromIntentKey_returnsExpectedFlagWhenValidKeySpecified() {
    // Test flag without value.
    FlutterEngineFlags.Flag flag = FlutterEngineFlags.getFlagFromIntentKey("old-gen-heap-size");
    assertEquals(FlutterEngineFlags.OLD_GEN_HEAP_SIZE, flag);

    // Test with flag.
    flag = FlutterEngineFlags.getFlagFromIntentKey("vm-snapshot-data");
    assertEquals(FlutterEngineFlags.VM_SNAPSHOT_DATA, flag);
  }

  @Test
  public void getFlagFromIntentKey_returnsNullWhenInvalidKeySpecified() {
    assertNull(FlutterEngineFlags.getFlagFromIntentKey("non-existent-flag"));
  }

  @Test
  public void isDisabled_returnsTrueWhenFlagIsDisabled() {
    assertTrue(FlutterEngineFlags.isDisabled(FlutterEngineFlags.DISABLE_MERGED_PLATFORM_UI_THREAD));
  }

  @Test
  public void isDisabled_returnsFalseWhenFlagIsNotDisabled() {
    assertFalse(FlutterEngineFlags.isDisabled(FlutterEngineFlags.VM_SNAPSHOT_DATA));
  }

  // Deprecated flags are tested in this test.
  @SuppressWarnings("deprecation")
  @Test
  public void getReplacementFlagIfDeprecated_returnsExpectedFlag() {
    assertEquals(
        FlutterEngineFlags.AOT_SHARED_LIBRARY_NAME,
        FlutterEngineFlags.getReplacementFlagIfDeprecated(
            FlutterEngineFlags.DEPRECATED_AOT_SHARED_LIBRARY_NAME));
    assertEquals(
        FlutterEngineFlags.FLUTTER_ASSETS_DIR,
        FlutterEngineFlags.getReplacementFlagIfDeprecated(
            FlutterEngineFlags.DEPRECATED_FLUTTER_ASSETS_DIR));
  }

  @Test
  public void getReplacementFlagIfDeprecated_returnsNullWhenFlagIsNotDeprecated() {
    assertNull(
        FlutterEngineFlags.getReplacementFlagIfDeprecated(FlutterEngineFlags.VM_SNAPSHOT_DATA));
  }
}
