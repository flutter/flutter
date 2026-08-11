// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import io.flutter.Build.API_LEVELS;
import io.flutter.Log;
import java.util.List;

class IntentUtils {

  private static final String TAG = "IntentUtils";

  /**
   * Verify that the source of the Intent is self-sent for security purposes. Debug/profile builds
   * are allowed to bypass the verification.
   */
  static boolean isIntentSelfSent(@NonNull Activity activity) {
    boolean isSelfSent = checkIntentSource(activity);

    // Trust Intent in debug/profile modes.
    if (io.flutter.BuildConfig.DEBUG || io.flutter.BuildConfig.PROFILE) {
      if (!isSelfSent) {
        Log.w(
            TAG,
            "Intent verification failed: the Intent was not sent by this app. "
                + "This intent will be IGNORED in release builds to prevent security vulnerabilities. "
                + "If this launch was internal, see TODO(camsim99) for migration options.");
      } // TODO(camsim99): Possibly send more information about the Intent.
      return true;
    }

    return isSelfSent;
  }

  @VisibleForTesting
  static boolean checkIntentSource(@NonNull Activity activity) {
    // If the Activity is not exported, then automatically trust it. Non-exported
    // Activities can only be launched by components of the same app, apps with the
    // same user ID, or priviliged system components.
    try {
      PackageManager pm = activity.getPackageManager();
      ComponentName cn = activity.getComponentName();
      if (pm != null && cn != null) {
        ActivityInfo activityInfo = pm.getActivityInfo(cn, 0);
        if (!activityInfo.exported) {
          return true;
        }
      }
    } catch (PackageManager.NameNotFoundException e) {
    }

    // Android API 34+: Verify directly that the uinque user ID of the launcher
    // is the same as the app's.
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_34) {
      return activity.getLaunchedFromUid() == android.os.Process.myUid();
    }

    // Legacy verification fallback: Verify the launching Activity is within the
    // same application package or is result-expecting (started with
    // startActivityForResult or startActivityIfNeeded).
    String callingPackage = activity.getCallingPackage();
    if (callingPackage != null) {
      return callingPackage.equals(activity.getPackageName());
    }
    return false;
  }

  /**
   * Verify that an external Intent representing a valid deep link matches a publicly declared
   * filter.
   */
  static boolean isIntentValidForDeeplinking(@NonNull Intent intent, @NonNull Activity activity) {
    if (intent.getData() == null) return false;

    // ACTION_VIEW is the required Intent action for deeplinks.
    if (intent.getAction() == null || !intent.getAction().equals(Intent.ACTION_VIEW)) {
      return false;
    }

    // Create an implicit intent with the same action, data, and type to check if it
    // matches any of the declared intent-filters inside the app manifest.
    Intent implicitIntent = new Intent(Intent.ACTION_VIEW).setPackage(activity.getPackageName());
    if (intent.getType() != null) {
      implicitIntent.setDataAndType(intent.getData(), intent.getType());
    } else {
      implicitIntent.setData(intent.getData());
    }

    List<ResolveInfo> resolveInfos =
        activity.getPackageManager().queryIntentActivities(implicitIntent, 0);

    for (ResolveInfo resolveInfo : resolveInfos) {
      if (resolveInfo.activityInfo.name.equals(activity.getClass().getName())) {
        return true;
      }
      // Check if it matches an activity-alias target.
      if (resolveInfo.activityInfo.targetActivity != null
          && resolveInfo.activityInfo.targetActivity.equals(activity.getClass().getName())) {
        return true;
      }
    }
    return false;
  }
}
