// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepickerexample;

import static androidx.test.espresso.flutter.EspressoFlutter.onFlutterWidget;
import static androidx.test.espresso.flutter.action.FlutterActions.click;
import static androidx.test.espresso.flutter.assertion.FlutterAssertions.matches;
import static androidx.test.espresso.flutter.matcher.FlutterMatchers.withText;
import static androidx.test.espresso.flutter.matcher.FlutterMatchers.withValueKey;
import static androidx.test.espresso.intent.Intents.intended;
import static androidx.test.espresso.intent.Intents.intending;
import static androidx.test.espresso.intent.matcher.IntentMatchers.hasAction;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.net.Uri;
import androidx.test.espresso.intent.rule.IntentsTestRule;
import org.junit.Ignore;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TestRule;

public class ImagePickerPickTest {

  @Rule public TestRule rule = new IntentsTestRule<>(DriverExtensionActivity.class);

  @Test
  @Ignore("Doesn't run in Firebase Test Lab: https://github.com/flutter/flutter/issues/94748")
  public void imageIsPickedWithOriginalName() {
    Instrumentation.ActivityResult result =
        new Instrumentation.ActivityResult(
            Activity.RESULT_OK, new Intent().setData(Uri.parse("content://dummy/dummy.png")));
    intending(hasAction(Intent.ACTION_GET_CONTENT)).respondWith(result);
    onFlutterWidget(withValueKey("image_picker_example_from_gallery")).perform(click());
    onFlutterWidget(withText("PICK")).perform(click());
    intended(hasAction(Intent.ACTION_GET_CONTENT));
    onFlutterWidget(withValueKey("image_picker_example_picked_image_name"))
        .check(matches(withText("dummy.png")));
  }
}
