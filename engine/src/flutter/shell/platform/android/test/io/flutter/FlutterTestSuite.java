// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import io.flutter.embedding.android.FlutterActivityAndFragmentDelegateTest;
import io.flutter.embedding.android.FlutterActivityTest;
import io.flutter.embedding.android.FlutterAndroidComponentTest;
import io.flutter.embedding.android.FlutterFragmentTest;
import io.flutter.embedding.android.FlutterViewTest;
import io.flutter.embedding.engine.FlutterEngineCacheTest;
import io.flutter.embedding.engine.FlutterEnginePluginRegistryTest;
import io.flutter.embedding.engine.FlutterJNITest;
import io.flutter.embedding.engine.RenderingComponentTest;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistryTest;
import io.flutter.embedding.engine.renderer.FlutterRendererTest;
import io.flutter.external.FlutterLaunchTests;
import io.flutter.plugin.common.StandardMessageCodecTest;
import io.flutter.plugin.editing.InputConnectionAdaptorTest;
import io.flutter.plugin.editing.TextInputPluginTest;
import io.flutter.plugin.platform.PlatformPluginTest;
import io.flutter.plugin.platform.SingleViewPresentationTest;
import io.flutter.util.PreconditionsTest;
import io.flutter.view.AccessibilityBridgeTest;
import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;
import test.io.flutter.embedding.engine.FlutterEngineTest;
import test.io.flutter.embedding.engine.FlutterShellArgsTest;
import test.io.flutter.embedding.engine.PluginComponentTest;
import test.io.flutter.embedding.engine.dart.DartExecutorTest;

@RunWith(Suite.class)
@SuiteClasses({
  DartExecutorTest.class,
  FlutterActivityAndFragmentDelegateTest.class,
  FlutterActivityTest.class,
  FlutterAndroidComponentTest.class,
  FlutterEngineCacheTest.class,
  FlutterEnginePluginRegistryTest.class,
  FlutterEngineTest.class,
  FlutterFragmentTest.class,
  FlutterJNITest.class,
  FlutterLaunchTests.class,
  FlutterShellArgsTest.class,
  FlutterRendererTest.class,
  FlutterViewTest.class,
  InputConnectionAdaptorTest.class,
  PlatformPluginTest.class,
  PluginComponentTest.class,
  PreconditionsTest.class,
  RenderingComponentTest.class,
  StandardMessageCodecTest.class,
  ShimPluginRegistryTest.class,
  SingleViewPresentationTest.class,
  SmokeTest.class,
  TextInputPluginTest.class,
  AccessibilityBridgeTest.class,
})
/** Runs all of the unit tests listed in the {@code @SuiteClasses} annotation. */
public class FlutterTestSuite {}
