// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter.utils;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import org.junit.Assert;

public class TestUtils {
  public static <T> void setFinalStatic(Class<T> classToModify, String fieldName, Object newValue) {
    try {
      Field field = classToModify.getField(fieldName);
      field.setAccessible(true);

      Field modifiersField = Field.class.getDeclaredField("modifiers");
      modifiersField.setAccessible(true);
      modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);

      field.set(null, newValue);
    } catch (Exception e) {
      Assert.fail("Unable to mock static field: " + fieldName);
    }
  }
}
