// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.scenariosui;

import static org.junit.Assert.*;

import android.content.Intent;
import android.graphics.Bitmap;
import androidx.annotation.NonNull;
import androidx.test.filters.LargeTest;
import androidx.test.rule.ActivityTestRule;
import androidx.test.runner.AndroidJUnit4;
import dev.flutter.scenarios.GetBitmapActivity;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
@LargeTest
public class GetBitmapTests {
  @Rule @NonNull
  public ActivityTestRule<GetBitmapActivity> activityRule =
      new ActivityTestRule<>(
          GetBitmapActivity.class, /*initialTouchMode=*/ false, /*launchActivity=*/ false);

  @Test
  public void getBitmap() throws Exception {
    Intent intent = new Intent(Intent.ACTION_MAIN);
    intent.putExtra("scenario_name", "get_bitmap");
    GetBitmapActivity activity = activityRule.launchActivity(intent);
    Bitmap bitmap = activity.getBitmap();

    assertEquals(bitmap.getPixel(10, 10), 0xFFFF0000);
    assertEquals(bitmap.getPixel(10, bitmap.getHeight() - 10), 0xFF0000FF);
  }
}
