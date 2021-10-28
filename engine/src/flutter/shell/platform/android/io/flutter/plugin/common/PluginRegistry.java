// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import android.app.Activity;
import android.content.Intent;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

/**
 * Container class for Android API listeners used by {@link ActivityPluginBinding}.
 *
 * <p>This class also contains deprecated v1 embedding APIs used for plugin registration.
 *
 * <p>In v1 Android applications, an auto-generated and auto-updated plugin registrant class
 * (GeneratedPluginRegistrant) makes use of a {@link PluginRegistry} to register contributions from
 * each plugin mentioned in the application's pubspec file. The generated registrant class is, again
 * by default, called from the application's main {@link android.app.Activity}, itself a {@link
 * PluginRegistry}.
 */
public interface PluginRegistry {
  /**
   * Delegate interface for handling result of permissions requests on behalf of the main {@link
   * Activity}.
   */
  interface RequestPermissionsResultListener {
    /**
     * @param requestCode The request code passed in {@code
     *     ActivityCompat.requestPermissions(android.app.Activity, String[], int)}.
     * @param permissions The requested permissions.
     * @param grantResults The grant results for the corresponding permissions which is either
     *     {@code PackageManager.PERMISSION_GRANTED} or {@code PackageManager.PERMISSION_DENIED}.
     * @return true if the result has been handled.
     */
    boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults);
  }

  /**
   * Delegate interface for handling activity results on behalf of the main {@link
   * android.app.Activity}.
   */
  interface ActivityResultListener {
    /**
     * @param requestCode The integer request code originally supplied to {@code
     *     startActivityForResult()}, allowing you to identify who this result came from.
     * @param resultCode The integer result code returned by the child activity through its {@code
     *     setResult()}.
     * @param data An Intent, which can return result data to the caller (various data can be
     *     attached to Intent "extras").
     * @return true if the result has been handled.
     */
    boolean onActivityResult(int requestCode, int resultCode, Intent data);
  }

  /**
   * Delegate interface for handling new intents on behalf of the main {@link android.app.Activity}.
   */
  interface NewIntentListener {
    /**
     * @param intent The new intent that was started for the activity.
     * @return true if the new intent has been handled.
     */
    boolean onNewIntent(Intent intent);
  }

  /**
   * Delegate interface for handling user leave hints on behalf of the main {@link
   * android.app.Activity}.
   */
  interface UserLeaveHintListener {
    void onUserLeaveHint();
  }
}
