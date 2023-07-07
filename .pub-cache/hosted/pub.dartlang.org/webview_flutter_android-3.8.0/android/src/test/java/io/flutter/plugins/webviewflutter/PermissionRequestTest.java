// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;

import android.webkit.PermissionRequest;
import io.flutter.plugin.common.BinaryMessenger;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class PermissionRequestTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public PermissionRequest mockPermissionRequest;

  @Mock public BinaryMessenger mockBinaryMessenger;

  @Mock
  public io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.PermissionRequestFlutterApi
      mockFlutterApi;

  InstanceManager instanceManager;

  @Before
  public void setUp() {
    instanceManager = InstanceManager.create(identifier -> {});
  }

  @After
  public void tearDown() {
    instanceManager.stopFinalizationListener();
  }

  // These values MUST equal the constants for the Dart PermissionRequest class.
  @Test
  public void enums() {
    assertEquals(PermissionRequest.RESOURCE_AUDIO_CAPTURE, "android.webkit.resource.AUDIO_CAPTURE");
    assertEquals(PermissionRequest.RESOURCE_VIDEO_CAPTURE, "android.webkit.resource.VIDEO_CAPTURE");
    assertEquals(PermissionRequest.RESOURCE_MIDI_SYSEX, "android.webkit.resource.MIDI_SYSEX");
    assertEquals(
        PermissionRequest.RESOURCE_PROTECTED_MEDIA_ID,
        "android.webkit.resource.PROTECTED_MEDIA_ID");
  }

  @Test
  public void grant() {
    final List<String> resources =
        Collections.singletonList(PermissionRequest.RESOURCE_AUDIO_CAPTURE);

    final long instanceIdentifier = 0;
    instanceManager.addDartCreatedInstance(mockPermissionRequest, instanceIdentifier);

    final PermissionRequestHostApiImpl hostApi =
        new PermissionRequestHostApiImpl(mockBinaryMessenger, instanceManager);

    hostApi.grant(instanceIdentifier, resources);

    verify(mockPermissionRequest).grant(new String[] {PermissionRequest.RESOURCE_AUDIO_CAPTURE});
  }

  @Test
  public void deny() {
    final long instanceIdentifier = 0;
    instanceManager.addDartCreatedInstance(mockPermissionRequest, instanceIdentifier);

    final PermissionRequestHostApiImpl hostApi =
        new PermissionRequestHostApiImpl(mockBinaryMessenger, instanceManager);

    hostApi.deny(instanceIdentifier);

    verify(mockPermissionRequest).deny();
  }

  @Test
  public void flutterApiCreate() {
    final PermissionRequestFlutterApiImpl flutterApi =
        new PermissionRequestFlutterApiImpl(mockBinaryMessenger, instanceManager);
    flutterApi.setApi(mockFlutterApi);

    final List<String> resources =
        Collections.singletonList(PermissionRequest.RESOURCE_AUDIO_CAPTURE);

    flutterApi.create(mockPermissionRequest, resources.toArray(new String[0]), reply -> {});

    final long instanceIdentifier =
        Objects.requireNonNull(
            instanceManager.getIdentifierForStrongReference(mockPermissionRequest));
    verify(mockFlutterApi).create(eq(instanceIdentifier), eq(resources), any());
  }
}
