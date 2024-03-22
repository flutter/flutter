// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.plugins.integration_test;

import org.junit.Test;

import static org.junit.Assert.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import org.junit.runner.RunWith;

import android.app.Activity;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterView;

@RunWith(AndroidJUnit4.class)
public class FlutterDeviceScreenshotTest {
    @Test
    public void getFlutterView_returnsNullForNonFlutterActivity() {
        Activity mockActivity = mock(Activity.class);
        assertNull(FlutterDeviceScreenshot.getFlutterView(mockActivity));
    }

    @Test
    public void getFlutterView_returnsFlutterViewForFlutterActivity() {
        FlutterView mockFlutterView = mock(FlutterView.class);
        FlutterActivity mockFlutterActivity = mock(FlutterActivity.class);
        when(mockFlutterActivity.findViewById(FlutterActivity.FLUTTER_VIEW_ID))
                .thenReturn(mockFlutterView);
        assertEquals(
                FlutterDeviceScreenshot.getFlutterView(mockFlutterActivity),
                mockFlutterView
        );
    }

    @Test
    public void getFlutterView_returnsFlutterViewForFlutterFragmentActivity() {
        FlutterView mockFlutterView = mock(FlutterView.class);
        FlutterFragmentActivity mockFlutterFragmentActivity = mock(FlutterFragmentActivity.class);
        when(mockFlutterFragmentActivity.findViewById(FlutterFragment.FLUTTER_VIEW_ID))
                .thenReturn(mockFlutterView);
        assertEquals(
                FlutterDeviceScreenshot.getFlutterView(mockFlutterFragmentActivity),
                mockFlutterView
        );
    }
}
