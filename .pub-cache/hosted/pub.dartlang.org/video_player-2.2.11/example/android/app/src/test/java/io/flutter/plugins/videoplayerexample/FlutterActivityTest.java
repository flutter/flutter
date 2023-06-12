// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayerexample;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugins.videoplayer.VideoPlayerPlugin;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(manifest = Config.NONE)
public class FlutterActivityTest {

  @Test
  public void disposeAllPlayers() {
    VideoPlayerPlugin videoPlayerPlugin = spy(new VideoPlayerPlugin());
    FlutterLoader flutterLoader = mock(FlutterLoader.class);
    FlutterJNI flutterJNI = mock(FlutterJNI.class);
    ArgumentCaptor<FlutterPlugin.FlutterPluginBinding> pluginBindingCaptor =
        ArgumentCaptor.forClass(FlutterPlugin.FlutterPluginBinding.class);

    when(flutterJNI.isAttached()).thenReturn(true);
    FlutterEngine engine =
        spy(new FlutterEngine(RuntimeEnvironment.application, flutterLoader, flutterJNI));
    FlutterEngineCache.getInstance().put("my_flutter_engine", engine);

    engine.getPlugins().add(videoPlayerPlugin);
    verify(videoPlayerPlugin, times(1)).onAttachedToEngine(pluginBindingCaptor.capture());

    engine.destroy();
    verify(videoPlayerPlugin, times(1)).onDetachedFromEngine(pluginBindingCaptor.capture());
    verify(videoPlayerPlugin, times(1)).initialize();
  }
}
