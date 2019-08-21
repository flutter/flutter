// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenarios;

import android.content.Context;
import android.support.annotation.Nullable;

import java.nio.ByteBuffer;

import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StringCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public final class TextPlatformViewFactory extends PlatformViewFactory {
  TextPlatformViewFactory() {
    super(new MessageCodec<Object>() {
      @Nullable
      @Override
      public ByteBuffer encodeMessage(@Nullable Object o) {
        if (o instanceof String) {
          return StringCodec.INSTANCE.encodeMessage((String)o);
        }
        return null;
      }

      @Nullable
      @Override
      public Object decodeMessage(@Nullable ByteBuffer byteBuffer) {
        return StringCodec.INSTANCE.decodeMessage(byteBuffer);
      }
    });
  }

  @SuppressWarnings("unchecked")
  @Override
  public PlatformView create(Context context, int id, Object args) {
    String params = (String) args;
    return new TextPlatformView(context, id, params);
  }
}
