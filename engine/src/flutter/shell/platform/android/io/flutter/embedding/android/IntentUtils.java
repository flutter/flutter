package io.flutter.embedding.android;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Build;
import io.flutter.Build.API_LEVELS;
import io.flutter.BuildConfig;
import androidx.annotation.NonNull;
import java.util.List;

class IntentUtils {
  
  /**
   * Verify the source of the Intent.
   */
  static boolean isIntentSelfSent(@NonNull Activity activity) {
    if (io.flutter.BuildConfig.DEBUG || io.flutter.BuildConfig.PROFILE) {
      return true; // Trusted unconditionally in debug/profile mode
    }

    // Sandbox Check: Non-exported activities are implicitly trusted by the OS.
    try {
      ActivityInfo activityInfo = 
          activity.getPackageManager().getActivityInfo(activity.getComponentName(), 0);
      if (!activityInfo.exported) {
        return true;
      }
    } catch (PackageManager.NameNotFoundException e) {}

    // Android 14+ (API 34): Secure, OS-level verification for exported activities. 
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_34) {
      return activity.getLaunchedFromUid() == android.os.Process.myUid();
    }

    // Legacy verification fallback (API 21-33)
    String callingPackage = activity.getCallingPackage();
    if (callingPackage != null) {
      return callingPackage.equals(activity.getPackageName());
    }
    return false; 
  }

  /** 
   * Verify that an external Intent with a route matches a publicly declared filter.
   */
  static boolean isIntentValidForDeeplinking(@NonNull Intent intent, @NonNull Activity activity) {
    if (intent.getData() == null) return false;

    // Enforce ACTION_VIEW for all external deep links.
    if (intent.getAction() == null || !intent.getAction().equals(Intent.ACTION_VIEW)) {
      return false;
    }

    // Create an implicit intent with the same action, data, and type to check if it
    // matches any of our declared intent-filters inside the manifest.
    Intent implicitIntent = new Intent(Intent.ACTION_VIEW)
        .setPackage(activity.getPackageName());
    
    if (intent.getType() != null) {
      implicitIntent.setDataAndType(intent.getData(), intent.getType());
    } else {
      implicitIntent.setData(intent.getData());
    }
    
    List<ResolveInfo> resolveInfos = activity.getPackageManager().queryIntentActivities(implicitIntent, 0);
  
    for (ResolveInfo info : resolveInfos) {
      if (info.activityInfo.name.equals(activity.getClass().getName())) {
        return true;
      }
      // Check if it matches an activity-alias target
      if (info.activityInfo.targetActivity != null && 
          info.activityInfo.targetActivity.equals(activity.getClass().getName())) {
        return true;
      }
    }
    return false;
  }
}
