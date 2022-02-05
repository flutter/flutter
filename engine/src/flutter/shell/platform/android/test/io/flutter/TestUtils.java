// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import static org.junit.Assert.assertTrue;

import android.content.res.Configuration;
import android.os.Build;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.Locale;

public class TestUtils {

  public static void setApiVersion(int apiVersion) {
    try {
      Field field = Build.VERSION.class.getField("SDK_INT");

      field.setAccessible(true);
      Field modifiersField = Field.class.getDeclaredField("modifiers");
      modifiersField.setAccessible(true);
      modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);

      field.set(null, apiVersion);
    } catch (Exception e) {
      assertTrue(false);
    }
  }

  public static void setLegacyLocale(Configuration config, Locale locale) {
    try {
      Field field = config.getClass().getField("locale");
      field.setAccessible(true);
      Field modifiersField = Field.class.getDeclaredField("modifiers");
      modifiersField.setAccessible(true);
      modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);

      field.set(config, locale);
    } catch (Exception e) {
      assertTrue(false);
    }
  }
}
