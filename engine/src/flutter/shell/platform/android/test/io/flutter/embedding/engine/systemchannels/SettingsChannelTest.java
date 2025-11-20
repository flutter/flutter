// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static io.flutter.Build.API_LEVELS;
import static junit.framework.TestCase.assertEquals;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.annotation.TargetApi;
import android.util.DisplayMetrics;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.SettingsChannel.ConfigurationQueue.SentConfiguration;
import io.flutter.plugin.common.BasicMessageChannel;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
public class SettingsChannelTest {
  @Test
  @TargetApi(API_LEVELS.API_33)
  @Config(sdk = API_LEVELS.API_33)
  @SuppressWarnings("deprecation")
  // DartExecutor.send is deprecated.
  public void setDisplayMetricsDoesNothingOnAPILevel33() {
    final DartExecutor executor = mock(DartExecutor.class);
    executor.onAttachedToJNI();
    final SettingsChannel settingsChannel = new SettingsChannel(executor);

    final ArgumentCaptor<ByteBuffer> messageCaptor = ArgumentCaptor.forClass(ByteBuffer.class);

    settingsChannel.startMessage().setDisplayMetrics(mock(DisplayMetrics.class)).send();

    verify(executor).send(eq("flutter/settings"), messageCaptor.capture(), isNull());
  }

  @Test
  public void configurationQueueWorks() {
    final SettingsChannel.ConfigurationQueue queue = new SettingsChannel.ConfigurationQueue();

    SentConfiguration config1 = new SentConfiguration(mock(DisplayMetrics.class));
    SentConfiguration config2 = new SentConfiguration(mock(DisplayMetrics.class));

    queue.enqueueConfiguration(config1);
    queue.enqueueConfiguration(config2);

    assertEquals(
        config1.generationNumber,
        queue.getConfiguration(config1.generationNumber).generationNumber);
    // Can get the same configuration more than once.
    assertEquals(
        config2.generationNumber,
        queue.getConfiguration(config2.generationNumber).generationNumber);
    assertEquals(
        config2.generationNumber,
        queue.getConfiguration(config2.generationNumber).generationNumber);

    SentConfiguration config3 = new SentConfiguration(mock(DisplayMetrics.class));
    SentConfiguration config4 = new SentConfiguration(mock(DisplayMetrics.class));

    queue.enqueueConfiguration(config3);
    queue.enqueueConfiguration(config4);

    assertEquals(
        config4.generationNumber,
        queue.getConfiguration(config4.generationNumber).generationNumber);
    // Can get the same configuration more than once.
    assertEquals(
        config4.generationNumber,
        queue.getConfiguration(config4.generationNumber).generationNumber);

    final BasicMessageChannel.Reply replyFor5 =
        queue.enqueueConfiguration(new SentConfiguration(mock(DisplayMetrics.class)));
    final SentConfiguration config6 = new SentConfiguration(mock(DisplayMetrics.class));
    final BasicMessageChannel.Reply replyFor6 = queue.enqueueConfiguration(config6);
    replyFor5.reply(null);
    replyFor6.reply(null);
    assertEquals(
        config6.generationNumber,
        queue.getConfiguration(config6.generationNumber).generationNumber);
    assertEquals(
        config6.generationNumber,
        queue.getConfiguration(config6.generationNumber).generationNumber);
  }

  // TODO(LongCatIsLooong): add tests for API 34 code path.
  // https://github.com/flutter/flutter/issues/128825
}
