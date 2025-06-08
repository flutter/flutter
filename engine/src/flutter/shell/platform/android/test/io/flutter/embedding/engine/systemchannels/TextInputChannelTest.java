// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.systemchannels;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.annotation.TargetApi;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.Locale;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(shadows = {})
@RunWith(AndroidJUnit4.class)
@TargetApi(API_LEVELS.API_24)
public class TextInputChannelTest {
  @Test
  public void setEditableSizeAndTransformCompletes() throws JSONException {
    TextInputChannel textInputChannel = new TextInputChannel(mock(DartExecutor.class));
    textInputChannel.setTextInputMethodHandler(mock(TextInputChannel.TextInputMethodHandler.class));
    JSONObject arguments = new JSONObject();
    arguments.put("width", 100.0);
    arguments.put("height", 20.0);
    arguments.put("transform", new JSONArray(new double[16]));
    MethodCall call = new MethodCall("TextInput.setEditableSizeAndTransform", arguments);
    MethodChannel.Result result = mock(MethodChannel.Result.class);
    textInputChannel.parsingMethodHandler.onMethodCall(call, result);
    verify(result).success(null);
  }

  @Test
  @TargetApi(API_LEVELS.API_24)
  @Config(sdk = API_LEVELS.API_24)
  public void configurationFromJsonParsesHintLocales() throws JSONException, NoSuchFieldException {
    JSONObject arguments = new JSONObject();

    // Mandatory parameters.
    arguments.put("inputAction", "TextInputAction.done");
    arguments.put("textCapitalization", "TextCapitalization.none");
    JSONObject inputType = new JSONObject();
    inputType.put("name", "TextInputType.text");
    arguments.put("inputType", inputType);

    arguments.put("hintLocales", new JSONArray(new String[] {"en", "fr"}));
    final TextInputChannel.Configuration configuration =
        TextInputChannel.Configuration.fromJson(arguments);

    final Locale[] hintLocales = {
      new Locale.Builder().setLanguage("en").build(), new Locale.Builder().setLanguage("fr").build()
    };
    assertEquals(configuration.hintLocales.length, hintLocales.length);
    assertEquals(configuration.hintLocales[0], hintLocales[0]);
    assertEquals(configuration.hintLocales[1], hintLocales[1]);
  }
}
