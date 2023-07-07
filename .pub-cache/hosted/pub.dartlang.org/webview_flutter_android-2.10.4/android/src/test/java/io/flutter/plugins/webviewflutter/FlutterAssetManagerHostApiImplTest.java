// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;

public class FlutterAssetManagerHostApiImplTest {
  @Mock FlutterAssetManager mockFlutterAssetManager;

  FlutterAssetManagerHostApiImpl testFlutterAssetManagerHostApiImpl;

  @Before
  public void setUp() {
    mockFlutterAssetManager = mock(FlutterAssetManager.class);

    testFlutterAssetManagerHostApiImpl =
        new FlutterAssetManagerHostApiImpl(mockFlutterAssetManager);
  }

  @Test
  public void list() {
    try {
      when(mockFlutterAssetManager.list("test/path"))
          .thenReturn(new String[] {"index.html", "styles.css"});
      List<String> actualFilePaths = testFlutterAssetManagerHostApiImpl.list("test/path");
      verify(mockFlutterAssetManager).list("test/path");
      assertArrayEquals(new String[] {"index.html", "styles.css"}, actualFilePaths.toArray());
    } catch (IOException ex) {
      fail();
    }
  }

  @Test
  public void list_returns_empty_list_when_no_results() {
    try {
      when(mockFlutterAssetManager.list("test/path")).thenReturn(null);
      List<String> actualFilePaths = testFlutterAssetManagerHostApiImpl.list("test/path");
      verify(mockFlutterAssetManager).list("test/path");
      assertArrayEquals(new String[] {}, actualFilePaths.toArray());
    } catch (IOException ex) {
      fail();
    }
  }

  @Test(expected = RuntimeException.class)
  public void list_should_convert_io_exception_to_runtime_exception() {
    try {
      when(mockFlutterAssetManager.list("test/path")).thenThrow(new IOException());
      testFlutterAssetManagerHostApiImpl.list("test/path");
    } catch (IOException ex) {
      fail();
    }
  }

  @Test
  public void getAssetFilePathByName() {
    when(mockFlutterAssetManager.getAssetFilePathByName("index.html"))
        .thenReturn("flutter_assets/index.html");
    String filePath = testFlutterAssetManagerHostApiImpl.getAssetFilePathByName("index.html");
    verify(mockFlutterAssetManager).getAssetFilePathByName("index.html");
    assertEquals("flutter_assets/index.html", filePath);
  }
}
