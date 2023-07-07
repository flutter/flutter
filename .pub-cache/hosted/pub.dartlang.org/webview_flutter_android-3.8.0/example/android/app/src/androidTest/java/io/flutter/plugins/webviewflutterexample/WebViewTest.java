// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutterexample;

import static org.junit.Assert.assertTrue;

import androidx.test.core.app.ActivityScenario;
import io.flutter.plugins.webviewflutter.WebViewFlutterPlugin;
import org.junit.Test;

public class WebViewTest {
  @Test
  public void webViewPluginIsAdded() {
    final ActivityScenario<WebViewTestActivity> scenario =
        ActivityScenario.launch(WebViewTestActivity.class);
    scenario.onActivity(
        activity -> {
          assertTrue(activity.engine.getPlugins().has(WebViewFlutterPlugin.class));
        });
  }
}
