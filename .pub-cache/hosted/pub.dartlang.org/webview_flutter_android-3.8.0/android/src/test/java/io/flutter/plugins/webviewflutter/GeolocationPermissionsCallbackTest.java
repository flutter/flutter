// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;

import android.webkit.GeolocationPermissions;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.GeolocationPermissionsCallbackFlutterApi;
import java.util.Objects;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;

public class GeolocationPermissionsCallbackTest {
  @Rule public MockitoRule mockitoRule = MockitoJUnit.rule();

  @Mock public GeolocationPermissions.Callback mockGeolocationPermissionsCallback;

  @Mock public BinaryMessenger mockBinaryMessenger;

  @Mock public GeolocationPermissionsCallbackFlutterApi mockFlutterApi;

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
  public void invoke() {
    final String origin = "testString";
    final boolean allow = true;
    final boolean retain = true;

    final long instanceIdentifier = 0;
    instanceManager.addDartCreatedInstance(mockGeolocationPermissionsCallback, instanceIdentifier);

    final GeolocationPermissionsCallbackHostApiImpl hostApi =
        new GeolocationPermissionsCallbackHostApiImpl(mockBinaryMessenger, instanceManager);

    hostApi.invoke(instanceIdentifier, origin, allow, retain);

    verify(mockGeolocationPermissionsCallback).invoke(origin, allow, retain);
  }

  @Test
  public void flutterApiCreate() {
    final GeolocationPermissionsCallbackFlutterApiImpl flutterApi =
        new GeolocationPermissionsCallbackFlutterApiImpl(mockBinaryMessenger, instanceManager);
    flutterApi.setApi(mockFlutterApi);

    flutterApi.create(mockGeolocationPermissionsCallback, reply -> {});

    final long instanceIdentifier =
        Objects.requireNonNull(
            instanceManager.getIdentifierForStrongReference(mockGeolocationPermissionsCallback));
    verify(mockFlutterApi).create(eq(instanceIdentifier), any());
  }
}
