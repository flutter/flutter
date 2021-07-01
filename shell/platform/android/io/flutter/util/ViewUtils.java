// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.util;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;

public final class ViewUtils {
  /**
   * Retrieves the {@link Activity} from a given {@link Context}.
   *
   * <p>This method will recursively traverse up the context chain if it is a {@link ContextWrapper}
   * until it finds the first instance of the base context that is an {@link Activity}.
   */
  public static Activity getActivity(Context context) {
    if (context == null) {
      return null;
    }
    if (context instanceof Activity) {
      return (Activity) context;
    }
    if (context instanceof ContextWrapper) {
      // Recurse up chain of base contexts until we find an Activity.
      return getActivity(((ContextWrapper) context).getBaseContext());
    }
    return null;
  }
}
