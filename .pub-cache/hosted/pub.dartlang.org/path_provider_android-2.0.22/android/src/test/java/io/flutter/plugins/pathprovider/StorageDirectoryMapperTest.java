// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.pathprovider;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.fail;

import android.os.Environment;
import org.junit.Test;

public class StorageDirectoryMapperTest {
  @org.junit.Test
  public void testAndroidType_null() {
    assertNull(StorageDirectoryMapper.androidType(null));
  }

  @org.junit.Test
  public void testAndroidType_valid() {
    assertEquals(Environment.DIRECTORY_MUSIC, StorageDirectoryMapper.androidType(0));
    assertEquals(Environment.DIRECTORY_PODCASTS, StorageDirectoryMapper.androidType(1));
    assertEquals(Environment.DIRECTORY_RINGTONES, StorageDirectoryMapper.androidType(2));
    assertEquals(Environment.DIRECTORY_ALARMS, StorageDirectoryMapper.androidType(3));
    assertEquals(Environment.DIRECTORY_NOTIFICATIONS, StorageDirectoryMapper.androidType(4));
    assertEquals(Environment.DIRECTORY_PICTURES, StorageDirectoryMapper.androidType(5));
    assertEquals(Environment.DIRECTORY_MOVIES, StorageDirectoryMapper.androidType(6));
    assertEquals(Environment.DIRECTORY_DOWNLOADS, StorageDirectoryMapper.androidType(7));
    assertEquals(Environment.DIRECTORY_DCIM, StorageDirectoryMapper.androidType(8));
  }

  @Test
  public void testAndroidType_invalid() {
    try {
      assertEquals(Environment.DIRECTORY_DCIM, StorageDirectoryMapper.androidType(10));
      fail();
    } catch (IllegalArgumentException e) {
      assertEquals("Unknown index: " + 10, e.getMessage());
    }
  }
}
