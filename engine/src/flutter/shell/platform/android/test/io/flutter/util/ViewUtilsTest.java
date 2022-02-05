// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.util;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class ViewUtilsTest {
  @Test
  public void canGetActivity() {
    // Non activity context returns null
    Context nonActivityContext = mock(Context.class);
    assertEquals(null, ViewUtils.getActivity(nonActivityContext));

    Activity activity = mock(Activity.class);
    assertEquals(activity, ViewUtils.getActivity(activity));

    ContextWrapper wrapper = new ContextWrapper(new ContextWrapper(activity));
    assertEquals(activity, ViewUtils.getActivity(wrapper));
  }
}
