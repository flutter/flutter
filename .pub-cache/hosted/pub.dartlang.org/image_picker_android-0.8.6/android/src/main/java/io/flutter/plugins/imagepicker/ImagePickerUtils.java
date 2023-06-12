// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import java.util.Arrays;

final class ImagePickerUtils {
  /** returns true, if permission present in manifest, otherwise false */
  private static boolean isPermissionPresentInManifest(Context context, String permissionName) {
    try {
      PackageManager packageManager = context.getPackageManager();
      // TODO(stuartmorgan): Add new codepath: https://github.com/flutter/flutter/issues/121816
      @SuppressWarnings("deprecation")
      PackageInfo packageInfo =
          packageManager.getPackageInfo(context.getPackageName(), PackageManager.GET_PERMISSIONS);

      String[] requestedPermissions = packageInfo.requestedPermissions;
      return Arrays.asList(requestedPermissions).contains(permissionName);
    } catch (PackageManager.NameNotFoundException e) {
      e.printStackTrace();
      return false;
    }
  }

  /**
   * Camera permission need request if it present in manifest, because for M or great for take Photo
   * ar Video by intent need it permission, even if the camera permission is not used.
   *
   * <p>Camera permission may be used in another package, as example flutter_barcode_reader.
   * https://github.com/flutter/flutter/issues/29837
   *
   * @return returns true, if need request camera permission, otherwise false
   */
  static boolean needRequestCameraPermission(Context context) {
    boolean greatOrEqualM = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M;
    return greatOrEqualM && isPermissionPresentInManifest(context, Manifest.permission.CAMERA);
  }
}
