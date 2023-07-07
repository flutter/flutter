// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.webkit.WebChromeClient.FileChooserParams;
import io.flutter.plugin.common.BinaryMessenger;
import java.util.Arrays;
import java.util.Objects;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class FileChooserParamsTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public FileChooserParams mockFileChooserParams;

  @Mock public BinaryMessenger mockBinaryMessenger;

  InstanceManager instanceManager;

  @Before
  public void setUp() {
    instanceManager = InstanceManager.create(identifier -> {});
  }

  @After
  public void tearDown() {
    instanceManager.stopFinalizationListener();
  }

  @Test
  public void flutterApiCreate() {
    final FileChooserParamsFlutterApiImpl spyFlutterApi =
        spy(new FileChooserParamsFlutterApiImpl(mockBinaryMessenger, instanceManager));

    when(mockFileChooserParams.isCaptureEnabled()).thenReturn(true);
    when(mockFileChooserParams.getAcceptTypes()).thenReturn(new String[] {"my", "list"});
    when(mockFileChooserParams.getMode()).thenReturn(FileChooserParams.MODE_OPEN_MULTIPLE);
    when(mockFileChooserParams.getFilenameHint()).thenReturn("filenameHint");
    spyFlutterApi.create(mockFileChooserParams, reply -> {});

    final long identifier =
        Objects.requireNonNull(
            instanceManager.getIdentifierForStrongReference(mockFileChooserParams));
    final ArgumentCaptor<GeneratedAndroidWebView.FileChooserModeEnumData> modeCaptor =
        ArgumentCaptor.forClass(GeneratedAndroidWebView.FileChooserModeEnumData.class);

    verify(spyFlutterApi)
        .create(
            eq(identifier),
            eq(true),
            eq(Arrays.asList("my", "list")),
            modeCaptor.capture(),
            eq("filenameHint"),
            any());
    assertEquals(
        modeCaptor.getValue().getValue(), GeneratedAndroidWebView.FileChooserMode.OPEN_MULTIPLE);
  }
}
